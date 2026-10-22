// Summarise the replicator Monte Carlo (replicators.mjs): per dictionary, size and setting, the leading species of each
// seed, with its basin under the decoder alone, the waiting time 1 / (N b) that basin predicts for a first appearance,
// the observed first appearance (a k-cycle is visible from turn 2k - 1), and the turns at which it held 10, 50 and 90 %.
// Usage: node paper/experiments/replicators-summary.mjs [paper/data/replicators] > paper/results/replicators-table.md
import fs from 'node:fs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const inDir = process.argv[2] || dir + '/paper/data/replicators';
const files = fs.readdirSync(inDir).filter(f => f.endsWith('.json') && !f.includes('-seed')).sort();
const med = a => { const s = a.filter(v => v !== null && v !== undefined).sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : null; };
const fmt = v => v === null ? '-' : typeof v === 'number' && !Number.isInteger(v) ? v.toFixed(2) : String(v);
console.log('| dictionary | setting | n | leader k | basin b | 1/(N b) turns | first seen (median) | 10 % | 50 % | 90 % | final share | species ever ≥ 1 % | seeds where leader took 90 % | latest newcomer ≥ 1 %: first seen, k, basin, peak |');
console.log('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|');
for (const f of files) {
  const r = JSON.parse(fs.readFileSync(`${inDir}/${f}`, 'utf8')), N = r.n * r.n;
  const bySeed = new Map(); for (const row of r.rows) { const s = bySeed.get(row.seed) || []; s.push(row); bySeed.set(row.seed, s); }
  const leaders = [...bySeed.values()].map(rows => rows.reduce((a, b) => (b.final > a.final ? b : a)));
  const k = med(leaders.map(l => l.k)), basin = med(leaders.map(l => l.basin)), wait = basin > 0 ? 1 / (N * basin) : null;
  const majors = r.rows.filter(x => x.t1 !== null), major = new Set(majors.map(x => x.id)).size, took = leaders.filter(l => l.t90 !== null).length;
  const late = majors.length ? majors.reduce((a, b) => (b.first > a.first ? b : a)) : null;
  const lateText = late ? `${late.first}, ${late.k}, ${(100 * late.basin).toFixed(2)} %, ${(100 * late.max).toFixed(0)} %` : '-';
  console.log(`| ${r.dict} | ${r.page ? 'page frame' : `swap ${r.pm}, median ${r.ps}`} | ${r.n} | ${fmt(k)} | ${basin !== null ? (100 * basin).toFixed(2) + ' %' : '-'} | ${wait === null ? '-' : wait < 1 ? '< 1' : wait.toFixed(0)} | ${fmt(med(leaders.map(l => l.first)))} | ${fmt(med(leaders.map(l => l.t10)))} | ${fmt(med(leaders.map(l => l.t50)))} | ${fmt(med(leaders.map(l => l.t90)))} | ${(100 * med(leaders.map(l => l.final))).toFixed(0)} % | ${major} | ${took} of ${leaders.length} | ${lateText} |`);
}
