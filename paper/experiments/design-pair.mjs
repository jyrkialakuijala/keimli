// Design dictionaries for the pair modes of the Brotli-like decoder (kind 36, skip 6): pixels 2i and 2i+1 joined into a
// 32-byte cell (mode 1 concatenated, 2 bit-interleaved, 3 nibble-interleaved, 5 byte-interleaved), decoded as one
// stream (bits wrap at 256, 32 bytes out) and split back, the roles of the two cells swapping every turn.
//
// Construction. Let J be the joint cell as the decoder sees it this turn. Its first bits read "no literals, copies
// from the dictionary adding up to 32 bytes at a distance d ≥ 32", a pointer to a 32-byte word W; the split hands the
// cells W's two parts, and next turn, with the roles swapped, the decoder sees swap(W), where swap is the mode's role
// exchange (halves, bit pairs, nibbles, byte pairs). So a cycle J_0 .. J_7 needs the word swap(J_{k+1}) at J_k's
// pointer: every state has one word, the two cells of a pair differ, and the pair walks the cycle whichever cell
// leads. The joint heads walk a Gray code on header bits (8-cycles), slots 32 bytes apart. Printability: every byte of
// every word, i.e. of every swap(J), must be printable, so J's head bytes are drawn from an alphabet closed under the
// mode's swap: mode 1 and 5 any printable non-lowercase byte, mode 2 the sixteen bytes 0..? (0x30..0x3F: bits 4, 5
// set and 6, 7 clear survive the bit-pair swap), mode 3 bytes whose two nibbles are both in 2..5. The command form
// (copy lengths, distance, transforms) is searched for the one with the most header spots within the alphabet.
// Filler: constant byte regions with landing pads, as design-dict.mjs; the all-X joint cell (width 32) must copy
// dictionary bytes into the positions that become the next joint's head after the swap.
// Usage: node paper/experiments/design-pair.mjs mode=1|2|3|4|5 [species=3] [V=60000] [len=61440] [name=] [census=10000] [seed=1]
import fs from 'node:fs';
import { decode36, rangeBits, joinPair, splitPair } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const MODE = Number(opt.mode ?? 1), S = Number(opt.species ?? 3);
const V = Number(opt.V ?? 60000), TL = Number(opt.len ?? (V > 8192 ? 61440 : 4400)), HB = rangeBits(V), SKIP = 6, OPTS = { skip: SKIP, V, coff: 0, width: 32 };
const MODENAME = { 1: 'cat', 2: 'bit', 3: 'nib', 4: 'bit2', 5: 'byte' }[MODE]; if (!MODENAME) throw new Error('mode 1, 2, 3, 4 or 5');
const NAME = opt.name || `ca-pair${MODENAME}${S}`, SEED = Number(opt.seed ?? 1), NCENSUS = Number(opt.census ?? 10000);
const key = c => Buffer.from(c).toString('latin1');
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const printable = v => v >= 0x20 && v <= 0x7e, lower = v => v >= 0x61 && v <= 0x7a, upper = v => v >= 0x41 && v <= 0x5a;
const gray = k => k ^ (k >> 1);
// the role swap on a joint cell. Only the dictionary word W = swap(J) must be printable, not the joint J itself, so a
// head byte b of J is allowed when its swapped image is printable and not lowercase: for the byte-level modes (1, 5)
// the swap moves whole bytes, so any printable non-lowercase byte; for bits, b with bit 6 clear and bit 4 or 5 set
// (its pair-swapped image is then in 0x20..0x7E and not a letter); for nibbles, b whose low nibble is 2..5 or 7, 6 with
// a zero high nibble excepted, so that the swapped byte is printable and not lowercase.
const swapJ = j => { const [a, b] = splitPair(j, MODE, 0); return joinPair(b, a, MODE, 0); };
const swapByte = b => MODE === 2 ? (((b & 0x55) << 1) | ((b & 0xaa) >> 1)) : MODE === 3 ? (((b & 15) << 4) | (b >> 4)) : MODE === 4 ? (((b & 0x33) << 2) | ((b & 0xcc) >> 2)) : b;
const ALPHA = []; for (let v = 0; v < 256; v++) { const w = swapByte(v); if (printable(w) && !lower(w)) ALPHA.push(v); }
const inAlpha = new Uint8Array(256); for (const v of ALPHA) inAlpha[v] = 1;
const hasUpper = ALPHA.some(v => upper(swapByte(v)));
// ---- the joint head: header h and a sequence of copies written as joint bits from bit 6
const putBits = (cell, bp, v, n) => { for (let i = 0; i < n; i++, bp++) if ((v >> i) & 1) cell[bp >> 3] |= 1 << (bp & 7); return bp; };
function headJ(h, form) {
  const c = new Uint8Array(32); let bp = putBits(c, 6, h, HB);
  for (const cmd of form.cmds) {
    bp = putBits(c, bp, 0, 2);
    if (cmd.len <= 3) bp = putBits(c, bp, cmd.len - 2, 2); else if (cmd.len <= 5) { bp = putBits(c, bp, 2, 2); bp = putBits(c, bp, cmd.len - 4, 1); } else { bp = putBits(c, bp, 3, 2); bp = putBits(c, bp, cmd.len - 6, 3); }
    if (cmd.explicit) { bp = putBits(c, bp, 1, 1); bp = putBits(c, bp, form.d - 1, 6); } else { bp = putBits(c, bp, 0, 1); bp = putBits(c, bp, 0, 4); }
    bp = putBits(c, bp, form.tf, 2);
  }
  return { c, end: bp };
}
function* forms() {
  const lens = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], seqs = [];
  const rec = (acc, sum) => { if (sum === 32 && acc.length >= 2) seqs.push(acc.slice()); if (sum >= 32 || acc.length === 4) return; for (const l of lens) if (sum + l <= 32) { acc.push(l); rec(acc, sum + l); acc.pop(); } };
  rec([], 0);
  const tfs = [0, 1, 2]; if (!hasUpper) tfs.push(3);   // the copied bytes are dictionary bytes, never lowercase, so 1 and 2 change nothing; 3 only when no word byte is uppercase
  for (const seq of seqs) for (let e = 0; e < 1 << (seq.length - 1); e++) {
    const cmds = seq.map((len, i) => ({ len, explicit: i === 0 || !!((e >> (i - 1)) & 1) }));
    for (let d = 32; d <= 64; d++) for (const tf of tfs) yield { cmds, d, tf };
  }
}
// Gray bits: any three header bits from 5 upwards (slot moves of 32 or more); the set with the most header spots wins
const GRAYSETS = []; for (let a = 5; a <= 13; a++) for (let b = a + 1; b <= 13; b++) for (let c = b + 1; c <= 13; c++) GRAYSETS.push([a, b, c]);
const codeOf = (g, bits) => (((g & 1) << bits[0]) | (((g >> 1) & 1) << bits[1]) | ((g >> 2) << bits[2]));
const fillFree = c => { for (let f = 0; f < 64; f++) if (inAlpha[(c[0] & 0xc0) | f]) { c[0] = (c[0] & 0xc0) | f; return c; } return c; };   // the six skipped bits: any value that keeps byte 0 in the alphabet
const HEADER_BYTES = Math.ceil((6 + HB + 2) / 8);   // the bytes holding header bits (and the first command's literal code 00)
function headOk(h, form, bytes) { if (h >= V || h - form.d < 0) return false; const { c } = headJ(h, form); fillFree(c); for (let i = 0; i < bytes; i++) if (!inAlpha[c[i]]) return false; return true; }
// A header's own bytes depend on h alone (the literal code after it is always 00), so they are tested once for every h;
// the command bytes after them depend on the form alone. Headers keep a fixed offset OFF within the 32-byte slot spacing
// (h = OFF + 32 m): nibble interleaving needs header bits 3 or 4 set for byte 1's low nibble.
const validH = new Uint8Array(V); { const probe = { cmds: [{ len: 13, explicit: true }, { len: 13, explicit: true }, { len: 6, explicit: true }], d: 33, tf: 0 }; for (let h = 0; h < V; h++) { const { c } = headJ(h, probe); fillFree(c); let ok = true; for (let i = 0; i < HEADER_BYTES; i++) if (!inAlpha[c[i]]) ok = false; validH[h] = ok ? 1 : 0; } }
let bestGeom = null;   // offset and Gray bits with the most header spots
for (let OFF = 0; OFF < 32; OFF++) for (const bits of GRAYSETS) {
  const mask = codeOf(7, bits); let spots = 0;
  for (let H0 = OFF; H0 < V; H0 += 32) { if (H0 & mask) continue; let ok = true; for (let g = 0; g < 8 && ok; g++) { const h = H0 ^ codeOf(gray(g), bits); if (h >= V || h < 64 || !validH[h]) ok = false; } if (ok) spots++; }
  if (spots && (!bestGeom || spots > bestGeom.spots)) bestGeom = { OFF, bits, spots };
}
if (!bestGeom) throw new Error(`no header fits the alphabet (mode ${MODE}, V ${V})`);
let best = null, nForms = 0;
for (const form of forms()) {
  nForms++;
  const { end } = headJ(0, form), bytes = Math.ceil(end / 8);
  const { c } = headJ(0, form); fillFree(c); let bad = false; for (let i = HEADER_BYTES; i < bytes; i++) if (!inAlpha[c[i]]) bad = true; if (bad) continue;   // the command bytes, independent of h
  if (!best || end < best.end) best = { ...form, ...bestGeom, end, bytes };
}
if (!best) {
  let diag = null;   // the form whose header-free bytes come closest
  for (const form of forms()) { const { end } = headJ(0, form), bytes = Math.ceil(end / 8), { c } = headJ(0, form); fillFree(c); let bad = 0; const which = []; for (let i = Math.ceil((6 + HB) / 8); i < bytes; i++) if (!inAlpha[c[i]]) { bad++; which.push(i + ':' + c[i].toString(16)); } if (!diag || bad < diag.bad) diag = { bad, which, form, bytes }; }
  throw new Error(`no head form within the alphabet among ${nForms} (mode ${MODE}, V ${V}); closest: copies ${diag.form.cmds.map(c => c.len + (c.explicit ? 'e' : 'r')).join('+')} d ${diag.form.d} tf ${diag.form.tf}, ${diag.bad} bytes outside the alphabet (${diag.which.join(' ')})`);
}
const FORM = best, D = FORM.d, HEAD_BYTES = FORM.bytes, BITS = FORM.bits, GMASK = codeOf(7, BITS);
console.error(`mode ${MODE} (${MODENAME}), V ${V} (${HB} header bits), head alphabet ${ALPHA.length} bytes: ${nForms} forms; chosen copies ${FORM.cmds.map(c => c.len + (c.explicit ? 'e' : 'r')).join('+')} at d ${D}, tf ${FORM.tf}, header offset ${FORM.OFF}, Gray bits ${BITS.join(',')}: head ${FORM.end} bits (${HEAD_BYTES} bytes), ${FORM.spots} header spots`);
// header spots at every offset within the slot spacing (a letter whose all-X cell starts with a literal needs header bits 0, 1 to match it)
const spotsAll = []; for (let H0 = 64; H0 < V; H0++) { if (H0 & GMASK) continue; let ok = true; for (let g = 0; g < 8 && ok; g++) if (!headOk(H0 ^ codeOf(gray(g), BITS), FORM, HEAD_BYTES)) ok = false; if (ok) spotsAll.push(H0); }
console.error(`${spotsAll.length} header spots over all offsets`);
// ---- landing pads: the all-X joint must copy dictionary bytes into the word positions that become the next head after the swap
const srcIndex = Array.from({ length: 32 }, (_, q) => MODE === 1 ? (q + 16) % 32 : MODE === 5 ? q ^ 1 : q);   // next head byte q comes from W byte srcIndex[q] (the bit and nibble swaps stay inside the byte)
// The landing only has to get the next head right: the output bytes that become it come from the first commands of the
// all-X joint's own decoding (the pad), so the pad must cover the joint bytes holding the head and those commands whose
// copies add up to the head's length; the later commands may read junk and only spoil the tail, restored next turn.
const PAD_BYTES = (() => { let bp = 6 + HB, made = 0; for (const cmd of FORM.cmds) { bp += 2 + (cmd.len <= 3 ? 2 : cmd.len <= 5 ? 3 : 5) + (cmd.explicit ? 7 : 5) + 2; made += cmd.len; if (made >= HEAD_BYTES) break; } return Math.ceil(bp / 8); })();
const PAD_INDEX = [...new Set(Array.from({ length: Math.max(PAD_BYTES, 1) }, (_, q) => srcIndex[q]))];
const DUMMY = new Uint8Array(TL).fill(0x20);
function padOne(X) {   // the pad positions the all-X joint reads for the head bytes of the next joint; a literal at word byte 0 is allowed
  const r = decode36(new Uint8Array(32).fill(X), DUMMY, OPTS); let di = 0; const posAt = [];
  for (let i = 0; i < 32; i++) posAt[i] = r.src[i] === 2 ? r.dictPos[di++] : -1;
  let lit0 = null; const pos = [], index = [];
  for (const i of PAD_INDEX) {
    if (posAt[i] >= 0) { pos.push(posAt[i]); index.push(i); continue; }
    // a literal: its value comes from the letter's own bits; only word byte 0 can be made to match it (the joint's byte 0 has six free bits)
    if (r.src[i] === 0 && i === 0 && printable(r.out[0]) && !lower(r.out[0])) { lit0 = r.out[0]; continue; }
    return null;
  }
  if (new Set(pos).size !== pos.length) return null;
  return { pos, index, lit0, consumed: r.consumed };
}
// a filler letter X whose all-X joint does not survive the role swap (bits, nibbles) appears as all-swap(X) every other
// turn, so both cells need a pad, both holding the same word bytes; positions read by both must agree
function padOf(X) {
  const a = padOne(X); if (!a) return null;
  const Y = swapByte(X); if (Y === X) return { X, pos: a.pos, index: a.index, lit0: a.lit0, consumed: a.consumed };
  if (!printable(Y) || lower(Y)) return null;
  const b = padOne(Y); if (!b) return null;
  if (a.lit0 !== null && b.lit0 !== null && a.lit0 !== b.lit0) return null;   // both cells would fix word byte 0 to different values
  const lit0 = a.lit0 ?? b.lit0;
  const pos = a.pos.slice(), index = a.index.slice();
  for (let j = 0; j < b.pos.length; j++) { const k = pos.indexOf(b.pos[j]); if (k >= 0) { if (index[k] !== b.index[j]) return null; continue; } pos.push(b.pos[j]); index.push(b.index[j]); }
  if (lit0 !== null && index.includes(0)) return null;   // one cell reads byte 0 from the dictionary, the other writes a literal there: both cannot hold
  return { X, pos, index, lit0, consumed: Math.max(a.consumed, b.consumed), partner: Y };
}
// the filler letter must survive the role swap, or the all-X joint of one turn is a different cell the next turn (bit mode: 0 3 < ?)
const swapInvariant = X => key(swapJ(new Uint8Array(32).fill(X))) === key(new Uint8Array(32).fill(X));
if (process.env.DEBUG_PAD) for (const ch of (process.env.DEBUG_PAD.length > 1 ? [...process.env.DEBUG_PAD] : ['3', '7', '%', 'R', '"'])) { const X = ch.charCodeAt(0), r = decode36(new Uint8Array(32).fill(X), DUMMY, OPTS); console.error(`pad debug ${ch}: swap ${swapByte(X).toString(16)} src ${Array.from(r.src).map(v => 'LSD.'[v]).join('')} pos ${r.dictPos.slice(0, 12).join(',')} -> ${JSON.stringify(padOf(X))}`); }
const letters = []; for (let v = 0x20; v <= 0x7e; v++) if (!lower(v)) { const p = padOf(v); if (p) letters.push(p); }
letters.sort((a, b) => a.consumed - b.consumed);
console.error(`filler letters that land (${PAD_INDEX.length} pad bytes of ${HEAD_BYTES} head bytes): ${letters.map(l => JSON.stringify(String.fromCharCode(l.X)) + (l.partner ? '/' + JSON.stringify(String.fromCharCode(l.partner)) : '') + ':' + l.consumed + (l.lit0 !== null ? ' lit ' + JSON.stringify(String.fromCharCode(l.lit0)) : '')).join(' ')}`);
// ---- species packing
const SLOT = 32, slotsOf = H0 => Array.from({ length: 8 }, (_, k) => (H0 ^ codeOf(gray(k), BITS)) - D);
let rs = (SEED * 2654435761 + 7) >>> 0; const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs / 4294967296; };
const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
let pick = null;
for (let t = 0; t < 400; t++) {
  const chosen = [], used = [], padPos = new Set(), inSlots = p => used.some(s => p >= s && p < s + SLOT);
  for (const H0 of shuffle(spotsAll)) {
    if (chosen.length === S) break;
    const sl = slotsOf(H0); if (sl.some(s => used.some(u => Math.abs(u - s) < SLOT) || [...padPos].some(p => p >= s && p < s + SLOT))) continue;
    const L = shuffle(letters).find(l => !chosen.some(c => c.letter.X === l.X) && !l.pos.some(p => inSlots(p) || sl.some(s => p >= s && p < s + SLOT) || padPos.has(p)) && (l.lit0 === null || (swapByte(l.lit0) >> 6) === (H0 & 3)));
    if (!L) continue;
    chosen.push({ H0, letter: L }); used.push(...sl); L.pos.forEach(p => padPos.add(p));
  }
  const spread = chosen.length ? Math.max(...chosen.map(c => c.letter.consumed)) - Math.min(...chosen.map(c => c.letter.consumed)) : 0;
  if (!pick || chosen.length > pick.chosen.length || (chosen.length === pick.chosen.length && spread < pick.spread)) pick = { chosen, spread };
}
if (!pick || pick.chosen.length < S) throw new Error(`only ${pick ? pick.chosen.length : 0} species fit (${spotsAll.length} spots, ${letters.length} letters)`);
const NAMES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const TAILS = ALPHA.filter(v => printable(v) && !lower(v) && v !== 0x30);   // tail bytes of the joint (unread): one per species, plus a one-bit partner for the parity byte
const altOf = v => TAILS.find(u => u !== v && POP[u ^ v] === 1) ?? TAILS.find(u => u !== v);
const SPECIES = pick.chosen.map((c, i) => ({ name: NAMES[i], H0: c.H0, letter: c.letter, b0: c.letter.lit0 !== null ? swapByte(c.letter.lit0) & 63 : null, tail: TAILS[i % TAILS.length], alt: altOf(TAILS[i % TAILS.length]) }));
// ---- joint states, words, cells
function jointOf(s, k) {
  const g = gray(k), { c } = headJ(s.H0 ^ codeOf(g, BITS), FORM); if (s.b0 !== null) c[0] = (c[0] & 0xc0) | s.b0; else fillFree(c);   // byte 0's free bits: the letter's literal (swapped), or any alphabet value
  const par = POP[g] & 1;
  for (let j = HEAD_BYTES; j < 32; j++) c[j] = j === HEAD_BYTES && par ? s.alt : s.tail;
  return c;
}
const posOf = (s, k) => (s.H0 ^ codeOf(gray(k), BITS)) - D;   // where J_k points: the word swap(J_{k+1}) lives there
const cellsOf = (s, k) => splitPair(jointOf(s, k), MODE, 0);
const designedCells = new Map(), designedJoints = new Map();
for (const s of SPECIES) for (let k = 0; k < 8; k++) { designedJoints.set(key(jointOf(s, k)), { species: s.name, k }); for (const c of cellsOf(s, k)) designedCells.set(key(c), { species: s.name, k }); }
// ---- build
const dict = new Uint8Array(TL), isFixed = new Uint8Array(TL);
SPECIES.forEach((s, i) => { const a = Math.round(V * i / S), b = i === S - 1 ? TL - 1 : Math.round(V * (i + 1) / S); for (let p = a; p < b; p++) dict[p] = s.letter.X; });
dict[TL - 1] = 10;
for (const s of SPECIES) for (let k = 0; k < 8; k++) { const p = posOf(s, k), w = swapJ(jointOf(s, (k + 1) % 8)); for (let i = 0; i < 32; i++) { if (isFixed[p + i] && dict[p + i] !== w[i]) throw new Error('slots overlap'); dict[p + i] = w[i]; isFixed[p + i] = 1; } }
for (const s of SPECIES) { const w0 = swapJ(jointOf(s, 1)); s.letter.pos.forEach((p, j) => { const i = s.letter.index[j]; if (isFixed[p] && dict[p] !== w0[i]) throw new Error(`pad of ${s.name} collides at ${p}`); dict[p] = w0[i]; isFixed[p] = 1; }); }   // the all-X joint lands on the word of state 0, so the next joint is J_1
for (const v of dict.subarray(0, TL - 1)) if (!printable(v)) throw new Error('non-printable byte ' + v);
// ---- verify: from the pair holding J_k at either role order, one turn gives a pair whose joint at the other role order is J_{k+1}
const step = (a, b, flip) => { const out = decode36(joinPair(a, b, MODE, flip), dict, OPTS).out; return splitPair(out, MODE, flip); };
for (const s of SPECIES) for (let k = 0; k < 8; k++) for (const flip of [0, 1]) {
  const [a0, b0] = cellsOf(s, k), pair = flip ? [b0, a0] : [a0, b0];   // so that joinPair(pair, flip) = J_k
  const [a, b] = step(pair[0], pair[1], flip), next = joinPair(a, b, MODE, flip ^ 1);
  if (key(next) !== key(jointOf(s, (k + 1) % 8))) throw new Error(`species ${s.name} state ${k} flip ${flip}: next joint ${JSON.stringify(key(next))} expected ${JSON.stringify(key(jointOf(s, (k + 1) % 8)))}`);
}
// ---- census: random pairs under the alternating roles until the joint as seen is a designed state
function makeCells(n, seed) { let z = seed >>> 0 || 1; const r = () => { z ^= z << 13; z >>>= 0; z ^= z >>> 17; z ^= z << 5; z >>>= 0; return z; }; return Array.from({ length: n }, () => Uint8Array.from({ length: 16 }, () => r() & 255)); }
function census(n, seed, cap) {
  const A = makeCells(n, seed), B = makeCells(n, seed ^ 0x5bd1e995), per = Object.fromEntries([...SPECIES.map(s => [s.name, 0]), ['none', 0]]), trans = []; let onBy8 = 0;
  for (let i = 0; i < n; i++) {
    let a = A[i], b = B[i], hit = -1, who = null;
    for (let t = 0; t < cap; t++) { const dj = designedJoints.get(key(joinPair(a, b, MODE, t & 1))); if (dj) { hit = t; who = dj.species; break; } [a, b] = step(a, b, t & 1); }
    if (hit >= 0) { per[who]++; trans.push(hit); if (hit <= 8) onBy8++; } else per.none++;
  }
  trans.sort((x, y) => x - y);
  return { shares: Object.fromEntries(Object.entries(per).map(([k, v]) => [k, v / n])), transientMean: trans.reduce((s, v) => s + v, 0) / (trans.length || 1), p90: trans[Math.floor(0.9 * trans.length)] ?? null, max: trans[trans.length - 1] ?? null, onBy8: onBy8 / n };
}
const cen = census(NCENSUS, 4242 + SEED, 400);
fs.mkdirSync(`${dir}/paper/data/design`, { recursive: true });
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.txt`, Buffer.from(dict));
const hamJ = (s, k) => { const a = jointOf(s, k), b = jointOf(s, (k + 1) % 8); let n = 0; for (let i = 0; i < 32; i++) n += POP[a[i] ^ b[i]]; return n; };
const states = SPECIES.map(s => ({ species: s.name, H0: s.H0, letter: String.fromCharCode(s.letter.X), reading: s.letter.consumed,
  states: Array.from({ length: 8 }, (_, k) => { const [a, b] = cellsOf(s, k); return { k, pos: posOf(s, k), header: s.H0 ^ codeOf(gray(k), BITS), joint: key(jointOf(s, k)), text: key(a), texts: [key(a), key(b)], hammingToNext: hamJ(s, k) }; }) }));
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.json`, JSON.stringify({ name: NAME, pairMode: MODE, species: S, cycles: SPECIES.map(() => 8), V, len: TL, headerBits: HB, form: { cmds: FORM.cmds, d: D, tf: FORM.tf, grayBits: BITS, headerOffset: FORM.OFF }, headBytes: HEAD_BYTES, alphabetSize: ALPHA.length, states, census: cen }, null, 1));
const md = [`# Designed pair dictionary ${NAME}\n`, `pair mode ${MODE} (${MODENAME}), ${S} species of 8-cycles, V = ${V} (${HB} header bits), ${TL} bytes; copies ${FORM.cmds.map(c => c.len).join(' + ')} at distance ${D}, transform ${FORM.tf}; head ${FORM.end} bits; Gray bits ${BITS.join(', ')}; ${ALPHA.length} head bytes allowed.\n`,
  '| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |', '|---|---|---|---|---|---|---|',
  ...states.map(s => `| ${s.species} | \`${s.letter}\` | ${s.reading} | ${s.H0} | \`${s.states[0].joint.replace(/\|/g, '\\|')}\` | ${s.states[0].texts.map(t => JSON.stringify(t)).join(' ')} | ${[...new Set(s.states.map(x => x.hammingToNext))].join('/')} |`),
  `\n## Census (random pairs, roles alternating, ${NCENSUS} pairs)\n`, `Joint on a designed cycle: ${Object.entries(cen.shares).map(([k, v]) => `${k} ${(100 * v).toFixed(1)} %`).join(', ')}; within 8 turns ${(100 * cen.onBy8).toFixed(1)} %; transient mean ${cen.transientMean.toFixed(1)}, p90 ${cen.p90}, max ${cen.max}.\n`];
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.md`, md.join('\n') + '\n');
console.log(md.join('\n'));
