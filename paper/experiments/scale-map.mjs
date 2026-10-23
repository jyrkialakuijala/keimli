// The map alone for a designed dictionary ca-size-NN: random cells through decode36 until an attractor repeats
// (Brent), the attractor types realised with their basins, how many designed types are reached, the strays, the
// transient lengths, and the closure index C(A, A) of the 20 largest realised types: two random states of A (random
// phases) crossed (each differing bit from the second with probability r), f applied once, the share landing on A.
// Usage: node paper/experiments/scale-map.mjs size=16 [design=1] [dict=path.txt] [json=design.json] [cells=16384] [samples=4000] [seed=1] [out=paper/data/scale]
import fs from 'node:fs';
import { decode36 } from './decode36.mjs';
import { loadDict } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const size = Number(opt.size ?? 16), NAME = `ca-size-${String(size).padStart(2, '0')}`, DSEED = Number(opt.design ?? 1), DTAG = DSEED === 1 ? NAME : `${NAME}-s${DSEED}`;   // design=K: the design seed (1: the shipped dictionary; others under paper/data/design-seeds)
const NC = Number(opt.cells ?? 16384), SAMPLES = Number(opt.samples ?? 4000), SEED = Number(opt.seed ?? 1), outDir = opt.out || `${dir}/paper/data/scale`;
fs.mkdirSync(outDir, { recursive: true });
const dictPath = opt.dict || (DSEED === 1 ? null : `${dir}/paper/data/design-seeds/${DTAG}.txt`), jsonPath = opt.json || (DSEED === 1 ? `${dir}/paper/data/design/${NAME}.json` : `${dir}/paper/data/design-seeds/${DTAG}.json`);
const outFile = `${outDir}/map-${DTAG}.json`; if (fs.existsSync(outFile) && !opt.force) { console.error(`${DTAG}: exists`); process.exit(0); }
const design = JSON.parse(fs.readFileSync(jsonPath, 'utf8')), V = design.V, OPTS = { skip: 6, V, coff: 0 };
const dict = loadDict(dictPath || NAME).bytes; if (dict.length !== V) throw new Error('dictionary length');
const key = c => Buffer.from(c).toString('latin1'), f = x => decode36(x, dict, OPTS).out;
const typeOf = new Map(); design.typeTable.forEach(t => t.states.forEach(s => typeOf.set(s, t.index)));
let rs = (SEED * 2654435761 + 12345) >>> 0 || 1; const r32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; }, rnd = () => r32() / 4294967296;
const randomCell = () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = r32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };
const t0 = Date.now(), attractors = new Map(), trans = []; let unsettled = 0;
for (let i = 0; i < NC; i++) {
  const x0 = randomCell(); let power = 1, lam = 1, tortoise = x0, hare = f(x0), steps = 0;
  while (key(tortoise) !== key(hare)) { if (power === lam) { tortoise = hare; power *= 2; lam = 0; } hare = f(hare); lam++; if (++steps > 2000) break; }
  if (steps > 2000) { unsettled++; continue; }
  let mu = 0; tortoise = x0; hare = x0; for (let k = 0; k < lam; k++) hare = f(hare);
  while (key(tortoise) !== key(hare)) { tortoise = f(tortoise); hare = f(hare); mu++; }
  const states = []; let c = tortoise; for (let k = 0; k < lam; k++) { states.push(key(c)); c = f(c); }
  const best = states.reduce((a, b) => (b < a ? b : a)), type = states.map(s => typeOf.get(s)).find(v => v !== undefined) ?? null;
  const rec = attractors.get(best) || { len: lam, count: 0, type, states }; rec.count++; attractors.set(best, rec); trans.push(mu);
}
trans.sort((a, b) => a - b);
const list = [...attractors.values()].sort((a, b) => b.count - a.count), reached = new Set(list.filter(a => a.type !== null).map(a => a.type));
const strays = list.filter(a => a.type === null);
// closure of the 20 largest realised types
const closure = list.slice(0, 20).map(A => {
  const own = new Set(A.states), S = A.states.map(s => Uint8Array.from(Buffer.from(s, 'latin1'))), out = { type: A.type, len: A.len, basin: A.count / NC };
  for (const r of [0.05, 0.25, 0.5]) { let on = 0; for (let i = 0; i < SAMPLES; i++) { const a = S[Math.floor(rnd() * S.length)], b = S[Math.floor(rnd() * S.length)], c = new Uint8Array(16); for (let k = 0; k < 16; k++) { let m = 0; for (let j = 0; j < 8; j++) if (rnd() < r) m |= 1 << j; c[k] = (a[k] & ~m) | (b[k] & m); } if (own.has(key(f(c)))) on++; } out[`C${r}`] = on / SAMPLES; }
  return out;
});
const basins = design.typeTable.map(t => 0); for (const a of list) if (a.type !== null) basins[a.type] += a.count / NC;
const kinds = { gray: 0, chase: 0, fixed: 0 }; for (const t of reached) kinds[design.typeTable[t].kind]++;
const res = { name: NAME, tag: DTAG, designSeed: DSEED, approach: design.approach, log2: size, V, cells: NC, seed: SEED, nTypes: design.nTypes, designedKinds: design.types, attractors: list.length, designedReached: reached.size, reachedKinds: kinds, strayAttractors: strays.length, strayShare: strays.reduce((s, a) => s + a.count, 0) / NC, unsettled,
  transientMean: trans.reduce((a, b) => a + b, 0) / Math.max(1, trans.length), transientP90: trans[Math.floor(0.9 * trans.length)] ?? null, transientMax: trans[trans.length - 1] ?? null,
  basinMin: Math.min(...basins), basinMax: Math.max(...basins), basinZero: basins.filter(b => b === 0).length, basins, closure, top: list.slice(0, 30).map(a => ({ len: a.len, basin: a.count / NC, type: a.type, kind: a.type === null ? 'stray' : design.typeTable[a.type].kind, example: JSON.stringify(a.states[0]) })), seconds: (Date.now() - t0) / 1000 };
fs.writeFileSync(outFile, JSON.stringify({ provenance: provenance(import.meta.url, { size, design: DSEED, dictPath, jsonPath, NC, SAMPLES, SEED }), ...res }));
console.error(`${DTAG}: ${list.length} attractors from ${NC} cells, ${reached.size} of ${design.nTypes} designed types reached (${JSON.stringify(kinds)}), ${strays.length} strays with ${(100 * res.strayShare).toFixed(2)} %, transient ${res.transientMean.toFixed(1)} (p90 ${res.transientP90}), C(A,A) at r 0.25 of the top 20: ${closure.map(c => (100 * c['C0.25']).toFixed(0)).join(' ')} %; ${res.seconds.toFixed(0)} s`);
