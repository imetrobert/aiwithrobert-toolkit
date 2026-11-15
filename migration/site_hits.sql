-- AI with Robert Toolkit: anonymous visit counters for the Business, Seniors and Hub websites.
-- Run once in the Supabase SQL editor (same project as the other apps), BEFORE using the toolkit's
-- "Website metrics" screen or deploying js/hits.js on the sites.
--
-- site_hits   one row per day + site + kind + name + source, with a counter. No IP address, no cookie, no
--             per-person data: the sites only add 1 to a counter. Public sites call track_hit() only
--             (they never read the table); the toolkit reads it (gated by has_app_access('toolkit')).
--   kind 'visit'  first page of the day on a device (about one per person per day)
--   kind 'view'   a page view; name = page path, e.g. /services/ai-workflow-setup/
--   kind 'event'  a click or form: feasibility_submit, generate_lead, email_click, phone_click, booking_click,
--                 brand_card_click:seniors / brand_card_click:business
--   source        utm_source if the link had one, else the referring website (host name), else '' (direct)
-- Explicit Data API grants are included (Supabase no longer grants them automatically).

create table if not exists public.site_hits (
  day     date not null,
  site    text not null check (site in ('seniors', 'business', 'hub')),
  kind    text not null check (kind in ('visit', 'view', 'event')),
  name    text not null default '' check (char_length(name) <= 80),
  source  text not null default '' check (char_length(source) <= 40),
  n       integer not null default 0,
  primary key (day, site, kind, name, source)
);

create index if not exists site_hits_day_idx on public.site_hits (day desc);

alter table public.site_hits enable row level security;

drop policy if exists "site_hits select" on public.site_hits;
create policy "site_hits select" on public.site_hits
  for select to authenticated using (public.has_app_access('toolkit'));

revoke all on public.site_hits from anon;
revoke insert, update, delete on public.site_hits from authenticated;  -- only track_hit() writes
grant select on public.site_hits to authenticated;
revoke truncate, references, trigger, maintain on public.site_hits from authenticated;
grant all on public.site_hits to service_role;

-- Public function (called by the websites with the publishable key). Validates every value, adds 1, and
-- stops creating NEW rows once a day already has 3000 (junk protection); existing rows still count.
create or replace function public.track_hit(p_site text, p_kind text, p_name text, p_source text)
returns void
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_day    date := (now() at time zone 'America/Toronto')::date;
  v_name   text := lower(btrim(coalesce(p_name, '')));
  v_source text := lower(btrim(coalesce(p_source, '')));
  v_rows   integer;
begin
  if p_site not in ('seniors', 'business', 'hub') then return; end if;
  if p_kind not in ('visit', 'view', 'event') then return; end if;
  if p_kind = 'visit' then v_name := '';
  elsif p_kind = 'view' then
    if v_name !~ '^/[a-z0-9/_.-]{0,78}$' then return; end if;
  else
    if v_name !~ '^[a-z_]{3,40}(:[a-z0-9_-]{1,20})?$' then return; end if;
  end if;
  if v_source !~ '^[a-z0-9._/-]{0,40}$' then v_source := ''; end if;

  update public.site_hits set n = n + 1
   where day = v_day and site = p_site and kind = p_kind and name = v_name and source = v_source;
  if found then return; end if;
  select count(*) into v_rows from public.site_hits where day = v_day;
  if v_rows >= 3000 then return; end if;
  insert into public.site_hits (day, site, kind, name, source, n) values (v_day, p_site, p_kind, v_name, v_source, 1)
  on conflict (day, site, kind, name, source) do update set n = public.site_hits.n + 1;
end;
$$;

revoke all on function public.track_hit(text, text, text, text) from public;
grant execute on function public.track_hit(text, text, text, text) to anon, authenticated;
