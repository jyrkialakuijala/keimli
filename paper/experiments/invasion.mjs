// The invasion table of a designed dictionary: cross a cell of species X (random phase) with a cell of species Y
// (random phase) by uniform crossover at rate q per bit, iterate the decoder until a designed cycle is reached, and
// count which species wins. Reports P(X wins | X x Y) for q = 1/2 (the lattice's exchange rate at swap p = 1/2) and
// q = 1/8, plus the stray share and the mean steps to settle. Also crosses each species with a random cell.
// Usage: node paper/experiments/invasion.mjs design=paper/data/design/ca-gray3c.json [N=20000]
import fs from 'node:fs';
import { decode36 } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const design = JSON.parse(fs.readFileSync(opt.design || dir + '/paper/data/design/ca-gray3c.json', 'utf8')), N = Number(opt.N ?? 20000);
const dict = new Uint8Array(fs.readFileSync(`${dir}/paper/data/design/${design.name}.txt`)), O = { skip: 6, V: design.V ?? 4096, coff: 0 }, key = c => Buffer.from(c).toString('latin1');
const label = new Map(); design.states.forEach((sp, si) => sp.states.forEach(x => label.set(x.text, si)));
const S = design.states.map(sp => sp.states.map(x => Uint8Array.from(Buffer.from(x.text, 'latin1'))));
let rs = 2024; const r32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
const rnd = () => r32() / 4294967296, ri = n => Math.floor(rnd() * n);
const randomCell = () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = r32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };
function settle(x) { for (let k = 0; k <= 100; k++) { const l = label.get(key(x)); if (l !== undefined) return [l, k]; x = decode36(x, dict, O).out; } return [-1, 101]; }
function cross(a, b, q) { const c = a.slice(); for (let i = 0; i < 16; i++) { let m = 0; for (let j = 0; j < 8; j++) if (rnd() < q) m |= 1 << j; c[i] = (a[i] & ~m) | (b[i] & m); } return c; }
const names = design.states.map(s => s.species), NSP = names.length, out = { N, tables: {} }, md = [`# Invasion table of ${design.name}\n`, `N = ${N} crossings per cell of the table; the row species X receives bits from the column species Y at rate q per bit; entries: P(X wins) / P(Y wins) / stray or unsettled (the rest went to a third species), mean steps to settle.\n`];
for (const q of [0.5, 0.25, 0.125, 0.0625]) {
  md.push(`## q = ${q}\n`, '| X \\ Y | ' + names.join(' | ') + ' | random cell |', '|---|' + '---|'.repeat(names.length + 1));
  const T = {};
  for (let a = 0; a < NSP; a++) {
    const row = [];
    for (let b = 0; b <= NSP; b++) {
      const w = new Array(NSP + 1).fill(0); let steps = 0;
      for (let i = 0; i < N; i++) { const x = cross(S[a][ri(8)], b < NSP ? S[b][ri(8)] : randomCell(), q); const [l, k] = settle(x); w[l < 0 ? NSP : l]++; steps += k; }
      T[`${names[a]}x${b < NSP ? names[b] : 'random'}`] = { wins: w.map(v => v / N), steps: steps / N };
      const other = b < NSP ? w[b] : N - w[a] - w[NSP];
      row.push(b === a ? `${(100 * w[a] / N).toFixed(1)} % stays, ${(steps / N).toFixed(1)}` : `${(100 * w[a] / N).toFixed(1)} / ${(100 * other / N).toFixed(1)} / ${(100 * w[NSP] / N).toFixed(1)}, ${(steps / N).toFixed(1)}`);
    }
    md.push(`| ${names[a]} | ${row.join(' | ')} |`);
  }
  md.push('');
  out.tables[q] = T;
}
fs.writeFileSync(`${dir}/paper/data/design/${design.name}-invasion.md`, md.join('\n') + '\n');
fs.writeFileSync(`${dir}/paper/data/design/${design.name}-invasion.json`, JSON.stringify(out, null, 1));
console.log(md.join('\n'));
