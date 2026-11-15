# Common edits — recipes (toolkit)

Find the line with `docs/code-map.md` or `grep -n "NAME" index.html`, read only that range, edit, push to `main`. The Maintain workflow
checks the file (syntax, migration grants, prices vs website) and refreshes the code map. Reload in Safari (not the Home Screen icon) to see the change.

## Change a price (Proposal builder and quotes)
`FX_PRICE` (assessSmall 900, assessLarge 1800, workflow 2000, partialAdd 500, training 1500, trainingIncluded 10, trainingExtra 100, bundleOff 0.1).
Must equal the Business website Pricing section (+ `llms.txt`, `ba-math-text`) and `BUSINESS_SERVICES` in the invoicing app. The weekly Maintain run fails if
a number is missing from the website's pricing text.

## Refresh the feasibility rules (every 3 months; the home screen shows a stripe at 90 days)
Feasibility screen > "Copy refresh prompt" > paste into a free AI chat with web search > paste the JSON reply into "Import updated table". Importing also
publishes the verdicts to the Business website (re-import the table to publish again). The built-in fallback table is `CAPS_BUILTIN`;
the stripe threshold is `CAPS_REFRESH_DAYS`.

## Change the email templates for leads (invite, reopen, Seniors reopen)
`LEAD_MAIL` (EN and FR), sender `BIZ_FROM`, booking link `BOOKING_URL` (must equal `BOOKING` in the Business site's `js/feascheck.js`; the Maintain run checks).

## Update the free AI tool advice (which chatbot to recommend)
`TOOLS` (name, url, strong, limit) and `recommendTools()`. Edit when free plans change.

## Change the AI prompt rules
`buildPrompt()` holds the PERSONALISATION RULES, LENGTH RULE, VENUE rule and TRANSCRIPT RULES; `VOICE` holds per-brand voice guardrails; `JSON_RULES` is appended to every
prompt so replies can be read by `readAiJson()`. Intake questions: `VENUE_Q`, `SIZE_QS`, `TRANSCRIPT_Q` and the `examples` question.

## Change brand colours, logo, footer or tagline
`BRANDING.brands.seniors` / `.business` (colours, line1/line2 footer, `tag` EN/FR); logos are `LOGO` and `LOGO_BIZ` (base64 PNG). Output styling is the CSS block
"Polished client output" at the end of the style section.

## Add or change a material type
`OUTPUT_TYPES` (what each material is), `ARTIFACTS`/`ARTIFACT_ORDER`/`BASE` (which four materials per brand), `BLOCK_TYPES`/`BLOCK_SPECS` (allowed blocks and
their validation). Local Business documents (assessment, workflow doc, proposal) are `LOCAL_DOCS` + `FXD`/`NEED_WF`.

## Site availability (capacity mode) and waitlist
`CAP_SITES` (the two sites) and the capacity screen; wording shown on the public sites is inside each site's `js/capacity.js`. See `docs/at-capacity.md`.

## Pipeline stages and what each "Next step" does
`LEAD_ST`, `LEAD_LABEL`, `LEAD_FLOW` (Business), `leadFlow()` (Seniors has fewer stages), `leadAct()` (the "Did you already...?" question), `changeStage()`.
Website checks become leads in `inqAutoLeads()` (note text: `feasNote()`); waitlist sign-ups in `wlAutoLeads()`.

## Survey reader (Gemini)
`SV_GEMINI_URL` names the Gemini model (currently gemini-3.5-flash-lite); change it if Google retires the model (the Survey > key setup screen holds his key in the
browser). `SV_PROMPT` is the extraction prompt; `SV_TOPICS`/`SV_SUPPORT`/`SV_SECTIONS` mirror the paper form.

## PDF export
`pdfBuild()` uses html2canvas + jsPDF from a CDN (`PDF_LIBS`, pinned versions). If a CDN link breaks, update the version there.

## A new database table
New file in `migration/` with grants in the same file; run it by hand in the Supabase SQL editor; keep the table owned by the repo that uses it.

## Website preview (what visitors see)

Screen `wsScreen()` (button "Preview what clients see on the website" under Feasibility > Keep the table current). It reads the live table
from the public RPC `public_caps` and rebuilds the visitor result with the same rules and wording as `js/feascheck.js` on the Business site.
The wording lives in the `WS_TXT` constant (copied from feascheck.js `T.en/T.fr`): if the site's result wording changes, update `WS_TXT` too.
Importing a table already publishes it automatically; this screen only shows what is live.

## Where leads come from (Leads screen, top card)
`leadSources()` groups website feasibility checks by the saved `extra.source` (`utm_source/utm_campaign`, set by the Business site's `js/feascheck.js`). Blog LinkedIn posts use
`linkedin/issue-YYYY-MM[-d1|-d2|-d3|-fr]` (d = follow-up post, fr = French post); the button inside an issue uses `imetrobert-blog/issue-YYYY-MM`. Booked/won counts come from the lead's stage.

## Results by website card (Leads screen)

`siteResults()` (search the file for it) shows checks/messages, waitlist sign-ups and top answers per site from `S.cap.inq` and `S.cap.wl`. The "Open Google Analytics"
links come from `ANALYTICS_LINKS` just above it: replace a URL there with a direct link to that site's GA4 property or a Looker Studio dashboard. Visits and traffic are
NOT stored in the toolkit; they live in Google Analytics (one property per site).

## Website metrics and analytics screen (all sites)

Home button "Website analytics (both sites)" opens `analyticsScreen()` (search the file for it). `GA_BASE` is the shared GA4 property (539541576) and `GA_LINKS` the
one-tap reports (Realtime, traffic sources, pages, events); a different property id means changing `GA_BASE` and `ANALYTICS_LINKS`. GA cannot filter by Site from a link,
so each site has a field for the owner's own saved GA/Looker Studio view, kept in localStorage (`tk-ga-saved`, this device only).

## Looker Studio dashboard per site: NOT DONE YET (status 2026-11-15)

The owner works only on an iPhone and Looker Studio crashes there, so the dashboard is NOT built. State so far: he accepted the Looker Studio account setup (company
"AIWithRobert") and started an "Untitled Report" connected to the Google Analytics connector, property 539541576; nothing else was built. That empty report can be deleted.
Until he builds it on a computer, the toolkit's "Your saved view" fields on the Website analytics screen stay empty and that is normal: do not treat it as a bug.

Checklist for a computer (about 15 minutes, no code change needed). Goal: one Looker report with TWO PAGES, one per site, each page filtered to that site only:
1. lookerstudio.google.com > Create > Report > Google Analytics connector > account AIWithRobert.com > property 539541576 > Add. Name it "Website results".
2. Page 1, rename "Business". Add a Table (dimension Hostname; metrics Views, Users, Event count) and a second Table (dimension Event name; filter to feasibility_submit, phone_click, email_click, booking_click). Add a Date range control (last 28 days). Then Page > Page settings (or the page's Filter panel): add a page-level filter Include Hostname contains "biz".
3. Page 2: Edit > Duplicate page, rename "Seniors", change the filter to Hostname contains "seniors" and the event filter to generate_lead, phone_click, email_click.
4. Open each page in the browser and copy its own address from the address bar (each page has its own link; make sure Share > Anyone with the link is NOT needed, he is the only viewer, signed in).
5. Toolkit > Website metrics and analytics: paste the Business page link into the Business card's "Your saved view" box and the Seniors page link into the Seniors card's box. Each card then shows an "Open my saved ... view" button for that site only.
Once done, delete this section.

### Own visit counters (Website metrics, top of that screen)

`js/hits.js` (identical file on the Business, Seniors and Hub sites; only `CONFIG.site` differs) adds anonymous counters to Supabase table `site_hits` through the public
RPC `track_hit` (migration/site_hits.sql, run by hand in the Supabase SQL editor first). It counts visit (first page of the day on a device), view (path), event (the same
events GA gets; it wraps `gtag`) and source (utm_source, else referrer host). `metLoad()` / `metricsBlock()` in index.html read the last 95 days and sum per site for 7/30/90 days.
No cookies, no IP. Bots and devices that opened any site with `?notrack=1` are skipped (`?notrack=0` undoes it). Numbers will differ a little from GA. New event to count:
add its name to `EVENTS` in all three hits.js files, to the regex-compatible names in `track_hit` (letters and underscores) and to `MET_EVENTS` for its label.
If the screen says "Run migration/site_hits.sql in Supabase first", the SQL has not been run yet.
