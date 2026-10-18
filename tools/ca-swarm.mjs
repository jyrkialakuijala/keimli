// A long-running swarm search for dictionaries with many modes in the animation. A population of dictionaries is bred
// on the lattice harness (entropy stages on at the page defaults, each cell on its own) with operators that copy words
// between files and from the pool of every dictionary, reorder a file's chunks, change the case of letters, flip single
// bits, and the character and word mutations of ca-lattice-search.mjs. The score counts modes over space and time: each
// 8 x 8 block is classed by its change, neighbour difference and entropy at the last sample and again ten turns earlier,
// and the score is the effective number of (now, before) classes present, behind guards against frozen, blinking,
// uniform and pure-noise fields.
// Usage: node tools/ca-swarm.mjs [hours] [kind] [skip] [dictLen] [cursorRead] [grid] [turns] [seed]
// Defaults: 16 36 6 4400 4096 64 200 1. Writes build/ca-swarm-best*.json and appends to build/ca-swarm*.log.
import fs from 'node:fs';
import { makeSim, evaluate } from './ca-harness.mjs';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const [HOURS, KIND, SKIP, DLEN, CREAD, GRIDN, TURNS, SEED] = [16, 36, 6, 4400, 4096, 64, 200, 1].map((d, i) => Number(process.argv[2 + i] ?? d));
const TAG = `-k${KIND}-s${SKIP}-l${DLEN}-v${CREAD}-g${GRIDN}`;
const OUT = dir + `/build/ca-swarm-best${TAG}.json`;
const LOG = m => { console.log(m); fs.appendFileSync(dir + `/build/ca-swarm${TAG}.log`, m + '\n'); };
let seed = SEED; const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
const ri = n => Math.floor(rand() * n), pick = a => a[ri(a.length)];
const clean = ch => { const c = ch.charCodeAt(0); return c === 10 || (c >= 32 && c < 127) ? ch : ' '; };   // one byte each, printable or newline
const fit = s => { s = [...s].map(clean).join(''); while (s.length < DLEN) s += s; return s.slice(0, DLEN); };
const sim = await makeSim({ W: GRIDN, H: GRIDN, changer: KIND, pairMode: 0, skip: SKIP, cread: CREAD, coff: 0 });
const dd = dir + '/src/changers/dict/';
const POOL = fs.readdirSync(dd).filter(f => f.endsWith('.txt')).concat(['../declaration.txt']).map(f => fit(fs.readFileSync(dd + f, 'utf8')));
const words = t => t.split(/\s+/).filter(w => w.length >= 2);

// ---- operators
const copyWords = (t, donor) => { const ws = words(donor); if (!ws.length) return t; let a = t; for (let k = 1 + ri(4); k > 0; k--) { const w = pick(ws), i = ri(DLEN); a = a.slice(0, i) + w + ' ' + a.slice(i + w.length + 1); } return fit(a); };
const reorder = t => { const n = 2 + ri(6), cuts = Array.from({ length: n - 1 }, () => ri(DLEN)).sort((a, b) => a - b), parts = []; let p = 0; for (const c of cuts) { parts.push(t.slice(p, c)); p = c; } parts.push(t.slice(p));
  if (rand() < 0.5) { const i = ri(parts.length), j = ri(parts.length); [parts[i], parts[j]] = [parts[j], parts[i]]; } else { const k = ri(parts.length); parts.push(...parts.splice(0, k)); } return fit(parts.join('')); };
const recase = t => { if (rand() < 0.5) { const i = ri(DLEN), n = 1 + ri(40); const seg = t.slice(i, i + n); return fit(t.slice(0, i) + (rand() < 0.5 ? seg.toUpperCase() : seg.toLowerCase()) + t.slice(i + n)); }
  const letters = [...new Set(t.match(/[a-zA-Z]/g) || [])]; if (!letters.length) return t; const L = pick(letters), M = L === L.toLowerCase() ? L.toUpperCase() : L.toLowerCase(); return fit(t.split(L).join(M)); };
const bitflip = t => { const a = t.split(''); for (let k = 1 + ri(8); k > 0; k--) { const i = ri(DLEN), c = a[i].charCodeAt(0) ^ (1 << ri(7)); a[i] = clean(String.fromCharCode(c)); } return fit(a.join('')); };
const charmut = t => { const a = t.split(''); const r = rand();
  if (r < 0.4) { a[ri(DLEN)] = String.fromCharCode(32 + ri(95)); }
  else if (r < 0.6) { const i = ri(DLEN), j = ri(DLEN), n = 1 + ri(12); for (let k = 0; k < n; k++) if (i + k < DLEN && j + k < DLEN) a[j + k] = t[i + k]; }
  else if (r < 0.8) { const i = ri(DLEN), n = 1 + ri(12), c = pick(t); for (let k = 0; k < n && i + k < DLEN; k++) a[i + k] = c; }
  else { const i = ri(DLEN), n = 2 + ri(10); const seg = t.slice(i, i + n); return fit(t.slice(0, i) + seg + t.slice(i)); }
  return fit(a.join('')); };
const splice = (t, o) => { const k = ri(DLEN); return fit(rand() < 0.5 ? t.slice(0, k) + o.slice(k) : o.slice(0, k) + t.slice(k)); };
const transplant = (t, o) => { const i = ri(DLEN), n = 8 + ri(DLEN >> 3); return fit(t.slice(0, i) + o.slice(i, i + n) + t.slice(i + n)); };
const breed = (parent, swarm) => {
  const donor = rand() < 0.6 ? pick(swarm).text : pick(POOL), r = rand();
  let c = r < 0.22 ? copyWords(parent, donor) : r < 0.34 ? reorder(parent) : r < 0.46 ? recase(parent) : r < 0.58 ? bitflip(parent) : r < 0.72 ? charmut(parent) : r < 0.86 ? splice(parent, donor) : transplant(parent, donor);
  if (rand() < 0.3) c = breed(c, swarm);   // sometimes two operators in a row
  return c;
};

// ---- the score: modes over space and time
const win = (x, lo, hi, soft = 0.5) => { if (x >= lo && x <= hi) return 1; const d = x < lo ? (lo - x) / (lo * soft + 1e-9) : (x - hi) / (hi * soft + 1e-9); return Math.max(0, 1 - d); };
function assess(text) {
  const rows = evaluate(sim, text, { turns: TURNS, seed: 11, every: 10, keepFrom: TURNS - 13 });   // the last two samples have their previous frames
  const late = rows.slice(-5), mean = k => late.reduce((s, r) => s + r[k], 0) / late.length;
  const last = rows[rows.length - 1], before = rows[rows.length - 4];   // samples at turns T and T - 10 (the last three rows are consecutive turns)
  const d1 = last.d1, d2 = last.d2, sp = mean('spatial'), ent = mean('ent'), zip = mean('zip'), distinct = mean('distinct');
  const f = { change: win(d1, 0.005, 0.35), blink: win(d2 / (d1 + 1e-9), 0.5, 10), structure: win(sp, 0.05, 0.42), entropy: win(ent, 1.5, 7.2), compress: win(zip, 0.1, 0.9), variety: win(distinct, 0.05, 0.98), alive: d1 > 0.002 ? 1 : 0 };
  let modes = 1, regimes = last.regimes ? last.regimes.effective : 1;
  if (last.regimes && before && before.regimes && before.regimes.blocks.length === last.regimes.blocks.length) {
    const cls = new Map(); last.regimes.blocks.forEach((k, i) => { const key = k * 48 + before.regimes.blocks[i]; cls.set(key, (cls.get(key) || 0) + 1); });
    let H = 0; const n = last.regimes.blocks.length; for (const v of cls.values()) { const p = v / n; H -= p * Math.log(p); } modes = Math.exp(H);
  }
  const score = Object.values(f).reduce((a, b) => a * b, 1) * modes;
  return { score, modes, regimes, d1, spatial: sp, ent, zip, distinct, act: mean('act') };
}
const fmt = m => `score ${m.score.toFixed(2)} modes ${m.modes.toFixed(2)} regimes ${m.regimes.toFixed(2)} d1 ${m.d1.toFixed(3)} spatial ${m.spatial.toFixed(3)} ent ${m.ent.toFixed(2)} zip ${m.zip.toFixed(2)} distinct ${m.distinct.toFixed(2)}`;

// ---- the swarm
const SIZE = 16, KEEP = 8;
const t0 = Date.now(), deadline = t0 + HOURS * 3600e3;
LOG(`ca-swarm: kind ${KIND}, skip ${SKIP}, ${DLEN}-byte dictionaries, cursor read ${CREAD}, ${GRIDN}x${GRIDN}, ${TURNS} turns, swarm of ${SIZE} keeping ${KEEP}, ${HOURS} h, seed ${SEED}`);
const starts = ['ca-brotli-13', 'ca-brotli-15', 'ca-brotli-14', 'ca-brotli-12', 'ca-brotli-11', 'ca-brotli-9', 'ca-brotli-1', 'ca-brotli-2'].map(id => fit(fs.readFileSync(dd + id + '.txt', 'utf8')));
let swarm = starts.map(text => ({ text, m: assess(text), born: 0 }));
for (const t of starts) swarm.push({ text: breed(t, swarm), m: null, born: 0 });
for (const e of swarm) if (!e.m) e.m = assess(e.text);
swarm.sort((a, b) => b.m.score - a.m.score);
LOG(`generation 0: ` + swarm.slice(0, 4).map(e => e.m.score.toFixed(2)).join(' ') + ` | best ${fmt(swarm[0].m)}`);
const archive = new Map(); const remember = e => { if (!archive.has(e.text)) archive.set(e.text, e); if (archive.size > 40) { const worst = [...archive.values()].sort((a, b) => a.m.score - b.m.score)[0]; archive.delete(worst.text); } };
swarm.forEach(remember);
let gen = 0, lastSave = Date.now(), lastLog = Date.now();
while (Date.now() < deadline) {
  gen++;
  const parents = swarm.slice(0, KEEP), children = [];
  const seen = new Set(swarm.map(e => e.text));
  while (children.length < SIZE - KEEP) { const c = breed(pick(parents).text, swarm); if (seen.has(c)) continue; seen.add(c); children.push({ text: c, m: assess(c), born: gen }); }
  swarm = parents.concat(children).sort((a, b) => b.m.score - a.m.score);
  if (gen % 25 === 0) { const inj = pick(POOL); swarm[swarm.length - 1] = { text: inj, m: assess(inj), born: gen }; swarm.sort((a, b) => b.m.score - a.m.score); }   // fresh blood from the pool
  swarm.slice(0, 3).forEach(remember);
  if (Date.now() - lastLog > 300e3) { lastLog = Date.now(); LOG(`generation ${gen} (${((Date.now() - t0) / 60000).toFixed(0)} min): ` + swarm.slice(0, 4).map(e => e.m.score.toFixed(2)).join(' ') + ` | best ${fmt(swarm[0].m)} | ${JSON.stringify(swarm[0].text.slice(0, 50))}`); }
  if (Date.now() - lastSave > 600e3) { lastSave = Date.now(); fs.writeFileSync(OUT, JSON.stringify({ swarm, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1)); }
}
fs.writeFileSync(OUT, JSON.stringify({ swarm, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1));
LOG(`done: ${gen} generations in ${((Date.now() - t0) / 3600e3).toFixed(1)} h; best ${fmt(swarm[0].m)}\n${JSON.stringify(swarm[0].text)}`);
