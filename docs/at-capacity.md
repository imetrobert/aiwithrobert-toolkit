# At-capacity mode (Seniors and Business sites)

One-time setup: run `migration/site_capacity.sql` in the Supabase SQL editor (creates `site_status`, `waitlist_requests`,
and the public functions `site_capacity` and `join_waitlist`, with grants). Until it is run, the sites simply show normally.

Daily use (toolkit home):
- **Site availability**: one card per site, green = open, red = AT CAPACITY, amber = scheduled. "Set to at capacity now" /
  "Open for requests now" (also clears the schedule). Optional start, end and expected reopening date (device clock, Montreal).
  The site flips by itself at the scheduled times (decided by the database clock, no job to run).
- **Waitlist**: people who joined while a site was at capacity. Make a lead (goes to Leads), mark contacted, archive, copy emails.
- Also pause the Google Calendar booking page while at capacity: its link still works for anyone who has it.

What visitors see while a site is at capacity (script `js/capacity.js` in each site repo): phone number, discovery/booking
buttons, hero and speaking CTAs and the contact form are hidden; the contact section shows a "fully booked" notice (with the
reopening date if set) and a waitlist form (name, organization, email, phone, services, consent). EN and FR.
