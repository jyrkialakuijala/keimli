// One lattice run of the ablation matrix (research plan Q1 / H1, amended after review): uniform parameters, the three
// stages switched on or off, quenched (salt 0) or annealed (salt by turn) hashing, and the measurements the referees
// asked for instead of byte-labelled domains: the Hamming correlation C(r) = 1 - 2 <d_H(x, x + r)> / 128 along x and
// along y in the bulk of the grid (edge cells excluded, since the lattice is a bounded plane), per byte group of 8 bit
// planes and, at a few turns, per bit plane; the activity (d1, bits moved, bits median-changed, bits rewritten); byte
// entropy; distinct cells. Writes one JSON file with every sample.
// Usage: node paper/experiments/ablation.mjs cond=MSR pm=0.5 ps=1 salt=0 seed=1 n=256 turns=1000 dict=ca-swarm-f out=paper/data/ablation
//   cond: three letters, M mixing, S settling, R rewriting, '-' for off (MSR the reference, M-R, -SR, MS-, M--, -S-, --R)
//   pm: the swap slider p (uniform; the exchange rate is 2p(1-p)); ps: the median probability (uniform)
//   salt: 0 content only (quenched), 1 by turn (annealed), 2 by position, 3 both; margin: bulk margin in cells (default n/8)
//   variant=shuffle:3 | wordshuffle:1 | reverse : a control version of the dictionary (dict-variants.mjs)
//   rewrite=hash:K | hashdict:K | cycle3 | cycle3f : instead of the decoder, the null-model map that keeps the first K bits of the cell and replaces
//   the other 128 - K by a fixed hash of those K bits (a random many-to-one map with image size 2^K)
import fs from 'node:fs';
import { provenance } from './provenance.mjs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, variantOf, asText } from './dict-variants.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const cond = opt.cond || 'MSR', pm = Number(opt.pm ?? 0.5), ps = Number(opt.ps ?? 1), salt = Number(opt.salt ?? 0), seed = Number(opt.seed ?? 1), n = Number(opt.n ?? 256), turns = Number(opt.turns ?? 1000);
const dictId = opt.dict || 'ca-swarm-f', outDir = opt.out || dir + '/paper/data/ablation', margin = Number(opt.margin ?? n >> 3);
const mixOn = cond[0] === 'M', settleOn = cond[1] === 'S', rewriteOn = cond[2] === 'R';

// variant=shuffle:3 etc.: a control version of the dictionary (dict-variants.mjs), the number its shuffle seed
const [variant, vseed] = (opt.variant || 'raw').split(':'), dictLabel = variant === 'raw' ? dictId : `${dictId}-${variant}${vseed || 1}`;
const text = asText(variantOf(loadDict(dictId).bytes, variant, Number(vseed || 1)));

// the null-model rewrite: keep K bits, hash them into the rest (splitmix64 over the kept words)
// hashdict:K: the same, but the replaced bytes are drawn from the dictionary's own bytes (its byte histogram exactly),
// so the null has the decoder's alphabet without its copy structure
let rewrite = null, rewriteName = 'decoder', dictTable = null;
if (opt.rewrite && /^hash(dict)?:/.test(opt.rewrite)) {
  const K = Number(opt.rewrite.split(':')[1]); rewriteName = opt.rewrite.startsWith('hashdict') ? `hashdict${K}` : `hash${K}`;
  if (opt.rewrite.startsWith('hashdict')) dictTable = Uint8Array.from(Buffer.from(text, 'latin1'));
  const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
  rewrite = (g, N) => {
    let changed = 0; const w = new Uint8Array(16);
    for (let i = 0; i < N; i++) {
      const a = 16 * i;
      // the kept prefix: K bits from bit 0 (LSB-first within bytes, as the decoder reads them)
      let h = 0x9E3779B97F4A7C15n;
      for (let k = 0; k < 16; k++) { const keep = Math.max(0, Math.min(8, K - 8 * k)); const m = keep >= 8 ? 255 : (1 << keep) - 1; w[k] = g[a + k] & m; h = BigInt.asUintN(64, (h ^ BigInt(w[k] | (k << 8))) * 0xBF58476D1CE4E5B9n); h ^= h >> 31n; }
      // the rest: bytes of successive splitmix steps (hash:K), or dictionary bytes picked by them (hashdict:K)
      let z = h;
      for (let k = 0; k < 16; k++) {
        const keep = Math.max(0, Math.min(8, K - 8 * k)); if (keep >= 8) continue;
        z = BigInt.asUintN(64, z + 0x9E3779B97F4A7C15n); let t = z; t = BigInt.asUintN(64, (t ^ (t >> 30n)) * 0xBF58476D1CE4E5B9n); t = BigInt.asUintN(64, (t ^ (t >> 27n)) * 0x94D049BB133111EBn); t ^= t >> 31n;
        const m = (1 << keep) - 1, rb = dictTable ? dictTable[Number(t % BigInt(dictTable.length))] : Number(t & 255n), v = (w[k] & m) | (rb & ~m & 255);
        changed += POP[g[a + k] ^ v]; g[a + k] = v;
      }
    }
    return changed;
  };
}

// cycle3 / cycle3f: a map with one global 3-cycle and nothing else. Three 16-byte states S0 S1 S2 (cycle3: random bytes
// from the run's own seed; cycle3f: the decoder's own cycle, found by iterating the reference decoder from a random
// cell); f(S_i) = S_(i+1), and any other cell goes to S_(hash mod 3). Every cell is on the cycle after one turn.
if (opt.rewrite && /^cycle3f?$/.test(opt.rewrite)) {
  rewriteName = opt.rewrite;
  let S;
  if (opt.rewrite === 'cycle3f') {
    const { decode36 } = await import('./decode36.mjs'); const dict = Uint8Array.from(Buffer.from(text, 'latin1'));
    let x = new Uint8Array(16).map((_, i) => (i * 97 + 13) & 255); for (let k = 0; k < 200; k++) x = decode36(x, dict, { skip: 6, V: 4096, coff: 0 }).out;
    S = [x]; for (let k = 1; k < 3; k++) S.push(decode36(S[k - 1], dict, { skip: 6, V: 4096, coff: 0 }).out);
    if (Buffer.compare(Buffer.from(decode36(S[2], dict, { skip: 6, V: 4096, coff: 0 }).out), Buffer.from(S[0])) !== 0) throw new Error('the reference decoder did not give a 3-cycle');
  } else { let z = BigInt(seed) * 0x9E3779B97F4A7C15n; const nb = () => { z = BigInt.asUintN(64, z + 0x9E3779B97F4A7C15n); let t = z; t = BigInt.asUintN(64, (t ^ (t >> 30n)) * 0xBF58476D1CE4E5B9n); t = BigInt.asUintN(64, (t ^ (t >> 27n)) * 0x94D049BB133111EBn); return Number((t ^ (t >> 31n)) & 255n); }; S = [0, 1, 2].map(() => Uint8Array.from({ length: 16 }, nb)); }
  const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
  const same = (g, a, s) => { for (let k = 0; k < 16; k++) if (g[a + k] !== s[k]) return false; return true; };
  rewrite = (g, N) => {
    let changed = 0;
    for (let i = 0; i < N; i++) {
      const a = 16 * i; let j = -1;
      for (let s = 0; s < 3; s++) if (same(g, a, S[s])) { j = (s + 1) % 3; break; }
      if (j < 0) { let h = 2166136261; for (let k = 0; k < 16; k++) h = Math.imul(h ^ g[a + k], 16777619); j = (h >>> 0) % 3; }
      for (let k = 0; k < 16; k++) { changed += POP[g[a + k] ^ S[j][k]]; g[a + k] = S[j][k]; }
    }
    return changed;
  };
}

const altOrder = opt.altorder === undefined ? 'rotate' : opt.altorder === '0' || opt.altorder === 'fixed' ? false : opt.altorder === '1' ? 'alternate' : opt.altorder;   // default since 2026-10-21: the page's rotating order; altorder=fixed for the earlier runs   // altorder=1|alternate|palindrome|cycle4|random: the swap-order scheme (Band.SCHEMES); unset: the fixed order of the runs before 2026-10-20
const nbr = Number(opt.nbr ?? 1), passes = Number(opt.passes ?? 3), cread = Number(opt.cread ?? 4096);   // nbr=0: the 4-connected cross (5 votes); passes: median passes a turn
const mixSync = Number(opt.mixsync ?? 0) === 1;   // mixsync=1: the synchronous isotropic mixing instead of the swap phases
const sim = await makeSim({ W: n, H: n, passes, nbr, changer: 36, pairMode: 0, maxlen: 3, skip: 6, cread, coff: 0, saltMode: salt, swap: [pm, pm], smooth: [ps, ps], mixOn, settleOn, rewriteOn, rewrite, altOrder, mixSync });
sim.setDict(text); sim.reset(seed);
const { W, H, N } = sim;
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const RS = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64].filter(r => r < n - 2 * margin);
const x0 = margin, x1 = W - margin, y0 = margin, y1 = H - margin;
// C(r) along an axis per byte group: 1 - 2 <popcount(g[a+k] ^ g[b+k])> / 8
function corr(g, axis) {
  const out = [];
  for (const r of RS) {
    const acc = new Float64Array(16); let cnt = 0;
    for (let y = y0; y < (axis ? y1 - r : y1); y++) for (let x = x0; x < (axis ? x1 : x1 - r); x++) {
      const a = 16 * (y * W + x), b = axis ? a + 16 * W * r : a + 16 * r;
      for (let k = 0; k < 16; k++) acc[k] += POP[g[a + k] ^ g[b + k]];
      cnt++;
    }
    out.push(Array.from(acc, s => 1 - 2 * s / (8 * cnt)));
  }
  return out;
}
// the connected correlation: C(r) of each bit plane's spins (+1/-1) less the square of the plane's mean spin over the
// region, averaged over the 8 planes of a byte group; the raw C(r) above never subtracts the bias, which makes biased
// planes look correlated at every distance (the panel's correction of 2026-10-21)
function planeMean2(g) {
  const ones = new Float64Array(128); let nb = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { const a = 16 * (y * W + x); nb++; for (let k = 0; k < 16; k++) { let v = g[a + k]; while (v) { const j = 31 - Math.clz32(v & -v); ones[8 * k + j]++; v &= v - 1; } } }
  const m2 = new Float64Array(16); for (let j = 0; j < 128; j++) { const m = 2 * ones[j] / nb - 1; m2[j >> 3] += m * m / 8; } return m2;
}
const connected = (c, m2) => c.map(row => row.map((v, k) => v - m2[k]));
// per bit plane C(1) along an axis (128 values)
function corrPlanes(g, axis, r = 1) {
  const acc = new Float64Array(128); let cnt = 0;
  for (let y = y0; y < (axis ? y1 - r : y1); y++) for (let x = x0; x < (axis ? x1 : x1 - r); x++) {
    const a = 16 * (y * W + x), b = axis ? a + 16 * W * r : a + 16 * r;
    for (let k = 0; k < 16; k++) { let d = g[a + k] ^ g[b + k]; while (d) { const j = 31 - Math.clz32(d & -d); acc[8 * k + j]++; d &= d - 1; } }
    cnt++;
  }
  return Array.from(acc, s => 1 - 2 * s / cnt);
}
function bulkStats(g, prev) {
  const cnt = new Float64Array(256); let d1 = 0, ones = 0; const seen = new Set();
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const a = 16 * (y * W + x);
    for (let k = 0; k < 16; k++) { cnt[g[a + k]]++; ones += POP[g[a + k]]; if (prev) d1 += POP[g[a + k] ^ prev[a + k]]; }
    seen.add(Buffer.from(g.subarray(a, a + 16)).toString('latin1'));
  }
  const nb = (x1 - x0) * (y1 - y0); let ent = 0; for (let v = 0; v < 256; v++) if (cnt[v]) { const p = cnt[v] / (16 * nb); ent -= p * Math.log2(p); }
  // per bit plane density of ones (the magnetisation per plane, as |2m - 1|)
  const dens = new Float64Array(128);
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { const a = 16 * (y * W + x); for (let k = 0; k < 16; k++) { let v = g[a + k]; while (v) { const j = 31 - Math.clz32(v & -v); dens[8 * k + j]++; v &= v - 1; } } }
  let mag = 0; for (let j = 0; j < 128; j++) mag += Math.abs(2 * dens[j] / nb - 1); mag /= 128;
  return { ent, d1: prev ? d1 / (128 * nb) : null, ones: ones / (128 * nb), distinct: seen.size / nb, planeMag: mag };
}
const sampleTurns = new Set(); for (let t = 1; t <= turns; t++) if (t <= 10 || (t <= 100 && t % 5 === 0) || t % 20 === 0 || t === turns) sampleTurns.add(t);
const planeTurns = new Set([10, 100, Math.min(400, turns), turns]);
const rows = []; let prev = null; const t0 = Date.now();
let acc = { moved: 0, smoothed: 0, rewritten: 0, k: 0 };
for (let t = 1; t <= turns; t++) {
  const r = sim.step(); acc.moved += r.moved; acc.smoothed += r.smoothed; acc.rewritten += r.rewritten; acc.k++;
  if (sampleTurns.has(t)) {
    const g = sim.grid();
    const row = { t, moved: acc.moved / (acc.k * 128 * N), smoothed: acc.smoothed / (acc.k * 128 * N), rewritten: acc.rewritten / (acc.k * N), ...bulkStats(g, prev), cx: corr(g, 0), cy: corr(g, 1) }; { const m2 = planeMean2(g); row.ccx = connected(row.cx, m2); row.ccy = connected(row.cy, m2); }
    if (planeTurns.has(t)) { row.px1 = corrPlanes(g, 0); row.py1 = corrPlanes(g, 1); }
    rows.push(row); acc = { moved: 0, smoothed: 0, rewritten: 0, k: 0 };
  }
  if (sampleTurns.has(t + 1)) prev = sim.grid().slice(); else prev = null;   // the previous frame, kept only when the next turn is sampled
}
const res = { provenance: provenance(import.meta.url, opt), cond, pm, ps, rate: 2 * pm * (1 - pm), salt, seed, n, turns, dict: dictLabel, dictId, variant, rewrite: rewriteName, altOrder, margin, rs: RS, params: sim.params, seconds: (Date.now() - t0) / 1000, rows };
fs.mkdirSync(outDir, { recursive: true });
const name = `${cond}-${rewriteName}-pm${pm}-ps${ps}-salt${salt}-n${n}-t${turns}-${dictLabel}-seed${seed}${altOrder ? '-' + (altOrder === 'alternate' ? 'alt' : altOrder) : ''}${nbr !== 1 || passes !== 3 ? `-nbr${nbr}-p${passes}` : ''}${mixSync ? '-sync' : ''}.json`;
fs.writeFileSync(`${outDir}/${name}`, JSON.stringify(res));
const last = rows[rows.length - 1];
console.log(`${name}: ${res.seconds.toFixed(0)} s | final d1 ${last.d1?.toFixed(4)} moved ${last.moved.toFixed(4)} smoothed ${last.smoothed.toFixed(4)} rewritten ${last.rewritten.toFixed(3)} ent ${last.ent.toFixed(2)} distinct ${last.distinct.toFixed(3)} planeMag ${last.planeMag.toFixed(3)} | Cx(1) ${(last.cx[0].reduce((a, b) => a + b) / 16).toFixed(3)} Cx(8) ${(last.cx[5].reduce((a, b) => a + b) / 16).toFixed(3)} Cx(32) ${(last.cx[9].reduce((a, b) => a + b) / 16).toFixed(3)} Cy(1) ${(last.cy[0].reduce((a, b) => a + b) / 16).toFixed(3)} | connected Cx(1) ${(last.ccx[0].reduce((a, b) => a + b) / 16).toFixed(3)} Cx(8) ${(last.ccx[5].reduce((a, b) => a + b) / 16).toFixed(3)} Cx(32) ${(last.ccx[9].reduce((a, b) => a + b) / 16).toFixed(3)}`);
