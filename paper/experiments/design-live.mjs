// Design a lively dictionary for the Brotli-like decoder (kind 36, skip 6, window range 4096) from understood parts.
// Every designed cell has the same command bits ("copy 10 bytes at distance 16, then 6 more at the same distance", as
// in design-dict.mjs) and a 12-bit header h = 16 u, so it decodes to the 16 dictionary bytes before h: slot u. The
// 8-bit code u is the only part of a designed cell that f reads; the other bits (byte 0's low six, the ten tail bytes)
// are inert and only set the colour. Mixing and settling keep the command bits (they are equal in all designed cells),
// so among designed cells the decoder is a map on codes, and the dictionary is its table of 16-byte slots.
// A code can be a state (its head bytes printable) when bit 5 is 0 and bits 3 and 4 differ; the designs also keep bit 7
// at 0, which leaves 32 state codes and five free bits (bits 0..2, the pair 3/4, bit 6). No crossover of states sets
// bits 5 or 7, but every code below 128 still has a slot, so the table also says where every crossover child of two
// states goes. Slots 128..255 (bytes 2032..4079), read only by cells that are not designed, hold the funnel: constant
// filler bytes as in design-dict.mjs, whose repeated-byte cell copies its head from fixed positions (the landing pad)
// that hold the head of a chosen state, so random cells reach the designed states in a few steps. The design names the attractor types (Gray cycles: closed, all 8 codes of a
// 3-cube; open cycles: states far apart; fixed points and 2-cycles: closed) and, for each pair of types, where their
// crossover children go (the interface outcome). Each non-state code is routed by its expected parentage: the
// probability that a one-exchange crossover (rate r) of each pair of states gives it, times that pair's outcome.
// Usage: node paper/experiments/design-live.mjs name=ca-live-phases [out=src/changers/dict] [seed=1]
import fs from 'node:fs';
import vm from 'node:vm';
import { decode36 } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const V = 4096, TL = 4096, OPTS = { skip: 6, V, coff: 0 }, R = Number(opt.r ?? 0.25);
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
// a state code from its genes: g3 (bits 0..2), a (bit 4, bit 3 its complement), hi (bits 6, 7)
export const code = (g3, a, hi) => g3 | (a ? 16 : 8) | (hi << 6);
const isTarget = u => !(u & 160) && ((u >> 3) & 1) !== ((u >> 4) & 1);
const gray = k => k ^ (k >> 1);
// ---- the candidates (paper/results/redesign.md). kinds: gray (8-cycle on g3 in class [a, hi]), cycle (codes in order), fixed (one code).
// out: for an unordered pair of types 'A|B' (or 'A|A'), the outcome weights of their crossover children; 'parent' sends
// a child to the nearer parent's type; pairs not listed default to 'parent'. colour: an RGB target for the tail bytes.
const SEAS = [[30, 60, 170], [40, 130, 210], [0, 170, 190], [90, 90, 220], [20, 100, 140]], LAND = [120, 140, 40], GOLD = [215, 170, 0];
const FAR3 = [code(0, 1, 1), code(7, 0, 1), code(3, 0, 0)];   // a 3-cycle whose states are 4 to 6 bits apart, across three classes
const land = { id: 'L', kind: 'gray', a: 1, hi: 0, colour: LAND };   // a closed Gray 8-cycle on class (a 1, hi 0)
const sea = { id: 'S', kind: 'cycle', codes: FAR3, colours: SEAS.slice(0, 3) };
export const SPECS = {
  // one far 3-cycle; a child of two phases joins the phase ahead, so each phase invades the one behind it (cyclic dominance)
  'ca-live-phases': { types: [sea], out: { 'S|S': 'lead' }, filler: [{ P: '"', to: 'S', share: 1 }] },
  // the phases' sea, plus a Gray land: 30 % of the sea's crossover children become land, land and sea at the coast split
  // half to the sea, half to the nearer parent
  'ca-live-archipelago': { types: [land, sea], out: { 'S|S': { lead: 0.7, L: 0.3 }, 'L|S': { S: 0.5, parent: 0.5 } },
    filler: [{ P: '"', to: 'S', share: 0.8 }, { P: '#', to: 'L', share: 0.2 }] },
  // as the archipelago with 10 % nucleation and a coast that goes to the nearer parent (a stand-off)
  'ca-live-coast': { types: [land, sea], out: { 'S|S': { lead: 0.9, L: 0.1 }, 'L|S': 'parent' },
    filler: [{ P: '"', to: 'S', share: 0.8 }, { P: '#', to: 'L', share: 0.2 }] },
  // the archipelago with 10 % nucleation and a fixed point that eats the land and is eaten by the sea
  'ca-live-reef': { types: [land, sea, { id: 'I', kind: 'fixed', codes: [code(4, 1, 1)], colour: GOLD }],
    out: { 'S|S': { lead: 0.9, L: 0.1 }, 'L|S': { S: 0.5, parent: 0.5 }, 'I|L': { I: 1 }, 'I|S': { S: 1 } },
    filler: [{ P: '"', to: 'S', share: 0.7 }, { P: '#', to: 'L', share: 0.2 }, { P: '2', to: 'I', share: 0.1 }] },
  // a near 5-cycle (states 2 to 3 bits apart, one class) whose phases chase, a Gray land it erodes, a fixed point that
  // eats the sea and is eaten by the land
  'ca-live-lagoon': { types: [{ id: 'L', kind: 'gray', a: 0, hi: 0, colour: LAND }, { id: 'S', kind: 'cycle', codes: [code(0, 1, 1), code(3, 1, 1), code(5, 1, 1), code(6, 1, 1), code(1, 0, 1)], colours: SEAS },
      { id: 'I', kind: 'fixed', codes: [code(4, 0, 1)], colour: GOLD }],
    out: { 'S|S': 'lead', 'I|S': { I: 1 }, 'I|L': { L: 1 }, 'L|S': { S: 1 } },
    filler: [{ P: '"', to: 'S', share: 0.6 }, { P: '#', to: 'L', share: 0.3 }, { P: '2', to: 'I', share: 0.1 }] },
};
// spec=file.json: a design to screen, codes as [g3, a, hi] triples
const spec = opt.spec ? JSON.parse(fs.readFileSync(opt.spec, 'utf8')) : SPECS[opt.name || 'ca-live-phases']; if (!spec) throw new Error('unknown name; known: ' + Object.keys(SPECS).join(' '));
for (const t of spec.types) if (t.codes) t.codes = t.codes.map(c => Array.isArray(c) ? code(...c) : c);
const NAME = opt.name || 'ca-live-phases';
// ---- states
const states = [];   // { type, k, u, next }
for (const t of spec.types) {
  const codes = t.kind === 'gray' ? Array.from({ length: 8 }, (_, k) => code(gray(k), t.a, t.hi)) : t.codes;
  if (new Set(codes).size !== codes.length) throw new Error(`${t.id}: repeated code`);
  t.codes = codes; codes.forEach((u, k) => { if (!isTarget(u)) throw new Error(`${t.id}: code ${u} is not a state code`); states.push({ type: t.id, k, u, n: codes.length }); });
}
const stateOfCode = new Map(); for (const s of states) { if (stateOfCode.has(s.u)) throw new Error(`code ${s.u} used twice`); stateOfCode.set(s.u, s); }
const typeById = Object.fromEntries(spec.types.map(t => [t.id, t]));
const nextCode = s => typeById[s.type].codes[(s.k + 1) % s.n];
// ---- routing of the other codes
let rs = (Number(opt.seed ?? 1) * 2654435761 + 99) >>> 0 || 1; const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs / 4294967296; };
const outcomeOf = (A, B) => spec.out[`${A}|${B}`] ?? spec.out[`${B}|${A}`] ?? 'parent';
const route = new Array(256).fill(null);   // code -> the code of the state its slot holds
const routeType = new Array(256).fill(null);
const nearestState = (x, T) => { let best = null, bd = 99; for (const s of states) if ((!T || s.type === T) && POP[x ^ s.u] < bd) { bd = POP[x ^ s.u]; best = s; } return best; };
// outcomes: weights over type ids; 'parent' (the nearer parent's type); 'lead' or 'lag' (two states of one cycle: the
// child joins the phase ahead, or behind, of the other: the next state of the leading or lagging parent)
for (let x = 0; x < 128; x++) {
  if (stateOfCode.has(x)) { route[x] = nextCode(stateOfCode.get(x)); routeType[x] = stateOfCode.get(x).type; continue; }
  const mass = new Map(), add = (u, p) => mass.set(u, (mass.get(u) || 0) + p);   // target state code -> weight
  for (const A of spec.types) for (const B of spec.types) {
    const o = outcomeOf(A.id, B.id), w = 1 / (A.codes.length * B.codes.length);
    for (const a of A.codes) for (const b of B.codes) {
      if (a === b) continue; const d = a ^ b; if ((x ^ a) & ~d & 255) continue;   // x outside the subcube of a and b
      const k = POP[d], kb = POP[x ^ a], p = R ** kb * (1 - R) ** (k - kb) * w;
      const oo = typeof o === 'string' ? { [o]: 1 } : o;   // an outcome is a rule name or weights over rules and type ids
      for (const [T, q] of Object.entries(oo)) {
        if (T === 'parent') { const da = POP[x ^ a], db = POP[x ^ b]; if (da < db) add(nearestState(x, A.id).u, p * q); else if (da > db) add(nearestState(x, B.id).u, p * q); else { add(nearestState(x, A.id).u, p * q / 2); add(nearestState(x, B.id).u, p * q / 2); } }
        else if (T === 'lead' || T === 'lag') {
          const sa = stateOfCode.get(a), sb = stateOfCode.get(b), n = sa.n, ahead = (sb.k - sa.k + n) % n;   // b is ahead of a by this many steps
          if (2 * ahead === n) { add(nextCode(sa), p * q / 2); add(nextCode(sb), p * q / 2); continue; }
          const bLeads = 2 * ahead < n, win = (T === 'lead') === bLeads ? sb : sa; add(nextCode(win), p * q);
        }
        else add(nearestState(x, T).u, p * q);
      }
    }
  }
  const tot = [...mass.values()].reduce((s, v) => s + v, 0);
  let u;
  if (!tot) u = nearestState(x).u;
  else { let z = rnd() * tot; for (const [k, v] of mass) { u = k; z -= v; if (z < 0) break; } }
  route[x] = u; routeType[x] = stateOfCode.get(u).type;
}
// ---- bytes: the head of code u and the colour bytes
function headBytes(u, b0) {
  const cell = new Uint8Array(6); let bp = 6;
  const put = (v, n) => { for (let i = 0; i < n; i++, bp++) if ((v >> i) & 1) cell[bp >> 3] |= 1 << (bp & 7); };
  put(16 * u, 12); put(0, 2); put(3, 2); put(4, 3); put(1, 1); put(15, 6); put(0, 2); put(0, 2); put(3, 2); put(0, 3); put(0, 1); put(0, 4); put(1, 2);
  if (bp !== 48) throw new Error('head is not 48 bits'); cell[0] |= b0 & 63; return cell;
}
const LUT = Codec.BYTE_PALETTE, rgb = v => [LUT[v] & 255, (LUT[v] >> 8) & 255, (LUT[v] >> 16) & 255];
const okByte = v => v >= 0x20 && v <= 0x7e && !(v >= 0x61 && v <= 0x7a);
const dist2 = (c, v) => { const q = rgb(v); return (q[0] - c[0]) ** 2 + (q[1] - c[1]) ** 2 + (q[2] - c[2]) ** 2; };
const nearestBytes = (c, n, pool) => pool.slice().sort((a, b) => dist2(c, a) - dist2(c, b)).slice(0, n);
const ALL = []; for (let v = 0x20; v <= 0x7e; v++) if (okByte(v)) ALL.push(v);
const B0 = ALL.filter(v => v < 0x40);   // byte 0 with header bits 0, 1 clear: 0x20..0x3f
const content = new Map();   // state code -> its 16 bytes
for (const t of spec.types) {
  // colours: one per phase when given, else the type's colour (a Gray cycle's phases then differ only by the order of its bytes)
  t.codes.forEach((u, k) => {
    const col = t.colours ? t.colours[k % t.colours.length] : t.colour, pool = nearestBytes(col, 4, ALL), b0 = nearestBytes(col, 1, B0)[0];
    const c = headBytes(u, b0), tail = Array.from({ length: 10 }, (_, j) => pool[(j + k) % pool.length]); content.set(u, Uint8Array.from([...c, ...tail]));
  });
}
for (const c of content.values()) for (const v of c) if (!okByte(v)) throw new Error('unprintable byte ' + v);
// ---- the dictionary: slot u is bytes 16u - 16 .. 16u - 1 (slot 0 wraps to the last 16 bytes, whose final byte is the newline)
const dict = new Uint8Array(TL);
for (let u = 1; u < 128; u++) dict.set(content.get(route[u]), 16 * u - 16);
dict.set(content.get(route[0]), TL - 16); dict[TL - 1] = 10;
// the funnel: the filler patterns tiled over bytes 2032..4079 in regions by share, then the landing pads (the head of
// state 0 of the pattern's type at the positions its constant cell reads)
const F0 = 2032, F1 = TL - 16, fill = spec.filler || [{ P: '"', to: spec.types[0].id, share: 1 }];
{ let at = F0; fill.forEach((f, i) => { const end = i === fill.length - 1 ? F1 : Math.round(at + f.share * (F1 - F0)); for (let x = at; x < end; x++) dict[x] = f.P.charCodeAt(0); f.region = [at, end]; at = end; }); }
const padTaken = new Map();
for (const f of fill) {
  const cell = new Uint8Array(16).fill(f.P.charCodeAt(0)), r = decode36(cell, new Uint8Array(TL), OPTS), pos = r.dictPos.slice(0, 6);
  if (r.src.slice(0, 6).some(v => v !== 2) || new Set(pos).size !== 6 || pos.some(p => p < F0 || p >= F1)) throw new Error(`pattern ${f.P} does not land in the filler`);
  const head = content.get(typeById[f.to].codes[0]);
  pos.forEach((p, j) => { if (padTaken.has(p) && padTaken.get(p) !== head[j]) throw new Error('pads collide'); padTaken.set(p, head[j]); dict[p] = head[j]; });
  f.pad = pos; f.reads = r.consumed;
}
// ---- verify: every designed code decodes to its slot
for (let u = 0; u < 128; u++) {
  const cell = new Uint8Array(16); cell.set(content.get(states[0].u)); cell.set(headBytes(u, 0x20).subarray(0, 6)); cell[0] = (cell[0] & 0xc0) | 0x20;
  const out = decode36(cell, dict, OPTS).out, want = u ? content.get(route[u]) : Uint8Array.from([...content.get(route[0]).subarray(0, 15), 10]);
  if (Buffer.compare(Buffer.from(out), Buffer.from(want))) throw new Error(`code ${u} does not decode to its slot`);
}
// ---- exact closure: children of random state pairs (exchange rate r per differing bit), after one step of f
const typeOfCode = x => routeType[x];   // the type of the state the slot of x holds
function closure(A, B, r = R) {
  let onA = 0, onB = 0, tot = 0;
  for (const a of A.codes) for (const b of B.codes) {
    const d = a ^ b, bits = []; for (let i = 0; i < 8; i++) if ((d >> i) & 1) bits.push(i);
    for (let m = 0; m < 1 << bits.length; m++) { let x = a, kb = 0; bits.forEach((bi, j) => { if ((m >> j) & 1) { x ^= 1 << bi; kb++; } }); const p = r ** kb * (1 - r) ** (bits.length - kb); const T = typeOfCode(x); if (T === A.id) onA += p; else if (T === B.id) onB += p; tot += p; }
  }
  return { onA: onA / tot, onB: onB / tot, other: 1 - (onA + onB) / tot };
}
const clos = {}; for (const A of spec.types) for (const B of spec.types) clos[`${A.id}|${B.id}`] = closure(A, B);
// ---- basins: random cells through f alone, until a designed state repeats or 300 steps
const key = c => Buffer.from(c).toString('latin1'), designedKey = new Map(); for (const [u, c] of content) designedKey.set(key(c), stateOfCode.get(u).type);
let cs = 0x9e3779b9; const r32 = () => { cs ^= cs << 13; cs >>>= 0; cs ^= cs >>> 17; cs ^= cs << 5; cs >>>= 0; return cs; };
const NC = Number(opt.census ?? 20000), basin = {}, steps = []; let stray = 0;
for (let i = 0; i < NC; i++) {
  let c = new Uint8Array(16); for (let j = 0; j < 16; j += 4) { const v = r32(); c[j] = v & 255; c[j + 1] = (v >> 8) & 255; c[j + 2] = (v >> 16) & 255; c[j + 3] = v >>> 24; }
  let t = 0, T = null; for (; t < 300; t++) { c = decode36(c, dict, OPTS).out; const k = key(c); if (designedKey.has(k)) { T = designedKey.get(k); break; } if (key(c.subarray(0, 15)) === key(content.get(route[0]).subarray(0, 15))) { T = routeType[0]; break; } }
  if (T) { basin[T] = (basin[T] || 0) + 1; steps.push(t + 1); } else stray++;
}
for (const k in basin) basin[k] /= NC;
const routeShare = {}; for (let x = 0; x < 128; x++) if (!stateOfCode.has(x)) routeShare[routeType[x]] = (routeShare[routeType[x]] || 0) + 1;
const outDir = opt.out || dir + '/src/changers/dict';
fs.writeFileSync(`${outDir}/${NAME}.txt`, Buffer.from(dict));
const info = { name: NAME, V, len: TL, r: R, types: spec.types.map(t => ({ id: t.id, kind: t.kind, codes: t.codes, colour: t.colour, colours: t.colours })), out: spec.out,
  states: states.map(s => ({ type: s.type, k: s.k, u: s.u, text: key(content.get(s.u)) })), filler: fill, route: route.slice(0, 128), routeType: routeType.slice(0, 128), routeShare, closure: clos,
  basin, stray: stray / NC, meanSteps: steps.reduce((a, b) => a + b, 0) / Math.max(1, steps.length) };
fs.mkdirSync(`${dir}/paper/data/redesign`, { recursive: true });
fs.writeFileSync(`${dir}/paper/data/redesign/${NAME}.json`, JSON.stringify(info, null, 1));
const pct = v => (100 * v).toFixed(1);
console.log(`${NAME}: ${states.length} states; non-state codes routed: ${JSON.stringify(routeShare)}`);
console.log(`basins (f alone, ${NC} random cells): ${Object.entries(basin).map(([k, v]) => `${k} ${pct(v)} %`).join(', ')}, stray ${pct(stray / NC)} %, mean ${info.meanSteps.toFixed(1)} steps`);
for (const A of spec.types) console.log(`closure ${A.id}: ` + spec.types.map(B => { const c = clos[`${A.id}|${B.id}`]; return `x${B.id} ${pct(c.onA)}/${pct(c.onB)}/${pct(c.other)}`; }).join('  '));
