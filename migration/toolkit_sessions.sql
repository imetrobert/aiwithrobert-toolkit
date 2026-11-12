-- AI with Robert Toolkit: cloud copy of saved sessions.
-- Run once in the Supabase SQL editor (project shared with the other apps).
-- Follows the PERSONAL policy shape from Supabase-platform-/migration/app_access_pattern.sql
-- (gated by has_app_access('toolkit'); reads widen for an app_admin, writes stay ownership-only).

create table if not exists public.toolkit_sessions (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id         text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint toolkit_sessions_id_chk check (id ~ '^[A-Za-z0-9_-]{1,64}$')
);

alter table public.toolkit_sessions enable row level security;

drop policy if exists "toolkit_sessions select" on public.toolkit_sessions;
create policy "toolkit_sessions select" on public.toolkit_sessions
  for select to authenticated
  using (public.has_app_access('toolkit')
         and (public.app_role('toolkit') = 'app_admin' or user_id = auth.uid()));

drop policy if exists "toolkit_sessions insert" on public.toolkit_sessions;
create policy "toolkit_sessions insert" on public.toolkit_sessions
  for insert to authenticated
  with check (public.has_app_access('toolkit') and user_id = auth.uid());

drop policy if exists "toolkit_sessions update" on public.toolkit_sessions;
create policy "toolkit_sessions update" on public.toolkit_sessions
  for update to authenticated
  using (public.has_app_access('toolkit') and user_id = auth.uid())
  with check (public.has_app_access('toolkit') and user_id = auth.uid());

drop policy if exists "toolkit_sessions delete" on public.toolkit_sessions;
create policy "toolkit_sessions delete" on public.toolkit_sessions
  for delete to authenticated
  using (public.has_app_access('toolkit') and user_id = auth.uid());

-- Explicit Data API grants (Supabase no longer grants these automatically on new tables).
revoke all on public.toolkit_sessions from anon;
grant select, insert, update, delete on public.toolkit_sessions to authenticated;
-- Supabase default privileges also hand out these; the app does not need them (TRUNCATE ignores RLS).
revoke truncate, references, trigger, maintain on public.toolkit_sessions from authenticated;
grant all on public.toolkit_sessions to service_role;
