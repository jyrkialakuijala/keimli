// Replicase ablation: which ingredients does a rewriting rule need for heritable, non-trivial replication to arise from
// random cells, and what does it cost in entropy? The rules are constructed (von Neumann's constructor + description):
// a cell's 128 bits are [control: bytes 0..3 | tape: bytes 4..15]. A cell is a "replicator" when the low m bits of its
// control word equal a fixed motif (a random cell matches with probability p = 2^-m). Each turn the write direction is
// d = turn mod 4 (right, down, left, up), so every cell has exactly one possible writer and the update is synchronous.
// Independent switches:
//   copy    none | template | derived | verbatim (template: the child is the canonical replicator, the motif with free
//           control bits zero and the tape derived from the motif: no heredity at all, Langton's crystal growth); a replicator writes into its neighbour, with probability q, a tape that is either
//           derived from its control word (a fixed hash: the tape carries no information of its own, heredity at most
//           through the 32 - m free control bits) or its own tape verbatim (96 unread bits: unlimited heredity)
//   self    0 | 1: the copy includes the control word (true self-replication: the child is a replicator) or only the tape
//   trait   0 | 1: q = (1 + popcount(tape byte 0)) / 9 (the tape sets its own copy rate: heritable selectable variation),
//           or q = 5/9 for every replicator (the trait's mean over random tapes: inert tape)
//   erase   id | r90 | dec: the background map for non-replicating cells: the identity, elementary rule 90 on the
//           128-bit ring (loses exactly 2 bits a turn, every cell zero after 64 turns), or one step of the Brotli-like
//           decoder (kind 36, Swarm F, via the wasm changer; loses ~110 bits in its first step)
//   protect 1 | 0: replicators are exempt from the background map (default) or not
//   med     off | weak | strong: the lattice's mixing and settling (the page's rotating swap order) before the rewrite:
//           mild swap 0.002 / median 0.01 (below the replicators' error threshold), weak swap 0.05 / median 0.1, strong
//           swap 1/2 / median 1 (the uniform setting of entropy-manipulators.md), or p<swap>s<median>
//   mu      bit flips per cell per turn (one random bit, with probability mu), after the rewrite
// Lineages are tracked in side arrays the rule updates: a cell that becomes a replicator without being copied into
// founds a new lineage; a copy inherits its writer's lineage; the background map changing a cell clears it. At turn
// tinj 48 marked point mutations are injected into replicators' tapes: 16 neutral (a bit of tape bytes 1..11), 16 "up"
// (a 0 bit of the trait byte set to 1) and 16 "down" (a 1 bit cleared); their copied descendants are counted, and a
// descendant "carries" the mutation when its content still has the mutated bit value (heredity = carriers/descendants).
// Randomness is counter-based (a hash of seed, turn, cell), so twin runs (twin=1: the same run without the injection)
// see identical draws, and "novel cells" (cells whose content occurs nowhere in the twin lattice) measure the
// mutations' footprint in the same way as for the plain decoder (mode=decoder).
// Usage:
//   node paper/experiments/replicase.mjs mode=run copy=verbatim self=1 trait=1 erase=r90 med=off mu=0.001 m=16 seed=1 [n=128] [turns=2000] [twin=0]
//   node paper/experiments/replicase.mjs mode=grid [set=main|m|protect|all] [seeds=5] [jobs=10]   (runs the factorial in parallel)
//   node paper/experiments/replicase.mjs mode=decoder [n=128] [seeds=5]                          (the plain decoder's mutant fate)
//   node paper/experiments/replicase.mjs mode=summary                                           (tables to stdout and summary.json)
import fs from 'node:fs';
import { spawn } from 'node:child_process';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { decode36 } from './decode36.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const outDir = opt.out || dir + '/paper/data/replicase';
const MEDN = { off: { pm: 0, ps: 0 }, mild: { pm: 0.002, ps: 0.01 }, weak: { pm: 0.05, ps: 0.1 }, strong: { pm: 0.5, ps: 1 } };
const medOf = s => { if (MEDN[s]) return MEDN[s]; const m = /^p([\d.]+)s([\d.]+)$/.exec(s); if (!m) throw new Error('med: ' + s); return { pm: Number(m[1]), ps: Number(m[2]) }; };   // a named level or p<swap>s<median>
const MOTIF = 0xB5E3A71C;
const POP8 = new Uint8Array(256); for (let i = 0; i < 256; i++) POP8[i] = (i & 1) + POP8[i >> 1];
const pop32 = x => POP8[x & 255] + POP8[(x >>> 8) & 255] + POP8[(x >>> 16) & 255] + POP8[x >>> 24];
function mix32(h) { h ^= h >>> 16; h = Math.imul(h, 0x85EBCA6B); h ^= h >>> 13; h = Math.imul(h, 0xC2B2AE35); h ^= h >>> 16; return h >>> 0; }
const rnd = (seed, t, i, k) => mix32(mix32(mix32(seed * 0x9E3779B1 + k) ^ t) + Math.imul(i, 0x27D4EB2F)) ;   // counter-based: identical in twin runs
const dictText = id => { const p = `${dir}/paper/data/design/${id}.txt`; return fs.existsSync(p) ? fs.readFileSync(p, 'latin1') : asText(loadDict(id).bytes); };
// collision entropy (bits) and distinct cells of a lattice given as a Uint32Array of 4N words
function entropy(u, N) {
  const cnt = new Map(); for (let i = 0; i < N; i++) { const k = u[4 * i] + ',' + u[4 * i + 1] + ',' + u[4 * i + 2] + ',' + u[4 * i + 3]; cnt.set(k, (cnt.get(k) || 0) + 1); }
  let pairs = 0; for (const c of cnt.values()) pairs += c * (c - 1) / 2;
  return { h2: pairs ? -Math.log2(pairs / (N * (N - 1) / 2)) : null, distinct: cnt.size, keys: cnt };
}
// ---- one run of the constructed rule ---------------------------------------------------------------------------------
async function makeRun(c, inject) {
  const n = c.n, N = n * n, med = medOf(c.med), m = c.m, MASK = m >= 32 ? 0xFFFFFFFF : ((1 << m) - 1) >>> 0, MOT = (MOTIF & MASK) >>> 0;
  const isRep = w => ((w ^ MOT) & MASK) === 0;
  let engine = null;
  if (c.erase === 'dec') { engine = await makeSim({ W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread: 4096, coff: 0, pairMode: 0, passes: 0, mixOn: false, settleOn: false, swap: [0, 0], smooth: [0, 0] }); engine.setDict(dictText('ca-swarm-f')); engine.reset(1); }
  const snap = new Uint32Array(4 * N), rep = new Uint8Array(N), written = new Uint8Array(N), bgch = new Uint8Array(N);
  let lin = new Uint32Array(N), lin2 = new Uint32Array(N), mark = new Uint16Array(N), mark2 = new Uint16Array(N), mcopy = new Uint8Array(N), mcopy2 = new Uint8Array(N);
  const founders = []; let nextId = 1, t = 0, copyBits = 0, bgBits = 0, copies = 0;
  const S = { lin: () => lin, mark: () => mark, mcopy: () => mcopy, founders, copyBits: () => copyBits, bgBits: () => bgBits, copies: () => copies, isRep, N };
  const DX = [1, 0, -1, 0], DY = [0, 1, 0, -1];
  function derive(w, o, j) { const h1 = mix32(w ^ 0x9E3779B9), h2 = mix32(h1 + 0x85EBCA6B), h3 = mix32(h2 + 0xC2B2AE35); o[4 * j + 1] = h1; o[4 * j + 2] = h2; o[4 * j + 3] = h3; }
  function rewrite(g) {
    const u = new Uint32Array(g.buffer, g.byteOffset, 4 * N);
    snap.set(u);
    for (let i = 0; i < N; i++) rep[i] = isRep(snap[4 * i]) ? 1 : 0;
    written.fill(0); bgch.fill(0);
    // the background map
    if (c.erase === 'r90') {
      for (let i = 0; i < N; i++) {
        if (rep[i] && c.protect) continue;
        const a = 4 * i, w0 = snap[a], w1 = snap[a + 1], w2 = snap[a + 2], w3 = snap[a + 3];
        // ring bit k = word k>>5, bit k&31; new[k] = old[k-1] ^ old[k+1]
        const l0 = (w0 << 1) | (w3 >>> 31), l1 = (w1 << 1) | (w0 >>> 31), l2 = (w2 << 1) | (w1 >>> 31), l3 = (w3 << 1) | (w2 >>> 31);
        const r0 = (w0 >>> 1) | (w1 << 31), r1 = (w1 >>> 1) | (w2 << 31), r2 = (w2 >>> 1) | (w3 << 31), r3 = (w3 >>> 1) | (w0 << 31);
        u[a] = l0 ^ r0; u[a + 1] = l1 ^ r1; u[a + 2] = l2 ^ r2; u[a + 3] = l3 ^ r3;
      }
    } else if (c.erase === 'dec') {
      const eg = engine.grid(); eg.set(g); engine.step();
      const eu = new Uint32Array(eg.buffer, eg.byteOffset, 4 * N);
      for (let i = 0; i < N; i++) { if (rep[i] && c.protect) continue; const a = 4 * i; u[a] = eu[a]; u[a + 1] = eu[a + 1]; u[a + 2] = eu[a + 2]; u[a + 3] = eu[a + 3]; }
    }
    if (c.erase !== 'id') for (let i = 0; i < N; i++) { const a = 4 * i; const d = pop32(u[a] ^ snap[a]) + pop32(u[a + 1] ^ snap[a + 1]) + pop32(u[a + 2] ^ snap[a + 2]) + pop32(u[a + 3] ^ snap[a + 3]); if (d) { bgch[i] = 1; bgBits += d; } }
    lin2.set(lin); mark2.set(mark); mcopy2.set(mcopy);
    // the copy: every replicator writes towards d with probability q
    if (c.copy !== 'none') {
      const d = t & 3, dx = DX[d], dy = DY[d];
      for (let y = 0; y < n; y++) {
        const ty = y + dy; if (ty < 0 || ty >= n) continue;
        for (let x = 0; x < n; x++) {
          const i = y * n + x; if (!rep[i]) continue;
          const tx = x + dx; if (tx < 0 || tx >= n) continue;
          const j = ty * n + tx, a = 4 * i, b = 4 * j;
          const q = c.trait ? (1 + POP8[snap[a + 1] & 255]) / 9 : 5 / 9;
          if (rnd(c.seed, t, i, 1) / 4294967296 >= q) continue;
          const o0 = u[b], o1 = u[b + 1], o2 = u[b + 2], o3 = u[b + 3];
          if (c.self) u[b] = snap[a];
          if (c.copy === 'verbatim') { u[b + 1] = snap[a + 1]; u[b + 2] = snap[a + 2]; u[b + 3] = snap[a + 3]; } else if (c.copy === 'template') { if (c.self) u[b] = MOT; derive(MOT, u, j); } else derive(snap[a], u, j);
          copyBits += pop32(o0 ^ u[b]) + pop32(o1 ^ u[b + 1]) + pop32(o2 ^ u[b + 2]) + pop32(o3 ^ u[b + 3]); copies++;
          if (!lin[i]) { lin[i] = nextId++; founders.push({ id: lin[i], turn: t, trait: POP8[snap[a + 1] & 255] }); lin2[i] = lin[i]; }   // a replicator present from turn 0
          written[j] = 1; lin2[j] = lin[i]; mark2[j] = mark[i]; mcopy2[j] = mark[i] ? 1 : 0;
        }
      }
    }
    // mutation
    if (c.mu > 0) for (let i = 0; i < N; i++) if (rnd(c.seed, t, i, 2) / 4294967296 < c.mu) { const k = rnd(c.seed, t, i, 3) & 127; u[4 * i + (k >> 5)] ^= 1 << (k & 31); }
    // lineage housekeeping: the background map clears a cell's lineage; a new replicator outside any lineage founds one
    for (let i = 0; i < N; i++) {
      if (!written[i] && bgch[i]) { lin2[i] = 0; mark2[i] = 0; mcopy2[i] = 0; }
      if (!lin2[i] && isRep(u[4 * i])) { lin2[i] = nextId++; founders.push({ id: lin2[i], turn: t, trait: POP8[u[4 * i + 1] & 255] }); }
    }
    [lin, lin2] = [lin2, lin]; [mark, mark2] = [mark2, mark]; [mcopy, mcopy2] = [mcopy2, mcopy];
    t++;
    if (inject && t === c.tinj) inject(u, S);
    return 0;
  }
  const sim = await makeSim({ W: n, H: n, pairMode: 0, passes: 1, nbr: 1, swap: [med.pm, med.pm], smooth: [med.ps, med.ps], mixOn: med.pm > 0, settleOn: med.ps > 0, altOrder: 'rotate', rewrite });
  sim.reset(c.seed);
  return { sim, S, u: () => { const g = sim.grid(); return new Uint32Array(g.buffer, g.byteOffset, 4 * N); } };
}
async function runOne(c) {
  const N = c.n * c.n, mutants = [];
  // the injection: 48 marked mutations into distinct replicators (16 neutral, 16 up, 16 down), chosen by the run's RNG
  function inject(u, S) {
    const reps = []; for (let i = 0; i < N; i++) if (S.isRep(u[4 * i])) reps.push(i);
    for (let k = reps.length - 1; k > 0; k--) { const r = rnd(c.seed, 1 << 20, k, 7) % (k + 1); [reps[k], reps[r]] = [reps[r], reps[k]]; }
    const mark = S.mark(), mcopy = S.mcopy(); let ri = 0;
    for (const cls of ['neutral', 'up', 'down']) for (let k = 0; k < 16; k++) {
      while (ri < reps.length) {
        const i = reps[ri++], tb = u[4 * i + 1] & 255; let bit = -1;
        const h = rnd(c.seed, 1 << 21, i, 8);
        if (cls === 'neutral') bit = 40 + (h % 88);                               // tape bytes 1..11 (ring bits 40..127)
        else { const want = cls === 'up' ? 0 : 1, cand = []; for (let b = 0; b < 8; b++) if (((tb >> b) & 1) === want) cand.push(b); if (cand.length) bit = 32 + cand[h % cand.length]; }
        if (bit < 0) continue;
        u[4 * i + (bit >> 5)] ^= 1 << (bit & 31);
        const id = mutants.length + 1; mark[i] = id; mcopy[i] = 0;
        mutants.push({ id, cls, cell: i, bit, val: (u[4 * i + (bit >> 5)] >>> (bit & 31)) & 1, trait: POP8[u[4 * i + 1] & 255] });
        break;
      }
    }
  }
  const A = await makeRun(c, inject), B = c.twin ? await makeRun(c, null) : null;
  const rows = [], marks = []; let firstLin = { 2: null, 16: null, pct1: null };
  for (let t = 1; t <= c.turns; t++) {
    A.sim.step(); if (B) B.sim.step();
    const sample = t % c.every === 0 || t === c.turns;
    const lin = A.S.lin(), u = A.u();
    // lineage sizes (cheap enough every turn for the first-lineage times)
    if (firstLin.pct1 === null || sample) {
      const sz = new Map(); let rep = 0, copied = 0, trSum = 0;
      for (let i = 0; i < N; i++) { if (A.S.isRep(u[4 * i])) { rep++; trSum += POP8[u[4 * i + 1] & 255]; } if (lin[i]) { copied++; sz.set(lin[i], (sz.get(lin[i]) || 0) + 1); } }
      let big = 0; for (const v of sz.values()) if (v > big) big = v;
      if (firstLin[2] === null && big >= 2) firstLin[2] = t; if (firstLin[16] === null && big >= 16) firstLin[16] = t; if (firstLin.pct1 === null && big >= N / 100) firstLin.pct1 = t;
      if (sample) {
        const e = entropy(u, N);
        const row = { t, rep: rep / N, copied: copied / N, lineages: sz.size, biggest: big / N, trait: rep ? trSum / rep : null, h2: e.h2, distinct: e.distinct / N, copyBits: A.S.copyBits() / (N * t), bgBits: A.S.bgBits() / (N * t) };
        if (B) { const keys = entropy(B.u(), N).keys; let novel = 0; for (let i = 0; i < N; i++) if (!keys.has(u[4 * i] + ',' + u[4 * i + 1] + ',' + u[4 * i + 2] + ',' + u[4 * i + 3])) novel++; row.novel = novel; }
        rows.push(row);
        if (mutants.length && t >= c.tinj) {
          const mk = A.S.mark(), mc = A.S.mcopy(), desc = new Int32Array(mutants.length + 1), carr = new Int32Array(mutants.length + 1), alive = new Int32Array(mutants.length + 1);
          for (let i = 0; i < N; i++) { const id = mk[i]; if (!id) continue; alive[id]++; if (!mc[i]) continue; desc[id]++; const M = mutants[id - 1]; if (((u[4 * i + (M.bit >> 5)] >>> (M.bit & 31)) & 1) === M.val) carr[id]++; }
          marks.push({ t, desc: Array.from(desc.subarray(1)), carriers: Array.from(carr.subarray(1)), alive: Array.from(alive.subarray(1)) });
        }
      }
    }
  }
  return { cond: c, tag: tagOf(c), firstLin, founders: A.S.founders.length, founderTrait: A.S.founders.length ? A.S.founders.reduce((a, f) => a + f.trait, 0) / A.S.founders.length : null, foundersAtStart: A.S.founders.filter(f => f.turn === 0).length, mutants, rows, marks, provenance: provenance(import.meta.url, c) };
}
const tagOf = c => `${c.copy}-s${c.self}-t${c.trait}-${c.erase}${c.protect ? '' : '-noprot'}-${c.med}-mu${c.mu}-m${c.m}-n${c.n}-T${c.turns}${c.twin ? '-twin' : ''}-seed${c.seed}`;
function condFrom(o) {
  return { copy: o.copy ?? 'verbatim', self: Number(o.self ?? 1), trait: Number(o.trait ?? 1), erase: o.erase ?? 'r90', protect: Number(o.protect ?? 1), med: o.med ?? 'off', mu: Number(o.mu ?? 0.001),
           m: Number(o.m ?? 16), n: Number(o.n ?? 128), turns: Number(o.turns ?? 2000), every: Number(o.every ?? 25), tinj: Number(o.tinj ?? 500), twin: Number(o.twin ?? 0), seed: Number(o.seed ?? 1) };
}
// ---- the plain decoder's mutant fate ----------------------------------------------------------------------------------
async function decoderRef() {
  const n = Number(opt.n ?? 128), N = n * n, seeds = Number(opt.seeds ?? 5), T0 = 300, K = [1, 2, 3, 10, 50, 200];
  const text = dictText('ca-swarm-f'), dict = Uint8Array.from(Buffer.from(text, 'latin1')), O = { skip: 6, V: 4096, coff: 0 };
  const key = x => Buffer.from(x).toString('latin1');
  // (1) in isolation: every single-bit mutant of the attractor's states
  let x = new Uint8Array(16).map((_, i) => (i * 97 + 13) & 255); for (let k = 0; k < 200; k++) x = decode36(x, dict, O).out;
  const cyc = [key(x)]; let y = decode36(x, dict, O).out; while (key(y) !== cyc[0] && cyc.length < 64) { cyc.push(key(y)); y = decode36(y, dict, O).out; }
  const onCyc = new Map(cyc.map((s, i) => [s, i])), iso = { period: cyc.length, mutants: 0, sameCycle: 0, samePhase: 0, other: 0, steps: 0 };
  for (let s = 0; s < cyc.length; s++) for (let b = 0; b < 128; b++) {
    let z = Uint8Array.from(Buffer.from(cyc[s], 'latin1')); z[b >> 3] ^= 1 << (b & 7); iso.mutants++;
    let k = 0; for (; k < 200 && !onCyc.has(key(z)); k++) z = decode36(z, dict, O).out;
    if (onCyc.has(key(z))) { iso.sameCycle++; iso.steps += k; if (onCyc.get(key(z)) === (s + k) % cyc.length) iso.samePhase++; } else iso.other++;
  }
  console.error(`decoder alone: ${cyc.length}-cycle, ${iso.mutants} single-bit mutants: ${iso.sameCycle} back on the cycle (${iso.samePhase} in phase) in ${(iso.steps / iso.sameCycle).toFixed(1)} steps on average, ${iso.other} elsewhere`);
  // (2) on the lattice: twin runs, 64 mutations (one per 16 x 16 tile) at turn T0; footprint = cells differing from the twin,
  // novel = cells whose content occurs nowhere in the twin lattice
  const lattice = [];
  for (const med of ['off', 'mild', 'weak', 'strong']) for (let seed = 1; seed <= seeds; seed++) {
    const M = medOf(med), mk = () => makeSim({ W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread: 4096, coff: 0, pairMode: 0, passes: 1, nbr: 1, swap: [M.pm, M.pm], smooth: [M.ps, M.ps], mixOn: M.pm > 0, settleOn: M.ps > 0, altOrder: 'rotate' });
    const A = await mk(), B = await mk(); A.setDict(text); B.setDict(text); A.reset(seed); B.reset(seed);
    for (let t = 0; t < T0; t++) { A.step(); B.step(); }
    const tiles = n / 16, ga = A.grid();
    for (let ty = 0; ty < tiles; ty++) for (let tx = 0; tx < tiles; tx++) { const i = (16 * ty + 8) * n + 16 * tx + 8, b = rnd(seed, 0, i, 9) & 127; ga[16 * i + (b >> 3)] ^= 1 << (b & 7); }
    const res = { med, seed, k: {} };
    for (let t = 1; t <= Math.max(...K); t++) {
      A.step(); B.step();
      if (!K.includes(t)) continue;
      const a = A.grid(), b = B.grid(), keys = new Set(); for (let i = 0; i < N; i++) keys.add(key(b.subarray(16 * i, 16 * i + 16)));
      let foot = 0, novel = 0, tilesHit = 0; const hit = new Uint8Array(tiles * tiles);
      for (let i = 0; i < N; i++) { let d = 0; for (let q = 0; q < 16; q++) if (a[16 * i + q] !== b[16 * i + q]) { d = 1; break; } if (d) { foot++; hit[((i / n | 0) >> 4) * tiles + ((i % n) >> 4)] = 1; if (!keys.has(key(a.subarray(16 * i, 16 * i + 16)))) novel++; } }
      for (const h of hit) tilesHit += h;
      res.k[t] = { foot: foot / 64, novel: novel / 64, persist: tilesHit / 64 };
    }
    lattice.push(res);
    console.error(`decoder, med ${med}, seed ${seed}: ` + K.map(k => `k${k} foot ${res.k[k].foot.toFixed(2)} novel ${res.k[k].novel.toFixed(2)} persist ${res.k[k].persist.toFixed(2)}`).join(' | '));
  }
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(`${outDir}/decoder-mutants-n${n}.json`, JSON.stringify({ n, T0, K, isolation: iso, lattice, provenance: provenance(import.meta.url, { mode: 'decoder', n, seeds }) }, null, 1));
}
// ---- the factorial, in parallel ---------------------------------------------------------------------------------------
function conditions(set, seeds) {
  const L = [];
  const add = o => { for (let s = 1; s <= seeds; s++) L.push({ ...o, seed: s }); };
  if (set === 'main' || set === 'all') {
    for (const erase of ['id', 'r90', 'dec']) for (const med of ['off', 'mild', 'strong']) for (const mu of [0, 0.001]) {
      add({ copy: 'none', self: 0, trait: 0, erase, med, mu });
      for (const copy of ['derived', 'verbatim']) for (const self of [0, 1]) for (const trait of [0, 1]) add({ copy, self, trait, erase, med, mu });
    }
  }
  if (set === 'm' || set === 'all') for (const m of [8, 12, 20, 24]) for (const erase of ['id', 'r90', 'dec']) for (const mu of [0, 0.001]) add({ copy: 'verbatim', self: 1, trait: 1, erase, med: 'off', mu, m });
  if (set === 'template') for (const erase of ['id', 'r90']) for (const med of ['off', 'mild']) for (const mu of [0, 0.001]) for (const trait of [0, 1]) add({ copy: 'template', self: 1, trait, erase, med, mu });
  if (set === 'protect' || set === 'all') for (const erase of ['r90', 'dec']) for (const copy of ['derived', 'verbatim']) add({ copy, self: 1, trait: 1, erase, med: 'off', mu: 0.001, protect: 0 });
  if (set === 'twin' || set === 'all') for (const copy of ['derived', 'verbatim']) for (const med of ['off', 'mild']) add({ copy, self: 1, trait: 0, erase: 'r90', med, mu: 0.001, twin: 1 });
  if (set === 'medscan' || set === 'all') for (const copy of ['derived', 'verbatim']) for (const med of ['p0.001s0', 'p0.002s0', 'p0.005s0', 'p0.01s0', 'p0.02s0', 'p0.05s0', 'p0s0.01', 'p0s0.1', 'p0s1', 'weak']) add({ copy, self: 1, trait: 1, erase: 'r90', med, mu: 0.001 });
  return L;
}
async function grid() {
  const set = opt.set || 'all', seeds = Number(opt.seeds ?? 5), jobs = Number(opt.jobs ?? 10);
  const todo = conditions(set, seeds).map(o => condFrom({ ...o, n: opt.n, turns: opt.turns })).filter(c => !fs.existsSync(`${outDir}/runs/${tagOf(c)}.json`));
  console.error(`${todo.length} runs on ${jobs} workers`);
  let next = 0, done = 0;
  await Promise.all(Array.from({ length: jobs }, () => (async () => {
    while (next < todo.length) {
      const c = todo[next++];
      const args = ['mode=run', ...Object.entries(c).map(([k, v]) => `${k}=${v}`)];
      await new Promise(res => { const p = spawn(process.execPath, [new URL(import.meta.url).pathname, ...args], { stdio: ['ignore', 'ignore', 'inherit'] }); p.on('exit', res); });
      if (++done % 20 === 0) console.error(`${done}/${todo.length}`);
    }
  })()));
}
// ---- summary ----------------------------------------------------------------------------------------------------------
const T975 = [NaN, 12.71, 4.30, 3.18, 2.78, 2.57, 2.45, 2.36, 2.31, 2.26, 2.23];
function ci(v) { v = v.filter(x => x !== null && Number.isFinite(x)); const k = v.length; if (!k) return null; const mu = v.reduce((a, b) => a + b, 0) / k; if (k < 2) return { mean: mu, half: null, n: k }; const sd = Math.sqrt(v.reduce((a, b) => a + (b - mu) ** 2, 0) / (k - 1)); return { mean: mu, half: (T975[k - 1] ?? 2) * sd / Math.sqrt(k), n: k }; }
function summary() {
  const files = fs.readdirSync(`${outDir}/runs`).filter(f => f.endsWith('.json'));
  const groups = new Map();
  for (const f of files) { const r = JSON.parse(fs.readFileSync(`${outDir}/runs/${f}`, 'utf8')); const g = r.tag.replace(/-seed\d+$/, ''); if (!groups.has(g)) groups.set(g, []); groups.get(g).push(r); }
  const out = [];
  for (const [g, runs] of [...groups.entries()].sort()) {
    const c = runs[0].cond, last = r => r.rows[r.rows.length - 1], atT = (r, t) => r.rows.find(x => x.t === t);
    const per = runs.map(r => {
      const L = last(r), mk = r.marks.length ? r.marks[r.marks.length - 1] : null, k100 = r.marks.find(x => x.t >= c.tinj + 100);
      const cls = (m, name, f) => m ? r.mutants.map((M, i) => M.cls === name ? f(m, i) : null).filter(x => x !== null) : [];
      const sum = a => a.reduce((x, y) => x + y, 0);
      const her = m => { const d = sum(cls(m, 'neutral', (m, i) => m.desc[i])), ca = sum(cls(m, 'neutral', (m, i) => m.carriers[i])); return d ? ca / d : null; };
      const up = mk ? sum(cls(mk, 'up', (m, i) => m.desc[i])) : null, down = mk ? sum(cls(mk, 'down', (m, i) => m.desc[i])) : null;
      const trF = r.founderTrait;
      return { tFirst2: r.firstLin[2], tFirst16: r.firstLin[16], tPct1: r.firstLin.pct1, founders: r.founders, rep: L.rep, copied: L.copied, biggest: L.biggest, lineages: L.lineages,
               h2: L.h2, distinct: L.distinct, copyBits: L.copyBits, bgBits: L.bgBits, trait: L.trait, dTrait: L.trait !== null && trF !== null ? L.trait - trF : null,
               her100: k100 ? her(k100) : null, herEnd: mk ? her(mk) : null, descNeutral: mk ? sum(cls(mk, 'neutral', (m, i) => m.desc[i])) / 16 : null,
               survNeutral: mk ? cls(mk, 'neutral', (m, i) => m.carriers[i] > 0 ? 1 : 0).reduce((a, b) => a + b, 0) / 16 : null,
               logUpDown: up !== null ? Math.log2((up + 1) / (down + 1)) : null, injected: r.mutants.length, novel: L.novel ?? null };
    });
    const keys = Object.keys(per[0]), agg = {}; for (const k of keys) agg[k] = ci(per.map(p => p[k]));
    out.push({ group: g, cond: { ...c, seed: undefined }, seeds: runs.map(r => r.cond.seed), never16: per.filter(p => p.tFirst16 === null).length, agg });
  }
  fs.writeFileSync(`${outDir}/summary.json`, JSON.stringify({ groups: out, provenance: provenance(import.meta.url, { mode: 'summary' }) }, null, 1));
  const f = (a, d = 2, s = 1) => !a ? '–' : `${(s * a.mean).toFixed(d)}${a.half !== null ? ` ± ${(s * a.half).toFixed(d)}` : ''}`;
  console.log('| condition | seeds | t(lineage ≥ 16) | never | replicators | copied | biggest lineage | H2 | distinct | copy bits/cell/turn | bg bits/cell/turn | heredity (k=100) | heredity (end) | neutral descendants/mutant (end) | log2 up/down | Δtrait |');
  console.log('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|');
  for (const o of out) { const a = o.agg; console.log(`| ${o.group} | ${o.seeds.length} | ${f(a.tFirst16, 0)} | ${o.never16} | ${f(a.rep, 3)} | ${f(a.copied, 3)} | ${f(a.biggest, 3)} | ${f(a.h2, 1)} | ${f(a.distinct, 3)} | ${f(a.copyBits, 2)} | ${f(a.bgBits, 2)} | ${f(a.her100, 2)} | ${f(a.herEnd, 2)} | ${f(a.descNeutral, 0)} | ${f(a.logUpDown, 2)} | ${f(a.dTrait, 2)} |`); }
}
// ---- main -------------------------------------------------------------------------------------------------------------
const mode = opt.mode || 'run';
if (mode === 'run') {
  const c = condFrom(opt), t0 = Date.now(), r = await runOne(c);
  fs.mkdirSync(`${outDir}/runs`, { recursive: true });
  fs.writeFileSync(`${outDir}/runs/${r.tag}.json`, JSON.stringify(r));
  const L = r.rows[r.rows.length - 1];
  console.error(`${r.tag}: ${((Date.now() - t0) / 1000).toFixed(1)} s; founders ${r.founders} (${r.foundersAtStart} at t0); first lineage >=16 at ${r.firstLin[16]}; end: rep ${L.rep.toFixed(3)} copied ${L.copied.toFixed(3)} biggest ${L.biggest.toFixed(3)} H2 ${L.h2 === null ? '>max' : L.h2.toFixed(1)} distinct ${L.distinct.toFixed(3)} trait ${L.trait?.toFixed(2)}; injected ${r.mutants.length}`);
} else if (mode === 'grid') await grid();
else if (mode === 'decoder') await decoderRef();
else if (mode === 'summary') summary();
