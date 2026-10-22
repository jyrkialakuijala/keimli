// Join the closure index (closure.mjs) with the droplet runs (droplets.mjs): for every attractor type, its self-closure
// C(A, A) (random phases, crossover rate r, one step of f) against the survival of a whole-lattice domain of the type
// in random phases under mixing (swap 0.1) and partial settling (median < 1). The prediction: survival iff closure ~ 1.
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const r = Number(process.argv[2] ?? 0.25);
console.log(provLine(provenance(import.meta.url)));
console.log(`| dictionary | type | period | basin | self-closure C(A, A), r = ${r}, 1 step | random-phase domain share after 400 turns, swap 0.1, median 0 / 0.25 / 0.5 / 1 | coherent domain, same |`);
console.log('|---|---|---|---|---|---|---|');
const pts = [];
for (const f of fs.readdirSync(dir + '/paper/data/droplets').filter(f => f.endsWith('.json'))) {
  const d = JSON.parse(fs.readFileSync(dir + '/paper/data/droplets/' + f)), cf = dir + `/paper/data/closure/closure-${d.dict}.json`; if (!fs.existsSync(cf)) continue;
  const c = JSON.parse(fs.readFileSync(cf));
  for (const t of d.types) {
    const ct = c.types.find(x => x.id === t.id); if (!ct || ct.period !== t.period || Math.abs(ct.basin - t.basin) > 1e-9) { console.error('type mismatch', d.dict, t.id); continue; }
    const self = c.rows.find(x => x.A === t.id && x.B === t.id && x.r === r && x.steps === 1).closed;
    const surv = ph => [0, 0.25, 0.5, 1].map(m => d.runs.find(x => x.whole && x.Y === t.id && x.phase === ph && x.m === m)?.xT);
    const sr = surv('random'), sc = surv('coherent');
    pts.push([self, sr.slice(0, 3).reduce((a, b) => a + b, 0) / 3]);
    console.log(`| ${d.dict} | #${t.id} | ${t.period} | ${(100 * t.basin).toFixed(2)} % | ${(100 * self).toFixed(0)} % | ${sr.map(v => (100 * v).toFixed(0)).join(' / ')} % | ${sc.map(v => (100 * v).toFixed(0)).join(' / ')} % |`);
  }
}
const mx = pts.reduce((a, p) => a + p[0], 0) / pts.length, my = pts.reduce((a, p) => a + p[1], 0) / pts.length;
const cov = pts.reduce((a, p) => a + (p[0] - mx) * (p[1] - my), 0), vx = pts.reduce((a, p) => a + (p[0] - mx) ** 2, 0), vy = pts.reduce((a, p) => a + (p[1] - my) ** 2, 0);
console.log(`\nAcross ${pts.length} types: correlation between self-closure and the mean random-phase survival at median < 1, r = ${(cov / Math.sqrt(vx * vy)).toFixed(2)}. Types with closure ≥ 99 %: ${pts.filter(p => p[0] >= 0.99).length}, of which surviving (> 90 %): ${pts.filter(p => p[0] >= 0.99 && p[1] > 0.9).length}; types with closure < 90 %: ${pts.filter(p => p[0] < 0.9).length}, of which surviving: ${pts.filter(p => p[0] < 0.9 && p[1] > 0.9).length}.`);
