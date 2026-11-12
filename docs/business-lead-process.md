# Business lead process: from first interest to a confident, honest reply

Goal: never promise what the client's AI plan cannot do, and always have a clear reply that shows what we can and cannot do with their subscription. Same steps every time.

Tools: Google Calendar booking page, formsubmit email, the toolkit (Leads, Feasibility check, Client documents).

## 1. Interest arrives (same day)
- Contact-form submissions (both sites) are also saved automatically: toolkit home > Inquiries. From a Business inquiry tap Start feasibility check (fills needs, plan and team size) or Make a lead. Setup: run migration/site_inquiries.sql once in Supabase. The formsubmit.co email still arrives as the alert; the saved copy is what the toolkit reads (no more pasting).
- Contact form: email arrives with team_size, tool_*, personal_info and need_* fields (mapping is in the biz repo CLAUDE.md).
- Booking page: Google emails you and adds a calendar event. No prep fields, only the one custom question.
- Toolkit > Leads > Add lead: name, source, contact. Status New. Follow-up date = 1 business day.
- Booking with no prep info: send template A below.

## 2. Evaluate (10 minutes, before the call)
0. Shortcut for contact-form leads: open the formsubmit email, select all, copy, then in Toolkit > Feasibility check paste it under "Start from a contact-form email" and tap Fill from email. It fills the name, needs, plan and team size, and the contact details go to the lead. Check it, then Save this check. (Booking-page requests have no form fields; use steps 1 to 3.)
1. Toolkit > Feasibility check. Enter the client name.
2. Tick the needs they listed (or that you inferred from their message). Tick "personal information" if they handle client data.
3. Pick the plan they already pay for. If none or unsure, tap Compare all four.
4. Set people and number of workflows. Read the verdict and the subscription cost.
5. Toolkit gate: every deliverable you plan to promise must be producible as a final asset in the toolkit (session pack, workbook, deck, survey, handout, Assessment report, Workflow document, Proposal). If an item has no toolkit output, do not promise it: either build that output first or leave it out of the scope.
6. Check the age line: if the capability table is over 60 days old, refresh it first (Copy refresh prompt, then Import updated table).
7. Save this check. Lead status stays Contacted.

## 3. Pick the reply from the verdict
- Yes: confirm plainly, then proceed to scope.
- Partly or Unknown: promise only the Yes items. Name each condition in writing. Mark Unknown items "to be confirmed". Confirm on the vendor page linked in the table before you promise them.
- No: do not promise it. Offer in this order: (a) a different plan that covers it (Compare all four), (b) a custom or extra-tool solution quoted separately, (c) an honest "not a fit right now".

## 4. Discovery call (15 minutes)
1. Confirm the goal in their words and one real example task.
2. Confirm which AI plan they own or will buy (about $30 per user per month). They buy it directly.
3. State plainly: included, included with conditions, not included.
4. If personal information is involved, mention Law 25 and plan privacy settings.
5. Do not quote a final price on the call. Say a written scope and price follow within 1 business day.
6. Book the next step. Update lead: Call booked or Proposal.

## 5. After the call (within 1 business day)
- Optional: if you have a transcript (Voice Memos text), paste it in Toolkit > Feasibility check under "After the discovery call", tap Copy AI prompt, paste it into a free AI chat, paste the JSON reply back and tap Apply. It ticks the needs the client mentioned (with quotes to verify), updates people and workflows, and adds open questions to the lead note. Then Save this check.
1. Reopen the saved check, correct needs from the call, Update saved check.
2. Build the Assessment report (EN or FR). Send it with a short email (templates B, C or D).
3. If they proceed: build the Workflow document and the Proposal. Edit prices before sending (the built-in fees are estimates).
4. Lead status: Proposal sent. Follow-up date = 3 business days.

## 6. Rules that prevent overpromising
- Only promise Yes cells. A "general" (not sourced) cell is a Partly until you confirm it.
- Anything not on the client's plan is "not included", never "I'll figure it out".
- Vendors change plans: every document carries the verified date. Refresh the table monthly.
- Every promised item has a toolkit output that produces the final asset. No toolkit output, no promise.
- No promise outside the written scope. No names or personal data in prompts.

## 7. Close
Won or Lost in Leads, with a note on why. Review lost notes monthly.

## Reply templates

### A. Booking with no details (EN)
Subject: Before our call
Hi [name], thanks for booking. To make our 15 minutes useful, could you reply with: how many people would use AI, which AI tool you already pay for (ChatGPT, Claude, Gemini, Copilot or none), and the 2 or 3 tasks you most want help with? I'll check what is realistic on your plan before we speak. Robert

### A. (FR)
Objet : Avant notre appel
Bonjour [nom], merci d'avoir réservé. Pour que nos 15 minutes soient utiles, pourriez-vous répondre avec : le nombre de personnes qui utiliseraient l'IA, l'outil d'IA que vous payez déjà (ChatGPT, Claude, Gemini, Copilot ou aucun) et les 2 ou 3 tâches pour lesquelles vous voulez de l'aide? Je vérifierai ce qui est réaliste avec votre forfait avant notre conversation. Robert

### B. Everything works (EN)
Hi [name], I checked your list against [plan]. Everything you asked for can be done on it. Attached is a short assessment. The only thing you need is a paid [plan] account for each person, bought directly from the vendor. If it looks right, I'll send a scope and price. Robert

### B. (FR)
Bonjour [nom], j'ai comparé votre liste à [forfait]. Tout ce que vous demandez est réalisable avec ce forfait. Vous trouverez ci-joint une courte évaluation. Il vous faut seulement un abonnement payant [forfait] par personne, acheté directement auprès du fournisseur. Si cela vous convient, je vous envoie la portée et le prix. Robert

### C. Some conditions (EN)
Hi [name], most of what you asked for works on [plan]. [Item] works with conditions: [condition]. [Item] is still to be confirmed, so I am not promising it yet. Attached is the full breakdown. Want to go ahead with the parts that work today? Robert

### C. (FR)
Bonjour [nom], la plupart de vos demandes sont réalisables avec [forfait]. [Élément] fonctionne sous conditions : [condition]. [Élément] reste à confirmer; je ne le promets donc pas pour l'instant. Vous trouverez ci-joint le détail complet. Souhaitez-vous aller de l'avant avec ce qui fonctionne dès maintenant? Robert

### D. Cannot do on this plan (EN)
Hi [name], thank you for the detail. I checked your list against [plan]. [Items that work] work well. [Item] cannot be done reliably on this plan, and I would rather say that now than promise it. Options: (1) [other plan] covers it at about [cost], (2) a custom solution, quoted separately, (3) we start with what works and revisit this later. Attached is the breakdown. Which do you prefer? Robert

### D. (FR)
Bonjour [nom], merci pour les détails. J'ai comparé votre liste à [forfait]. [Éléments réalisables] fonctionnent bien. [Élément] ne peut pas être réalisé de façon fiable avec ce forfait, et je préfère vous le dire maintenant plutôt que de le promettre. Options : (1) [autre forfait] le couvre pour environ [coût], (2) une solution sur mesure, soumissionnée séparément, (3) nous commençons par ce qui fonctionne et revoyons cela plus tard. Vous trouverez ci-joint le détail. Quelle option préférez-vous? Robert

## Surveys (workshop feedback forms)

Home > **Surveys** shows the saved responses (totals, most requested topics, search, CSV exports for the newsletter list and all data, delete). **Add a survey** reads a paper form two ways: a photo or PDF sent to Gemini (optional one-time key, stored in this browser only), or **no API key**: copy the prompt, attach the photo(s) in any free chatbot, paste its reply back. Either way you review and correct every field before saving. Data lives in `survey_responses` (`migration/survey_responses.sql`); the invoicing app no longer holds this feature.
