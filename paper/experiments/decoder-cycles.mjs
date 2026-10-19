// The decoder iterated on a single cell: the attractor census of f (pre-registered in PLAN_AMENDMENTS.md section 3,
// H4). From N random cells, iterate x -> f(x) with Brent's cycle detection up to a cap; report the cycle lengths, the
// transient lengths, the number of distinct cycles reached and their basin shares, per dictionary.
// Usage: node paper/experiments/decoder-cycles.mjs [N=10000] [cap=4000] [V=4096] [skip=6]
import fs from 'node:fs';
import { decode36 } from './decode36.mjs';
import { loadDict, variantOf } from './dict-variants.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const [N = 1e4, CAP = 4000, V = 4096, SKIP = 6] = process.argv.slice(2).filter(a => !a.includes('-') || /^\d/.test(a)).map(Number);
const LIST = process.env.DICTS ? process.env.DICTS.split(',') : ['declaration', 'don-quijote', 'kalevala-1', 'ca-brotli-1', 'ca-brotli-9', 'ca-brotli-13', 'ca-swarm-a', 'ca-swarm-d', 'ca-swarm-f'];   // id or id:variant:seed
let rs = 777; const rnd32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
const randomCell = () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = rnd32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };
const key = c => Buffer.from(c).toString('latin1');
const md = [`# The decoder iterated on one cell: attractors\n`, `N = ${N} random cells per dictionary, V = ${V}, skip ${SKIP}, cap ${CAP} steps. A cycle is identified by its lexicographically smallest state. Transient = steps before the cycle is entered.\n`,
  '| dictionary | cycles found | cycle lengths (count) | largest basin % | transient mean | transient p90 | transient max | not settled |', '|---|---|---|---|---|---|---|---|'];
const out = {};
for (const tok of LIST) {
  const [id0, variant = 'raw', vseed = 1] = tok.split(':'), id = variant === 'raw' ? id0 : `${id0}-${variant}${vseed}`;
  const dict = variantOf(loadDict(id0).bytes, variant, Number(vseed)), f = x => decode36(x, dict, { skip: SKIP, V, coff: 0 }).out;
  const cycles = new Map(), lens = new Map(), transients = []; let unsettled = 0;
  for (let i = 0; i < N; i++) {
    // Brent: find the cycle length lam and then mu
    let power = 1, lam = 1, tortoise = randomCell(), hare = f(tortoise), x0 = tortoise, steps = 0;
    while (key(tortoise) !== key(hare)) { if (power === lam) { tortoise = hare; power *= 2; lam = 0; } hare = f(hare); lam++; steps++; if (steps > CAP) break; }
    if (steps > CAP) { unsettled++; continue; }
    let mu = 0; tortoise = x0; hare = x0; for (let k = 0; k < lam; k++) hare = f(hare);
    while (key(tortoise) !== key(hare)) { tortoise = f(tortoise); hare = f(hare); mu++; if (mu > CAP) break; }
    if (mu > CAP) { unsettled++; continue; }
    // canonical cycle id: the smallest state key on the cycle
    let c = tortoise, best = key(c); for (let k = 1; k < lam; k++) { c = f(c); const kk = key(c); if (kk < best) best = kk; }
    cycles.set(best, (cycles.get(best) || 0) + 1); lens.set(lam, (lens.get(lam) || 0) + 1); transients.push(mu);
  }
  transients.sort((a, b) => a - b);
  const settled = N - unsettled, basins = [...cycles.values()].sort((a, b) => b - a);
  const lenStr = [...lens.entries()].sort((a, b) => a[0] - b[0]).map(([l, c]) => `${l} (${c})`).join(', ');
  const mean = transients.reduce((s, v) => s + v, 0) / (transients.length || 1);
  out[id] = { cycles: cycles.size, lens: Object.fromEntries(lens), basins: basins.slice(0, 10), transientMean: mean, transientP90: transients[Math.floor(0.9 * transients.length)] ?? null, transientMax: transients[transients.length - 1] ?? null, unsettled };
  md.push(`| ${id} | ${cycles.size} | ${lenStr} | ${settled ? (100 * basins[0] / settled).toFixed(1) : '-'} | ${mean.toFixed(1)} | ${out[id].transientP90} | ${out[id].transientMax} | ${unsettled} |`);
  console.error(md[md.length - 1]);
}
const suffix = process.env.DICTS ? '-' + process.env.DICTS.replace(/[^a-z0-9]+/gi, '_').slice(0, 60) : '';
fs.writeFileSync(`${dir}/paper/data/decoder-map/cycles${suffix}.md`, md.join('\n') + '\n');
fs.writeFileSync(`${dir}/paper/data/decoder-map/cycles${suffix}.json`, JSON.stringify({ N, CAP, V, SKIP, out }, null, 1));
console.log(md.join('\n'));
