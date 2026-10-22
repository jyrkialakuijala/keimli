// Table of the dose-response runs (dose.mjs). Usage: node paper/experiments/dose-summary.mjs [paper/data/dose]
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const inDir = process.argv[2] || dir + '/paper/data/dose';
const NAMES = { 2: 'Brainfuck', 6: 'Z80', 7: '6502', 9: 'Subleq', 15: 'RISC-V', 47: 'Redcode', 36: 'decoder', 58: 'look-and-say, base 10', 346: 'rule 90' };
const f = v => v === null || v === undefined ? '> 27' : v.toFixed(1), p = v => (100 * v).toFixed(0) + ' %';
console.log(provLine(provenance(import.meta.url)));
console.log('| rule | joining | instructions | map: H₂ after 1 / 16 turns (bits) | map: cells on a cycle ≤ 64 at turn 300 | map: attractor types (of 16,384 cells) | map: largest basin | lattice (swap ½, median 1, turn 400): H₂ | distinct cells | leading type | block-8 entropy |');
console.log('|---|---|---|---|---|---|---|---|---|---|---|');
const files = fs.readdirSync(inDir).filter(x => x.endsWith('.json')).map(x => JSON.parse(fs.readFileSync(`${inDir}/${x}`))).sort((a, b) => (a.pair || 0) - (b.pair || 0) || [2, 6, 7, 9, 15, 47, 36, 58, 346].indexOf(a.changer) - [2, 6, 7, 9, 15, 47, 36, 58, 346].indexOf(b.changer) || String(a.dict).localeCompare(b.dict));
for (const d of files) for (const r of d.rows)
  console.log(`| ${NAMES[d.changer] || d.changer}${d.changer === 36 ? ' (' + d.dict.replace('ca-', '') + ')' : ''} | ${d.pair ? 'concatenated pair' : 'single cell'} | ${r.steps || '–'} | ${f(r.map.h2_1)} / ${f(r.map.h2_16)} | ${p(r.map.onCycle)} | ${r.map.types} | ${p(r.map.largest)} (period ${r.map.largestPeriod}) | ${f(r.lattice.h2)} | ${r.lattice.distinct} | ${p(r.lattice.leader)} (period ${r.lattice.leaderPeriod}) | ${r.lattice.block8.toFixed(2)} |`);
