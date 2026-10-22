// Summary of the droplet runs (droplets.mjs): for every ordered pair of types and setting, the final shares of the
// droplet type X, the sea type Y and everything else, and the outcome: X wins (X > 50 %), Y holds (Y > 50 %, X below
// its start), coexist, or both dissolve (neither type above 50 % and "other" above 50 %). Also the head-to-head
// tally by period class (fixed point against cycle) and phase mode.
// Usage: node paper/experiments/droplets-summary.mjs [paper/data/droplets] > paper/results/droplets-table.md
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const inDir = process.argv[2] || dir + '/paper/data/droplets';
const files = fs.readdirSync(inDir).filter(f => f.endsWith('.json')).sort();
const pc = v => (100 * v).toFixed(0);
const outcome = r => r.xT > 0.5 ? 'X wins' : r.yT > 0.5 ? (r.xT > 1.5 * r.x0 ? 'X grows' : r.xT < 0.5 * r.x0 ? 'Y holds' : 'stand-off') : r.otherT > 0.5 ? 'both dissolve' : 'mixed';
console.log(provLine(provenance(import.meta.url)));
const tally = new Map(); const bump = (k, o) => { const t = tally.get(k) || {}; t[o] = (t[o] || 0) + 1; tally.set(k, t); };
for (const f of files) {
  const d = JSON.parse(fs.readFileSync(`${inDir}/${f}`, 'utf8')), T = d.types, P = [...new Set(d.runs.map(r => r.p))], M = [...new Set(d.runs.map(r => r.m))];
  console.log(`\n## ${d.dict} (${d.n}², ${d.T} turns): ` + T.map(t => `#${t.id} ${t.period === 1 ? 'fixed point' : t.period + '-cycle'} (basin ${(100 * t.basin).toFixed(2)} %)`).join(', ') + '\n');
  console.log('Each cell: final X / Y / other share (%), droplet X planted in sea Y, radius 16 (start X ≈ 5 %).\n');
  for (const phase of ['coherent', 'random']) {
    console.log(`### ${phase} phases\n`);
    console.log('| X in Y | swap p | ' + M.map(m => 'm = ' + m).join(' | ') + ' |'); console.log('|---|---|' + M.map(() => '---').join('|') + '|');
    for (const X of T) for (const Y of T) { if (X === Y) continue;
      for (const p of P) console.log(`| #${X.id} in #${Y.id} | ${p} | ` + M.map(m => { const r = d.runs.find(r => !r.whole && r.X === X.id && r.Y === Y.id && r.p === p && r.m === m && r.phase === phase && r.lam === 0); if (!r) return ''; bump(`${phase} | ${X.period === 1 ? 'fixed' : 'cycle'} droplet in ${Y.period === 1 ? 'fixed' : 'cycle'} sea | p ${p > 0 ? '> 0' : '= 0'}`, outcome(r)); return `${pc(r.xT)}/${pc(r.yT)}/${pc(r.otherT)}`; }).join(' | ') + ' |'); }
    console.log('');
  }
  console.log('### whole-lattice domains (swap 0.1): the type\'s share after the run\n');
  console.log('| type | phases | ' + M.map(m => 'm = ' + m).join(' | ') + ' |'); console.log('|---|---|' + M.map(() => '---').join('|') + '|');
  for (const Y of T) for (const phase of ['coherent', 'random']) console.log(`| #${Y.id} (${Y.period === 1 ? 'fixed point' : Y.period + '-cycle'}) | ${phase} | ` + M.map(m => { const r = d.runs.find(r => r.whole && r.Y === Y.id && r.phase === phase && r.m === m); return r ? pc(r.xT) + ' %' : ''; }).join(' | ') + ' |');
}
console.log('\n## Outcomes by kind, all dictionaries (zero-noise runs)\n');
const keys = ['X wins', 'X grows', 'stand-off', 'Y holds', 'mixed', 'both dissolve'];
console.log('| phases, droplet in sea, mixing | ' + keys.join(' | ') + ' |'); console.log('|---|' + keys.map(() => '---').join('|') + '|');
for (const [k, t] of [...tally.entries()].sort()) console.log(`| ${k} | ` + keys.map(o => t[o] || 0).join(' | ') + ' |');
