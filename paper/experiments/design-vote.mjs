// Design a dictionary for a cell rewritten together with its 4-neighbour vote (the page's Cells entries "Self and its
// 4-neighbour vote", pair modes 8 + m: m = 2 bits, 4 two bits, 3 nibbles, 5 bytes), for the Brotli-like decoder (kind 36, skip 6).
//
// In a synchronised domain the vote equals the cell, so the joint cell J the decoder sees is the cell S in its doubled
// form, dup(S) = join(S, S), whichever role leads. A cycle S_0 .. S_7 then needs, at the pointer that J_k = dup(S_k)
// reads, the word dup(S_{k+1}): both halves of the split are S_{k+1}, so the cell gets it in either role and the vote
// half is discarded. The words live in a text file the page reads as UTF-8, so every word byte must be below 0x80 and
// no line end; joint bytes 2m and 2m+1 come from cell byte m (its two halves in the bit, two-bit and nibble joinings,
// the byte twice in the byte joining), so the allowed cell bytes are those whose doubled images are such bytes. In the
// byte joining letters are excluded too, since a transform would change them.
// The head of J (header, then copy commands adding up to 32 bytes at one distance d >= 32, so that the output is one
// contiguous dictionary word) is found by enumerating the joint bytes after the header over the allowed images and
// parsing them as the decoder does; the header bytes (cell byte 0 and the low bits of byte 1) then give the windows, and
// a Gray walk on three bits of cell byte 0 that move the window by 32 or more gives an 8-cycle. Filler: constant regions
// of a letter X with landing pads for the doubled cell that a filler copy produces, as design-pair.mjs.
// Usage: node paper/experiments/design-vote.mjs mode=2|3|4|5 [species=1] [V=60000] [len=61440] [name=] [census=10000] [seed=1]
import fs from 'node:fs';
import { decode36, rangeBits, joinPair, splitPair } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const MODE = Number(opt.mode ?? 2), V = Number(opt.V ?? 60000), TL = Number(opt.len ?? 61440), HB = rangeBits(V), SKIP = 6, OPTS = { skip: SKIP, V, coff: 0, width: 32 };
const MODENAME = { 2: 'bit', 3: 'nib', 4: 'bit2', 5: 'byte' }[MODE]; if (!MODENAME) throw new Error('mode 2, 3, 4 or 5');
const S = Number(opt.species ?? 1), SEED = Number(opt.seed ?? 1), NCENSUS = Number(opt.census ?? 10000);
const key = c => Buffer.from(c).toString('latin1');
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const printable = v => v >= 0x20 && v <= 0x7e, lower = v => v >= 0x61 && v <= 0x7a, letter = v => lower(v) || (v >= 0x41 && v <= 0x5a);
const gray = k => k ^ (k >> 1);
const dup = cell => joinPair(cell, cell, MODE, 0);
const evenHalf = j => splitPair(j, MODE, 0)[0];
const safeByte = v => v < 0x80 && v !== 10 && v !== 13 && (MODE !== 5 || !letter(v)) && (!process.env.PRINTABLE || (printable(v) && !lower(v)));
const CELLBYTES = [], DUP = new Map();   // cell byte value -> its two joint bytes
for (let v = 0; v < 256; v++) { const j = dup(new Uint8Array(16).fill(v)); if (safeByte(j[0]) && safeByte(j[1])) { CELLBYTES.push(v); DUP.set(v, [j[0], j[1]]); } }
const inCell = new Uint8Array(256); for (const v of CELLBYTES) inCell[v] = 1;
console.error(`mode ${MODE} (${MODENAME}): ${CELLBYTES.length} cell byte values allowed; V ${V}, ${HB} header bits`);
// ---- the command grammar on a joint byte string, from bit 6 + HB: copies summing to 32 at one distance (no literals)
const bitAt = (c, bp) => (c[bp >> 3] >> (bp & 7)) & 1;
const bits = (c, bp, n) => { let v = 0; for (let i = 0; i < n; i++) v |= bitAt(c, bp + i) << i; return v; };
function parse(c, limitBits) {   // -> { cmds, d, tf, end } or null
  let bp = 6 + HB, made = 0, d = -1, tf = -1; const cmds = [];
  while (made < 32) {
    if (bp + 2 > limitBits) return null;
    if (bits(c, bp, 2) !== 0) return null; bp += 2;   // no literals
    const code = bits(c, bp, 2); bp += 2; let len = code + 2;
    if (code === 2) { len = 4 + bits(c, bp, 1); bp += 1; } else if (code === 3) { len = 6 + bits(c, bp, 3); bp += 3; }
    let explicit;
    if (bits(c, bp, 1)) { const dd = 1 + bits(c, bp + 1, 6); bp += 7; if (d < 0) d = dd; else if (dd !== d) return null; explicit = true; }
    else { if (d < 0 || bits(c, bp + 1, 4) !== 0) return null; bp += 5; explicit = false; }   // the ring's slot 0: the same distance again
    const t = bits(c, bp, 2); bp += 2; if (tf < 0) tf = t; else if (t !== tf) return null;
    if (bp > limitBits) return null;
    cmds.push({ len, explicit }); made += len;
  }
  if (made !== 32 || d < 32) return null;
  return { cmds, d, tf, end: bp };
}
// ---- enumerate the joint bytes after the header's first two bytes (cell bytes 1..NTAIL) and keep the parses
const HDR_END = 6 + HB, HDR_CELL = Math.ceil(HDR_END / 16);   // cell bytes that hold header bits (2 for 16 header bits: bits 6..21 reach joint byte 2 = cell byte 1)
const NTAIL = 4;   // cell bytes 1..4 enumerated: joint bytes 2..9, 80 bits, enough for three copy commands
const tails = new Map();   // command-tail key -> { form, tail (cell bytes 1..NTAIL) }
{
  const c = new Uint8Array(32), cell = new Uint8Array(16); let tried = 0;
  const rec = m => {
    if (m > NTAIL) {
      tried++;
      const r = parse(c, 16 + 16 * NTAIL); if (!r) return;
      const k = `${r.cmds.map(x => x.len + (x.explicit ? 'e' : 'r')).join('+')}|${r.d}|${r.tf}|${Array.from(cell.subarray(1, NTAIL + 1)).join(',')}`;
      tails.set(k, { form: r, tail: Array.from(cell.subarray(1, NTAIL + 1)) });
      return;
    }
    for (const v of CELLBYTES) { cell[m] = v; const [e, o] = DUP.get(v); c[2 * m] = e; c[2 * m + 1] = o; rec(m + 1); }
  };
  // cell byte 0 does not matter for the parse (its bits are header), set it to any allowed value
  cell[0] = CELLBYTES[0]; [c[0], c[1]] = DUP.get(cell[0]);
  rec(1);
  console.error(`${tried} tails tried, ${tails.size} parse as a pointer`);
}
if (!tails.size) throw new Error('no head form fits');
// ---- for every tail: the windows over the header bits of cell bytes 0 and 1, and the Gray bases: three cell bits whose
// doubled images lie in the skip and header bits only (so the parse is unchanged) and move the window by 32 or more
const headerOf = (v0, v1, tail) => { const c = new Uint8Array(6); [c[0], c[1]] = DUP.get(v0); [c[2], c[3]] = DUP.get(v1); [c[4], c[5]] = DUP.get(tail[1]); return bits(c, 6, HB); };
const imageOf = t => { const z = new Uint8Array(16), o = new Uint8Array(16); o[t >> 3] = 1 << (t & 7); const a = dup(z), b = dup(o); const l = []; for (let bp = 0; bp < 256; bp++) if (bitAt(a, bp) !== bitAt(b, bp)) l.push(bp); return l; };
// a cell bit is usable when its doubled image touches only skipped bits (below 6) and header bits 5 and up (joint bits 11 to 6 + HB - 1): the window moves by 32 or more and the parse is untouched
const GRAYBITS = []; for (let t = 0; t < 16; t++) { const img = imageOf(t); if (img.every(bp => bp < 6 || (bp >= 11 && bp < 6 + HB)) && img.some(bp => bp >= 11)) GRAYBITS.push(t); }
console.error(`cell bits usable for the Gray walk: ${GRAYBITS.join(' ')}`);
const candidates = [];   // { tail, form, v0, v1 (base bytes 0 and 1), gb, codeOf (16-bit mask over cell bytes 0 and 1), wins }
for (const { form, tail } of tails.values()) {
  const ok = (v0, v1) => { if (!inCell[v0] || !inCell[v1]) return false; const h = headerOf(v0, v1, tail); return h < V && h - form.d >= 0 && h - form.d + 32 <= TL - 1; };
  for (const v0 of CELLBYTES) {
    for (let a = 0; a < GRAYBITS.length; a++) for (let b = a + 1; b < GRAYBITS.length; b++) for (let cc = b + 1; cc < GRAYBITS.length; cc++) {
      const gb = [GRAYBITS[a], GRAYBITS[b], GRAYBITS[cc]], codeOf = g => ((g & 1) << gb[0]) | (((g >> 1) & 1) << gb[1]) | ((g >> 2) << gb[2]);
      const base = v0 | (tail[0] << 8); if (base & codeOf(7)) continue;   // the base has the Gray bits clear
      let good = true; const wins = [];
      for (let g = 0; g < 8 && good; g++) { const v = base ^ codeOf(gray(g)); if (!ok(v & 255, v >> 8)) good = false; else wins.push(headerOf(v & 255, v >> 8, tail)); }
      if (!good) continue;
      for (let i = 0; i < 8 && good; i++) for (let j = i + 1; j < 8; j++) if (Math.abs(wins[i] - wins[j]) < 32) { good = false; break; }
      if (good) candidates.push({ tail, form, v0, v1: tail[0], gb, codeOf, wins });
    }
  }
}
candidates.sort((x, y) => x.form.end - y.form.end);
console.error(`${candidates.length} cycle candidates (tail, base, Gray bits); shortest head ${candidates[0]?.form.end} bits`);
if (!candidates.length) throw new Error('no cycle fits');
// ---- filler letters and pads, per command form (the pad must cover the joint bytes read for the next head)
const padBytesOf = form => { const headBytes = Math.ceil(form.end / 8); let bp = 6 + HB, made = 0; for (const cmd of form.cmds) { bp += 2 + (cmd.len <= 3 ? 2 : cmd.len <= 5 ? 3 : 5) + (cmd.explicit ? 7 : 5) + 2; made += cmd.len; if (made >= headBytes) break; } return Math.ceil(bp / 8); };
const DUMMY = new Uint8Array(TL).fill(0x20);
const yOf = X => evenHalf(new Uint8Array(32).fill(X))[0];
const padCache = new Map();
function lettersFor(padBytes) {
  if (padCache.has(padBytes)) return padCache.get(padBytes);
  const list = [];
  for (let X = 0x20; X <= 0x7e; X++) {
    if (lower(X)) continue;
    const Y = yOf(X), J = dup(new Uint8Array(16).fill(Y)), r = decode36(J, DUMMY, OPTS); let di = 0; const posAt = [];
    for (let i = 0; i < 32; i++) posAt[i] = r.src[i] === 2 ? r.dictPos[di++] : -1;
    const pos = [], index = []; let good = true;
    for (let i = 0; i < padBytes; i++) { if (posAt[i] < 0) { good = false; break; } pos.push(posAt[i]); index.push(i); }
    if (!good || new Set(pos).size !== pos.length) continue;
    list.push({ X, Y, pos, index, consumed: r.consumed });
  }
  list.sort((a, b) => a.consumed - b.consumed);
  padCache.set(padBytes, list); return list;
}
// ---- species: pick cycles from the candidates without slot or pad collisions
const SLOT = 32;
let rs = (SEED * 2654435761 + 7) >>> 0; const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs / 4294967296; };
const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
const shortest = candidates.filter(c => c.form.end <= candidates[0].form.end + 8);   // the shortest heads and the next byte's worth
let pick = [];
for (let t = 0; t < 200 && pick.length < S; t++) {
  const chosen = [], used = [], padPos = new Set(), inSlots = p => used.some(s => p >= s && p < s + SLOT);
  for (const cand of shuffle(shortest)) {
    if (chosen.length === S) break;
    const sl = cand.wins.map(h => h - cand.form.d);
    if (sl.some(s => used.some(u => Math.abs(u - s) < SLOT) || [...padPos].some(p => p >= s && p < s + SLOT))) continue;
    const letters = lettersFor(padBytesOf(cand.form));
    const L = shuffle(letters).find(l => !chosen.some(c => c.letter.X === l.X) && !l.pos.some(p => inSlots(p) || sl.some(s => p >= s && p < s + SLOT) || padPos.has(p)));
    if (!L) continue;
    chosen.push({ ...cand, letter: L }); used.push(...sl); L.pos.forEach(p => padPos.add(p));
  }
  if (chosen.length > pick.length) pick = chosen;
}
if (pick.length < S) { if (opt.max) console.error(`only ${pick.length} species fit of ${S}: taking them`); else throw new Error(`only ${pick.length} species fit of ${S} (max=1 takes what fits)`); }
const NAMES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', NAME = opt.name || `ca-vote${MODENAME}${pick.length}`;
const TAILPAIRS = []; for (const v of CELLBYTES) for (let b = 0; b < 8; b++) { const u = v ^ (1 << b); if (inCell[u] && v !== 0 && u !== 0 && v < u) TAILPAIRS.push([v, u]); }
if (!TAILPAIRS.length) throw new Error('no tail byte pair');
const SPECIES = pick.map((c, i) => ({ name: NAMES[i], ...c, tailByte: TAILPAIRS[i % TAILPAIRS.length][0], alt: TAILPAIRS[i % TAILPAIRS.length][1], headCell: Math.ceil(Math.ceil(c.form.end / 8) / 2) }));
function cellOf(s, k) {
  const g = gray(k), cell = new Uint8Array(16);
  const code = s.codeOf(g); cell[0] = s.v0 ^ (code & 255); for (let m = 1; m <= NTAIL; m++) cell[m] = s.tail[m - 1]; cell[1] ^= code >> 8;
  const par = POP[g] & 1;
  for (let j = Math.max(s.headCell, NTAIL + 1); j < 16; j++) cell[j] = j === Math.max(s.headCell, NTAIL + 1) && par ? s.alt : s.tailByte;
  return cell;
}
const windowOf = (s, k) => s.wins[k], posOf = (s, k) => s.wins[k] - s.form.d;
const designed = new Map(); for (const s of SPECIES) for (let k = 0; k < 8; k++) designed.set(key(cellOf(s, k)), { species: s.name, k });
// ---- build
const dict = new Uint8Array(TL), isFixed = new Uint8Array(TL);
SPECIES.forEach((s, i) => { const a = Math.round(V * i / S), b = i === S - 1 ? TL - 1 : Math.round(V * (i + 1) / S); for (let p = a; p < b; p++) dict[p] = s.letter.X; });
dict[TL - 1] = 10;
for (const s of SPECIES) for (let k = 0; k < 8; k++) { const p = posOf(s, k), w = dup(cellOf(s, (k + 1) % 8)); for (let i = 0; i < 32; i++) { if (isFixed[p + i] && dict[p + i] !== w[i]) throw new Error('slots overlap'); dict[p + i] = w[i]; isFixed[p + i] = 1; } }
for (const s of SPECIES) { const w0 = dup(cellOf(s, 1)); s.letter.pos.forEach((p, j) => { const i = s.letter.index[j]; if (isFixed[p] && dict[p] !== w0[i]) throw new Error(`pad of ${s.name} collides at ${p}`); dict[p] = w0[i]; isFixed[p] = 1; }); }
for (const v of dict.subarray(0, TL - 1)) if (!(safeByte(v) || (printable(v) && !lower(v)))) throw new Error('byte the page cannot carry: ' + v);
// ---- verify: the cell with the vote equal to itself, in either role, steps along the cycle; and the doubled joint's window is the designed one
const step = (a, v, flip) => splitPair(decode36(joinPair(a, v, MODE, flip), dict, OPTS).out, MODE, flip)[0];
for (const s of SPECIES) for (let k = 0; k < 8; k++) {
  const a = cellOf(s, k), r = decode36(dup(a), dict, OPTS);
  if (r.window !== windowOf(s, k)) throw new Error(`species ${s.name} state ${k}: window ${r.window} expected ${windowOf(s, k)}`);
  for (const flip of [0, 1]) { const next = step(a, a, flip); if (key(next) !== key(cellOf(s, (k + 1) % 8))) throw new Error(`species ${s.name} state ${k} flip ${flip}: wrong next cell`); }
}
const vote4 = (a, nb) => { const v = new Uint8Array(16); for (let k = 0; k < 128; k++) { const bit = c => (c[k >> 3] >> (k & 7)) & 1; const n = nb.reduce((t, c) => t + bit(c), 0); v[k >> 3] |= (n >= 3 ? 1 : n <= 1 ? 0 : bit(a)) << (k & 7); } return v; };
let pulled = 0; for (const s of SPECIES) for (let k = 0; k < 8; k++) { const a = cellOf(s, k), v = vote4(a, Array(4).fill(cellOf(s, (k + 1) % 8))); if (designed.has(key(step(a, v, 0)))) pulled++; }
console.error(`cell one phase behind its four neighbours: lands on a designed state in ${pulled} of ${8 * S} cases`);
// ---- census: random cells with the vote equal to themselves, and with a random vote on the first turn
function makeCells(n, seed) { let z = seed >>> 0 || 1; const r = () => { z ^= z << 13; z >>>= 0; z ^= z >>> 17; z ^= z << 5; z >>>= 0; return z; }; return Array.from({ length: n }, () => Uint8Array.from({ length: 16 }, () => r() & 255)); }
function census(n, seed, cap, randomVote) {
  const A = makeCells(n, seed), B = makeCells(n, seed ^ 0x5bd1e995), per = Object.fromEntries([...SPECIES.map(s => [s.name, 0]), ['none', 0]]), trans = []; let onBy8 = 0;
  for (let i = 0; i < n; i++) { let a = A[i], hit = -1, who = null;
    for (let t = 0; t < cap; t++) { const d = designed.get(key(a)); if (d) { hit = t; who = d.species; break; } a = step(a, randomVote && t === 0 ? B[i] : a, t & 1); }
    if (hit >= 0) { per[who]++; trans.push(hit); if (hit <= 8) onBy8++; } else per.none++; }
  trans.sort((x, y) => x - y);
  return { shares: Object.fromEntries(Object.entries(per).map(([k, v]) => [k, v / n])), transientMean: trans.reduce((t, v) => t + v, 0) / (trans.length || 1), p90: trans[Math.floor(0.9 * trans.length)] ?? null, max: trans[trans.length - 1] ?? null, onBy8: onBy8 / n };
}
const cen = census(NCENSUS, 4242 + SEED, 400, false), cenR = census(NCENSUS, 4242 + SEED, 400, true);
fs.mkdirSync(`${dir}/paper/data/design`, { recursive: true });
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.txt`, Buffer.from(dict));
const ham = (s, k) => { const a = cellOf(s, k), b = cellOf(s, (k + 1) % 8); let n = 0; for (let i = 0; i < 16; i++) n += POP[a[i] ^ b[i]]; return n; };
const formText = s => `${s.form.cmds.map(c => c.len + (c.explicit ? 'e' : 'r')).join('+')} d ${s.form.d} tf ${s.form.tf}`;
const states = SPECIES.map(s => ({ species: s.name, form: formText(s), headBits: s.form.end, grayBits: s.gb, letter: String.fromCharCode(s.letter.X), cellLetter: s.letter.Y, reading: s.letter.consumed,
  states: Array.from({ length: 8 }, (_, k) => ({ k, pos: posOf(s, k), header: windowOf(s, k), text: key(cellOf(s, k)), joint: key(dup(cellOf(s, k))), hammingToNext: ham(s, k) })) }));
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.json`, JSON.stringify({ name: NAME, pairMode: 8 + MODE, species: SPECIES.length, cycles: SPECIES.map(() => 8), V, len: TL, headerBits: HB, states, census: cen, censusRandomVote: cenR }, null, 1));
const md = [`# Designed dictionary ${NAME}: a cell with its 4-neighbour vote, ${MODENAME}-interleaved\n`, `pair mode ${8 + MODE} (self and vote, ${MODENAME}-interleaved), ${SPECIES.length} species of 8-cycles, V = ${V} (${HB} header bits), ${TL} bytes. Every word is the next state in its doubled form, so the cell gets it in either role; ${CELLBYTES.length} cell byte values allowed. Heads found by enumerating ${tails.size} command tails.\n`,
  '| species | head (copies, distance, transform) | head bits | Gray bits of cell byte 0 | filler letter | cell letter | reading (bits) | cell state 0 | Hamming per step |', '|---|---|---|---|---|---|---|---|---|',
  ...states.map(s => `| ${s.species} | ${s.form} | ${s.headBits} | ${s.grayBits.join(' ')} | \`${s.letter}\` | 0x${s.cellLetter.toString(16)} | ${s.reading} | ${JSON.stringify(s.states[0].text)} | ${[...new Set(s.states.map(x => x.hammingToNext))].join('/')} |`),
  `\n## Census (${NCENSUS} random cells)\n`, `Vote equal to the cell (a synchronised start): on a designed cycle ${Object.entries(cen.shares).map(([k, v]) => `${k} ${(100 * v).toFixed(1)} %`).join(', ')}; within 8 turns ${(100 * cen.onBy8).toFixed(1)} %; transient mean ${cen.transientMean.toFixed(1)}, p90 ${cen.p90}, max ${cen.max}.`,
  `Random vote on the first turn, then equal: ${Object.entries(cenR.shares).map(([k, v]) => `${k} ${(100 * v).toFixed(1)} %`).join(', ')}; within 8 turns ${(100 * cenR.onBy8).toFixed(1)} %.`];
fs.writeFileSync(`${dir}/paper/data/design/${NAME}.md`, md.join('\n') + '\n');
console.log(md.join('\n'));
