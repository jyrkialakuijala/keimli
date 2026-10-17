// Dictionary search for cellular-automaton dynamics. With entropy increase and decrease off, every concatenated pair
// iterates the decoder on its own (roles alternating each turn), so the dynamics is exactly the attractor structure of
// that iteration: this script measures it by a census (common random starts, cycle detection) and hill-climbs 200-byte
// dictionaries for several attractors with balanced basins, cycles of 2..8 (the renderer shows those as stripes) and
// moderate transients. Usage: node tools/ca-search.mjs [seed] [seeds] [climbs] [kind]   (kind 45 = the codebook)
// Writes build/ca-search-best.json and appends to build/ca-search.log.
import fs from 'node:fs';
import { Codec } from './ca-harness.mjs';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const OUT = dir + '/build/ca-search-best.json';
const KIND = Number(process.argv[5] || 45);
const LOG = m => { console.log(m); fs.appendFileSync(dir + '/build/ca-search.log', m + '\n'); };
let seed = Number(process.argv[2] || 1);
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
const ri = n => Math.floor(rand() * n), pick = a => a[ri(a.length)];
const LETTERS = 'abcdefghijklmnopqrstuvwxyz';
const fit = s => { s = s.replace(/[^\x20-\x7e\n]/g, ''); while (s.length < 200) s += s; return s.slice(0, 200); };
const wasmBytes = fs.readFileSync(dir + '/build/keimli.wasm');
const { instance } = await WebAssembly.instantiate(wasmBytes);
const ex = instance.exports, L = Codec.LAYOUT, GRID = L.GRID;
const m8 = () => new Uint8Array(ex.memory.buffer);
let io;
const setDict = text => { io = Codec.install(ex.memory, Codec.build(text, 3)); io.setChanger(KIND); io.setSkipBits(0); io.setCursorRead(127); io.setCursorOffset(0); };
const decodeOnce = (pair, flip) => { m8().set(pair, GRID); io.setPair(1, flip); ex.change(2, GRID, L.PRM); io.setPair(0, 0); return m8().slice(GRID, GRID + 32); };
// common random starts for every candidate
let s2 = 99; const r2 = () => { s2 = (s2 * 1103515245 + 12345) & 0x7fffffff; return s2 / 0x7fffffff; };
const STARTS = Array.from({ length: 96 }, () => Uint8Array.from({ length: 32 }, () => Math.floor(r2() * 256)));
const CAP = 64;
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const ham = (a, b) => { let d = 0; for (let i = 0; i < 32; i++) d += POP[a[i] ^ b[i]]; return d; };
// per start: an exact cycle (length, transient) when one appears within CAP steps; otherwise the nearest recurrence,
// the smallest Hamming distance (of 256 bits) between the last state and any earlier one, which grades how close to a
// cycle the trajectory comes, so the search has a slope to climb where no exact cycle exists yet
function census(text) {
  setDict(text);
  const basins = new Map(); let chaotic = 0, trSum = 0, nearSum = 0; const lens = []; let q = 0;
  for (const s0 of STARTS) {
    let p = s0, t = 0; const seen = new Map(), path = []; let key;
    while (t < CAP) { key = p.join(','); if (seen.has(key)) break; seen.set(key, t); path.push(p); p = decodeOnce(p, t & 1); t++; }
    if (t >= CAP) {
      chaotic++; let near = 256; for (let i = 0; i + 1 < path.length; i++) near = Math.min(near, ham(path[path.length - 1], path[i]));
      nearSum += near; q += 0.3 * Math.exp(-near / 12); continue;
    }
    const start = seen.get(key), len = t - start; trSum += start; lens.push(len);
    let qb = p, best = key; for (let i = 0; i < len; i++) { qb = decodeOnce(qb, (start + i) & 1); const k = qb.join(','); if (k < best) best = k; }
    const id = best + '|' + len; basins.set(id, (basins.get(id) || 0) + 1);
    const wl = len >= 2 && len <= 8 ? 1 : len === 1 ? 0.55 : len <= 16 ? 0.5 : 0.2, wt = start >= 2 && start <= 30 ? 1 : start < 2 ? 0.6 : 0.35;
    q += wl * wt;
  }
  const n = STARTS.length, settled = n - chaotic;
  let H = 0; for (const v of basins.values()) { const pr = v / settled; H -= pr * Math.log(pr); }
  const effN = settled ? Math.exp(H) : 0;
  const cyc2 = lens.filter(l => l >= 2).length / n, cyc28 = lens.filter(l => l >= 2 && l <= 8).length / n;
  const lenKinds = new Set(lens.filter(l => l >= 2)).size;
  return { attractors: basins.size, effN, chaotic: chaotic / n, near: chaotic ? nearSum / chaotic : 0, transient: settled ? trSum / settled : CAP, cyc2, cyc28, lenKinds, maxCycle: Math.max(0, ...lens), meanCycle: lens.length ? lens.reduce((a, b) => a + b, 0) / lens.length : 0, q: q / n };
}
const win = (x, lo, hi, soft = 0.5) => { if (x >= lo && x <= hi) return 1; const d = x < lo ? (lo - x) / (lo * soft + 1e-9) : (x - hi) / (hi * soft + 1e-9); return Math.max(0, 1 - d); };
// interesting: most starts settle into short cycles after a few steps (q), into several attractors with balanced basins
// (effN), with more than one cycle length; the per-start quality carries the gradient, the population terms shape it
const score = c => c.q * (0.4 + 0.6 * win(c.effN, 3, 16, 1)) * (1 + 0.15 * Math.min(4, c.lenKinds));

// ---- families (initial hypotheses) and mutations
const phrase = (alpha, len) => Array.from({ length: len }, () => pick(alpha)).join('');
const families = {
  phrases() { const k = 2 + ri(6), len = 3 + ri(10); const letters = LETTERS.split('').sort(() => rand() - 0.5); const per = Math.max(2, Math.floor(26 / k));
    const ps = Array.from({ length: k }, (_, i) => phrase(letters.slice(i * per, (i + 1) * per), len)); let s = ''; while (s.length < 200) s += pick(ps) + ' '; return fit(s); },
  phrasesShared() { const k = 2 + ri(5), len = 4 + ri(10); const alpha = LETTERS.slice(0, 4 + ri(12)).split(''); const ps = Array.from({ length: k }, () => phrase(alpha, len)); let s = ''; while (s.length < 200) s += pick(ps) + ' '; return fit(s); },
  branchChain() { const len = 8 + ri(30), nb = 1 + ri(5); const alpha = LETTERS.split('').sort(() => rand() - 0.5).slice(0, len); const base = alpha.join(''); const alts = Array.from({ length: nb }, () => [ri(len), pick(LETTERS)]); let s = '';
    while (s.length < 200) { const w = base.split(''); for (const [i, c] of alts) if (rand() < 0.5) w[i] = c; s += w.join('') + ' '; } return fit(s); },
  mixed() { const f = 0.05 + rand() * 0.4; return fit(families.phrases().split('').map(c => rand() < f ? String.fromCharCode(32 + ri(95)) : c).join('')); },
  selfConsistent() { let s = phrase(LETTERS.slice(0, 4 + ri(12)).split(''), 6 + ri(10)) + ' ', rounds = 0;
    while (s.length < 200 && rounds < 40) { setDict(fit(s)); const cell = new Uint8Array(32); cell.set(new TextEncoder().encode(s.slice(-32)).subarray(0, 32)); const out = decodeOnce(cell, rounds & 1); s += String.fromCharCode(...out).replace(/[^\x20-\x7e]/g, '') + ' '; rounds++; }
    return fit(s); },
  natural() { const dd = dir + '/src/changers/dict/'; const files = ['../declaration.txt', 'nocturne.txt', 'kalevala-1.txt', 'catullus-5.txt', 'don-quijote.txt', 'nam-quoc-son-ha-viet.txt', 'voluspa.txt', 'qaro-kozum.txt']; const t = fs.readFileSync(dd + pick(files), 'utf8').replace(/[^\x20-\x7e\n]/g, ''); const i = ri(Math.max(1, t.length - 200)); return fit(t.slice(i, i + 200)); },
  random() { return fit(Array.from({ length: 200 }, () => String.fromCharCode(32 + ri(95))).join('')); },
  smallAlphabet() { const a = LETTERS.slice(0, 2 + ri(4)).split('').concat([' ']); return fit(Array.from({ length: 200 }, () => pick(a)).join('')); },
};
const mutate = t => {
  const a = t.split(''); const r = rand();
  if (r < 0.4) { a[ri(200)] = String.fromCharCode(32 + ri(95)); }
  else if (r < 0.6) { const i = ri(200), j = ri(200), n = 1 + ri(12); for (let k = 0; k < n; k++) if (i + k < 200 && j + k < 200) a[j + k] = t[i + k]; }   // copy a segment
  else if (r < 0.75) { const i = ri(200), n = 1 + ri(12), c = pick(t); for (let k = 0; k < n && i + k < 200; k++) a[i + k] = c; }   // a run of one existing character
  else if (r < 0.9) { const i = ri(200), n = 2 + ri(10); const seg = t.slice(i, i + n); return fit(t.slice(0, i) + seg + t.slice(i)); }   // duplicate in place
  else { const i = ri(200), j = ri(200); [a[i], a[j]] = [a[j], a[i]]; }
  return fit(a.join(''));
};

// ---- search: family seeds, then hill climbing on a few elites with restarts, within a time budget
const N_SEED = Number(process.argv[3] || 240), N_CLIMB = Number(process.argv[4] || 3000), HOURS = Number(process.argv[6] || 0);
const deadline = HOURS ? Date.now() + HOURS * 3600e3 : Infinity;
const t0 = performance.now();
const pool = [];
const names = Object.keys(families);
LOG(`ca-search: kind ${KIND}, seed ${process.argv[2] || 1}, ${N_SEED} seeds, ${HOURS ? HOURS + ' h' : N_CLIMB + ' climbs'}`);
for (let i = 0; i < N_SEED; i++) { const fam = names[i % names.length]; const text = families[fam](); const c = census(text); pool.push({ text, fam, c, s: score(c) }); }
pool.sort((a, b) => b.s - a.s);
const fmt = e => `score ${e.s.toFixed(3)} q ${e.c.q.toFixed(2)} effN ${e.c.effN.toFixed(1)} attr ${e.c.attractors} cyc2-8 ${e.c.cyc28.toFixed(2)} lens ${e.c.lenKinds} tr ${e.c.transient.toFixed(1)} chaotic ${e.c.chaotic.toFixed(2)} near ${e.c.near.toFixed(0)}`;
LOG(`seeds done in ${((performance.now() - t0) / 1000).toFixed(0)} s; best per family:`);
for (const f of names) { const b = pool.find(p => p.fam === f); if (b) LOG(`  ${f.padEnd(14)} ${fmt(b)} | ${JSON.stringify(b.text.slice(0, 50))}`); }
const ELITES = 8;
let elite = pool.slice(0, ELITES).map(p => ({ ...p, stale: 0 }));
const archive = new Map();   // the best distinct dictionaries seen
const remember = e => { archive.set(e.text, { text: e.text, fam: e.fam, c: e.c, s: e.s }); if (archive.size > 40) { const worst = [...archive.values()].sort((a, b) => a.s - b.s)[0]; archive.delete(worst.text); } };
let evals = 0, lastLog = 0;
while (evals < N_CLIMB && Date.now() < deadline) {
  for (const e of elite) {
    const cand = rand() < 0.1 ? (() => { const o = pick(elite).text, i = ri(200); return fit(e.text.slice(0, i) + o.slice(i)); })() : rand() < 0.25 ? mutate(mutate(e.text)) : mutate(e.text);
    const c = census(cand); evals++; const s = score(c);
    if (s >= e.s) { if (s > e.s) e.stale = 0; e.text = cand; e.c = c; e.s = s; e.fam = e.fam.replace(/\*?$/, '*'); remember(e); } else e.stale++;
    if (e.stale > 1500) {   // restart: a fresh family seed or a copy of the best elite
      elite.sort((a, b) => b.s - a.s); remember(e);
      if (rand() < 0.5) { const fam = pick(names), text = families[fam](); const c2 = census(text); Object.assign(e, { text, fam, c: c2, s: score(c2), stale: 0 }); }
      else { const b = elite[0]; Object.assign(e, { text: mutate(mutate(mutate(b.text))), fam: b.fam, stale: 0 }); e.c = census(e.text); e.s = score(e.c); }
    }
  }
  if (evals - lastLog >= 4000) {
    lastLog = evals; elite.sort((a, b) => b.s - a.s);
    LOG(`climb ${evals} (${((performance.now() - t0) / 60000).toFixed(0)} min): best ${fmt(elite[0])} (${elite[0].fam}) | ${JSON.stringify(elite[0].text.slice(0, 50))}`);
    fs.writeFileSync(OUT, JSON.stringify({ elite: elite.sort((a, b) => b.s - a.s), archive: [...archive.values()].sort((a, b) => b.s - a.s) }, null, 1));
  }
}
elite.sort((a, b) => b.s - a.s); for (const e of elite) remember(e);
fs.writeFileSync(OUT, JSON.stringify({ elite, archive: [...archive.values()].sort((a, b) => b.s - a.s) }, null, 1));
LOG(`done: ${evals} climbs in ${((performance.now() - t0) / 60000).toFixed(1)} min; best ${fmt(elite[0])}\n${JSON.stringify(elite[0].text)}`);
