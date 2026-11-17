-- AI with Robert Toolkit: testimonial vault (the "Testimonials" screen) and the public feed the two websites read.
-- Run once in the Supabase SQL editor BEFORE opening that screen.
-- One row per testimonial. `data` keeps the private working copy (reply as received, consent record) AND `data.shown`, the
-- exact wording and credit the website may display. The database refuses to publish a row without a consent date and approved wording.
-- Websites call public_testimonials(site) with the publishable key and get ONLY published rows, ONLY the `shown` part.
-- Same access gate as the other toolkit tables (has_app_access('toolkit')). Explicit Data API grants are included.

create table if not exists public.site_testimonials (
  id           uuid        not null default gen_random_uuid() primary key,
  site         text        not null check (site in ('seniors', 'business')),
  status       text        not null default 'draft' check (status in ('draft', 'published')),
  data         jsonb       not null check (jsonb_typeof(data) = 'object' and octet_length(data::text) <= 12000),
  published_at timestamptz,
  updated_at   timestamptz not null default now(),
  constraint site_testimonials_consent check (
    status <> 'published'
    or (coalesce(data->>'consent_date', '') ~ '^\d{4}-\d{2}-\d{2}$'
        and coalesce(data->>'consent', 'none') <> 'none'
        and length(coalesce(data->'shown'->>'text', '')) between 20 and 1200)
  )
);

alter table public.site_testimonials enable row level security;

drop policy if exists "site_testimonials select" on public.site_testimonials;
create policy "site_testimonials select" on public.site_testimonials
  for select to authenticated using (public.has_app_access('toolkit'));

drop policy if exists "site_testimonials insert" on public.site_testimonials;
create policy "site_testimonials insert" on public.site_testimonials
  for insert to authenticated with check (public.has_app_access('toolkit'));

drop policy if exists "site_testimonials update" on public.site_testimonials;
create policy "site_testimonials update" on public.site_testimonials
  for update to authenticated
  using (public.has_app_access('toolkit')) with check (public.has_app_access('toolkit'));

drop policy if exists "site_testimonials delete" on public.site_testimonials;
create policy "site_testimonials delete" on public.site_testimonials
  for delete to authenticated using (public.has_app_access('toolkit'));

-- Explicit Data API grants (Supabase no longer grants these automatically on new tables).
revoke all on public.site_testimonials from anon;
grant select, insert, update, delete on public.site_testimonials to authenticated;
-- Supabase default privileges also hand out these; the app does not need them (TRUNCATE ignores RLS).
revoke truncate, references, trigger, maintain on public.site_testimonials from authenticated;
grant all on public.site_testimonials to service_role;

-- Public function the websites call. Only published rows, only the display part (name, role, organization, context, text, optional Google review link, language of the quote, optional approved translation).
create or replace function public.public_testimonials(p_site text)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(t.shown order by t.published_at desc), '[]'::jsonb)
  from (
    select jsonb_build_object(
             'name',    left(coalesce(data->'shown'->>'name', ''), 80),
             'role',    left(coalesce(data->'shown'->>'role', ''), 120),
             'org',     left(coalesce(data->'shown'->>'org', ''), 120),
             'context', left(coalesce(data->'shown'->>'context', ''), 160),
             'text',    left(coalesce(data->'shown'->>'text', ''), 1200),
             'review_url', left(coalesce(data->'shown'->>'review_url', ''), 300),
             'lang',    case when data->'shown'->>'lang' = 'fr' then 'fr' else 'en' end,
             'text_alt', left(coalesce(data->'shown'->>'text_alt', ''), 1200),
             'context_alt', left(coalesce(data->'shown'->>'context_alt', ''), 160)
           ) as shown,
           published_at
    from public.site_testimonials
    where site = p_site and status = 'published'
    order by published_at desc
    limit 12
  ) t;
$$;

revoke all on function public.public_testimonials(text) from public;
grant execute on function public.public_testimonials(text) to anon, authenticated;
