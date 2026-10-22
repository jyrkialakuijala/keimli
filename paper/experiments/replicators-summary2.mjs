// Summary of the replicator Monte Carlo (replicators.mjs, v2 outputs), censoring-aware: a seed whose leader never reached
// a share is censored at the last turn, not dropped. The median turn to 10, 50 and 90 % is the Kaplan-Meier median over
// seeds ("> T" when fewer than half the seeds reached it), with a 95 % bootstrap interval over seeds (2,000 resamples).
// Usage: node paper/experiments/replicators-summary2.mjs [paper/data/replicators-v2] > paper/results/replicators-table-v2.md
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const inDir = process.argv[2] || dir + '/paper/data/replicators-v2';
const files = fs.readdirSync(inDir).filter(f => f.endsWith('.json') && !f.includes('-seed')).sort();
// Kaplan-Meier median of event times with right-censoring at T: events {t, done}; returns the turn or Infinity
function kmMedian(ev) {
  const s = ev.slice().sort((a, b) => a.t - b.t || b.done - a.done); let S = 1, atRisk = s.length;
  for (let i = 0; i < s.length;) { const t = s[i].t; let d = 0, c = 0; while (i < s.length && s[i].t === t) { if (s[i].done) d++; else c++; i++; }
    if (d) { S *= 1 - d / atRisk; if (S <= 0.5) return t; } atRisk -= d + c; }
  return Infinity;
}
let rs = 12345; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
function boot(ev, B = 2000) { const m = []; for (let b = 0; b < B; b++) m.push(kmMedian(Array.from(ev, () => ev[Math.floor(rnd() * ev.length)]))); m.sort((a, b) => a - b); return [m[Math.floor(0.025 * B)], m[Math.floor(0.975 * B)]]; }
const f = (v, T) => v === Infinity ? `> ${T}` : String(v);
console.log(provLine(provenance(import.meta.url)));
console.log('| rule | setting | n | seeds | leader k (median) | leader basin (median) | first seen (median) | 10 %: KM median [95 % CI] | 50 %: KM median [95 % CI] | 90 %: KM median [95 % CI] | seeds reaching 50 % | final share (median) | distinct leaders |');
console.log('|---|---|---|---|---|---|---|---|---|---|---|---|---|');
for (const fn of files) {
  const r = JSON.parse(fs.readFileSync(`${inDir}/${fn}`, 'utf8')), T = r.turns - 1;
  const bySeed = new Map(); for (const row of r.rows) { const s = bySeed.get(row.seed) || []; s.push(row); bySeed.set(row.seed, s); }
  const leaders = [...bySeed.values()].map(rows => rows.reduce((a, b) => (b.final > a.final ? b : a)));
  const med = a => { const s = a.slice().sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; };
  const cell = key => { const ev = leaders.map(l => l[key] === null ? { t: T, done: 0 } : { t: l[key], done: 1 }); const m = kmMedian(ev), [lo, hi] = boot(ev); return `${f(m, T)} [${f(lo, T)}, ${f(hi, T)}]`; };
  const reach50 = leaders.filter(l => l.t50 !== null).length;
  console.log(`| ${r.dict} | ${r.page ? 'page frame' : `swap ${r.pm}, median ${r.ps}`}${r.salt ? ', salted by turn' : ''} | ${r.n} | ${leaders.length} | ${med(leaders.map(l => l.k))} | ${(100 * med(leaders.map(l => l.basin))).toFixed(2)} % | ${med(leaders.map(l => l.first))} | ${cell('t10')} | ${cell('t50')} | ${cell('t90')} | ${reach50} of ${leaders.length} | ${(100 * med(leaders.map(l => l.final))).toFixed(0)} % | ${new Set(leaders.map(l => l.id)).size} |`);
}
