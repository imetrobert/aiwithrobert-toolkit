# If something breaks (read this first, then fix only what it names)

1. **Red "Maintain" run or email:** open the run and read the last lines. Usual cause: a price drifted. `FX_PRICE` in `index.html` must equal the Pricing section on biz.aiwithrobert.com (and `llms.txt`, and `BUSINESS_SERVICES` in the invoicing app); fix the wrong side, then `python3 scripts/check_toolkit.py`.
2. **JavaScript error or blank screen:** `python3 scripts/check_toolkit.py` reports the syntax error. Never read `index.html` whole; use `docs/code-map.md` and `grep -n`.
3. **Sign-in or "no access":** grant the app `toolkit` at access.imetrobert.com. The shared Supabase login is used by every private app.
4. **A screen shows no data (Leads, Inquiries, Waitlist, Testimonials):** the migration for that table was probably not run in the Supabase SQL editor, or its Data API grants are missing (every migration in `migration/` must contain them). Give the fix to the Supabase AI assistant as a prompt.
5. **A phone shows an old version:** reload in Safari; the Home Screen copy can be stale.
6. Address or HTTPS problem: Settings > Pages (source `main`, custom domain from `CNAME`).
