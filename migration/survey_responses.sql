-- Workshop survey responses (paper feedback forms read by the toolkit's Surveys screen).
-- Safe to run more than once. The table already exists in the live database (it was created for the invoicing app's
-- survey screens); this file records it in the toolkit repo and makes sure toolkit users can read and write it.
-- Run in the Supabase SQL editor. Explicit Data API grants are included (Supabase no longer auto-grants new tables).

create table if not exists public.survey_responses (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  workshop_date date,
  workshop_location text,
  first_name text, last_name text, email text, phone text, address text,
  age_range text, preferred_language text, gender text,
  tech_comfort text, tech_interest text, ai_interest text,
  topics text[] not null default '{}',
  topics_other text,
  learning_format text, zoom_comfort text, online_preference text,
  ongoing_support text[] not null default '{}',
  enjoyed_most text, next_topic_comments text,
  wants_newsletter boolean not null default false,
  manually_reviewed boolean not null default false,
  source_pdf_name text
);

alter table public.survey_responses enable row level security;

-- Toolkit users (has_app_access('toolkit')) can read, add and delete. Existing policies, if any, are left alone.
drop policy if exists survey_toolkit_select on public.survey_responses;
create policy survey_toolkit_select on public.survey_responses for select to authenticated using (public.has_app_access('toolkit'));
drop policy if exists survey_toolkit_insert on public.survey_responses;
create policy survey_toolkit_insert on public.survey_responses for insert to authenticated with check (public.has_app_access('toolkit'));
drop policy if exists survey_toolkit_delete on public.survey_responses;
create policy survey_toolkit_delete on public.survey_responses for delete to authenticated using (public.has_app_access('toolkit'));

grant select, insert, delete on public.survey_responses to authenticated;
grant all on public.survey_responses to service_role;
