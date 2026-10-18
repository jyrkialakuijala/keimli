// A long-running swarm search for dictionaries with many modes in the animation. A population of dictionaries is bred
// on the lattice harness (entropy stages on at the page defaults, each cell on its own) with operators that copy words
// between files and from the pool of every dictionary, reorder a file's chunks, change the case of letters, flip single
// bits, and the character and word mutations of ca-lattice-search.mjs. The score counts modes over space and time: each
// 8 x 8 block is classed by its change, neighbour difference and entropy at the last sample and again ten turns earlier,
// and the score is the effective number of (now, before) classes present, behind guards against frozen, blinking,
// uniform and pure-noise fields.
// Usage: node tools/ca-swarm.mjs [hours] [kind] [skip] [dictLen] [cursorRead] [grid] [turns] [seed] [workers]
// Defaults: 16 36 6 4400 4096 128 200 1 8. The modes score cannot exceed the number of 8 x 8 blocks, so the 64 grid
// saturates near 32 and 128 (256 blocks) leaves headroom. The children of a generation are judged in parallel on [workers] threads, each
// with its own lattice. Writes build/ca-swarm-best*.json and appends to build/ca-swarm*.log; an existing best file seeds
// the next run, so a run can be stopped and restarted.
import fs from 'node:fs';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { makeSim, evaluate } from './ca-harness.mjs';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const ARGS = isMainThread ? process.argv.slice(2) : workerData.args;
const [HOURS, KIND, SKIP, DLEN, CREAD, GRIDN, TURNS, SEED, WORKERS] = [16, 36, 6, 4400, 4096, 128, 200, 1, 8].map((d, i) => Number(ARGS[i] ?? d));
const TAG = `-k${KIND}-s${SKIP}-l${DLEN}-v${CREAD}-g${GRIDN}`;
const OUT = dir + `/build/ca-swarm-best${TAG}.json`;
const LOG = m => { console.log(m); fs.appendFileSync(dir + `/build/ca-swarm${TAG}.log`, m + '\n'); };
const sim = await makeSim({ W: GRIDN, H: GRIDN, changer: KIND, pairMode: 0, skip: SKIP, cread: CREAD, coff: 0 });
let seed = (SEED * 2654435761) >>> 0; const rand = () => { seed = (Math.imul(seed, 1103515245) + 12345) >>> 0; return seed / 4294967296; };   // a 32-bit LCG; the earlier double arithmetic could fall into a short cycle
const ri = n => Math.floor(rand() * n), pick = a => a[ri(a.length)];
const clean = ch => { const c = ch.charCodeAt(0); return c === 10 || (c >= 32 && c < 127) ? ch : ' '; };   // one byte each, printable or newline
const fit = s => { s = [...s].map(clean).join('') || ' '; while (s.length < DLEN) s += s; return s.slice(0, DLEN); };
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
// whole-alphabet transforms: every byte (or those of a segment) is XORed in one bit, has a constant added, is multiplied by an
// odd constant or rotated, within the ring of the 95 printable characters so the result stays a dictionary; and the same on
// 32-bit little-endian words, whose bytes are folded back into the printable range. A bijection on the alphabet keeps the
// dictionary's structure and moves it to other bytes, so the same shapes come out in other colours and other codes.
const P = 95, pv = ch => { const c = ch.charCodeAt(0); return c >= 32 && c < 127 ? c - 32 : 0; }, pc = v => String.fromCharCode(32 + v);
const ror7 = (v, r) => ((v >>> r) | (v << (7 - r))) & 0x7f;
const xform = t => {
  const whole = rand() < 0.6, i0 = whole ? 0 : ri(DLEN), n = whole ? DLEN : 16 + ri(DLEN >> 2), a = t.split('');
  const kind = ri(4), wide = rand() < 0.35;
  if (!wide) {
    const b = ri(7), k = 1 + ri(P - 1), odd = [2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 21, 22, 23, 24, 26, 27, 28, 29, 31][ri(23)], r = 1 + ri(6);   // multipliers coprime with 95
    for (let i = i0; i < i0 + n && i < DLEN; i++) { if (a[i] === '\n') continue; const v = pv(a[i]); let w;
      if (kind === 0) { w = v ^ (1 << b); if (w >= P) w = v; } else if (kind === 1) w = (v + k) % P; else if (kind === 2) w = (v * odd) % P; else { w = ror7(v, r); if (w >= P) w = v; }
      a[i] = pc(w); }
  } else {
    const b = ri(32), k = (ri(0x10000) << 16 | ri(0x10000)) >>> 0, odd = ((ri(0x10000) << 16 | ri(0x10000)) | 1) >>> 0, r = 1 + ri(31);
    for (let i = i0; i + 3 < i0 + n && i + 3 < DLEN; i += 4) {
      let w = (a[i].charCodeAt(0) | a[i + 1].charCodeAt(0) << 8 | a[i + 2].charCodeAt(0) << 16 | a[i + 3].charCodeAt(0) << 24) >>> 0;
      if (kind === 0) w = (w ^ (1 << b)) >>> 0; else if (kind === 1) w = (w + k) >>> 0; else if (kind === 2) w = Math.imul(w, odd) >>> 0; else w = ((w >>> r) | (w << (32 - r))) >>> 0;
      for (let j = 0; j < 4; j++) { const byte = (w >>> (8 * j)) & 255; a[i + j] = byte === 10 ? '\n' : pc(byte % P); }
    }
  }
  return fit(a.join(''));
};
const breed = (parent, swarm) => {
  const donor = rand() < 0.6 ? pick(swarm).text : pick(POOL), r = rand();
  let c = r < 0.19 ? copyWords(parent, donor) : r < 0.29 ? reorder(parent) : r < 0.39 ? recase(parent) : r < 0.49 ? bitflip(parent) : r < 0.61 ? charmut(parent) : r < 0.73 ? splice(parent, donor) : r < 0.84 ? transplant(parent, donor) : xform(parent);
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
if (!isMainThread) { parentPort.on('message', ({ id, text }) => parentPort.postMessage({ id, m: assess(text) })); }
// a pool of workers judges many texts at once
const pool = isMainThread ? Array.from({ length: Math.max(1, WORKERS) }, () => new Worker(new URL(import.meta.url), { workerData: { args: ARGS } })) : [];
const assessMany = texts => new Promise(resolve => {
  const out = new Array(texts.length); let next = 0, done = 0;
  if (!texts.length) return resolve(out);
  const feed = w => { if (next >= texts.length) return; const id = next++; w.once('message', ({ id: rid, m }) => { out[rid] = m; done++; if (done === texts.length) resolve(out); else feed(w); }); w.postMessage({ id, text: texts[id] }); };
  pool.forEach(feed);
});
const fmt = m => `score ${m.score.toFixed(2)} modes ${m.modes.toFixed(2)} regimes ${m.regimes.toFixed(2)} d1 ${m.d1.toFixed(3)} spatial ${m.spatial.toFixed(3)} ent ${m.ent.toFixed(2)} zip ${m.zip.toFixed(2)} distinct ${m.distinct.toFixed(2)}`;

// ---- the swarm
if (!isMainThread) { await new Promise(() => {}); }   // workers only serve
const SIZE = 4 * Math.max(4, WORKERS), KEEP = SIZE / 2;   // children per generation = KEEP, a few rounds of the pool
const t0 = Date.now(), deadline = t0 + HOURS * 3600e3;
LOG(`ca-swarm: kind ${KIND}, skip ${SKIP}, ${DLEN}-byte dictionaries, cursor read ${CREAD}, ${GRIDN}x${GRIDN}, ${TURNS} turns, swarm of ${SIZE} keeping ${KEEP}, ${WORKERS} workers, ${HOURS} h, seed ${SEED}`);
const starts = ['ca-brotli-13', 'ca-brotli-15', 'ca-brotli-14', 'ca-brotli-12', 'ca-brotli-11', 'ca-brotli-9', 'ca-brotli-1', 'ca-brotli-2'].map(id => fit(fs.readFileSync(dd + id + '.txt', 'utf8')));
for (const f of fs.readdirSync(dir + '/build').filter(f => f.startsWith(`ca-swarm-best-k${KIND}-s${SKIP}-l${DLEN}-v${CREAD}-`) && f.endsWith('.json'))) { try { const prev = JSON.parse(fs.readFileSync(dir + '/build/' + f, 'utf8')); for (const e of (prev.archive || []).concat(prev.swarm || [])) if (e.text && !starts.includes(e.text)) starts.push(fit(e.text)); } catch (e) {} }
if (starts.length > 8) LOG(`seeded with ${starts.length - 8} dictionaries from earlier runs`);
let texts = starts.slice(0, SIZE); const stub = texts.map(() => null);
while (texts.length < SIZE) texts.push(breed(pick(starts), stub.map((_, i) => ({ text: texts[i % texts.length] }))));
let swarm = (await assessMany(texts)).map((m, i) => ({ text: texts[i], m, born: 0 }));
swarm.sort((a, b) => b.m.score - a.m.score);
LOG(`generation 0: ` + swarm.slice(0, 4).map(e => e.m.score.toFixed(2)).join(' ') + ` | best ${fmt(swarm[0].m)}`);
const archive = new Map(); const remember = e => { if (!archive.has(e.text)) archive.set(e.text, e); if (archive.size > 40) { const worst = [...archive.values()].sort((a, b) => a.m.score - b.m.score)[0]; archive.delete(worst.text); } };
swarm.forEach(remember);
let gen = 0, lastSave = Date.now(), lastLog = Date.now(), bestSeen = swarm[0].m.score, lastGain = 0, shakes = 0;
// parents: the best, but at most two of any one score, so a plateau of near-clones cannot fill the whole breeding stock
const chooseParents = sw => { const n = new Map(), out = []; for (const e of sw) { const k = e.m.score.toFixed(2); if ((n.get(k) || 0) >= 2) continue; n.set(k, (n.get(k) || 0) + 1); out.push(e); if (out.length === KEEP) break; } return out; };
while (Date.now() < deadline) {
  gen++;
  let parents = chooseParents(swarm); const childTexts = [];
  if (swarm[0].m.score > bestSeen + 1e-9) { bestSeen = swarm[0].m.score; lastGain = gen; }
  if (gen - lastGain > 300) {   // a shake: keep eight, bring back the archive and the pool, mutated twice
    shakes++; lastGain = gen; const back = [...archive.values()].concat(POOL.map(text => ({ text })));
    parents = parents.slice(0, 8); while (parents.length < KEEP) parents.push({ text: breed(breed(pick(back).text, swarm), swarm), m: { score: 0 } });
    LOG(`generation ${gen}: no gain for 300 generations, shake ${shakes}`);
  }
  const seen = new Set(swarm.map(e => e.text));
  for (let tries = 0; childTexts.length < SIZE - KEEP; tries++) { const c = tries < 500 ? breed(pick(parents).text, swarm) : breed(breed(pick(POOL), swarm), swarm); if (seen.has(c)) continue; seen.add(c); childTexts.push(c); }
  if (gen % 25 === 0) childTexts[childTexts.length - 1] = pick(POOL);   // fresh blood from the pool
  const ms = await assessMany(childTexts);
  swarm = parents.filter(e => e.m.score > 0 || e.born !== undefined).concat(childTexts.map((text, i) => ({ text, m: ms[i], born: gen }))).sort((a, b) => b.m.score - a.m.score);
  swarm.slice(0, 3).forEach(remember);
  if (Date.now() - lastLog > 300e3) { lastLog = Date.now(); LOG(`generation ${gen} (${((Date.now() - t0) / 60000).toFixed(0)} min): ` + swarm.slice(0, 4).map(e => e.m.score.toFixed(2)).join(' ') + ` | best ${fmt(swarm[0].m)} | ${JSON.stringify(swarm[0].text.slice(0, 50))}`); }
  if (Date.now() - lastSave > 600e3) { lastSave = Date.now(); fs.writeFileSync(OUT, JSON.stringify({ swarm, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1)); }
}
fs.writeFileSync(OUT, JSON.stringify({ swarm, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1));
LOG(`done: ${gen} generations in ${((Date.now() - t0) / 3600e3).toFixed(1)} h; best ${fmt(swarm[0].m)}\n${JSON.stringify(swarm[0].text)}`);
for (const w of pool) w.terminate();
