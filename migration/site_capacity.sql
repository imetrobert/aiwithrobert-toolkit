-- AI with Robert Toolkit: "At capacity" mode for the Seniors and Business websites.
-- Run once in the Supabase SQL editor (same project as the other apps), BEFORE using the
-- toolkit's "Site availability" screen or deploying the site changes.
--
-- site_status       one row per site (seniors, business). The toolkit writes it; the public
--                   sites only call the site_capacity() function (they never read the table).
-- waitlist_requests people who join the waitlist from a site while it is at capacity.
--                   Public sites can only call join_waitlist(); the toolkit reads the rows.
-- Both tables are gated by has_app_access('toolkit'), like toolkit_sessions.
-- Explicit Data API grants are included (Supabase no longer grants them automatically).

create table if not exists public.site_status (
  site         text primary key check (site in ('seniors', 'business')),
  manual_on    boolean not null default false,
  start_at     timestamptz,
  end_at       timestamptz,
  reopen_date  date,
  updated_at   timestamptz not null default now(),
  constraint site_status_window_chk check (end_at is null or start_at is null or end_at > start_at)
);

insert into public.site_status (site) values ('seniors'), ('business') on conflict (site) do nothing;

alter table public.site_status enable row level security;

drop policy if exists "site_status select" on public.site_status;
create policy "site_status select" on public.site_status
  for select to authenticated using (public.has_app_access('toolkit'));

drop policy if exists "site_status insert" on public.site_status;
create policy "site_status insert" on public.site_status
  for insert to authenticated with check (public.has_app_access('toolkit'));

drop policy if exists "site_status update" on public.site_status;
create policy "site_status update" on public.site_status
  for update to authenticated
  using (public.has_app_access('toolkit')) with check (public.has_app_access('toolkit'));

revoke all on public.site_status from anon;
revoke delete on public.site_status from authenticated;  -- Supabase default privileges also grant it; no policy allows it anyway
grant select, insert, update on public.site_status to authenticated;
revoke truncate, references, trigger, maintain on public.site_status from authenticated;
grant all on public.site_status to service_role;

-- Waitlist ---------------------------------------------------------------------------
create table if not exists public.waitlist_requests (
  id           uuid primary key default gen_random_uuid(),
  site         text not null check (site in ('seniors', 'business')),
  name         text not null check (char_length(name) between 1 and 120),
  organization text not null default '' check (char_length(organization) <= 160),
  email        text not null check (char_length(email) between 5 and 200),
  phone        text not null default '' check (char_length(phone) <= 40),
  services     text[] not null default '{}',
  language     text not null default 'en' check (language in ('en', 'fr')),
  status       text not null default 'new' check (status in ('new', 'contacted', 'archived')),
  created_at   timestamptz not null default now()
);

create index if not exists waitlist_requests_site_created_idx on public.waitlist_requests (site, created_at desc);

alter table public.waitlist_requests enable row level security;

drop policy if exists "waitlist select" on public.waitlist_requests;
create policy "waitlist select" on public.waitlist_requests
  for select to authenticated using (public.has_app_access('toolkit'));

drop policy if exists "waitlist update" on public.waitlist_requests;
create policy "waitlist update" on public.waitlist_requests
  for update to authenticated
  using (public.has_app_access('toolkit')) with check (public.has_app_access('toolkit'));

drop policy if exists "waitlist delete" on public.waitlist_requests;
create policy "waitlist delete" on public.waitlist_requests
  for delete to authenticated using (public.has_app_access('toolkit'));

revoke all on public.waitlist_requests from anon;
revoke insert on public.waitlist_requests from authenticated;  -- inserts only happen through join_waitlist()
grant select, update, delete on public.waitlist_requests to authenticated;
revoke truncate, references, trigger, maintain on public.waitlist_requests from authenticated;
grant all on public.waitlist_requests to service_role;

-- Public functions (called by the websites with the publishable key) -----------------------
-- True when the site is at capacity right now: the manual switch is on, or "now" falls inside
-- the scheduled window. Decided on the server clock, so no scheduled job is needed.
create or replace function public.site_capacity(p_site text)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    (select jsonb_build_object(
        'at_capacity', (s.manual_on or (s.start_at is not null and s.start_at <= now() and (s.end_at is null or now() < s.end_at))),
        'reopen', s.reopen_date)
       from public.site_status s where s.site = p_site),
    jsonb_build_object('at_capacity', false, 'reopen', null));
$$;

-- Adds a waitlist entry. Only works while the site is at capacity, validates every field,
-- ignores a repeat from the same email within 24 hours and throttles bursts.
create or replace function public.join_waitlist(
  p_site text, p_name text, p_organization text, p_email text, p_phone text,
  p_services text[], p_language text, p_consent boolean)
returns boolean
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_name  text := btrim(coalesce(p_name, ''));
  v_svc   text[];
begin
  if p_site not in ('seniors', 'business') then raise exception 'invalid_site'; end if;
  if coalesce(p_consent, false) is not true then raise exception 'consent_required'; end if;
  if not coalesce((public.site_capacity(p_site) ->> 'at_capacity')::boolean, false) then raise exception 'not_at_capacity'; end if;
  if v_name = '' or char_length(v_name) > 120 then raise exception 'invalid_name'; end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or char_length(v_email) > 200 then raise exception 'invalid_email'; end if;
  if char_length(coalesce(p_organization, '')) > 160 or char_length(coalesce(p_phone, '')) > 40 then raise exception 'too_long'; end if;
  select coalesce(array_agg(left(btrim(x), 80)), '{}') into v_svc
    from (select x from unnest(coalesce(p_services, '{}')) as x where btrim(x) <> '' limit 10) t;
  if exists (select 1 from public.waitlist_requests where site = p_site and lower(email) = v_email and created_at > now() - interval '24 hours') then
    return true;
  end if;
  if (select count(*) from public.waitlist_requests where site = p_site and created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'busy';
  end if;
  insert into public.waitlist_requests (site, name, organization, email, phone, services, language)
  values (p_site, v_name, btrim(coalesce(p_organization, '')), v_email, btrim(coalesce(p_phone, '')), v_svc,
          case when p_language = 'fr' then 'fr' else 'en' end);
  return true;
end;
$$;

revoke all on function public.site_capacity(text) from public;
revoke all on function public.join_waitlist(text, text, text, text, text, text[], text, boolean) from public;
grant execute on function public.site_capacity(text) to anon, authenticated;
grant execute on function public.join_waitlist(text, text, text, text, text, text[], text, boolean) to anon, authenticated;
