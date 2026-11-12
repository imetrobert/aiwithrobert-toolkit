-- AI with Robert Toolkit: copy of every contact-form submission (Seniors and Business sites).
-- Run once in the Supabase SQL editor, AFTER migration/site_capacity.sql (no dependency on it, but same pattern).
-- The sites still send the formsubmit.co email; this adds a saved copy that the toolkit's "Inquiries" screen reads.
-- Public sites can only call submit_inquiry(); only people with toolkit access can read, update or delete rows.
-- Explicit Data API grants are included (Supabase no longer grants them automatically).

create table if not exists public.site_inquiries (
  id           uuid primary key default gen_random_uuid(),
  site         text not null check (site in ('seniors', 'business')),
  name         text not null check (char_length(name) between 1 and 120),
  organization text not null default '' check (char_length(organization) <= 160),
  email        text not null check (char_length(email) between 5 and 200),
  phone        text not null default '' check (char_length(phone) <= 40),
  message      text not null default '' check (char_length(message) <= 4000),
  extra        jsonb not null default '{}'::jsonb check (jsonb_typeof(extra) = 'object' and octet_length(extra::text) <= 4000),
  language     text not null default 'en' check (language in ('en', 'fr')),
  status       text not null default 'new' check (status in ('new', 'contacted', 'archived')),
  created_at   timestamptz not null default now()
);

create index if not exists site_inquiries_site_created_idx on public.site_inquiries (site, created_at desc);

alter table public.site_inquiries enable row level security;

drop policy if exists "inquiries select" on public.site_inquiries;
create policy "inquiries select" on public.site_inquiries
  for select to authenticated using (public.has_app_access('toolkit'));

drop policy if exists "inquiries update" on public.site_inquiries;
create policy "inquiries update" on public.site_inquiries
  for update to authenticated
  using (public.has_app_access('toolkit')) with check (public.has_app_access('toolkit'));

drop policy if exists "inquiries delete" on public.site_inquiries;
create policy "inquiries delete" on public.site_inquiries
  for delete to authenticated using (public.has_app_access('toolkit'));

revoke all on public.site_inquiries from anon;
revoke all on public.site_inquiries from authenticated;
grant select, update, delete on public.site_inquiries to authenticated;
grant all on public.site_inquiries to service_role;

-- Public function called by the websites (publishable key). Validates every field, ignores an identical
-- repeat within 10 minutes (double taps) and throttles bursts.
create or replace function public.submit_inquiry(
  p_site text, p_name text, p_organization text, p_email text, p_phone text,
  p_message text, p_extra jsonb, p_language text)
returns boolean
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_name  text := btrim(coalesce(p_name, ''));
  v_msg   text := btrim(coalesce(p_message, ''));
  v_extra jsonb := coalesce(p_extra, '{}'::jsonb);
begin
  if p_site not in ('seniors', 'business') then raise exception 'invalid_site'; end if;
  if v_name = '' or char_length(v_name) > 120 then raise exception 'invalid_name'; end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or char_length(v_email) > 200 then raise exception 'invalid_email'; end if;
  if char_length(coalesce(p_organization, '')) > 160 or char_length(coalesce(p_phone, '')) > 40 or char_length(v_msg) > 4000 then raise exception 'too_long'; end if;
  if jsonb_typeof(v_extra) <> 'object' or octet_length(v_extra::text) > 4000 then raise exception 'invalid_extra'; end if;
  if exists (select 1 from public.site_inquiries where site = p_site and lower(email) = v_email and message = v_msg and created_at > now() - interval '10 minutes') then
    return true;
  end if;
  if (select count(*) from public.site_inquiries where site = p_site and created_at > now() - interval '10 minutes') >= 40 then
    raise exception 'busy';
  end if;
  insert into public.site_inquiries (site, name, organization, email, phone, message, extra, language)
  values (p_site, v_name, btrim(coalesce(p_organization, '')), v_email, btrim(coalesce(p_phone, '')), v_msg, v_extra,
          case when p_language = 'fr' then 'fr' else 'en' end);
  return true;
end;
$$;

revoke all on function public.submit_inquiry(text, text, text, text, text, text, jsonb, text) from public;
grant execute on function public.submit_inquiry(text, text, text, text, text, text, jsonb, text) to anon, authenticated;
