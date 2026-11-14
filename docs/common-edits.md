# Common edits — recipes (toolkit)

Find the line with `docs/code-map.md` or `grep -n "NAME" index.html`, read only that range, edit, push to `main`. The Maintain workflow
checks the file (syntax, migration grants, prices vs website) and refreshes the code map. Reload in Safari (not the Home Screen icon) to see the change.

## Change a price (Proposal builder and quotes)
`FX_PRICE` (assessSmall 900, assessLarge 1800, workflow 2000, partialAdd 500, training 1500, trainingIncluded 10, trainingExtra 100, bundleOff 0.1).
Must equal the Business website Pricing section (+ `llms.txt`, `ba-math-text`) and `BUSINESS_SERVICES` in the invoicing app. The weekly Maintain run fails if
a number is missing from the website's pricing text.

## Refresh the feasibility rules (every 3 months; the home screen shows a stripe at 90 days)
Feasibility screen > "Copy refresh prompt" > paste into a free AI chat with web search > paste the JSON reply into "Import updated table". Importing also
publishes the verdicts to the Business website ("Publish this table to the website" if it did not). The built-in fallback table is `CAPS_BUILTIN`;
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
