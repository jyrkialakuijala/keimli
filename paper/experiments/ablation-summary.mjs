// Summarise the ablation batch: paper/data/ablation/*.json -> groups over seeds by (cond, rewrite, pm, ps, salt, n, dict);
// per sample turn the mean and the 10th / 90th percentiles of d1, byte entropy, distinct cells, plane magnetisation,
// activity, and the correlation lengths xi_x, xi_y (the r where the mean C(r) over the 16 byte groups crosses 1/2,
// interpolated linearly in log r; 0.5 when C(1) is already below 1/2, 64 when C(64) is still above). Writes
// summary-final.md (the final turn), series.csv (every sample turn) and curves.csv (the final C(r) per group and axis).
// Usage: node paper/experiments/ablation-summary.mjs [dir=paper/data/ablation] [dict=ca-swarm-f]
import fs from 'node:fs';
const root = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dir = opt.dir || root + '/paper/data/ablation';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));
const runs = files.map(f => JSON.parse(fs.readFileSync(`${dir}/${f}`, 'utf8')));
const meanOf = a => a.reduce((s, v) => s + v, 0) / a.length;
export function xi(c, rs) {   // c: C(r) per byte group for each r; rs: the distances
  const m = c.map(meanOf);
  if (m[0] < 0.5) return 0.5;
  for (let i = 1; i < rs.length; i++) if (m[i] < 0.5) { const f = (m[i - 1] - 0.5) / (m[i - 1] - m[i]); return Math.exp(Math.log(rs[i - 1]) + f * (Math.log(rs[i]) - Math.log(rs[i - 1]))); }
  return rs[rs.length - 1];
}
const q = (a, p) => { const s = [...a].sort((x, y) => x - y); const i = (s.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return s[lo] + (s[hi] - s[lo]) * (i - lo); };
const stat = a => ({ mean: meanOf(a), p10: q(a, 0.1), p90: q(a, 0.9), n: a.length });
const groups = new Map();
for (const r of runs) {
  const key = [r.cond, r.rewrite, r.pm, r.ps, r.salt, r.n, r.turns, r.dict].join('|');
  if (!groups.has(key)) groups.set(key, { cond: r.cond, rewrite: r.rewrite, pm: r.pm, ps: r.ps, rate: r.rate, salt: r.salt, n: r.n, turns: r.turns, dict: r.dict, rs: r.rs, runs: [] });
  groups.get(key).runs.push(r);
}
const KEYS = ['d1', 'ent', 'distinct', 'planeMag', 'moved', 'smoothed', 'rewritten', 'xix', 'xiy', 'cx1', 'cy1'];
const series = [], finals = [], curves = [];
const condOrder = ['MSR', 'MS-', 'M-R', '-SR', 'M--', '-S-', '--R'];
const sorted = [...groups.values()].sort((a, b) => condOrder.indexOf(a.cond) - condOrder.indexOf(b.cond) || a.rewrite.localeCompare(b.rewrite) || a.dict.localeCompare(b.dict) || a.n - b.n || b.pm - a.pm || b.ps - a.ps || a.salt - b.salt);
for (const g of sorted) {
  const T = g.runs[0].rows.map(r => r.t);
  for (let i = 0; i < T.length; i++) {
    const vals = {}; for (const k of KEYS) vals[k] = [];
    for (const r of g.runs) {
      const row = r.rows[i]; if (!row || row.t !== T[i]) continue;
      vals.d1.push(row.d1 ?? NaN); vals.ent.push(row.ent); vals.distinct.push(row.distinct); vals.planeMag.push(row.planeMag); vals.moved.push(row.moved); vals.smoothed.push(row.smoothed); vals.rewritten.push(row.rewritten);
      vals.xix.push(xi(row.cx, r.rs)); vals.xiy.push(xi(row.cy, r.rs)); vals.cx1.push(meanOf(row.cx[0])); vals.cy1.push(meanOf(row.cy[0]));
    }
    const s = {}; for (const k of KEYS) s[k] = stat(vals[k].filter(v => !Number.isNaN(v)));
    const rec = { ...g, runs: undefined, t: T[i], seeds: g.runs.length, s };
    series.push(rec); if (i === T.length - 1) finals.push(rec);
  }
  // final C(r) curves, mean over seeds and byte groups, per axis; and per byte group along x
  const last = g.runs.map(r => r.rows[r.rows.length - 1]);
  for (const axis of ['cx', 'cy']) curves.push({ ...g, runs: undefined, axis, c: g.rs.map((r, i) => meanOf(last.map(row => meanOf(row[axis][i])))) });
  curves.push({ ...g, runs: undefined, axis: 'cx-bygroup-r1', c: Array.from({ length: 16 }, (_, k) => meanOf(last.map(row => row.cx[0][k]))) });
  curves.push({ ...g, runs: undefined, axis: 'cx-bygroup-r8', c: Array.from({ length: 16 }, (_, k) => meanOf(last.map(row => row.cx[5][k]))) });
  if (last[0].px1) curves.push({ ...g, runs: undefined, axis: 'px1-byplane', c: Array.from({ length: 128 }, (_, j) => meanOf(last.map(row => row.px1[j]))) });
}
const gcols = ['cond', 'rewrite', 'pm', 'ps', 'rate', 'salt', 'n', 'turns', 'dict'];
const f3 = v => typeof v === 'number' ? (Math.abs(v) < 0.01 && v !== 0 ? v.toExponential(2) : v.toFixed(3)) : String(v);
fs.writeFileSync(`${dir}/series.csv`, [gcols, 't', 'seeds', ...KEYS.flatMap(k => [k + '_mean', k + '_p10', k + '_p90'])].flat().join(',') + '\n' +
  series.map(r => [...gcols.map(c => r[c]), r.t, r.seeds, ...KEYS.flatMap(k => [r.s[k].mean, r.s[k].p10, r.s[k].p90])].map(v => typeof v === 'number' ? v.toPrecision(6) : v).join(',')).join('\n') + '\n');
fs.writeFileSync(`${dir}/curves.csv`, [...gcols, 'axis', 'values'].join(',') + '\n' + curves.map(r => [...gcols.map(c => r[c]), r.axis, r.c.map(v => v.toPrecision(5)).join(' ')].join(',')).join('\n') + '\n');
const band = s => `${f3(s.mean)} [${f3(s.p10)}, ${f3(s.p90)}]`;
const md = [`# Ablation batch: the final turn\n`, `Generated by paper/experiments/ablation-summary.mjs from ${runs.length} runs in ${dir.replace(root + '/', '')}. Bulk statistics at the last sampled turn: mean over seeds with the 10th to 90th percentile band in brackets. ξ is the correlation length (C(r) = ½ crossing, cells; 0.5 means C(1) < ½, 64 means C(64) > ½). d1 is the fraction of bulk bits changed in the last turn; moved and smoothed are per bit per turn, rewritten per cell per turn, averaged over the sampling interval.\n`,
  '| cond | rewrite | dict | n | p swap (rate) | p median | salt | seeds | d1 | ξx | ξy | C(1) x | byte H | distinct | plane |m| |', '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|'];
for (const r of finals) md.push(`| ${r.cond} | ${r.rewrite} | ${r.dict} | ${r.n} | ${r.pm} (${r.rate.toFixed(3)}) | ${r.ps} | ${r.salt ? 'turn' : 'quenched'} | ${r.seeds} | ${band(r.s.d1)} | ${band(r.s.xix)} | ${band(r.s.xiy)} | ${f3(r.s.cx1.mean)} | ${f3(r.s.ent.mean)} | ${f3(r.s.distinct.mean)} | ${f3(r.s.planeMag.mean)} |`);
// growth of xi: at turns 100, 400, 1000 for each group
md.push('\n## ξx against turn (mean over seeds)\n');
const tPick = [10, 50, 100, 200, 400, 600, 800, 1000];
md.push('| cond | rewrite | dict | n | p swap | p median | salt | ' + tPick.map(t => `t=${t}`).join(' | ') + ' | d1 at ' + tPick.filter(t => t >= 100).map(t => t).join(', ') + ' |');
md.push('|---|---|---|---|---|---|---|' + '---|'.repeat(tPick.length) + '---|');
for (const g of sorted) {
  const pick = t => series.find(r => r.cond === g.cond && r.rewrite === g.rewrite && r.dict === g.dict && r.n === g.n && r.pm === g.pm && r.ps === g.ps && r.salt === g.salt && r.t === t);
  md.push(`| ${g.cond} | ${g.rewrite} | ${g.dict} | ${g.n} | ${g.pm} | ${g.ps} | ${g.salt ? 'turn' : 'quenched'} | ${tPick.map(t => { const r = pick(t); return r ? f3(r.s.xix.mean) : ''; }).join(' | ')} | ${tPick.filter(t => t >= 100).map(t => { const r = pick(t); return r ? f3(r.s.d1.mean) : ''; }).join(', ')} |`);
}
fs.writeFileSync(`${dir}/summary-final.md`, md.join('\n') + '\n');
console.log(md.join('\n'));
