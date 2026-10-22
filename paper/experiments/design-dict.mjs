// Design a dictionary for the Brotli-like decoder (kind 36, skip 6) with S engineered attractors: each an 8-cycle
// whose consecutive states differ in one header bit (a reflected Gray code over bits 4..6 of the header) and,
// optionally, one tail byte. Construction: a 16-byte cell whose first 30 + HB bits (HB = ceil(log2 V) header bits)
// read "no literals, copy 10 bytes from the dictionary at distance d, then copy 6 more at the same distance" outputs
// the 16 dictionary bytes at h - d, where h is the header; the other bits are not read. Type s has its states at
// H0_s - d + 16 g(k-1) with headers H0_s + 16 g(k), g the Gray code, so state k decodes exactly to state k+1.
// The rest of the dictionary (the filler) decides how fast random cells fall into the cycles. mode=const (default):
// the header range is cut into S regions, each tiled with a short pattern P_s (one byte, or two bytes when more
// type are wanted than there are single bytes that qualify), so every misaligned reading is one of the pattern's
// rotations, whose decoding (fixed by the bits of the pattern) copies from dictionary positions we control: a
// "landing pad" holding state 0 of types s is written there, so rotation -> state 0 in one step; the alphabet
// stays tiny, as in the swarm's dictionaries, and the funnel is steep. A pattern qualifies when every rotation's
// cell begins with enough dictionary bytes from distinct positions to cover the head; the S patterns are chosen with
// the shortest and most equal reading lengths (the number of bits the decoder reads from the pattern cell), since the
// lattice favours the type with the shortest reading. The blocks go to header spots whose eight heads are
// printable, inside their own region when one is free, and for S <= 6 the region bounds are hill-climbed for equal
// basins. mode=words (3 types only, the first version): a 16-byte word per type tiled over its region, ten
// bytes hill-climbed; slow funnel, kept as a control.
// A pattern qualifies when at least one rotation's cell begins with enough dictionary bytes; patterns landing in
// every rotation are preferred. With V = 4096 (the page default) and a 4,400-byte dictionary there are 16 block spots
// (12 with printable heads, 4 whose byte 1 is a control character), so at most 16 types; V=8122 (the page's
// largest window range) with len=8800 gives 13 header bits and 32 spots, so up to 32 types.
// Every byte printable ASCII, no lowercase in the tails (the decoder's case transforms), file ends with one newline
// so the page and the harness see the same bytes.
// Usage: node paper/experiments/design-dict.mjs [name=ca-gray3c] [types=3] [V=4096] [len=4400] [letters=123] [blocks=128,2304,3328]
//        [bounds=1365,2730] [balance=0|1] [period=1|2|auto] [mode=const|words] [d=16] [tailgray=1] [iters=0] [N=400] [seed=1] [census=10000] [wt=0.01]
import fs from 'node:fs';
import { decode36, rangeBits } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const MODE = opt.mode || 'const', S = Number((opt.types ?? opt.species) ?? (opt.letters ? opt.letters.length : 3));
const V = Number(opt.V ?? (S > 12 ? 60000 : 4096)), TL = Number(opt.len ?? (V > 8192 ? 61440 : V > 4096 ? 8800 : 4400)), HB = rangeBits(V), SKIP = 6, OPTS = { skip: SKIP, V, coff: 0 };
const DEFAULT_LETTERS = { 3: '123', 4: '0123', 5: '0"123', 6: '0!"123', 7: '0!1"2#3' };
const LETTERS = opt.letters || null;   // the first designs (3 to 6 species) were built from letters= with blocks= and bounds=; the automatic selection is the default
const NAME = opt.name || `ca-gray${S}c`, TAILGRAY = Number(opt.tailgray ?? 1), ITERS = Number(opt.iters ?? (MODE === 'const' ? 0 : 1500)), NS = Number(opt.N ?? 400), SEED = Number(opt.seed ?? 1), NCENSUS = Number(opt.census ?? 10000);
const BALANCE = Number(opt.balance ?? (MODE === 'const' && !opt.bounds && S <= 6 ? 1 : 0));
const PERIOD = opt.period || 'auto';
// cycles=8 (default) or a list, one length per type (5 to 16): the cycle is a closed walk on the header cube over
// bits 4..6 (lengths up to 8) or bits 4..7 (9 to 16) with one-bit steps; an odd length takes one two-bit step. The tail
// byte 6 then flips on every one-bit step and stays on the two-bit step (its parity), so every step is two bits.
const CYCLES = (opt.cycles || '8').split(',').map(Number); if (CYCLES.length !== 1 && CYCLES.length !== S) throw new Error('cycles= needs one length or one per species');
const LEN = i => CYCLES.length === 1 ? CYCLES[0] : CYCLES[i];
for (let i = 0; i < S; i++) if (LEN(i) < 3 || LEN(i) > 16) throw new Error('cycle lengths 3 to 16');
const MBITS = i => LEN(i) <= 8 ? 3 : 4, SPAN = i => 128;   // a species with 4 Gray bits has two 128-byte blocks, 1024 apart (header bit 10)
const CLASSIC = !opt.cycles;   // the first designs: 8-cycles, the reflected Gray code, tail bytes 6..8 following its bits
// a closed walk of length n on the m-cube with one-bit steps (n even) or exactly one two-bit step (n odd), by depth-first search
function grayWalk(n, m) {
  if (n === 2 ** m) return Array.from({ length: n }, (_, k) => k ^ (k >> 1));
  const N = 2 ** m, path = [0], used = new Uint8Array(N); used[0] = 1;
  const dist = (a, b) => { let x = a ^ b, c = 0; while (x) { c += x & 1; x >>= 1; } return c; };
  const dfs = twoLeft => {
    if (path.length === n) return dist(path[n - 1], 0) === 1 || (twoLeft && dist(path[n - 1], 0) === 2) ? (twoLeft && dist(path[n - 1], 0) === 2 ? 'two' : 'one') : false;
    const last = path[path.length - 1];
    for (let v = 1; v < N; v++) { if (used[v]) continue; const dd = dist(last, v); if (dd !== 1 && !(dd === 2 && twoLeft)) continue; used[v] = 1; path.push(v); const r = dfs(dd === 2 ? false : twoLeft); if (r) return r; path.pop(); used[v] = 0; }
    return false;
  };
  const r = dfs(n % 2 === 1); if (!r) throw new Error(`no closed walk of length ${n} on ${m} bits`);
  return path.slice();
}
const WALKS = Array.from({ length: S }, (_, i) => grayWalk(LEN(i), MBITS(i)));
const codeOf = g => ((g & 7) << 4) | ((g >> 3) << 10);   // Gray bits to header bits 4, 5, 6 and 10 (bit 10 keeps head byte 1 printable; it is xor-ed into H0)
const blocksOf = (i, H0) => MBITS(i) === 3 ? [H0] : [H0, H0 ^ 0x400];   // the 128-byte block(s) of species i at H0
const gray = k => k ^ (k >> 1);
const key = c => Buffer.from(c).toString('latin1');
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const ham = (a, b) => { let n = 0; for (let i = 0; i < 16; i++) n += POP[a[i] ^ b[i]]; return n; };
const printable = v => v >= 0x20 && v <= 0x7e, lower = v => v >= 0x61 && v <= 0x7a;
const safe = v => v >= 1 && v <= 0x7e && v !== 10 && v !== 13;   // a byte the text pipeline (UTF-8, JSON, universal newlines) carries unchanged; control bytes allowed in head byte 1 only when the printable spots run out
// ---- the head: header h, "copy 10 at d, copy 6 at the same d", written LSB-first from bit 6
// The head's command form: the first copy (10 bytes at distance d, transform tf1) and the second (6 bytes at the same
// distance: the ring's last distance, 4 bits, or an explicit d again, 7 bits; transform tf2). At 12 header bits the
// first designs used d 16, tf1 0, the ring and tf2 1; at 13 the ring form puts 0x80 in byte 5, so the explicit form with
// tf2 0; at 14 or more header bits the form is searched for the most block spots with printable, lowercase-free heads.
function headBits(h, d, form, HBits = HB) {
  const cell = new Uint8Array(8); let bp = 6;
  const put = (v, n) => { for (let i = 0; i < n; i++, bp++) if ((v >> i) & 1) cell[bp >> 3] |= 1 << (bp & 7); };
  put(h, HBits); put(0, 2); put(3, 2); put(4, 3); put(1, 1); put(d - 1, 6); put(form.tf1, 2);
  put(0, 2); put(3, 2); put(0, 3); if (form.ring) { put(0, 1); put(0, 4); } else { put(1, 1); put(d - 1, 6); } put(form.tf2, 2);
  return { cell, end: bp };
}
const FORM = HB <= 12 ? { d: 16, tf1: 0, ring: true, tf2: 1 } : HB === 13 ? { d: 16, tf1: 0, ring: false, tf2: 0 } : chooseForm();
const D = Number(opt.d ?? FORM.d);   // the copy distance (16 in the first designs)
const HEAD_END = headBits(0, FORM.d, FORM).end, HEAD_BYTES = Math.ceil(HEAD_END / 8);
const TAIL6_MASK = HEAD_END > 48 ? (1 << (HEAD_END - 48)) - 1 : 0, TAIL6_FIXED = TAIL6_MASK ? headBits(0, FORM.d, FORM).cell[6] & TAIL6_MASK : 0;   // bits of tail byte 6 the head fixes
export function head(h, d, b0free) {
  if (h >= V || d < 16 || d > 31) throw new Error(`head: h ${h} d ${d} out of range`);
  const { cell } = headBits(h, d, FORM); cell[0] |= b0free & 63;
  return Array.from(cell.subarray(0, Math.min(HEAD_BYTES, 6)));   // the bytes fixed by the head; the 7th (if any) only constrains the tail's first byte
}
const headOk = (h, d, b0, test = printable) => { try { return head(h, d, b0).every((v, i) => i === 1 ? test(v) && !lower(v) : printable(v) && !lower(v)); } catch (e) { return false; } };
function chooseForm() {   // 14 or more header bits: the form with the most block spots (heads printable without lowercase, a tail byte 6 class available)
  let best = null;
  for (const ring of [true, false]) for (const tf1 of [0, 1, 2]) for (const tf2 of [0, 1, 2]) for (let d = 16; d <= 31; d++) {
    const form = { d, tf1, ring, tf2 }, { cell, end } = headBits(0, d, form); if (end > 56) continue;
    const mask = end > 48 ? (1 << (end - 48)) - 1 : 0, fixed = cell[6] & mask;
    if (mask && ![0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x21, 0x23, 0x24, 0x25, 0x26, 0x27, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f].some(v => (v & mask) === fixed)) continue;
    let spots = 0;
    for (let H0 = 16; H0 + 112 < V; H0 += 128) { let ok = true; for (let g = 0; g < 8 && ok; g++) { const c = headBits(H0 + 16 * g, d, form).cell; for (let i = 0; i < Math.min(6, Math.ceil(end / 8)); i++) if (!printable(c[i] | (i ? 0 : 0x30)) || lower(c[i])) ok = false; } if (ok) spots++; }
    if (!best || spots > best.spots || (spots === best.spots && end < best.end)) best = { ...form, spots, end };
  }
  if (!best) throw new Error('no head form with printable bytes at ' + HB + ' header bits');
  console.error(`head form at ${HB} header bits: d ${best.d}, tf1 ${best.tf1}, ${best.ring ? 'ring' : 'explicit'} second distance, tf2 ${best.tf2}: ${best.end} bits, ${best.spots} block spots`);
  return best;
}
const NAMES = Array.from({ length: 32 }, (_, i) => i < 26 ? String.fromCharCode(65 + i) : 'A' + String.fromCharCode(65 + i - 26));
// ---- a filler pattern's rotations: where does the decoder read when the cell is the pattern repeated?
const DUMMY = new Uint8Array(TL).fill(0x20);
function patternInfo(P) {
  const L = P.length, rots = [];
  for (let r = 0; r < L; r++) {
    const cell = new Uint8Array(16); for (let i = 0; i < 16; i++) cell[i] = P[(i + r) % L];
    const res = decode36(cell, DUMMY, OPTS), lead = res.src.findIndex(v => v !== 2);
    const pos = res.dictPos.slice(0, Math.min(HEAD_BYTES, lead < 0 ? 16 : lead)), ok = pos.length === HEAD_BYTES && new Set(pos).size === HEAD_BYTES;
    rots.push({ cell: key(cell), ok, pos: ok ? pos : [], consumed: res.consumed, src: Array.from(res.src).map(v => 'LSD.'[v]).join('') });
  }
  // a rotation whose pad would overlap another rotation's pad at a different byte is dropped (its pad cannot hold both)
  const taken = new Map();
  for (const r of rots) { if (!r.ok) continue; if (r.pos.some((p, j) => taken.has(p) && taken.get(p) !== j)) { r.ok = false; r.pos = []; continue; } r.pos.forEach((p, j) => taken.set(p, j)); }
  const good = rots.filter(r => r.ok); if (!good.length) return null;
  return { P, rots, full: good.length === L, reading: Math.max(...good.map(r => r.consumed)) };
}
// ---- type, blocks, regions, patterns
let SPECIES, REGIONS, pads = null, patterns = null;
if (MODE === 'words') {
  if (S !== 3 || V !== 4096) throw new Error('mode=words is the three-species control at V = 4096');
  SPECIES = [[0x080, 0x41, 0x43], [0x880, 0x50, 0x52], [0xC80, 0x28, 0x2a]].map(([H0, b, a], i) => ({ name: NAMES[i], index: i, H0, b0: 0x30 + i, tail: Array(10).fill(b), alt: Array(10).fill(a) }));
  const b = (opt.bounds || '1365,2730').split(',').map(Number); REGIONS = [[0, b[0]], [b[0], b[1]], [b[1], 4096]];
} else {
  // candidate patterns: single bytes, then byte pairs (printable, not lowercase, not the newline)
  const alpha = []; for (let v = 0x20; v <= 0x7e; v++) if (!lower(v)) alpha.push(v);
  let cands = [];
  if (LETTERS) { for (const ch of LETTERS) { const info = patternInfo([ch.charCodeAt(0)]); if (!info) throw new Error(`letter ${ch} does not qualify at V = ${V}`); cands.push(info); } }
  else {
    const singles = alpha.map(v => patternInfo([v])).filter(Boolean);
    const pairs = PERIOD === '1' ? [] : alpha.flatMap(a => alpha.filter(b => b !== a).map(b => patternInfo([a, b]))).filter(Boolean);
    const triples = PERIOD === '1' || PERIOD === '2' ? [] : alpha.flatMap(a => alpha.flatMap(b => alpha.filter(c => !(a === b && b === c)).map(c => patternInfo([a, b, c])))).filter(Boolean);
    cands = (PERIOD === '2' ? pairs : singles.concat(pairs, triples)).sort((a, b) => a.reading - b.reading || a.P.length - b.P.length);
    console.error(`patterns: ${singles.length} single bytes, ${pairs.length} pairs (${pairs.filter(c => c.full).length} landing in both rotations), ${triples.length} triples (${triples.filter(c => c.full).length} in all three) qualify at V = ${V}`);
  }
  // candidate block spots: H0 with bits 0, 1, 4..6 clear and all eight heads safe (printable preferred)
  const spotsAll = [], printableSpot = new Set(), wideSpot = new Set();   // wide: 256-byte span for 4 Gray bits (bit 7 added)
  for (let H0 = 16; H0 + 112 < V; H0 += 4) if (!(H0 & 0x73) && [0, 1, 2, 3, 4, 5, 6, 7].every(g => headOk(H0 + 16 * g, D, 0x30, safe))) {
    spotsAll.push(H0); if ([0, 1, 2, 3, 4, 5, 6, 7].every(g => headOk(H0 + 16 * g, D, 0x30))) printableSpot.add(H0);
  }
  const spotSet = new Set(spotsAll); for (const H0 of spotsAll) if (!(H0 & 0x400) && spotSet.has(H0 ^ 0x400)) wideSpot.add(H0);   // both blocks of a 4-bit species valid
  const overlapB = (a, b) => Math.abs(a - b) < 128;
  // choose S patterns and S blocks together: pads must not fall inside blocks or on other pads, blocks must not overlap.
  // Randomised greedy over windows of the reading-sorted pool (small spread of readings), many trials, best kept.
  let chosen = null;
  if (LETTERS || opt.blocks) {
    const blocks = opt.blocks ? opt.blocks.split(',').map(Number) : null;
    chosen = { pats: cands, blocks };
    if (!blocks) throw new Error('letters= needs blocks= (or use the automatic selection without letters=)');
  } else {
    const padsOf = c => c.rots.filter(r => r.ok).flatMap(r => r.pos);
    // blocks first (S non-overlapping spots in a random order, the control-byte spots sometimes first since no pad can
    // land there), then the patterns whose pads avoid the blocks and each other, fully landing ones first
    const tryOrder = (order, blockOrder) => {
      const blocks = [];   // blocks[i] for species i, with its span
      const placed = [];   // every 128-byte block placed so far
      for (let i = 0; i < S; i++) { const h = blockOrder.find(h => (MBITS(i) === 3 || wideSpot.has(h)) && blocksOf(i, h).every(x => placed.every(b => !overlapB(b, x)))); if (h === undefined) return { pats: [], blocks: [] }; blocks.push(h); placed.push(...blocksOf(i, h)); }
      const inBlock = p => placed.some(b => p >= b - D && p < b - D + 128);
      const pats = [], padPos = new Set();
      for (const c of order) { const pads = padsOf(c); if (pads.some(p => inBlock(p) || padPos.has(p))) continue; pats.push(c); pads.forEach(p => padPos.add(p)); if (pats.length === S) break; }
      return { pats, blocks };
    };
    const full = cands.filter(c => c.full), partial = cands.filter(c => !c.full && c.P.length <= 2);
    let best = null; const rnd0 = (() => { let z = 12345 ^ SEED; return () => { z ^= z << 13; z >>>= 0; z ^= z >>> 17; z ^= z << 5; z >>>= 0; return z / 4294967296; }; })();
    const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd0() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
    const TRIALS = Number(opt.trials ?? 1500);
    for (let t = 0; t < TRIALS; t++) {
      let blockOrder = shuffle(spotsAll); if (rnd0() < 0.5) blockOrder = [...blockOrder.filter(h => !printableSpot.has(h)), ...blockOrder.filter(h => printableSpot.has(h))];
      const order = [...shuffle(full), ...(rnd0() < 0.7 ? shuffle(partial) : partial)];
      const r = tryOrder(order, blockOrder);
      if (r.pats.length < S) { if (!best || r.pats.length > best.n) best = { ...r, n: r.pats.length, cost: Infinity }; continue; }
      const rd = r.pats.map(c => c.reading), cost = Math.max(...rd) - Math.min(...rd) + 0.01 * Math.max(...rd) + 8 * r.pats.filter(c => !c.full).length + 0.3 * r.pats.filter(c => c.P.length > 1).length + 2 * r.blocks.filter(h => !printableSpot.has(h)).length;
      if (!best || best.cost === Infinity || cost < best.cost) best = { ...r, n: S, cost };
    }
    if (!best || best.n < S) throw new Error(`only ${best ? best.n : 0} species fit at V = ${V} (${spotsAll.length} block spots, ${cands.length} patterns, ${full.length} landing in every rotation)`);
    chosen = best;
    if (CYCLES.length === 1) { const order = chosen.blocks.map((h, i) => i).sort((a, b) => chosen.blocks[a] - chosen.blocks[b]); chosen = { pats: order.map(i => chosen.pats[i]), blocks: order.map(i => chosen.blocks[i]) }; }   // species in block order when all cycles are alike
    console.error(`chosen: readings ${chosen.pats.map(c => c.reading).join(' ')} bits; ${chosen.pats.filter(c => c.P.length > 1).length} two-byte and ${chosen.pats.filter(c => c.P.length > 2).length} three-byte patterns, ${chosen.pats.filter(c => !c.full).length} with a rotation that does not land; blocks ${chosen.blocks.join(' ')} (${chosen.blocks.filter(h => !printableSpot.has(h)).length} with control bytes in head byte 1)`);
  }
  patterns = chosen.pats; const blocks = chosen.blocks;
  if (new Set(blocks).size !== S) throw new Error('blocks must be distinct');
  // tails: at 12 header bits one letter (the pattern's first allowed byte) over the ten bytes, as in the first designs; at 13,
  // byte 6 must be 0 mod 8 (the head's last bits), so it takes a class-0 letter and bytes 7..15 repeat the pattern
  const tailOk = v => printable(v) && !lower(v);
  const altOf = v => [v ^ 4, v ^ 8, v ^ 1, v ^ 2].find(tailOk) ?? v;
  const CLASS = []; for (let v = 0x20; v <= 0x7e; v++) if (tailOk(v) && (v & TAIL6_MASK) === TAIL6_FIXED) CLASS.push(v);   // tail byte 6 candidates (its low bits are the head's last bits)
  const alt6 = v => CLASS.find(u => u !== v && POP[u ^ v] === 1) ?? CLASS.find(u => u !== v) ?? v;
  SPECIES = blocks.map((H0, i) => {
    const P = patterns[i].P;
    if (!TAIL6_MASK) { const base = P.find(tailOk) ?? 0x30 + (i % 10); return { name: NAMES[i], index: i, H0, b0: 0x30 + i, P, tail: Array(10).fill(base), alt: Array(10).fill(altOf(base)) }; }
    const b6 = CLASS[i % CLASS.length], tail = [b6], alt = [alt6(b6)];
    for (let j = 1; j < 10; j++) { const v = P[(j - 1) % P.length]; tail.push(tailOk(v) ? v : 0x30); alt.push(altOf(tail[j])); }
    return { name: NAMES[i], index: i, H0, b0: 0x30 + i, P, tail, alt };
  });
  // regions: equal shares of the header range by default, cut between consecutive blocks when they are ordered (bounds=)
  const lo = i => SPECIES[i].H0 - D, hi = i => SPECIES[i].H0 - D + SPAN(i);
  let bounds;
  if (opt.bounds) bounds = opt.bounds.split(',').map(Number);
  else if (HB >= 14) bounds = Array.from({ length: S - 1 }, (_, i) => Math.round(V * (i + 1) / S));   // equal regions; the blocks sit where the heads are printable, not necessarily in their own region
  else bounds = Array.from({ length: S - 1 }, (_, i) => Math.max(hi(i), Math.min(lo(i + 1), Math.round(V * (i + 1) / S))));
  if (HB < 14) for (let i = 0; i < S - 1; i++) if (bounds[i] < hi(i) || bounds[i] > lo(i + 1)) throw new Error(`bound ${bounds[i]} does not separate blocks ${i} and ${i + 1}`);
  REGIONS = SPECIES.map((_, i) => [i ? bounds[i - 1] : 0, i < S - 1 ? bounds[i] : V]);
}
const walkOf = s => WALKS[s.index], lenOf = s => walkOf(s).length;
// the tail byte that carries the walk's parity: byte 6 unless the head fixes its low bits so tightly that no one-bit partner exists, then byte 7
const PARITY_BYTE = SPECIES.every(s => !s.alt || s.alt[0] !== s.tail[0]) ? 0 : 1;
const parity = g => { let c = 0; while (g) { c ^= g & 1; g >>= 1; } return c; };
function stateOf(s, k) {
  const w = walkOf(s), g = w[k % w.length], tail = [];
  if (CLASSIC) for (let j = 0; j < 10; j++) tail.push(TAILGRAY && j < 3 && (g >> j) & 1 ? s.alt[j] : s.tail[j]);
  else for (let j = 0; j < 10; j++) tail.push(TAILGRAY && j === PARITY_BYTE && parity(g) ? s.alt[j] : s.tail[j]);   // the parity byte flips on every one-bit header step
  if (TAIL6_MASK && (tail[0] & TAIL6_MASK) !== TAIL6_FIXED) throw new Error('tail byte 6 does not match the head\'s last bits');
  return Uint8Array.from([...head(s.H0 ^ codeOf(g), D, s.b0), ...tail]);
}
const posOf = (s, k) => { const w = walkOf(s); return (s.H0 ^ codeOf(w[(k + w.length - 1) % w.length])) - D; };
const designed = new Map();   // key -> { species, k }
for (const s of SPECIES) for (let k = 0; k < lenOf(s); k++) designed.set(key(stateOf(s, k)), { species: s.name, k });
const fixed = new Uint8Array(TL).fill(0x20), isFixed = new Uint8Array(TL);
for (const s of SPECIES) for (let k = 0; k < lenOf(s); k++) { const p = posOf(s, k), w = stateOf(s, k); for (let i = 0; i < 16; i++) { if (isFixed[p + i]) throw new Error('blocks overlap'); fixed[p + i] = w[i]; isFixed[p + i] = 1; } }
fixed[TL - 1] = 10; isFixed[TL - 1] = 1;
if (patterns) pads = SPECIES.map((s, i) => { const s0 = stateOf(s, 0); for (const r of patterns[i].rots) if (r.ok) r.pos.forEach((p, j) => { if (isFixed[p] && fixed[p] !== s0[j]) throw new Error(`landing pad of ${s.name} at ${p} collides with a block or another pad`); fixed[p] = s0[j]; isFixed[p] = 1; }); return { pattern: key(Uint8Array.from(patterns[i].P)), reading: patterns[i].reading, full: patterns[i].full, rots: patterns[i].rots.map(r => ({ ok: r.ok, pos: r.pos, consumed: r.consumed, src: r.src })) }; });
// mode=words: filler word per type, the head that maps to state 0 (header H0 + 64), ten searched bytes
const fillers = SPECIES.map(s => ({ b0: s.b0, tail: s.tail.slice() }));
const fillerWord = (s, f) => [...head(s.H0 ^ codeOf(walkOf(s)[lenOf(s) - 1]), D, f.b0), ...f.tail];
function build() {
  const d = fixed.slice();
  SPECIES.forEach((s, i) => {
    const [a, b] = REGIONS[i], w = MODE === 'const' ? s.P : fillerWord(s, fillers[i]), L = w.length;
    const fill = (p, q) => { for (let x = p; x < q; x++) if (!isFixed[x]) d[x] = w[(x - p) % L]; };
    fill(a, b); if (i === S - 1) fill(V, TL - 1);
  });
  return d;
}
// ---- verify the cycles exactly, and the landings
{
  const d = build();
  for (const s of SPECIES) for (let k = 0; k < lenOf(s); k++) {
    const out = decode36(stateOf(s, k), d, OPTS).out;
    if (key(out) !== key(stateOf(s, (k + 1) % lenOf(s)))) throw new Error(`species ${s.name} state ${k} does not map to state ${k + 1}: ${JSON.stringify(key(out))}`);
  }
  if (pads) SPECIES.forEach((s, i) => { pads[i].lands = patterns[i].rots.map(r => { if (!r.ok) return 'not a landing rotation'; const out = decode36(Uint8Array.from(Buffer.from(r.cell, 'latin1')), d, OPTS).out; const hit = designed.get(key(out)); return hit ? `state ${hit.k} of ${hit.species}` : `off-cycle (head ${key(out).slice(0, HEAD_BYTES) === key(stateOf(s, 0)).slice(0, HEAD_BYTES) ? 'of state 0' : 'wrong: ' + JSON.stringify(key(out))})`; }); });
}
// ---- census (Brent), on a fixed set of random cells
function makeCells(n, seed) {
  let rs = seed >>> 0 || 1; const r32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
  return Array.from({ length: n }, () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = r32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; });
}
function census(dict, cells, cap) {
  const f = x => decode36(x, dict, OPTS).out, cycles = new Map(), per = Object.fromEntries([...SPECIES.map(s => [s.name, []]), ['stray', []]]); let unsettled = 0;
  for (const x0 of cells) {
    let power = 1, lam = 1, tortoise = x0, hare = f(x0), steps = 0;
    while (key(tortoise) !== key(hare)) { if (power === lam) { tortoise = hare; power *= 2; lam = 0; } hare = f(hare); lam++; if (++steps > cap) break; }
    if (steps > cap) { unsettled++; continue; }
    let mu = 0; tortoise = x0; hare = x0; for (let k = 0; k < lam; k++) hare = f(hare);
    while (key(tortoise) !== key(hare)) { tortoise = f(tortoise); hare = f(hare); mu++; }
    let c = tortoise, best = key(c), who = null; for (let k = 0; k < lam; k++) { const kk = key(c); if (kk < best) best = kk; if (designed.has(kk)) who = designed.get(kk).species; c = f(c); }
    const rec = cycles.get(best) || { len: lam, count: 0, species: who, example: best }; rec.count++; cycles.set(best, rec);
    per[who || 'stray'].push(mu);
  }
  const n = cells.length, mean = a => a.length ? a.reduce((s, v) => s + v, 0) / a.length : null;
  const all = SPECIES.flatMap(s => per[s.name]).sort((a, b) => a - b), shares = {}; for (const k in per) shares[k] = per[k].length / n;
  const transient = { mean: mean(all), p90: all[Math.floor(0.9 * all.length)] ?? null, max: all[all.length - 1] ?? null }; for (const s of SPECIES) transient[s.name] = mean(per[s.name]);
  return { n, unsettled, cycles: [...cycles.values()].sort((a, b) => b.count - a.count), shares, transient };
}
const WT = Number(opt.wt ?? 0.01);
const score = c => { const sh = SPECIES.map(s => c.shares[s.name]), designedFrac = sh.reduce((a, b) => a + b, 0), balance = S * Math.min(...sh); return designedFrac + 0.5 * balance - 0.5 * c.shares.stray - c.unsettled / c.n - WT * (c.transient.mean ?? 50); };
const cells = makeCells(NS, 0x9e3779b9 ^ SEED);
let rs = (SEED * 2654435761 + 7) >>> 0; const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs / 4294967296; };
const ri = n => Math.floor(rnd() * n);
// ---- const mode, few types: hill-climb the region bounds for equal basins
if (BALANCE && MODE === 'const' && S > 1) {
  const lo = i => SPECIES[i].H0 - D, hi = i => SPECIES[i].H0 - D + SPAN(i);
  const bounds = REGIONS.slice(0, S - 1).map(r => r[1]);
  const evalB = () => { REGIONS = SPECIES.map((_, i) => [i ? bounds[i - 1] : 0, i < S - 1 ? bounds[i] : V]); const c = census(build(), cells, 150); return S * Math.min(...SPECIES.map(s => c.shares[s.name])); };
  let cur = evalB();
  console.error(`balance: start min share x S = ${cur.toFixed(3)} bounds ${bounds.join(',')}`);
  for (let it = 0; it < 60; it++) {
    const i = ri(S - 1), old = bounds[i], a = hi(i), b = lo(i + 1);
    bounds[i] = Math.max(a, Math.min(b, old + Math.round((rnd() - 0.5) * (it < 20 ? 600 : 200))));
    const v = evalB(); if (v >= cur) { if (v > cur) console.error(`balance: iter ${it} ${v.toFixed(3)} bounds ${bounds.join(',')}`); cur = v; } else bounds[i] = old;
  }
  REGIONS = SPECIES.map((_, i) => [i ? bounds[i - 1] : 0, i < S - 1 ? bounds[i] : V]);
}
// ---- words mode: hill-climb the filler bytes
const randPrintable = () => { for (;;) { const v = 0x20 + ri(95); if (lower(v)) continue; return v; } };
let cur = census(build(), cells, 150), curScore = score(cur);
console.error(`start: score ${curScore.toFixed(3)} designed ${(100 * (1 - cur.shares.stray - cur.unsettled / cur.n)).toFixed(1)} % transient ${cur.transient.mean?.toFixed(1)} unsettled ${cur.unsettled}`);
const t0 = Date.now();
for (let it = 0; it < ITERS; it++) {
  const i = ri(S), f = fillers[i], saved = { b0: f.b0, tail: f.tail.slice() };
  const nm = 1 + ri(3);
  for (let m = 0; m < nm; m++) { if (rnd() < 0.1) f.b0 = 0x20 + ri(32); else f.tail[ri(10)] = randPrintable(); }
  const c = census(build(), cells, 150), sc = score(c);
  if (sc >= curScore) { if (sc > curScore + 1e-9) console.error(`iter ${it} (${((Date.now() - t0) / 1000).toFixed(0)} s): score ${sc.toFixed(3)} shares ${JSON.stringify(c.shares)} transient ${c.transient.mean?.toFixed(1)} p90 ${c.transient.p90} unsettled ${c.unsettled}`); cur = c; curScore = sc; }
  else { f.b0 = saved.b0; f.tail = saved.tail; }
}
// ---- final: the dictionary, the full census, the steepness of the funnel, the state table
const dict = build();
const final = census(dict, makeCells(NCENSUS, 12345 + SEED), 4000);
function steepness(dict) {   // on-cycle share after s steps from random cells; return time after a single bit flip of a cycle state
  const f = x => decode36(x, dict, OPTS).out, N = 20000, on = new Array(9).fill(0), cs = makeCells(N, 4242 + SEED);
  for (const c0 of cs) { let x = c0; for (let s = 1; s <= 8; s++) { x = f(x); if (designed.has(key(x))) on[s]++; } }
  const ret = []; let lost = 0, same = 0, tot = 0;
  for (const s of SPECIES) for (let k = 0; k < lenOf(s); k++) for (let b = 0; b < 128; b++) { const x0 = stateOf(s, k); x0[b >> 3] ^= 1 << (b & 7); let x = x0, j; tot++; for (j = 0; j <= 100; j++) { if (designed.has(key(x))) break; x = f(x); } if (j > 100) lost++; else { ret.push(j); if (designed.get(key(x)).species === s.name) same++; } }
  ret.sort((a, b) => a - b);
  return { onCycle: on.slice(1).map(v => v / N), flipReturnMean: ret.reduce((a, b) => a + b, 0) / ret.length, flipReturnP90: ret[Math.floor(0.9 * ret.length)], flipReturnMax: ret[ret.length - 1], flipLost: lost, flipSameSpecies: same / tot };
}
const steep = steepness(dict);
const states = SPECIES.map(s => ({ species: s.name, H0: s.H0, length: lenOf(s), pattern: s.P ? key(Uint8Array.from(s.P)) : String.fromCharCode(s.tail[0]), states: Array.from({ length: lenOf(s) }, (_, k) => ({ k, pos: posOf(s, k), header: s.H0 ^ codeOf(walkOf(s)[k]), text: key(stateOf(s, k)), hammingToNext: ham(stateOf(s, k), stateOf(s, (k + 1) % lenOf(s))) })) }));
const between = {}; for (let a = 0; a < S; a++) for (let b = a + 1; b < S; b++) { let mn = 999, mx = 0; for (let i = 0; i < lenOf(SPECIES[a]); i++) for (let j = 0; j < lenOf(SPECIES[b]); j++) { const h = ham(stateOf(SPECIES[a], i), stateOf(SPECIES[b], j)); mn = Math.min(mn, h); mx = Math.max(mx, h); } between[SPECIES[a].name + SPECIES[b].name] = [mn, mx]; }
const sharedPlanes = SPECIES.map(s => { let n = 0; for (let j = 0; j < 128; j++) { const v = (stateOf(s, 0)[j >> 3] >> (j & 7)) & 1; let same = true; for (let k = 1; k < lenOf(s); k++) if (((stateOf(s, k)[j >> 3] >> (j & 7)) & 1) !== v) { same = false; break; } if (same) n++; } return n; });
fs.mkdirSync(`${dir}/paper/data/design`, { recursive: true });
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.txt`, Buffer.from(dict));
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.json`, JSON.stringify({ name: NAME, mode: MODE, species: S, cycles: SPECIES.map(s => lenOf(s)), V, len: TL, headerBits: HB, letters: LETTERS, patterns: SPECIES.map(s => s.P ? key(Uint8Array.from(s.P)) : null), blocks: SPECIES.map(s => s.H0), bounds: REGIONS.slice(0, S - 1).map(r => r[1]), pads, steep, d: D, tailgray: TAILGRAY, iters: ITERS, N: NS, seed: SEED, speciesTable: SPECIES, regions: REGIONS, fillers: MODE === 'words' ? fillers.map((f, i) => key(Uint8Array.from(fillerWord(SPECIES[i], f)))) : null, searchScore: curScore, states, between: S <= 8 ? between : undefined, sharedPlanes, census: { N: NCENSUS, cap: 4000, ...final, cycles: final.cycles.slice(0, 40).map(c => ({ ...c, example: JSON.stringify(c.example) })) } }, null, 1));
const shareStr = SPECIES.map(s => `${s.name} ${(100 * final.shares[s.name]).toFixed(1)}`).join(', ');
const md = [`# Designed dictionary ${NAME}\n`, `${S} species, V = ${V} (${HB} header bits), ${TL} bytes, mode ${MODE}, patterns ${SPECIES.map(s => JSON.stringify(s.P ? key(Uint8Array.from(s.P)) : String.fromCharCode(s.tail[0]))).join(' ')}, blocks ${SPECIES.map(s => s.H0).join(', ')}, bounds ${REGIONS.slice(0, S - 1).map(r => r[1]).join(', ')}, d = ${D}, tail Gray ${TAILGRAY}${MODE === 'words' ? `, filler search ${ITERS} iterations on ${NS} cells (score ${curScore.toFixed(3)})` : ''}. Census: ${NCENSUS} random cells, cap 4000.\n`,
  '| species | pattern | reading (bits) | H0 | cycle length | state 0 | Hamming per step |', '|---|---|---|---|---|---|---|',
  ...states.map((s, i) => `| ${s.species} | \`${s.pattern.replace(/\|/g, '\\|')}\` | ${pads ? pads[i].reading : ''} | ${s.H0} | ${s.length} | \`${s.states[0].text.replace(/\|/g, '\\|')}\` | ${[...new Set(s.states.map(x => x.hammingToNext))].join('/')} |`),
  `\nPlanes constant along the cycle: ${sharedPlanes[0]} of 128 (${HEAD_END - 6} are read by the decoder).${S <= 8 ? ` Hamming between species (min, max over state pairs): ${JSON.stringify(between)}.` : ''}\n`,
  MODE === 'const' ? `Filler: the patterns tiled over the regions ${JSON.stringify(REGIONS)}; landing pads: ${pads.map((p, i) => `${SPECIES[i].name} ${p.rots.map((r, j) => r.ok ? `${r.pos[0]}..${r.pos[r.pos.length - 1]} (reads ${r.consumed} bits, lands on ${p.lands[j]})` : 'rotation without a landing').join(' and ')}`).join('; ')}\n` : `Filler words: ${fillers.map((f, i) => '`' + key(Uint8Array.from(fillerWord(SPECIES[i], f))) + '`').join(', ')}\n`,
  `## Funnel\n`, `On a designed cycle after 1..8 steps from random cells: ${steep.onCycle.map(v => (100 * v).toFixed(1) + ' %').join(', ')}. After one bit flip of a cycle state (${SPECIES.reduce((a, s) => a + lenOf(s), 0) * 128} cases): return in ${steep.flipReturnMean.toFixed(1)} steps mean, p90 ${steep.flipReturnP90}, max ${steep.flipReturnMax}, lost (> 100) ${steep.flipLost}, same species ${(100 * steep.flipSameSpecies).toFixed(1)} %.\n`,
  `## Census\n`, `Shares (%): ${shareStr}, stray ${(100 * final.shares.stray).toFixed(2)}, unsettled ${final.unsettled}. Transient mean ${final.transient.mean?.toFixed(1)}, p90 ${final.transient.p90}, max ${final.transient.max}.\n`,
  '| cycle | length | basin | species |', '|---|---|---|---|', ...final.cycles.slice(0, S + 6).map(c => `| \`${JSON.stringify(c.example)}\` | ${c.len} | ${(100 * c.count / final.n).toFixed(2)} % | ${c.species || 'stray'} |`)];
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.md`, md.join('\n') + '\n');
console.log(md.join('\n'));
