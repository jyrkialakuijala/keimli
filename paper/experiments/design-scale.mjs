// One construction for every dictionary size 2^8 .. 2^24 (names ca-size-08 .. ca-size-24): the window range V is the
// size, the header has log2 V bits, and the number of designed types grows with the size.
//
// The construction is design-dict.mjs's. A designed cell is a quine head and a tail: byte 0's six skipped bits, the
// header h = 16 u (u the cell's code), and the commands "no literals, copy a bytes at distance d, then 16 - a more at
// the same distance" (the split, d and the transforms are searched per size for the most heads whose bytes the text
// pipeline carries: no byte above 0x7e, no NUL, newline, return or lowercase). Such a cell decodes to the 16 dictionary
// bytes at h - d, its slot, and nothing else of the cell is read, so among designed cells the decoder is a table over
// codes. Code bits 0..2 are the three Gray bits (header bits 4..6, inside byte 1 at bit positions 2..4, so flipping
// them keeps the byte printable); code bits 6 and 7 (header bits 10, 11) are the group bits. A spot is a block of 8
// codes (128 bytes of slots); a group is the 2-cube of 4 spots over the group bits (32 codes, 512 bytes).
//
// Three kinds of type:
// - Gray 8-cycle (closed, DEFINITION.md section 4): a spot; state k decodes to state k+1 along the reflected Gray code
//   over the Gray bits, the last tail byte flipping with the code's parity. Gray types come in groups of four, whose
//   blocks differ in one header bit, so every crossover child of two types of a group lands in the group: the four are
//   mutually closed (the corollary of DEFINITION.md section 4).
// - Phase-chasing 3-cycle (the mechanism of ca-live-phases, design-live.mjs): a whole group; the three states sit at the
//   codes 00000, 00111, 11011 of the group's 5-cube (Gray and group bits; pairwise 3, 3 and 4 bits apart), and every
//   other code of the cube is routed by expected parentage with the lead rule: the child of two phases joins the phase
//   ahead, so each phase invades the one behind it.
// - Fixed point: a spot whose eight slots all hold the one state, so a one-bit header variant returns at once.
// Every random cell is funnelled by the filler: each type has a short printable pattern (one to four bytes) tiled over
// its region of the header range, and the dictionary positions a cell made of that pattern copies its head from (its
// landing pad, fixed by the pattern's bits) hold the head of the type's state 0, so pattern -> state 0 in one step.
// Patterns run over the 98 safe bytes to period 4 and over the 29 control bytes to period 5 (at 15 and 23 header bits
// the "no literals" code falls on bits 5 and 6 of a byte, which only a control byte has both clear).
// Only patterns every rotation of which lands are used (a rotation without a landing made stray fixed points of filler
// bytes with 42 % of the cells in a trial), one pattern per distinct pad (the one with the shortest reading); the pads
// of the patterns in use are position-disjoint, and each rotation of a pattern may serve a different type (a pattern
// of period L feeds up to L types; its region is shared, so a type's basin is about its share of the region). A
// pattern's commands may carry a lowercase transform on a pad byte; such a pattern is given only to a type whose head
// holds no letter there, and spots whose heads hold no letter at all are taken first.
//
// Schedule (types per size). With U the groups whose 32 heads are all safe, the block budget is B = floor(U / 2)
// groups (blocks then cover at most a quarter of the dictionary and the filler the rest): nGrayGroups = max(1,
// round(B / 5)) (4 Gray types each), nChase = B - nGrayGroups, nFixed = min(6, max(1, floor(B / 4))) on single spots
// outside the groups, so the Gray and the chasing types are each about a third of the designed types when B >= 5.
// Below 12 header bits there are no groups (the group bits need header bits 10 and 11): the budget is half the safe
// spots, at least one, one fixed point when it is 2 or more, Gray cycles for the rest (paired over header bit 10 at 11
// bits). Then the pattern alphabet caps the count: a type needs its own pad outside the blocks; when fewer patterns fit
// than types were scheduled, the chasing types are dropped first, then whole Gray groups, then single Gray cycles.
// The pads come first in the placement (their positions are fixed by the patterns; the blocks then avoid them).
// Patterns are assigned by reading length (the bits the pattern cell consumes; the lattice favours short readings):
// the fixed points take the shortest, the longest and evenly spaced readings between, the Gray and chasing types
// alternate over the shortest remaining ones. Regions are equal shares of the header range in type order.
// Everything is verified on decode36: every state maps to its successor, every routed code of a chasing cube to its
// route, every landing pad to the head of state 0. The census (Brent on random cells) reports the attractors realised.
//
// Parallelism: the pattern enumeration (98^4 period-4 patterns, a few minutes on one core), the verification and the
// census run on node:worker_threads (workers=, default min(24, cores - 4)), split by first byte, type index and cell
// range, with a seed per chunk and the results merged in chunk order, so a re-run gives byte-identical dictionaries.
// The sizes are independent: design-scale.sh runs them as separate processes and merges the manifest entries at the end.
//
// Usage: node paper/experiments/design-scale.mjs [sizes=8-24 | sizes=12,16,20] [out=src/changers/dict] [seed=1] [census=16384] [workers=N] [periods=4]
//        node paper/experiments/design-scale.mjs merge          (the manifest entries of paper/data/design/*.entry.json into src/changers/dict/manifest.json)
// Writes <out>/ca-size-NN.txt, paper/data/design/ca-size-NN.{json,md,entry.json}; sizes of 100 KB and more become
// "url" manifest entries the page fetches on demand.
import fs from 'node:fs';
import os from 'node:os';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { decode36 } from './decode36.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const SKIP = 6, R = 0.25, URL_FROM = 100 * 1024;   // R: the exchange rate the routing assumes; URL_FROM: dictionaries this long are fetched, not inlined
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const lower = v => v >= 0x61 && v <= 0x7a;
const safe = v => v > 0 && v < 0x7f && v !== 10 && v !== 13 && !lower(v);   // a byte the text pipeline (UTF-8, JSON, universal newlines) carries unchanged
const printable = v => v >= 0x20 && v <= 0x7e && !lower(v);
const key = c => Buffer.from(c).toString('latin1');
const PAL = []; for (let v = 0x20; v <= 0x7e; v++) if (printable(v)) PAL.push(v);   // tail alphabet, 69 bytes (no lowercase: the transforms)
const PAT = []; for (let v = 1; v < 0x7f; v++) if (safe(v)) PAT.push(v);   // filler pattern alphabet: the 98 safe bytes (control bytes included: at 15 and 23 header bits the "no literals" code falls on bits 5 and 6 of a byte, which no printable byte has both clear; lowercase excluded: it bred stray cycles, 93 attractors with 20 % of the cells at 2^12 in a trial)
const isLetter = v => v >= 0x41 && v <= 0x5a;
const grayOf = k => k ^ (k >> 1);
const xorshift = seed => { let s = seed >>> 0 || 1; return () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s; }; };
const randomCellOf = r32 => () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = r32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };

// ---- the head: header h then two or three copy commands summing to 16 bytes, LSB-first from bit 6.
// form = { lens: [a, b(, c)], d, first: 'explicit' (1 + 6 bits, d 16..31) | 'ring' (the initial ring's distance 16, 5 bits),
//          ring: the later distances from the ring (5 bits each) or explicit again, tfs: a transform per command (0..2) }
function packHead(h, HB, form) {
  const cell = new Uint8Array(8); let bp = 6;
  const put = (v, n) => { for (let i = 0; i < n; i++, bp++) if ((v >> i) & 1) cell[bp >> 3] |= 1 << (bp & 7); };
  const lenCode = len => { if (len <= 3) put(len - 2, 2); else if (len <= 5) { put(2, 2); put(len - 4, 1); } else { put(3, 2); put(len - 6, 3); } };
  put(h, HB);
  form.lens.forEach((len, i) => {
    put(0, 2); lenCode(len);
    if (i === 0) { if (form.first === 'ring') { put(0, 1); put(3, 4); } else { put(1, 1); put(form.d - 1, 6); } }   // sc 3 is the initial ring's last distance, 16
    else if (form.ring) { put(0, 1); put(0, 4); } else { put(1, 1); put(form.d - 1, 6); }   // sc 0: the last distance again
    put(form.tfs[i], 2);
  });
  return { cell, end: bp };
}
const SPLITS = [];
for (let a = 2; a <= 13; a++) { if (16 - a >= 2 && 16 - a <= 13) SPLITS.push([a, 16 - a]); for (let b = 2; b <= 13; b++) { const c = 16 - a - b; if (c >= 2 && c <= 13) SPLITS.push([a, b, c]); } }
const FORMS = [];
for (const lens of SPLITS) for (const first of ['explicit', 'ring']) for (const ring of [true, false]) for (const d of first === 'ring' ? [16] : [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]) for (let t = 0; t < 3 ** lens.length; t++) { const tfs = lens.map((_, i) => Math.floor(t / 3 ** i) % 3); FORMS.push({ lens, d, first, ring, tfs }); }

// ---- the filler patterns: a pattern's rotations, where each copies its head from (the pad), only when all of them land
function patternInfo(P, { HB, HEAD_BYTES, DUMMY, DUMMY_A }) {
  const L = P.length, V = 2 ** HB, OPTS = { skip: SKIP, V, coff: 0 }, TL = V, rots = [];
  for (let r = 0; r < L; r++) {
    const cell = new Uint8Array(16); for (let i = 0; i < 16; i++) cell[i] = P[(i + r) % L];
    const res = decode36(cell, DUMMY, OPTS), lead = res.src.findIndex(v => v !== 2);
    const pos = res.dictPos.slice(0, Math.min(HEAD_BYTES, lead < 0 ? 16 : lead));
    if (!(pos.length === HEAD_BYTES && new Set(pos).size === HEAD_BYTES && !pos.includes(TL - 1))) return null;
    const lo = decode36(cell, DUMMY_A, OPTS).out, lowers = []; for (let j = 0; j < HEAD_BYTES; j++) if (lo[j] === 0x61) lowers.push(j);   // a lowercase transform on these pad bytes: the head there must hold no letter
    rots.push({ cell: Array.from(cell), pos, consumed: res.consumed, lowers });
  }
  const taken = new Map();   // one position cannot hold two head bytes
  for (const r of rots) { if (r.pos.some((p, j) => taken.has(p) && taken.get(p) !== j)) return null; r.pos.forEach((p, j) => taken.set(p, j)); }
  return { P, rots, reading: Math.max(...rots.map(r => r.consumed)), pads: rots.flatMap(r => r.pos.map((p, j) => [p, j])), lowers: [...new Set(rots.flatMap(r => r.lowers))].sort(), padKey: rots.map(r => r.pos.join(',')).sort().join('|') };
}
// ---- worker tasks
if (!isMainThread) {
  const t = workerData;
  if (t.task === 'patterns') {   // all fully landing patterns of periods 1..periods over the alphabet, and of period periods + 1 over the control bytes, whose first byte index is in [a0, a1)
    const V = 2 ** t.HB, env = { HB: t.HB, HEAD_BYTES: t.HEAD_BYTES, DUMMY: new Uint8Array(V).fill(0x20), DUMMY_A: new Uint8Array(V).fill(0x41) }, out = [];
    const CTRL = PAT.filter(v => v < 0x20);   // where the "no literals" code falls on bits 5 and 6 of a byte only control bytes land, so their alphabet goes one period further
    for (const [L, A] of [...Array.from({ length: t.periods }, (_, i) => [i + 1, PAT]), [t.periods + 1, CTRL]]) for (let a = t.a0; a < Math.min(t.a1, A.length); a++) {
      const rest = A.length ** (L - 1);
      for (let x = 0; x < rest; x++) {
        const P = [A[a]]; let y = x; for (let i = 1; i < L; i++) { P.push(A[y % A.length]); y = Math.floor(y / A.length); }
        let per = L; for (let q = 1; q < L; q++) if (L % q === 0 && P.every((v, i) => v === P[i % q])) { per = q; break; } if (per < L) continue;   // a shorter period is another pattern
        const info = patternInfo(P, env); if (info) out.push(info);
      }
    }
    parentPort.postMessage(out);
  } else if (t.task === 'census') {   // Brent cycle detection from random cells [i0, i1) with the chunk's own seed
    const dict = new Uint8Array(t.dict), OPTS = { skip: SKIP, V: t.V, coff: 0 }, f = x => decode36(x, dict, OPTS).out, designed = new Map(t.designed);
    const randomCell = randomCellOf(xorshift((0x9e3779b9 ^ t.seed) + 0x632be5ab * (t.chunk + 1)));
    const res = [];
    for (let i = t.i0; i < t.i1; i++) {
      const x0 = randomCell(); let power = 1, lam = 1, tortoise = x0, hare = f(x0), steps = 0;
      while (key(tortoise) !== key(hare)) { if (power === lam) { tortoise = hare; power *= 2; lam = 0; } hare = f(hare); lam++; if (++steps > 2000) break; }
      if (steps > 2000) { res.push(null); continue; }
      let mu = 0; tortoise = x0; hare = x0; for (let k = 0; k < lam; k++) hare = f(hare);
      while (key(tortoise) !== key(hare)) { tortoise = f(tortoise); hare = f(hare); mu++; }
      let c = tortoise, best = key(c), who = null; for (let k = 0; k < lam; k++) { const kk = key(c); if (kk < best) best = kk; if (designed.has(kk)) who = designed.get(kk); c = f(c); }
      res.push({ best, lam, mu, who });
    }
    parentPort.postMessage(res);
  } else if (t.task === 'verify') {   // every state to its successor, every routed code to its route, every pad to the head of state 0
    const dict = new Uint8Array(t.dict), OPTS = { skip: SKIP, V: t.V, coff: 0 }, HB = Math.log2(t.V), out = [];
    for (const ty of t.types) {
      const states = ty.states.map(s => Uint8Array.from(Buffer.from(s, 'latin1')));
      states.forEach((s, k) => { const o = decode36(s, dict, OPTS).out; if (key(o) !== key(states[ty.succ[k]])) throw new Error(`${ty.name} state ${k} does not map to state ${ty.succ[k]}`); });
      for (const [c, k] of ty.routed) { const cell = Uint8Array.from(states[0]); const { cell: hd } = packHead(16 * c, HB, t.form); hd[0] |= ty.b0 & 63; for (let j = 0; j < t.HEAD_BYTES - 1; j++) cell[j] = hd[j]; cell[t.HEAD_BYTES - 1] = (cell[t.HEAD_BYTES - 1] & ~t.pm) | (hd[t.HEAD_BYTES - 1] & t.pm); const o = decode36(cell, dict, OPTS).out; if (key(o) !== key(states[k])) throw new Error(`${ty.name} code ${c} does not route to state ${k}`); }
      out.push(ty.rots.map(cell => { const o = decode36(Uint8Array.from(cell), dict, OPTS).out; if (key(o.subarray(0, t.HEAD_BYTES)) !== key(states[0].subarray(0, t.HEAD_BYTES))) throw new Error(`pad of ${ty.name} (${JSON.stringify(ty.pattern)}) does not land: got ${JSON.stringify(key(o))}, wanted ${JSON.stringify(key(states[0]))}, cell ${JSON.stringify(key(Uint8Array.from(cell)))}`); const two = decode36(o, dict, OPTS).out; return key(two) === key(states[1 % states.length]) ? 'head of state 0, then state 1' : 'head of state 0'; }));
    }
    parentPort.postMessage(out);
  }
} else {
  const opt = Object.fromEntries(process.argv.slice(2).filter(a => a.includes('=')).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
  const SIZES = (() => { const s = opt.sizes || '8-24'; if (/^\d+-\d+$/.test(s)) { const [a, b] = s.split('-').map(Number); return Array.from({ length: b - a + 1 }, (_, i) => a + i); } return s.split(',').map(Number); })();
  const OUT = opt.out || `${dir}/src/changers/dict`, SEED = Number(opt.seed ?? 1), NCENSUS = Number(opt.census ?? 16384), PERIODS = Number(opt.periods ?? 4);
  const WORKERS = Math.max(1, Number(opt.workers ?? Math.min(24, os.cpus().length - 4)));
  const DATA = `${dir}/paper/data/design`; fs.mkdirSync(DATA, { recursive: true });
  const runTasks = tasks => Promise.all(tasks.map(wd => new Promise((res, rej) => { const w = new Worker(new URL(import.meta.url), { workerData: wd }); w.once('message', m => { res(m); w.terminate(); }); w.once('error', rej); })));
  const chunks = (n, k) => { k = Math.max(1, Math.min(k, n)); const out = []; for (let i = 0; i < k; i++) out.push([Math.floor(i * n / k), Math.floor((i + 1) * n / k)]); return out; };
  if (process.argv.includes('merge')) {
    const mp = `${dir}/src/changers/dict/manifest.json`, man = JSON.parse(fs.readFileSync(mp, 'utf8'));
    for (const f of fs.readdirSync(DATA).filter(f => /^ca-size-\d\d\.entry\.json$/.test(f)).sort()) { const e = JSON.parse(fs.readFileSync(`${DATA}/${f}`, 'utf8')); const i = man.findIndex(x => x.id === e.id); if (i >= 0) man[i] = e; else man.push(e); }
    fs.writeFileSync(mp, JSON.stringify(man, null, 1) + '\n'); console.error(`manifest: ${man.filter(e => /^ca-size-/.test(e.id)).length} ca-size entries`);
    process.exit(0);
  }
  for (const n of SIZES) await design(n);

  async function design(n) {
    const t0 = Date.now(), times = {}, lap = what => { times[what] = +((Date.now() - t0) / 1000).toFixed(1); };
    const V = 2 ** n, TL = V, HB = n, NAME = `ca-size-${String(n).padStart(2, '0')}`;
    const CODES = V >> 4, SPOTS = CODES >> 3, GROUP_DIMS = HB >= 12 ? [6, 7] : HB === 11 ? [6] : [];   // code bits that group spots
    const groupSize = 1 << GROUP_DIMS.length;
    const codeOfLocal = (base, l) => { let c = base | (l & 7); for (let j = 0; j < GROUP_DIMS.length; j++) if ((l >> (3 + j)) & 1) c |= 1 << GROUP_DIMS[j]; return c; };   // local index: Gray bits, then group bits
    const groupMask = GROUP_DIMS.reduce((m, b) => m | (1 << b), 0);
    const rnd = (() => { const r = xorshift(SEED * 2654435761 + 7 + 1000003 * n); return () => r() / 4294967296; })();
    const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
    const spread = (list, m) => m >= list.length ? list.slice() : Array.from({ length: m }, (_, i) => list[Math.floor((i + 0.5) * list.length / m)]);
    // ---- the form: the one with the most safe groups (spots below 12 bits), then the shortest head
    let form = null;
    for (const f of FORMS) {
      const { cell: base, end } = packHead(0, HB, f), HEAD_BYTES = Math.ceil(end / 8);
      if (end > 64) continue;
      let ok = true; for (let i = 4; i < Math.floor(end / 8); i++) if (!safe(base[i])) ok = false;   // bytes fully inside the head past the header: fixed by the form alone
      const pm = end & 7 ? (1 << (end & 7)) - 1 : 0, pf = pm ? base[end >> 3] & pm : 0;   // the partial last byte: its low bits are command bits, a tail byte must complete it
      if (pm && (end >> 3) >= 4 && !PAL.some(v => (v & pm) === pf)) ok = false;
      if (!ok) continue;
      // a spot is safe when its eight heads are; letter-free when no head byte past byte 0 is a letter (then every pattern can land on it, whatever case transforms its commands carry)
      const headClass = h => { const w = (h << 6) >>> 0; let letters = 0; for (let i = 0; i < 4 && i < HEAD_BYTES; i++) { const v = (base[i] | ((w >>> (8 * i)) & 255) | (i === 0 ? 0x20 : 0)) & 255; if (i < Math.floor(end / 8)) { if (!safe(v)) return 0; if (isLetter(v)) letters++; } else { const cls = PAL.filter(t => (t & pm) === pf && (t & ~pm) === (v & ~pm)); if (!cls.length) return 0; if (cls.every(isLetter)) letters++; } } for (let i = 4; i < Math.floor(end / 8); i++) if (isLetter(base[i])) letters++; return letters ? 1 : 2; };
      const spotClass = k => { let c = 2; for (let g = 0; g < 8; g++) { const x = headClass(128 * k + 16 * g); if (!x) return 0; c = Math.min(c, x); } return c; };
      const spotSafe = new Uint8Array(SPOTS); let nSpots = 0, nFree = 0; for (let k = 1; k < SPOTS; k++) { spotSafe[k] = spotClass(k); if (spotSafe[k]) nSpots++; if (spotSafe[k] === 2) nFree++; }   // spot 0 is skipped: the slot of h = 0 wraps onto the file's last bytes; 2 = letter-free, 1 = safe with letters
      let nGroups = 0, nGroupsFree = 0; if (GROUP_DIMS.length) for (let k = 1; k < SPOTS; k++) { const c = 8 * k; if (c & groupMask) continue; let all = 2; for (let l = 0; l < groupSize && all; l++) all = Math.min(all, spotSafe[codeOfLocal(c, l << 3) >> 3]); if (all) nGroups++; if (all === 2) nGroupsFree++; }
      const score = GROUP_DIMS.length ? nGroups + nGroupsFree : nSpots + nFree;   // letter-free counted twice
      if (!form || score > form.score || (score === form.score && end < form.end)) form = { ...f, score, end, HEAD_BYTES, base, pm, pf, spotSafe, nSpots, nFree, nGroups, nGroupsFree };
    }
    if (!form) throw new Error(`${NAME}: no head form`);
    const { end: HEAD_END, HEAD_BYTES, spotSafe, pm } = form, D = form.d, FORM = { lens: form.lens, d: D, first: form.first, ring: form.ring, tfs: form.tfs };
    const head = (h, b0) => { const { cell } = packHead(h, HB, FORM); cell[0] |= b0 & 63; return cell.subarray(0, HEAD_BYTES); };   // the bytes the head fixes (the last one partially, in its low pm bits)
    lap('form');
    console.error(`${NAME}: V ${V}, ${HB} header bits; form copy ${form.lens.join(' + ')} at d ${D} (${form.first} first distance, ${form.ring ? 'ring' : 'explicit'} after), tf ${form.tfs.join('/')}: head ${HEAD_END} bits (${HEAD_BYTES} bytes); ${form.nSpots} of ${SPOTS - 1} spots safe (${form.nFree} letter-free), ${form.nGroups} groups (${form.nGroupsFree} letter-free) (${times.form} s)`);
    // ---- the patterns, in parallel by first byte; one per distinct pad, the shortest reading
    const found = (await runTasks(chunks(PAT.length, WORKERS).map(([a0, a1]) => ({ task: 'patterns', HB, HEAD_BYTES, periods: PERIODS, a0, a1 })))).flat();   // (the control-byte alphabet is the first 29 of PAT, so its chunks are the first ones)
    const byPad = new Map(); for (const c of found) { const o = byPad.get(c.padKey); if (!o || c.reading < o.reading || (c.reading === o.reading && (c.P.length < o.P.length || (c.P.length === o.P.length && key(c.P) < key(o.P))))) byPad.set(c.padKey, c); }
    const cands = [...byPad.values()].sort((a, b) => a.reading - b.reading || a.P.length - b.P.length || (key(a.P) < key(b.P) ? -1 : 1));
    lap('patterns');
    console.error(`${NAME}: ${found.length} patterns of periods 1..${PERIODS} land in every rotation, ${cands.length} distinct pads, readings ${cands.length ? Math.min(...cands.map(c => c.reading)) + '..' + Math.max(...cands.map(c => c.reading)) : '-'} bits (${times.patterns} s, ${WORKERS} workers)`);
    // ---- the schedule
    const spotsAll = []; for (let k = 1; k < SPOTS; k++) if (spotSafe[k]) spotsAll.push(k);
    const groupsAll = [], groupClass = new Map(); if (GROUP_DIMS.length) for (let k = 1; k < SPOTS; k++) { const c = 8 * k; if (c & groupMask) continue; let all = 2; for (let l = 0; l < groupSize && all; l++) all = Math.min(all, spotSafe[codeOfLocal(c, l << 3) >> 3]); if (all) { groupsAll.push(c); groupClass.set(c, all); } }
    let gG, gC, nF, nGsingle = 0;
    const budget = u => Math.max(1, Math.floor(u / 2));   // half the safe groups (spots below 12 bits): blocks cover at most a quarter of the dictionary
    if (GROUP_DIMS.length === 2) { const B = budget(groupsAll.length); gG = Math.max(1, Math.round(B / 5)); gC = Math.max(0, B - gG); nF = Math.min(6, Math.max(1, Math.floor(B / 4))); }
    else if (GROUP_DIMS.length === 1) { const B = budget(spotsAll.length); nF = B >= 2 ? 1 : 0; gG = Math.min(groupsAll.length, Math.max(1, Math.floor((B - nF) / 2))); gC = 0; nGsingle = Math.max(0, B - nF - 2 * gG); }
    else { const B = budget(spotsAll.length); nF = B >= 2 ? 1 : 0; gG = 0; gC = 0; nGsingle = Math.max(1, B - nF); }
    const scheduled = { gray: gG * groupSize + nGsingle, chase: gC, fixed: nF };
    // placement. A pattern of period L has L rotations, each with its own pad, so it can feed up to L types (its region
    // is tiled with the one pattern, a random cell lands in a random phase, and the pad of that phase holds the head of
    // the type it serves); a type takes one rotation (a slot), and the rotations of a pattern that no type took point
    // at the first type the pattern serves. Pads first (they are tiny and their positions are fixed by the patterns):
    // position-disjoint patterns by reading length, then the blocks in groups and spots whose bytes hold none of the
    // pads (letter-free groups and spots first, in a seeded shuffle), then each type takes the shortest unused slot whose
    // case transforms touch no letter of its head (the types with the most letters choose first; the fixed points take
    // the shortest, the longest and evenly spaced readings). A type that finds no slot is dropped (a chasing type on
    // its own, a Gray type with its whole group). For the small sizes, where a few pads can block every spot, the
    // blocks come first and the patterns outside them after. Several pad budgets and shuffles are tried and the
    // placement that keeps the most types wins; the trial seeds follow the size's stream, so the result is deterministic.
    const groupSpots = c => Array.from({ length: groupSize }, (_, l) => codeOfLocal(c, l << 3) >> 3);
    const groupOf = t => (8 * t.block) & ~groupMask & ~7;
    const spotRange = k => [128 * k - D, 128 * k - D + 128];
    const partialClass = low => { const cls = PAL.filter(v => (v & pm) === low), nl = cls.filter(v => !isLetter(v)); return nl.length ? nl : cls; };   // the head's partial last byte: safe values with its low bits, letters avoided
    const headLetters = code => { const hd = head(16 * code, 0x20), out = new Set(); for (let j = 1; j < HEAD_BYTES; j++) { const letter = j === HEAD_BYTES - 1 && pm ? partialClass(hd[j] & pm).every(isLetter) : isLetter(hd[j]); if (letter) out.add(j); } return out; };   // the Gray and group bits sit below bit 5, so every state of a type agrees on where its head has letters
    const compatible = (slot, t) => slot.lowers.every(j => !t.letters.has(j));   // a rotation whose commands lowercase a pad byte cannot carry a letter there
    const want = scheduled.gray + scheduled.chase + scheduled.fixed;
    const shuffler = seed => { const r = xorshift(seed); return a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(r() / 4294967296 * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }; };
    const disjoint = (pool, cap, padUsed) => { const out = []; for (const c of pool) { if (out.length >= cap) break; if (c.pads.some(([p]) => padUsed[p])) continue; c.pads.forEach(([p]) => { padUsed[p] = 1; }); out.push(c); } return out; };
    const blocksFor = (sh, groupsOk, spotsOk) => {   // the scheduled blocks among the groups and spots allowed, letter-free first
      const groupsSh = [...sh(groupsOk.filter(c => groupClass.get(c) === 2)), ...sh(groupsOk.filter(c => groupClass.get(c) === 1))], inGroup = new Set();
      const grayGroups = groupsSh.slice(0, Math.min(gG, groupsSh.length)), chaseGroups = groupsSh.slice(grayGroups.length, grayGroups.length + Math.min(gC, groupsSh.length - grayGroups.length));
      for (const c of [...grayGroups, ...chaseGroups]) for (const k of groupSpots(c)) inGroup.add(k);
      const rest = spotsOk.filter(k => !inGroup.has(k)), spotsSh = [...sh(rest.filter(k => spotSafe[k] === 2)), ...sh(rest.filter(k => spotSafe[k] === 1))];
      const fixedSpots = spotsSh.slice(0, Math.min(nF, spotsSh.length)), graySingles = spotsSh.slice(fixedSpots.length, fixedSpots.length + Math.min(nGsingle, spotsSh.length - fixedSpots.length));
      const types = [], mk = (kind, block) => types.push({ kind, block, letters: headLetters(kind === 'chase' ? codeOfLocal(block, 0) : 8 * block) });
      for (const c of grayGroups) for (const k of groupSpots(c)) mk('gray', k);
      for (const k of graySingles) mk('gray', k);
      for (const c of chaseGroups) mk('chase', c);
      for (const k of fixedSpots) mk('fixed', k);
      return { types, grayGroups };
    };
    const assign = (types, pats) => {   // one slot (pattern, rotation) per type; a rotation no type took points at a compatible type (the pattern's own first, else any); a pattern with a rotation that no type can take is left out
      pats = pats.slice();
      for (;;) {
        const slots = pats.flatMap(c => c.rots.map((r, i) => ({ c, i, reading: r.consumed, lowers: r.lowers }))).sort((x, y) => x.reading - y.reading || x.c.P.length - y.c.P.length || x.i - y.i);
        const used = new Set(), take = (t, pool) => { for (const sl of pool) { if (used.has(sl) || !compatible(sl, t)) continue; used.add(sl); t.slot = sl; return true; } return false; };
        for (const t of types) delete t.slot;
        const fixedTypes = types.filter(t => t.kind === 'fixed');
        fixedTypes.forEach((t, i) => { const pool = slots.filter(sl => compatible(sl, t) && !used.has(sl)); if (pool.length) take(t, [pool[Math.floor((i + 0.5) * pool.length / fixedTypes.length)]]); });
        for (const t of types.filter(t => t.kind !== 'fixed').sort((x, y) => y.letters.size - x.letters.size || (x.kind === 'chase') - (y.kind === 'chase'))) take(t, slots);
        const placed = types.filter(t => t.slot), bad = new Set();
        for (const c of new Set(placed.map(t => t.slot.c))) {
          const own = placed.filter(t => t.slot.c === c);
          c.targets = c.rots.map((r, i) => own.find(t => t.slot.i === i) ?? own.find(t => compatible(r, t)) ?? placed.find(t => compatible(r, t)) ?? null);
          if (c.targets.some(t => !t)) bad.add(c);
        }
        if (!bad.size) return types;
        pats = pats.filter(c => !bad.has(c));
      }
    };
    const prune = (types, grayGroups) => { const lostGroups = new Set(types.filter(t => !t.slot && t.kind === 'gray' && grayGroups.includes(groupOf(t))).map(groupOf)); return types.filter(t => t.slot && !(t.kind === 'gray' && lostGroups.has(groupOf(t)))); };
    const settle = (types, pats, grayGroups) => { for (;;) { const kept = prune(assign(types, pats), grayGroups); if (kept.length === types.length) return kept; types = kept; } };   // the rotations' targets must be among the types kept
    const freeRange = (padUsed, [a, b]) => { for (let p = a; p < b; p++) if (padUsed[p]) return false; return true; };
    const padsFirst = (trial, padCap) => {
      const padUsed = new Uint8Array(TL), pats = disjoint(cands, padCap, padUsed);
      const { types, grayGroups } = blocksFor(shuffler(SEED * 2654435761 + 7 + 1000003 * n + 7919 * (trial + 1)), groupsAll.filter(c => groupSpots(c).every(k => freeRange(padUsed, spotRange(k)))), spotsAll.filter(k => freeRange(padUsed, spotRange(k))));
      const out = settle(types, pats, grayGroups);
      if (process.env.DEBUG) console.error(`pads first, trial ${trial}, cap ${padCap}: ${pats.length} patterns, ${types.length} types scheduled, ${out.length} placed`);
      return out;
    };
    const blocksFirst = trial => {
      let { types, grayGroups } = blocksFor(shuffler(SEED * 2654435761 + 11 + 1000003 * n + 7919 * (trial + 1)), groupsAll, spotsAll);
      for (;;) {
        const inBlock = new Uint8Array(TL); for (const t of types) for (const k of (t.kind === 'chase' ? groupSpots(t.block) : [t.block])) inBlock.fill(1, ...spotRange(k));
        const pats = disjoint(cands.filter(c => !c.pads.some(([p]) => inBlock[p])), Infinity, new Uint8Array(TL));
        assign(types, pats);
        if (process.env.DEBUG) console.error(`blocks first, trial ${trial}: ${pats.length} disjoint patterns outside ${types.length} blocks, without a slot ${types.filter(t => !t.slot).length}`);
        if (types.every(t => t.slot)) return settle(types, pats, grayGroups);
        const nChase = types.filter(t => t.kind === 'chase').length; if (nChase) { let drop = Math.ceil(nChase / 8); types = types.filter(t => t.kind !== 'chase' || drop-- <= 0); continue; }   // an eighth of the chasing types at a time
        const g = types.findIndex(t => t.kind === 'gray' && grayGroups.includes(groupOf(t))); if (g >= 0) { const c = groupOf(types[g]); types = types.filter(t => !(t.kind === 'gray' && groupOf(t) === c)); grayGroups = grayGroups.filter(x => x !== c); continue; }   // a whole Gray group: its closure is the group's
        if (types.length > 1) { types.pop(); continue; }
        return [];
      }
    };
    let types = [], best = null;   // the pattern objects are shared between trials, so the winning trial's rotation targets are kept in a snapshot
    const snap = r => ({ types: r, targets: new Map([...new Set(r.map(t => t.slot.c))].map(c => [c, c.targets])) });
    const better = r => r.length > types.length || (r.length === types.length && r.filter(t => t.kind === 'chase').length > types.filter(t => t.kind === 'chase').length);
    for (const padCap of [Math.ceil(want / 4), Math.ceil(want / 2), want, 2 * want, Infinity]) for (let trial = 0; trial < 8 && types.length < want; trial++) { const r = padsFirst(trial, padCap); if (better(r)) { types = r; best = snap(r); } }
    for (let trial = 0; trial < 16 && types.length < want; trial++) { const r = blocksFirst(trial); if (better(r)) { types = r; best = snap(r); } }
    if (!types.length) throw new Error(`${NAME}: no type fits: no pattern lands outside the one block`);
    for (const [c, tg] of best.targets) c.targets = tg;
    // the patterns in use, the type each rotation serves
    const patsUsed = [...new Set(types.map(t => t.slot.c))];
    for (const c of patsUsed) { if (c.targets.some(t => !types.includes(t))) throw new Error(`${NAME}: a rotation of ${JSON.stringify(key(Uint8Array.from(c.P)))} points at a dropped type`); c.served = new Set(c.targets).size; }
    // ---- states: the head (its partial last byte completed with a safe value), then a tail of type colours (the chasing phases in three colours)
    const b0Of = i => 0x20 + (i % 32);
    const stateBytes = (c, i, phase, kind) => {
      const s = new Uint8Array(16); s.set(head(16 * c, b0Of(i)));
      if (pm) { const cls = partialClass(s[HEAD_BYTES - 1] & pm); s[HEAD_BYTES - 1] = cls[(7 * i + phase) % cls.length]; }
      for (let j = HEAD_BYTES; j < 16; j++) s[j] = kind === 'chase' ? PAL[(7 * i + 23 * phase + j) % PAL.length] : PAL[(7 * i + (j >> 2)) % PAL.length];
      return s;
    };
    const altLast = v => PAL.find(u => u !== v && POP[u ^ v] === 1) ?? PAL.find(u => u !== v);
    types.forEach((t, i) => {
      t.index = i; t.name = `T${i}`; t.pat = t.slot.c; t.rot = t.slot.i; t.pattern = key(Uint8Array.from(t.pat.P)); t.reading = t.slot.reading; t.b0 = b0Of(i);
      if (t.kind === 'gray') {
        t.H0 = 128 * t.block; t.codes = Array.from({ length: 8 }, (_, k) => 8 * t.block + grayOf(k));
        const alt = altLast(stateBytes(t.codes[0], i, 0, 'gray')[15]);
        t.states = t.codes.map((c, k) => { const s = stateBytes(c, i, 0, 'gray'); if (POP[grayOf(k)] & 1) s[15] = alt; return s; });   // the last tail byte flips with the Gray code's parity
        t.succ = t.codes.map((c, k) => (k + 1) % 8); t.routed = [];
      } else if (t.kind === 'fixed') {
        t.H0 = 128 * t.block; t.codes = [8 * t.block]; t.states = [stateBytes(t.codes[0], i, 0, 'fixed')]; t.succ = [0];
        t.routed = Array.from({ length: 7 }, (_, g) => [8 * t.block + g + 1, 0]);   // the other seven codes of the spot -> the state
      } else {
        const base = t.block, locals = [0b00000, 0b00111, 0b11011];
        t.H0 = 16 * base; t.codes = locals.map(l => codeOfLocal(base, l));
        t.states = t.codes.map((c, k) => stateBytes(c, i, k, 'chase')); t.succ = [1, 2, 0];
        const localOf = new Map(locals.map((l, k) => [l, k])); t.routed = [];   // the other 29 codes of the cube, by expected parentage with the lead rule
        for (let x = 0; x < 32; x++) {
          if (localOf.has(x)) continue;
          const mass = new Map(); let tot = 0;
          for (let a = 0; a < 3; a++) for (let b = 0; b < 3; b++) { if (a === b) continue; const la = locals[a], lb = locals[b], d = la ^ lb; if ((x ^ la) & ~d & 31) continue; const kb = POP[x ^ la], p = R ** kb * (1 - R) ** (POP[d] - kb) / 6; const win = (b - a + 3) % 3 === 1 ? b : a; mass.set(win, (mass.get(win) || 0) + p); tot += p; }   // the phase one step ahead leads
          let k = 0; if (tot) { let z = rnd() * tot; for (const [w, v] of mass) { k = w; z -= v; if (z < 0) break; } }
          t.routed.push([codeOfLocal(base, x), (k + 1) % 3]);   // the child joins the next state of the leading phase
        }
      }
    });
    const designed = []; for (const t of types) t.states.forEach(s => designed.push([key(s), t.index]));
    // ---- the dictionary (a shared buffer: the workers read it without a copy)
    const sab = new SharedArrayBuffer(TL), dict = new Uint8Array(sab), isFixed = new Uint8Array(TL);
    const slot = c => { let p = 16 * c - D; if (p < 0) p += TL; return p; };
    const write = (p, bytes, what) => { for (let i = 0; i < bytes.length; i++) { if (isFixed[p + i] && dict[p + i] !== bytes[i]) throw new Error(`${NAME}: ${what} collides at ${p + i}`); dict[p + i] = bytes[i]; isFixed[p + i] = 1; } };
    for (const t of types) { t.codes.forEach((c, k) => write(slot(c), t.states[t.succ[k]], `${t.name} state ${k}`)); for (const [c, k] of t.routed) write(slot(c), t.states[k], `${t.name} route ${c}`); }
    dict[TL - 1] = 10; isFixed[TL - 1] = 1;
    for (const c of patsUsed) c.rots.forEach((r, i) => r.pos.forEach((p, j) => write(p, [c.targets[i].states[0][j]], `pad of ${c.targets[i].name}`)));
    // regions: the header range cut among the patterns in use, in the order of their first type, each share proportional to the types the pattern serves
    patsUsed.sort((x, y) => Math.min(...x.targets.map(t => t.index)) - Math.min(...y.targets.map(t => t.index)));
    { const total = patsUsed.reduce((s, c) => s + c.served, 0); let at = 0, acc = 0; for (const c of patsUsed) { acc += c.served; const end = Math.round(V * acc / total); for (let x = at; x < end; x++) if (!isFixed[x]) dict[x] = c.P[(x - at) % c.P.length]; c.region = [at, end]; at = end; } }
    for (const t of types) t.region = t.pat.region;
    lap('build');
    // ---- verify (in parallel by type)
    const vTasks = chunks(types.length, WORKERS).map(([i0, i1]) => ({ task: 'verify', dict: sab, V, form: FORM, HEAD_BYTES, pm, types: types.slice(i0, i1).map(t => ({ name: t.name, pattern: t.pattern, b0: t.b0, states: t.states.map(key), succ: t.succ, routed: t.routed, rots: t.pat.rots.filter((r, i) => t.pat.targets[i] === t).map(r => r.cell) })) }));
    const lands = (await runTasks(vTasks)).flat(); types.forEach((t, i) => { t.lands = lands[i]; });
    lap('verify');
    // ---- census (in parallel by cell range)
    const cells = (await runTasks(chunks(NCENSUS, WORKERS).map(([i0, i1], chunk) => ({ task: 'census', dict: sab, V, designed, seed: SEED, chunk, i0, i1 })))).flat();
    const cycles = new Map(), per = new Map(), trans = []; let unsettled = 0, stray = 0;
    for (const r of cells) { if (!r) { unsettled++; continue; } const rec = cycles.get(r.best) || { len: r.lam, count: 0, type: r.who, example: r.best }; rec.count++; cycles.set(r.best, rec); if (r.who === null) stray++; else per.set(r.who, (per.get(r.who) || 0) + 1); trans.push(r.mu); }
    trans.sort((a, b) => a - b);
    const realised = [...cycles.values()].sort((a, b) => b.count - a.count || (a.example < b.example ? -1 : 1)), reached = new Set(realised.filter(c => c.type !== null).map(c => c.type));
    const census = { N: NCENSUS, cap: 2000, unsettled, stray: stray / NCENSUS, strayAttractors: realised.filter(c => c.type === null).length, attractors: realised.length, designedReached: reached.size,
      transientMean: trans.reduce((a, b) => a + b, 0) / Math.max(1, trans.length), transientP90: trans[Math.floor(0.9 * trans.length)] ?? null, transientMax: trans[trans.length - 1] ?? null,
      basins: types.map(t => (per.get(t.index) || 0) / NCENSUS), top: realised.slice(0, 40).map(c => ({ len: c.len, basin: c.count / NCENSUS, type: c.type, example: JSON.stringify(c.example) })) };
    lap('census');
    // ---- write
    fs.mkdirSync(OUT, { recursive: true });
    fs.writeFileSync(`${OUT}/${NAME}.txt`, Buffer.from(dict));
    const counts = { gray: types.filter(t => t.kind === 'gray').length, chase: types.filter(t => t.kind === 'chase').length, fixed: types.filter(t => t.kind === 'fixed').length };
    const info = { name: NAME, log2: n, V, len: TL, headerBits: HB, d: D, form: { ...FORM, headBits: HEAD_END, headBytes: HEAD_BYTES },
      spots: { all: SPOTS - 1, safe: form.nSpots, letterFree: form.nFree, groups: groupsAll.length, groupsLetterFree: form.nGroupsFree }, patterns: { landingAll: found.length, distinctPads: cands.length, periods: PERIODS }, scheduled, types: counts, nTypes: types.length,
      schedule: GROUP_DIMS.length === 2 ? `B = floor(${groupsAll.length} / 2) = ${budget(groupsAll.length)} groups: ${gG} Gray groups, ${gC} chasing, ${nF} fixed` : `B = floor(${spotsAll.length} / 2) = ${budget(spotsAll.length)} spots: ${gG} Gray pairs, ${nGsingle} single Gray, ${nF} fixed`,
      seed: SEED, R, workers: WORKERS, seconds: +((Date.now() - t0) / 1000).toFixed(1), times,
      patternsUsed: patsUsed.length, typeTable: types.map(t => ({ index: t.index, kind: t.kind, H0: t.H0, codes: t.codes, pattern: t.pattern, rotation: t.rot, sharedWith: t.pat.served - 1, reading: t.reading, region: t.region, states: t.states.map(key), lands: t.lands, routed: t.routed.length })),
      census, provenance: provenance(import.meta.url, { n, SEED, NCENSUS, WORKERS, PERIODS }) };
    fs.writeFileSync(`${DATA}/${NAME}.json`, JSON.stringify(info));
    const pct = v => (100 * v).toFixed(1);
    const md = [`# Designed dictionary ${NAME}\n`, `${types.length} types (${counts.gray} Gray 8-cycles, ${counts.chase} chasing 3-cycles, ${counts.fixed} fixed points) at V = ${V} (${HB} header bits), ${TL} bytes. Head: copy ${form.lens.join(' + ')} at d ${D}, ${HEAD_END} bits. Spots: ${form.nSpots} of ${SPOTS - 1} safe, ${groupsAll.length} groups. Patterns: ${found.length} land in every rotation, ${cands.length} distinct pads, ${patsUsed.length} in use. Schedule: ${info.schedule}; scheduled ${JSON.stringify(scheduled)}, built ${JSON.stringify(counts)}. ${info.seconds} s with ${WORKERS} workers (${JSON.stringify(times)}).\n`,
      `## Census (${NCENSUS} random cells, cap 2000)\n`, `Attractors realised ${census.attractors} (${census.designedReached} designed types reached, ${census.strayAttractors} stray attractors with ${pct(census.stray)} % of the cells, ${unsettled} unsettled). Transient mean ${census.transientMean.toFixed(1)}, p90 ${census.transientP90}, max ${census.transientMax}.\n`,
      '| type | kind | pattern (rotation) | reading | basin |', '|---|---|---|---|---|', ...types.slice(0, 40).map(t => `| ${t.name} | ${t.kind} | \`${JSON.stringify(t.pattern).slice(1, -1).replace(/\|/g, '\\|')}\` (${t.rot}) | ${t.reading} | ${pct(census.basins[t.index])} % |`), types.length > 40 ? `| ... ${types.length - 40} more | | | | |` : ''];
    fs.writeFileSync(`${DATA}/${NAME}.md`, md.join('\n') + '\n');
    console.error(`${NAME}: ${types.length} types (${counts.gray} Gray, ${counts.chase} chasing, ${counts.fixed} fixed; scheduled ${scheduled.gray}/${scheduled.chase}/${scheduled.fixed}); census: ${census.attractors} attractors, ${census.designedReached} designed reached, stray ${pct(census.stray)} %, transient ${census.transientMean.toFixed(1)} (p90 ${census.transientP90}); ${info.seconds} s ${JSON.stringify(times)}`);
    // ---- the manifest entry (merged into manifest.json by `merge`, so parallel sizes do not race on the file)
    const entry = { id: NAME, file: `${NAME}.txt`, title: `Designed at 2^${n} bytes`, titleLatin: `Designed at 2^${n} bytes (${TL.toLocaleString('en-US')} bytes; ${types.length} types: ${counts.gray} Gray 8-cycles, ${counts.chase} chasing 3-cycles, ${counts.fixed} fixed points)`,
      author: `paper/experiments/design-scale.mjs sizes=${n}`, language: 'none', script: 'Latin', year: '2026', source: '',
      note: `One construction for every size (paper/experiments/design-scale.mjs, paper/results/dictionary-size.md): quine heads copying 16-byte slots, Gray 8-cycles in mutually closed groups of four, phase-chasing 3-cycles, fixed points, and a filler pattern with a landing pad per type. ${HB} header bits, window range ${V}. Not a text.`,
      cread: V, license: 'CC BY 4.0, Jyrki Alakuijala (generated by the project\'s tools)' };
    if (TL >= URL_FROM) { entry.url = `src/changers/dict/${NAME}.txt`; entry.bytes = TL; }
    fs.writeFileSync(`${DATA}/${NAME}.entry.json`, JSON.stringify(entry, null, 1) + '\n');
  }
}
