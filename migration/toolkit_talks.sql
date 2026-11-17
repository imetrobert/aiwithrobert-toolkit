-- AI with Robert Toolkit: speaking engagements (the "Speaking engagements" screen).
-- Run once in the Supabase SQL editor (project shared with the other apps), BEFORE opening that screen.
-- One row per talk; the details live in the jsonb column `data` (title, organizer, contact, date, place, audience size, fee,
-- Seniors or Business, language, status, notes, QR slug). Same personal-ownership policy shape as toolkit_sessions
-- (gated by has_app_access('toolkit'); an app_admin can read everyone's, writes stay ownership-only).

create table if not exists public.toolkit_talks (
  id         uuid        not null default gen_random_uuid() primary key,
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb       not null,
  updated_at timestamptz not null default now()
);

alter table public.toolkit_talks enable row level security;

drop policy if exists "toolkit_talks select" on public.toolkit_talks;
create policy "toolkit_talks select" on public.toolkit_talks
  for select to authenticated
  using (public.has_app_access('toolkit')
         and (public.app_role('toolkit') = 'app_admin' or user_id = auth.uid()));

drop policy if exists "toolkit_talks insert" on public.toolkit_talks;
create policy "toolkit_talks insert" on public.toolkit_talks
  for insert to authenticated
  with check (public.has_app_access('toolkit') and user_id = auth.uid());

drop policy if exists "toolkit_talks update" on public.toolkit_talks;
create policy "toolkit_talks update" on public.toolkit_talks
  for update to authenticated
  using (public.has_app_access('toolkit') and user_id = auth.uid())
  with check (public.has_app_access('toolkit') and user_id = auth.uid());

drop policy if exists "toolkit_talks delete" on public.toolkit_talks;
create policy "toolkit_talks delete" on public.toolkit_talks
  for delete to authenticated
  using (public.has_app_access('toolkit') and user_id = auth.uid());

-- Explicit Data API grants (Supabase no longer grants these automatically on new tables).
revoke all on public.toolkit_talks from anon;
grant select, insert, update, delete on public.toolkit_talks to authenticated;
-- Supabase default privileges also hand out these; the app does not need them (TRUNCATE ignores RLS).
revoke truncate, references, trigger, maintain on public.toolkit_talks from authenticated;
grant all on public.toolkit_talks to service_role;
