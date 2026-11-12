# AI with Robert Toolkit

Private client-session tool at https://toolkit.aiwithrobert.com — intake, prompt composer,
AI-reply import/validation, editor and branded client deliverable. One static file
(`index.html`); no build step.

- **Access:** signs in with the shared Supabase project; gated by `has_app_access('toolkit')`
  (manage on https://access.imetrobert.com).
- **AI step:** manual copy/paste into a free AI tool; no API keys.
- **Branding and output types:** `BRANDING` and `OUTPUT_TYPES` sections at the top of the script in `index.html`.
- **Data:** session data stays in the phone's browser; nothing client-related is sent to a server.

## Cloud sync

Saved sessions also sync to `public.toolkit_sessions` in the shared Supabase project. Run `migration/toolkit_sessions.sql` once in the Supabase SQL editor. Until then the app works as before and shows "Cloud sync is not set up yet".
