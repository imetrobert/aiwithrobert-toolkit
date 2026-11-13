-- AI with Robert Toolkit: published data the public Business site may read (free feasibility check).
-- Run once in the Supabase SQL editor. Until it is run, the website uses the table built into js/feascheck.js.
-- One row per key. key 'caps' = the capability table as verdicts only: {"verified":"YYYY-MM-DD","cells":{need:{tool:"yes|partial|no|unknown"}}}.
-- The toolkit writes it (Feasibility check > Import updated table, or "Publish this table to the website").
-- The public site can only call public_caps(); only people with toolkit access can read or write the table.
-- Explicit Data API grants are included (Supabase no longer grants them automatically).

create table if not exists public.site_public_data (
  key        text primary key check (key in ('caps')),
  data       jsonb not null check (jsonb_typeof(data) = 'object' and octet_length(data::text) <= 20000),
  updated_at timestamptz not null default now()
);

alter table public.site_public_data enable row level security;

drop policy if exists "public data select" on public.site_public_data;
create policy "public data select" on public.site_public_data
  for select to authenticated using (public.has_app_access('toolkit'));

drop policy if exists "public data insert" on public.site_public_data;
create policy "public data insert" on public.site_public_data
  for insert to authenticated with check (public.has_app_access('toolkit'));

drop policy if exists "public data update" on public.site_public_data;
create policy "public data update" on public.site_public_data
  for update to authenticated
  using (public.has_app_access('toolkit')) with check (public.has_app_access('toolkit'));

revoke all on public.site_public_data from anon;
revoke all on public.site_public_data from authenticated;
grant select, insert, update on public.site_public_data to authenticated;
grant all on public.site_public_data to service_role;

-- Public function called by the website (publishable key). Returns the published capability verdicts, or null.
create or replace function public.public_caps()
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select data from public.site_public_data where key = 'caps';
$$;

revoke all on function public.public_caps() from public;
grant execute on function public.public_caps() to anon, authenticated;
