#!/usr/bin/env python3
"""Checks the "Pre-fill the intake from a lead" feature in a headless browser (run by hand; needs: pip install playwright).
Run: python3 scripts/test_intake_prefill.py
Proves: the prompt lists every question of the chosen assets with exact option ids, never includes contact details; a typical AI reply fills text, choice and multi
answers; bad ids are dropped; defaults and "Empty" flags appear; Apply opens the intake on the lead's own record with the answers in place.
WHEN THIS GOES RED: give Claude the FAIL lines and docs/common-edits.md "Intake pre-fill"."""
import os, sys, json
from playwright.sync_api import sync_playwright
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
fails = []
def check(c, m):
    if not c: fails.append(m)
with sync_playwright() as pw:
    br = pw.chromium.launch(); pg = br.new_page(viewport={'width': 390, 'height': 900}); errs = []
    pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.route('**/*', lambda r: r.continue_() if r.request.url.startswith('file:') else r.abort())
    pg.goto('file://' + os.path.join(ROOT, 'index.html'))
    pg.wait_for_function("typeof ipPrompt === 'function'")
    pg.evaluate("""() => { S.auth.status = 'in'; S.auth.email = 't@e.com';
      Store.write([{ id: 'sLead1', brand: 'business', sel: ['business_pack'], typeId: 'business_pack', lang: 'en', name: 'Dupont Dental', created: Date.now(), updated: Date.now(), step: 0, answers: {}, pastes: {}, results: {}, feas: { tool: 'claude', reqs: ['write'], users: 4, flows: 1, assess: false, train: 0, request: 'Reply to patients faster. Call 514-555-1234 or a@b.com', verdict: '', verified: '', saved: Date.now() },
        lead: { status: 'checked', contact: 'Marie Dupont · marie@dupontdental.ca', follow: '', note: 'Family dental clinic, 4 staff. Reach me at marie@dupontdental.ca', archived: false, hist: {}, at: Date.now(), ref: '', code: '', after: {}, fu: {}, pitch: { o: { brand: 'business', company: 'Dupont Dental', url: 'https://dupontdental.example', industry: 'dental clinic', first: 'Marie', email: 'marie@dupontdental.ca', lang: 'en', logoUrl: '' }, out: null, fid: '', at: 0 } } }]);
      S.screen = 'home'; render(); }""")
    check('pre-fill the intake from a lead' in pg.inner_text('body').lower(), 'home: button missing')
    pg.evaluate("S.screen = 'leads'; render()")
    check('Pre-fill a session intake (AI)' in pg.inner_text('body'), 'leads: card button missing')
    pg.evaluate("openIntakePrefill(Store.all()[0], 'leads')")
    pg.evaluate("IP.sel = ['business_pack', 'business_workbook', 'business_deck']; IP.lang = 'en'; ipPrompt(Store.all()[0]) && render()")
    pr = pg.evaluate("ipPrompt(Store.all()[0])")
    for must in ['Dupont Dental', 'https://dupontdental.example', 'id: "business"', 'id: "size"', 'id: "tasks"', 'id: "experience"', 'id: "lesson"', '"solo" = Just the owner', 'JSON FORMAT']:
        check(must in pr, 'prompt missing: ' + must)
    check('marie@' not in pr and '514-555' not in pr and 'Marie' not in pr, 'prompt leaks contact details')
    check('id: "transcript"' not in pr and 'id: "hlen"' in pr, 'transcript must never be asked; handout length must be asked when the handout is chosen')
    only = pg.evaluate("() => { IP.sel = ['business_workbook']; return ipPrompt(Store.all()[0]); }")
    check('id: "lesson"' in only and 'id: "hlen"' not in only, 'workbook-only prompt should ask the lesson length but not the handout length')
    pg.evaluate("IP.sel = ['business_pack', 'business_workbook', 'business_deck']")
    reply = json.dumps({"answers": {"business": "Family dental clinic", "size": "2_5", "tasks": "Patient emails, appointment reminders", "examples": "Replying to rate questions; recap emails", "experience": "free", "tools": "Outlook", "notes": "Contact marie@x.ca please", "venue": "", "lesson": None}, "check": ["examples: suggested from the website", "size: guessed"]})
    out = pg.evaluate("(t) => { const o = ipRead(t); return o; }", "Here you go:\n```json\n" + reply + "\n```")
    a = out['answers']; f = out['flags']
    check(a.get('size') == '2_5' and a.get('experience') == 'free' and a.get('business') == 'Family dental clinic', 'basic answers not read')
    check('marie' not in a.get('notes', ''), 'email not removed from a text answer')
    check(a.get('lesson') == '60' and f.get('lesson') == 'default', 'lesson default not applied')
    check(f.get('size') == 'check' and f.get('examples') == 'check', 'check flags missing')
    bad = pg.evaluate("(t) => ipRead(t)", json.dumps({"answers": {"business": "X", "size": "huge", "tasks": ""}}))
    check('size' not in bad['answers'] and bad['flags'].get('size') == 'missing' and bad['flags'].get('tasks') == 'missing', 'invalid or empty answers should be flagged missing')
    err = pg.evaluate("() => { try { ipRead('{\"foo\": 1}'); return ''; } catch (e) { return e.message; } }")
    check('answers' in err, 'a reply without answers should give a clear error')
    pg.evaluate("(t) => { IP.reply = t; IP.out = ipRead(t); render(); }", reply)
    txt = pg.inner_text('body')
    check('Check the answers' in txt and 'Start the session with these answers' in txt, 'review card not shown')
    pg.evaluate("ipApply(Store.all()[0])")
    st = pg.evaluate("({screen: S.screen, sid: S.sid, size: S.answers.size, sel: S.sel, lead: !!S.lead, name: S.name})")
    check(st['screen'] == 'intake' and st['sid'] == 'sLead1' and st['size'] == '2_5' and st['lead'] and st['name'] == 'Dupont Dental', 'apply did not open the intake on the lead: %s' % st)
    check(st['sel'] == ['business_pack', 'business_workbook', 'business_deck'], 'asset selection not applied: %s' % st['sel'])
    pg.wait_for_timeout(300)
    rec = pg.evaluate("Store.all().find(x => x.id === 'sLead1')")
    check(rec and rec['answers'].get('size') == '2_5' and rec['lead']['status'] == 'checked', 'the answers were not saved on the lead record')
    # seniors
    pg.evaluate("IP.id = 'sLead1'; IP.brand = 'seniors'; IP.sel = ['seniors_handout']; IP.lang = 'fr'")
    sp = pg.evaluate("ipPrompt(Store.all()[0])")
    check('id: "goals"' in sp and 'id: "device"' in sp and 'Canadian French' in sp and '"iphone" = iPhone' in sp, 'seniors prompt incomplete')
    check(not errs, 'page errors: %s' % errs[:3])
    br.close()
if fails:
    print('FAIL: intake pre-fill'); [print(' -', x) for x in fails]; sys.exit(1)
print('OK: intake pre-fill (prompt, reader, review, apply on the lead record).')
