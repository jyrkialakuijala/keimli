#!/bin/sh
# End-to-end smoke test: load each built page in headless Chromium with #selftest
# (the page then runs 50 steps at boot) and check that the counters advanced, i.e.
# the wasm, the code tables, the worker pool and the canvas path all work and nothing hung.
# Usage: test/smoke.sh   (set BROWSER to a chromium/chrome binary if not on PATH)
set -e
cd "$(dirname "$0")/.."
BROWSER=${BROWSER:-chromium}
status=0
probe() {  # probe <file> <id of counter> <id of activity value>; each run gets a fresh profile, and one retry covers a slow cold start
  dom=''
  for attempt in 1 2; do
    prof=$(mktemp -d)
    dom=$(timeout 150 "$BROWSER" --headless=new --no-sandbox --disable-gpu --user-data-dir="$prof" --virtual-time-budget=1500 \
          --dump-dom "file://$PWD/$1#selftest" 2>/dev/null) && { rm -rf "$prof"; break; }
    rm -rf "$prof"; dom=''
  done
  [ -n "$dom" ] || { echo "FAIL $1: browser timed out or crashed twice (possible jam)"; status=1; return; }
  domfile=$(mktemp) && printf '%s' "$dom" > "$domfile"   # the DOM is too large for an argument
  python3 - "$1" "$2" "$3" "$domfile" <<'PY' || status=1
import re, sys
page, counter, activity = sys.argv[1], sys.argv[2], sys.argv[3]
dom = open(sys.argv[4]).read()
def val(i):
    m = re.search(r'id="%s"[^>]*>([^<]*)<' % i, dom)
    return m.group(1).strip() if m else None
c, a = val(counter), val(activity)
ok = c is not None and c.replace(',', '').isdigit() and int(c.replace(',', '')) >= 50
ok = ok and a is not None and a.replace(',', '').isdigit() and int(a.replace(',', '')) > 0
print(('ok   ' if ok else 'FAIL ') + f'{page}: {counter}={c} {activity}={a}')
sys.exit(0 if ok else 1)
PY
  rm -f "$domfile"
}
probe life.html gen pop
probe index.html turn rewritten
# Worker mode: --dump-dom cannot wait for Web Workers (virtual time idles the main thread), so poll
# the live page over the DevTools protocol until 50 turns have run.
if out=$(timeout 120 node test/cdp-poll.mjs "file://$PWD/index.html#selftest-workers" \
    "(() => { const t = +document.getElementById('turn').textContent.replace(/,/g, ''); return t >= 50 ? { turn: t, moved: document.getElementById('moved').textContent, time: document.getElementById('turnTime').textContent, entropy: document.getElementById('entropy').textContent } : null; })()" 60000) &&
   node -e 'const s = JSON.parse(process.argv[1]), e = parseFloat(s.entropy); process.exit(e > 0 && e <= 8 && /turns logged/.test(s.entropy) ? 0 : 1)' "$out"; then
  echo "ok   index.html#selftest-workers (4 workers, entropy logged): $out"
else
  echo "FAIL index.html#selftest-workers: workers did not complete 50 turns"; status=1
fi
# Thread switch: pause, go 1 -> 4 -> 1 workers; the turn counter and the (unstretched) image must not change.
if out=$(timeout 120 node test/cdp-poll.mjs "file://$PWD/index.html#selftest" "$(cat test/switch-expr.js)" 60000) &&
   node -e 'const s = JSON.parse(JSON.parse(process.argv[1])); process.exit(s.turnBefore === s.turnAfter && s.turnAfter === s.turnBack && s.sumBefore === s.sumAfter && s.sumAfter === s.sumBack ? 0 : 1)' "$out"; then
  echo "ok   thread switch 1 -> 4 -> 1 keeps the lattice: $out"
else
  echo "FAIL thread switch changed the lattice: $out"; status=1
fi
# Links: with 4 workers configured, Cells = Links and the Z80 run on the worker pool (edge rows exchanged between bands every round), with persistent link CPUs rewriting pixels.
if out=$(timeout 120 node test/cdp-poll.mjs "file://$PWD/index.html#selftest" "$(cat test/links-expr.js)" 60000) &&
   node -e 'const s = JSON.parse(JSON.parse(process.argv[1])); process.exit(s.turns > 0 && /^65,024 × 16 instructions a turn, reset every 4 turns/.test(s.linkN) && +s.rewritten.replace(/,/g, "") > 0 && /4 thr/.test(s.time) && /link machines whose code starts in this cell/.test(s.inspect) && (s.inspect.match(/PC=/g) || []).length === 4 ? 0 : 1)' "$out"; then
  echo "ok   links mode runs on 4 workers with persistent CPUs: $out"
else
  echo "FAIL links mode: $out"; status=1
fi
exit $status
