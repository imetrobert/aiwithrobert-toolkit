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

## Looker Studio report (built 2026-11-16)

The owner built the "Website results" report in Looker Studio (Google Analytics property 539541576, Hostname splits the sites; tables for views and for the key events
feasibility_submit, generate_lead, email_click, phone_click, booking_click). Its link is saved in the "Your saved view" boxes on the Website analytics screen. Those boxes are
kept per device (localStorage `tk-ga-saved`), so on a new phone or browser they are empty until the link is pasted again: that is normal, not a bug. The box accepts
analytics.google.com and lookerstudio.google.com links (datastudio.google.com links are rewritten to lookerstudio). An event missing from the report simply has no data in
the date range yet; it is not an error.

### Own visit counters (Website metrics, top of that screen)

`js/hits.js` (identical file on the Business, Seniors and Hub sites; only `CONFIG.site` differs) adds anonymous counters to Supabase table `site_hits` through the public
RPC `track_hit` (migration/site_hits.sql, run by hand in the Supabase SQL editor first). It counts visit (first page of the day on a device), view (path), event (the same
events GA gets; it wraps `gtag`) and source (utm_source, else referrer host). `metLoad()` / `metricsBlock()` in index.html read the last 95 days and sum per site for 7/30/90 days.
No cookies, no IP. Bots and devices that opened any site with `?countme=1` are skipped (`?countme=0` undoes it). The same switch also turns Google Analytics off on that device (an inline `ga-disable-G-DM4EY880K2` line before the gtag script, in each site's index.html and the page generators build_pages.py, build_articles.py, build_hub.py). Numbers will differ a little from GA. New event to count:
add its name to `EVENTS` in all three hits.js files, to the regex-compatible names in `track_hit` (letters and underscores) and to `MET_EVENTS` for its label.
If the screen says "Run migration/site_hits.sql in Supabase first", the SQL has not been run yet.

### Today card (top of the home screen)
`todayCard()` / `todayLoad()` in index.html (just above `homeScreen()`). Shows: follow-ups due (lead.follow on or before today, open and not archived), new leads still at status "new",
unpaid invoices (invoicing table `invoices`, status "sent", read only through the same login; "over 30 days" turns the box orange), and visits for the last 7 days (table `site_hits`, loaded by
`metLoad()`). Tapping a row opens Leads on that filter (`S.lFilter`). "Refresh" reloads invoices and visits. Leads come from this device's saved sessions, so a fresh device shows them after the cloud sync.
To count a different invoice status, change `status=eq.sent` in `todayLoad()`. If the card says "Invoices could not be read", the signed-in user lacks access to the invoices table (its policy is "Authenticated users only").

### After-session follow-up (pipeline step 7 / Seniors step 5)
Stage id `after` ("After-session follow-up") sits after `won` in `LEAD_ST`, `LEAD_FLOW` and `leadFlow()`. Emails: `LEAD_MAIL.thanks|review|rebook` and `...Seniors` variants (EN/FR, just above `mailFrom`); `mailKind()` picks the Seniors variant automatically.
Timing (0, 3 and 30 days) lives in `AFTER_KINDS`; `afterDue()` says what is due; `leadNext()` draws the three rows (`afterRows`); the Today card counts what is due. Sent dates are `lead.after.thanks|review|rebook` (validated in `cleanLead`).
Change wording or the review link (`REVIEW_URL`) there. Moving a lead from Won forward to this stage needs no prompt; moving back asks as usual.

### Speaking engagements (home button "Speaking engagements")
Table `toolkit_talks` (migration/toolkit_talks.sql, run once by hand in the Supabase SQL editor; until then the screen says "Run migration/toolkit_talks.sql in Supabase first."). One row per talk, details in the jsonb `data`
(validated by `cleanTalk()` in index.html: title, org, contact, date, place, size, fee, site seniors|business, lang, status, note, slug). Statuses: `TALK_ST` (Idea, Pitched, Confirmed, Delivered, Follow-up done, Declined).
Functions: `talksScreen()`, `talkLoad/talkSave/talkDelete`, `talkUrl()`, `talkResults()`, `talkMail()` (thank-you and testimonial request to the organizer, EN/FR, `TALK_MAIL`), `talkPng()`.
**QR code:** each talk gets a fixed slug (`yyyy-mm-organizer`, kept when the title changes) and the link `https://<site>/?utm_source=qr&utm_campaign=talk-<slug>` (Business adds `#feas-check`; French talks use `/fr/`).
The QR image is drawn by the MIT-licensed qrcode-generator library, minified and inlined at the top of the talks block (no network needed). "Make QR picture" builds a PNG to press-and-hold save.
**Attribution:** Business feasibility checks save `qr/talk-<slug>` as their source (biz js/feascheck.js); Seniors contact messages do the same (seniors js/form.js, `extra.source`). `talkResults()` counts them per talk and how far each got in the
pipeline; "Where leads come from" shows them as "Talk QR: <title>". Visits per talk are in Google Analytics (campaign `talk-<slug>`). The Today card shows the next confirmed talk and delivered talks still needing a thank-you.

### Lead to invoice handoff
On a Won lead, "Create invoice" (in `leadNext()`, constant `invoiceUrl`) opens `https://invoices.aiwithrobert.com/#/invoice/new?brand=&lead_name=&lead_email=&lead_org=&lead_lang=`; the invoicing app's `applyLeadParams()` fills the client, address and usual services.
Keep the parameter names equal in both repos. The details stay in the part after `#`, which the browser does not send to any server.

### Referrals ("Referred by" and a referral link per client)
On a lead card: a "Referred by" box, and for Won or After-session leads a "Referral link for this client" box (`referralBox()`). The link is `?utm_source=referral&utm_campaign=<code>` on the client's site and language (`refUrl()`, code from `refCodeFor()`, saved as `lead.code`).
The sites already save utm_source/utm_campaign as the message's source, so no site change is needed. `leadReferrer()` shows who referred a lead (typed name, else the client whose code they used); `referralSummary()` is the "Referrals" card on the Leads screen;
"Where leads come from" lists them as "Referral: <name>". The email with the link is `REF_MAIL` (EN/FR). `lead.ref` and `lead.code` are validated in `cleanLead()`.

### Toolkit logo (red) and header logos
The toolkit's own mark is the standard logo in red: `icon-192.png` (tab icon), `icon-512.png`, `apple-touch-icon.png` (Home Screen) and `LOGO_TK` (small copy inside index.html) shown top-left of every header.
The Seniors or Business logo (`BRANDING.brands[x].logo`) shows on the right of the header and follows the brand toggle. To recolour or replace: re-export the three PNGs and replace the `LOGO_TK` data URI. A phone may keep the old Home Screen icon until the app is removed and added again.

### Testimonials (home button "Testimonials")
Table `site_testimonials` (migration/site_testimonials.sql, run once by hand; until then the screen says "Run migration/site_testimonials.sql in Supabase first."). Private working copy (their reply, consent record) plus `data.shown` = the only text websites can read.
Flow: save their reply (or "Save a testimonial reply" on an After-session lead) > write the approved wording > "Copy approval email" (`TM_MAIL`, EN/FR) > when they agree, set how they agreed to be credited (full / first name / anonymous) and the date > "Publish to website".
The database refuses to publish without a consent date, a credit choice and approved wording (constraint `site_testimonials_consent`). Functions in index.html: `tmScreen`, `tmLoad/tmSave/tmDelete`, `tmShown` (what visitors see), `tmMail`, `tmStart`.
Sites read it through the public RPC `public_testimonials(site)` in `js/testimonials.js` (Seniors and Business repos), which adds the cards to the existing testimonials container.
