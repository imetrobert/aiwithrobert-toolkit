#!/usr/bin/env python3
"""
check_toolkit.py — catches the mistakes that would silently break the toolkit.

Run:  python3 scripts/check_toolkit.py
Checks: (1) the script inside index.html has valid JavaScript (needs node); (2) every migration that creates a table also has
explicit Data API grants; (3) the Business prices in FX_PRICE and the booking link equal what the Business website publishes
(llms.txt and js/feascheck.js; skipped with a note if the site cannot be reached). Prints OK or the exact problem; exit code 1 on failure.
"""
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
html = (ROOT / "index.html").read_text(encoding="utf-8")
bad, notes = [], []

# 1. JavaScript syntax
# the app is the one top-level <script> on its own line; "</script>" also appears inside JS strings, so use the line positions
_l = html.split("\n")
_a = next(i for i, x in enumerate(_l) if x.strip() == "<script>")
_b = max(i for i, x in enumerate(_l) if x.strip() == "</script>")
body = "\n".join(_l[_a + 1:_b])
with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False, encoding="utf-8") as f:
    f.write(body)
r = subprocess.run(["node", "--check", f.name], capture_output=True, text=True)
if r.returncode:
    bad.append("index.html script has a JavaScript syntax error:\n" + r.stderr.strip()[:600])

# 2. migrations carry grants
for p in sorted((ROOT / "migration").glob("*.sql")):
    t = p.read_text(encoding="utf-8").lower()
    if "create table" in t and "grant" not in t:
        bad.append(f"{p.name}: creates a table but has no explicit Data API grants (Supabase no longer grants new tables automatically)")

# 3. prices and booking link match the website
def fetch(url):
    return urllib.request.urlopen(url, timeout=30).read().decode("utf-8")

try:
    llms = fetch("https://biz.aiwithrobert.com/llms.txt")
    feas = fetch("https://biz.aiwithrobert.com/js/feascheck.js")
    fx = re.search(r"const FX_PRICE = \{([^}]*)\}", html).group(1)
    for k, v in re.findall(r"(\w+):\s*([\d.]+)", fx):
        if k in ("assessSmallMax", "trainingIncluded", "bundleOff"):
            continue
        n = int(float(v))
        if f"${n:,}" not in llms and f"${n}" not in llms:
            bad.append(f"FX_PRICE.{k} = {n} is not in the Business website's pricing text (llms.txt)")
    m = re.search(r'BOOKING_URL = "([^"]+)"', html)
    if m and m.group(1) not in feas:
        bad.append("BOOKING_URL in the toolkit differs from BOOKING in the Business site's js/feascheck.js")
except Exception as e:
    notes.append(f"price/booking comparison skipped (site not reachable: {e})")

if bad:
    print("PROBLEMS:\n - " + "\n - ".join(bad))
    sys.exit(1)
print("OK: script syntax valid, migrations have grants" + ("" if notes else ", prices and booking link match the website"))
for n in notes:
    print("note:", n)
