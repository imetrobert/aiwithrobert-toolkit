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

### Google review link and the Google review ask (Seniors)
A Seniors testimonial can carry an optional Google review link (`review_url`, checked by `gUrl()`; part of `data.shown`, returned by `public_testimonials`). The Seniors site shows it as a "See this review on Google" button; Business has no Google profile, so the field only appears for Seniors.
For Seniors, the approval email (`tmMail`), the talk testimonial email (`talkMail`) and the after-session review email (`LEAD_MAIL.reviewSeniors`) also ask for a short Google review using `REVIEW_URL` (the business page link, edit the constant to change it).
After adding the field, the `public_testimonials` function must be re-created (the migration file has the current version).

### Testimonial language and translation (2026-11-17)
On the Testimonials screen each testimonial has "Language of the quote" plus an optional "Translation" (and translated "What it is about") with a "They approved the translation" box. `tmShown()` only sends `text_alt`/`context_alt` to the websites when that box is ticked; `lang` is always sent. The English page shows English wording and /fr/ shows French; with no approved translation the other-language page shows the original with a small label. The approval email (`tmMail`) appends the translation for them to approve. The public function `public_testimonials` in `migration/site_testimonials.sql` returns `lang`, `text_alt`, `context_alt`: re-run its `create or replace function` block after changing it. Site side: `js/testimonials.js` `wording()` and `scripts/sync_testimonials.py` `pick()` in both site repos.
Update 2026-11-17: the language is now chosen explicitly (no silent English default; publishing is blocked until it is set, `tmReady`). The translation fields only appear once a language is chosen, with a "Copy a translation request for an AI chat" button. The site shows the original-language note at the top of the card when no approved translation exists.

### Feasibility check "Other" answers (2026-11-17)
The Business site's check has "Other (tell me which)" on the plan question (`extra.plan` = other, `extra.plan_other_text`) and "Something else" on the needs question (`extra.need_other`, `extra.need_other_text`). The lead note (`feasNote`) shows both, and the "Results by website" card on Leads lists what was typed in the last 30 days (`typed` in `siteResults`). Review it monthly: repeated answers are candidates for a new row in the capability table.

## Testimonial publish note ("refresh now" box)

After Publish, Unpublish or saving a live testimonial, `tmSyncBox()` (index.html, next to `tmSave`) shows a box with the next automatic refresh time of the site's
"Sync testimonials" workflow (`TM_SYNC`: Seniors repo imetrobert/aiwithrobert 09:17 UTC, Business repo imetrobert/aiwithrobert-biz 09:27 UTC; keep equal to the cron
lines in those repos' `sync-testimonials.yml`) and a button to the workflow page to run it now. If a cron time or repo name changes, edit `TM_SYNC`.


## Pitch builder (home button "Pitch builder: find clients", added 2026-11-26)

Code block `PITCH BUILDER` in index.html (grep `ptScreen`, `ptPrompt`, `ptRead`, `ptPage`, `ptAddLead`). Flow: details (business, website, pasted text, optional logo upload held in memory only) -> prompt for a free AI chat (asks it to open the site if it can browse) -> paste reply, `readAiJson` + `ptRead` check every field -> preview, plain-text email, LinkedIn message, one-page PDF (English and/or French, `ptPage` is one fixed A4 template in the Business brand, drawn by html2canvas + jsPDF like `pdfBuild`).
"I sent it: add to Leads" (`ptAddLead`) creates a Business lead at stage "Invited to call" with a follow-up date (default +4 days), so it shows in Leads and on the Today card. No new table, nothing else is stored.
- Wording of the page (EN/FR): `PT_TXT`. Services named in the prompt, rules about no invented numbers or "runs by itself": `ptPrompt`. Keep these equal to the Pricing section and `CLAUDE.md` rules of biz.aiwithrobert.com.
- Tracked link per prospect: `ptLink` = `?utm_source=pitch&utm_campaign=pitch-YYYYMM-company#feas-check`; the website's feasibility check saves it as `extra.source` and the Leads "Where leads come from" card shows it. Add `pitch` to the blog repo's list of tags in the Business CLAUDE.md if it is ever tidied.
- Email is plain text on purpose (inbox delivery); includes an opt-out line (CASL). Never add invented results to the template.
- Seniors version (added 2026-11-26): the first control on the Pitch builder form picks Business or "Seniors organization (workshops)" (`PT.o.brand`). Target = libraries, residences, community and senior centres, recreation departments, clubs. It changes the prompt (`ptPrompt`, `sen` branch: three workshop topics for their members, safety rule, no prices), the page text (`PT_SEN`), colours and footer (Seniors brand), the signature (`ptSig`), the tracked link (`ptLink`: seniors.aiwithrobert.com, anchor `#contact`) and the lead (Seniors pipeline, stage "Contacted"). To change a Seniors service wording edit the `sen` strings in `ptPrompt`.

## Prospect finder (home button "Prospect finder: who to pitch", added 2026-11-27)

Code block `PROSPECT FINDER` in index.html (grep `fdScreen`, `fdPrompt`, `fdRead`, `fdSend`, `ptNext`). Step before the Pitch builder: brand (Businesses or Seniors organizations), area, kinds, how many -> prompt for a free AI chat with web search -> paste the JSON list (`{"prospects":[...]}`, read by `readAiJson` + `fdRead`, which drops entries with no name, bad links or bad emails and forces `type` to one of the Pitch builder's lists) -> tick the ones to target -> "Send ticked to the Pitch builder" queues them; each fills company, website, type, contact first name and email (the pitch prompt tells the chatbot to open the site; the old pasted-text box is now a short optional "Your notes" box) and "Next prospect" loads the next. "I sent it" in the Pitch builder marks the prospect as pitched and creates the lead; ones already in Leads (by name or email) are greyed out.
- The list is kept on this device only (localStorage `awr_pf_v1`, max 60). No table, no migration.
- Prompt rules (real sites only, no invented emails, skip chains, government and competitors, published business contacts only): edit `fdPrompt`. The type lists are `PT_INDUSTRY` and `PT_INDUSTRY_S` (the Pitch builder dropdowns): change a type there and the finder follows.
- Always open each website before pitching: a chatbot list can contain mistakes.
- Logos in the finder (2026-11-27): the finder prompt also asks for `logo_url` (image link seen on their page). The card shows "Open logo"; sending the prospect to the Pitch builder calls `ptTryLogo()`, which loads the image with crossOrigin and puts it on the page only if the other site's server allows it. Most will not, so the form then shows a link: press and hold the picture, Save to Photos, pick it in the logo box. Chatbots can get image links wrong, so check the logo is really theirs.
- Seniors finder (2026-11-27): one home button that follows the Business or Seniors choice at the top of the home screen ("Prospect finder: businesses" or "Prospect finder: seniors organizations"; it sets `FD.f.brand` from `S.brand`; one stored list, each brand shows only its own prospects; the Pitch builder button also follows the choice when the form is empty). The Seniors form adds language of their members, whether they already run tech sessions (warm vs new topic) and whether they have a room. The Seniors prompt asks for extra fields (`member_language`, `runs_programs`, `program_example`, `contact_role`, `has_room`), the card shows them, and sending a prospect to the Pitch builder sets the pitch language from the members' language (English, French or both). Edit the Seniors targeting in `fdPrompt` (`sen` branches).

## Brand switch (top of the home screen, 2026-11-27)

`brandSwitch()` (index.html, just above `homeScreen`) draws the two big Seniors / Business buttons in each brand's own colours with a SELECTED tag, and a banner below ("You are working in: ...") that lists the tools of that brand (`BRAND_TOOLS`: edit the text when tools are added). Every screen also shows a SENIORS or BUSINESS pill next to the brand name in the header and a 6px header bottom border in the brand colour (CSS `.bpill`, `header.top`; classes `.bsw`, `.bswb`, `.bnd` next to `.opt`). The old brand buttons inside "Start a new session" were replaced by a one-line reminder. Colours come from `BRANDING.brands`, so a colour change in `BRANDING` updates the switch.

## Home screen layout (sales pipeline, 2026-11-27)

The home screen buttons are grouped in `homeScreen()` (index.html): "Win clients" = numbered pipeline steps built with `pstep(n, button, hint)` (1 Website metrics, 2 Prospect finder, 3 Pitch builder, 4 Leads, 5 Feasibility check for Business only), "Run the sessions" (Start a new session card, Saved materials, Speaking engagements), "After the event" (Testimonials; Surveys for Seniors only), "Settings and backup" (Site availability, backup import, cloud line, sign out). The hint lines under each step say how it feeds the next; edit them there. To add a tool, add a `pstep` or a button in the right group. CSS: `.sech` (section heading), `.pls` (step row), `.pnum`, `.phint`. Do not reuse the class name `pstep` for CSS: it already styles the lead stage chips.

## Lead back-links to the pitch (2026-11-27)

A lead made by "I sent it" in the Pitch builder stores `lead.pitch = { o, out, fid }` (prospect details without the logo or notes, the generated pitch, and the finder card id), written in `ptAddLead()`. `leadNext()` shows "Where this lead came from" under the next step: Open the pitch I sent (restores `PT` and opens the result stage), Open their website, Open the prospect list (finder). Leads made before this change, or typed in by hand, have no `pitch` and show nothing.
