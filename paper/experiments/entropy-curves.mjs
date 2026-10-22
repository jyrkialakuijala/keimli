// Entropy against the turn for rewriting rules of known and unknown information loss, on one cell's 128 bits.
// The known entropy manipulators calibrate the measures: on a 128-bit ring the elementary rules 150 and 170 are
// bijections (no loss), rule 60 loses exactly 1 bit a turn and rule 90 exactly 2 (all cells zero at turn 64). The same
// measures are then read for look-and-say, the Brotli-like decoder on two dictionaries and a CPU.
// Per turn, over the N cells of the lattice: the collision entropy of one cell, H2 = -log2 P(two cells equal), from the
// number of equal pairs among N (resolvable up to about 2 log2 N - 1 bits; above that it is reported as a lower bound);
// the number of distinct cells; and the block entropy of 8-bit windows of the cell's ring per bit (Wolfram's local
// measure, pooled over cells and positions). Two settings: the rewrite alone, and uniform mixing (swap 1/2) and settling
// (median 1) with the page's rotating swap order. Deterministic: seed 1, quenched hashing.
// Usage: node paper/experiments/entropy-curves.mjs [n=362] [turns=64] [out=paper/data/entropy]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const n = Number(opt.n ?? 362), turns = Number(opt.turns ?? 64), outDir = opt.out || dir + '/paper/data/entropy';
const RULES = [
  { id: 'eca170', name: 'rule 170 (rotation, no loss)', changer: 256 + 170, exact: () => 128 },
  { id: 'eca150', name: 'rule 150 (no loss)', changer: 256 + 150, exact: () => 128 },
  { id: 'eca60', name: 'rule 60 (1 bit a turn)', changer: 256 + 60, exact: t => Math.max(0, 128 - t) },
  { id: 'eca90', name: 'rule 90 (2 bits a turn)', changer: 256 + 90, exact: t => Math.max(0, 128 - 2 * t) },
  { id: 'las10', name: 'look-and-say, base 10', changer: 58 },
  { id: 'las16', name: 'look-and-say, base 16', changer: 64 },
  { id: 'swarmf', name: 'decoder, Swarm F', changer: 36, dict: 'ca-swarm-f', cread: 4096 },
  { id: 'gray20c', name: 'decoder, 20 Gray 8-cycles', changer: 36, dict: 'ca-gray20c', cread: 60000 },
  { id: 'z80', name: 'Z80, 256 instructions', changer: 6, steps: 256 },
];
const SETTINGS = [{ id: 'alone', name: 'the rewrite alone', mix: false }, { id: 'uniform', name: 'swap ½, median 1', mix: true }];
const textOf = d => { const p = `${dir}/paper/data/design/${d}.txt`; return fs.existsSync(p) ? fs.readFileSync(p, 'latin1') : asText(loadDict(d).bytes); };
const decl = fs.readFileSync(dir + '/src/changers/declaration.txt', 'latin1');
function measure(g, N) {
  const cnt = new Map(); for (let i = 0; i < N; i++) { const k = Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1'); cnt.set(k, (cnt.get(k) || 0) + 1); }
  let pairs = 0; for (const c of cnt.values()) pairs += c * (c - 1) / 2;
  const all = N * (N - 1) / 2, h2 = pairs ? -Math.log2(pairs / all) : null;   // null: no equal pair, H2 above the resolution
  const blk = new Float64Array(256); let tot = 0;   // 8-bit windows of the ring, every start position
  for (let i = 0; i < N; i++) { const c = g.subarray(16 * i, 16 * i + 16);
    for (let s = 0; s < 128; s++) { let v = 0; for (let k = 0; k < 8; k++) { const q = (s + k) & 127; v = (v << 1) | ((c[q >> 3] >> (7 - (q & 7))) & 1); } blk[v]++; tot++; } }
  let hb = 0; for (const c of blk) if (c) hb -= (c / tot) * Math.log2(c / tot);
  return { h2, distinct: cnt.size, block8: hb / 8 };
}
fs.mkdirSync(outDir, { recursive: true });
const N = n * n, resolution = 2 * Math.log2(N) - 1;
const result = { n, N, turns, resolution, seed: 1, order: 'rotate', date: new Date().toISOString().slice(0, 10), rules: [] };
for (const r of RULES) for (const s of SETTINGS) {
  const sim = await makeSim({ W: n, H: n, changer: r.changer, pairMode: 0, maxlen: 3, skip: 6, cread: r.cread ?? 4096, coff: 0, passes: 1, nbr: 1, steps: r.steps ?? 0,
    swap: s.mix ? [0.5, 0.5] : [0, 0], smooth: s.mix ? [1, 1] : [0, 0], mixOn: s.mix, settleOn: s.mix, altOrder: 'rotate' });
  sim.setDict(r.dict ? textOf(r.dict) : decl); sim.reset(1);
  const rows = [{ t: 0, ...measure(sim.grid(), N) }];
  for (let t = 1; t <= turns; t++) { sim.step(); if (t <= 16 || t % 4 === 0) rows.push({ t, ...measure(sim.grid(), N) }); }
  result.rules.push({ id: r.id, name: r.name, setting: s.id, settingName: s.name, exact: r.exact ? rows.map(x => [x.t, r.exact(x.t)]) : null, rows });
  const last = rows[rows.length - 1], at = t => rows.find(x => x.t === t);
  const f = x => x.h2 === null ? `>${resolution.toFixed(0)}` : x.h2.toFixed(1);
  console.log(`${r.name.padEnd(30)} ${s.name.padEnd(18)} H2 bits t1 ${f(at(1))} t8 ${f(at(8))} t16 ${f(at(16))} t32 ${f(at(32))} t${turns} ${f(last)} | distinct ${last.distinct} | block-8 bits/bit t1 ${at(1).block8.toFixed(3)} t${turns} ${last.block8.toFixed(3)}`);
}
fs.writeFileSync(`${outDir}/entropy-curves-n${n}-t${turns}.json`, JSON.stringify(result));
