// Tables for paper/results/dictionary-size.md from paper/data/design/ca-size-*.json (the designs), paper/data/scale/map-*.json
// (the map alone) and paper/data/scale/run-*.json (the lattice): one row per size, means over seeds with the range.
// Writes paper/data/scale/summary.json (everything, for the plot) and paper/data/scale/summary.md (the tables, with a
// provenance line). Usage: node paper/experiments/scale-summary.mjs
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const D = `${dir}/paper/data/design`, S = `${dir}/paper/data/scale`;
const rd = f => fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : null;
const mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : null, rng = a => a.length ? [Math.min(...a), Math.max(...a)] : null;
const rows = [];
for (let n = 8; n <= 26; n++) {
  const name = `ca-size-${String(n).padStart(2, '0')}`, d = rd(`${D}/${name}.json`), m = rd(`${S}/map-${name}.json`);
  if (!d) continue;
  // generation seconds: the batch log's (without the pattern cache) when there is one, else the design file's
  const log = (fs.existsSync(`${D}/${name}.log`) || fs.existsSync(`${D}/ca-size-${n}.log`)) ? fs.readFileSync(fs.existsSync(`${D}/${name}.log`) ? `${D}/${name}.log` : `${D}/ca-size-${n}.log`, 'utf8').match(/; ([\d.]+) s \{/) : null;
  const row = { n, name, V: d.V, designed: d.nTypes, kinds: d.types, scheduled: d.scheduled, schedule: d.schedule, form: d.form, spots: d.spots, patterns: d.patterns, seconds: log ? Number(log[1]) : d.seconds, times: d.times, workers: d.workers, censusStray: d.census.stray, censusTransient: d.census.transientMean };
  if (m) Object.assign(row, { realised: m.attractors, reached: m.designedReached, reachedKinds: m.reachedKinds, strays: m.strayAttractors, strayShare: m.strayShare, transient: m.transientMean, transientP90: m.transientP90, basinZero: m.basinZero, closure: m.closure.map(c => c['C0.25']), closureMin: Math.min(...m.closure.map(c => c['C0.25'])), closureStrays: m.closure.filter(c => c.type === null).map(c => c['C0.25']) });
  for (const setting of ['frame', 'uniform']) {
    const runs = [1, 2, 3].map(s => rd(`${S}/run-${name}-${setting}-s${s}-n256.json`)).filter(Boolean);
    if (!runs.length) continue;
    const g = k => runs.map(r => r.summary[k]);
    row[setting] = { seeds: runs.length, alive: mean(g('aliveEnd')), aliveRange: rng(g('aliveEnd')), alive200: mean(runs.map(r => r.summary.aliveAt[200])), alive1000: mean(runs.map(r => r.summary.aliveAt[1000])),
      byKind: ['gray', 'chase', 'fixed'].map(k => mean(runs.map(r => r.summary.byKindEnd[k]))), entropy: mean(g('entropyEnd')), entropyRange: rng(g('entropyEnd')), transient: mean(g('transientEnd')), domains: mean(g('domainsEnd')), domainsRange: rng(g('domainsEnd')),
      blockChange: mean(g('blockChangeEnd')), blockChangeLate: mean(g('blockChangeLate')), blockRange: rng(g('blockChangeEnd')), seconds: mean(g('seconds')),
      curves: runs[0].rows.map(r => ({ t: r.t, alive: mean(runs.map(x => x.rows.find(y => y.t === r.t)?.alive ?? NaN)), blockChange: mean(runs.map(x => x.rows.find(y => y.t === r.t)?.blockChange ?? NaN)) })) };
  }
  const big = rd(`${S}/run-${name}-frame-s1-n512.json`); if (big) row.frame512 = { alive: big.summary.aliveEnd, entropy: big.summary.entropyEnd, domains: big.summary.domainsEnd, blockChange: big.summary.blockChangeEnd, transient: big.summary.transientEnd, seconds: big.summary.seconds };
  rows.push(row);
}
const prov = provenance(import.meta.url, {});
fs.writeFileSync(`${S}/summary.json`, JSON.stringify({ provenance: prov, rows }));
const f1 = v => v === null || v === undefined || Number.isNaN(v) ? '–' : typeof v === 'number' ? (Math.abs(v) >= 100 || Number.isInteger(v) ? String(Math.round(v)) : v.toFixed(2)) : String(v);
const pct = v => v === null || v === undefined ? '–' : (100 * v).toFixed(1) + ' %';
const r1 = (v, r) => v === null || v === undefined ? '–' : `${f1(v)}${r && r[0] !== r[1] ? ` (${f1(r[0])}–${f1(r[1])})` : ''}`;
const md = [provLine(prov), '', '## The schedule and the construction per size', '',
  '| log2 size | bytes | safe spots (letter-free) | groups | distinct pads | scheduled Gray / chasing / fixed | built Gray / chasing / fixed | types | head bits | seconds (workers) |', '|---|---|---|---|---|---|---|---|---|---|',
  ...rows.map(r => `| ${r.n} | ${r.V.toLocaleString('en-US')} | ${r.spots.safe} (${r.spots.letterFree ?? '–'}) | ${r.spots.groups} | ${r.patterns.distinctPads} | ${r.scheduled.gray} / ${r.scheduled.chase} / ${r.scheduled.fixed} | ${r.kinds.gray} / ${r.kinds.chase} / ${r.kinds.fixed} | **${r.designed}** | ${r.form.headBits} | ${r.seconds} (${r.workers}) |`),
  '', '## The map alone (16,384 random cells)', '',
  '| log2 size | types designed | attractors realised | designed reached | stray attractors (share of cells) | transient mean (p90) | designed types with an empty basin | C(A,A) at r = 0.25, min over the 20 largest | C(A,A) of the strays |', '|---|---|---|---|---|---|---|---|---|',
  ...rows.filter(r => r.realised !== undefined).map(r => `| ${r.n} | ${r.designed} | ${r.realised} | ${r.reached} | ${r.strays} (${pct(r.strayShare)}) | ${r.transient.toFixed(1)} (${r.transientP90}) | ${r.basinZero} | ${pct(r.closureMin)} | ${r.closureStrays.length ? r.closureStrays.map(pct).join(', ') : '–'} |`),
  '', '## The lattice, 256², 2,000 turns, 3 seeds (mean, and the range over seeds where the seeds differ)', '',
  '| log2 size | designed | frame: alive at 2,000 | frame: Gray / chasing / fixed alive | frame: entropy (bits) | frame: transients | frame: domains | frame: block change | uniform: alive | uniform: entropy | uniform: transients | uniform: domains | uniform: block change |', '|---|---|---|---|---|---|---|---|---|---|---|---|---|',
  ...rows.filter(r => r.frame || r.uniform).map(r => { const F = r.frame || {}, U = r.uniform || {}; return `| ${r.n} | ${r.designed} | ${r1(F.alive, F.aliveRange)} | ${F.byKind ? F.byKind.map(f1).join(' / ') : '–'} | ${r1(F.entropy, F.entropyRange)} | ${pct(F.transient)} | ${r1(F.domains, F.domainsRange)} | ${r1(F.blockChange, F.blockRange)} | ${r1(U.alive, U.aliveRange)} | ${r1(U.entropy, U.entropyRange)} | ${pct(U.transient)} | ${r1(U.domains, U.domainsRange)} | ${r1(U.blockChange, U.blockRange)} |`; }),
  ''];
const big = rows.find(r => r.frame512); if (big) md.push(`2^${big.n} at 512², frame, seed 1: alive ${big.frame512.alive}, entropy ${big.frame512.entropy.toFixed(2)}, transients ${pct(big.frame512.transient)}, domains ${big.frame512.domains}, block change ${big.frame512.blockChange.toFixed(3)} (${big.frame512.seconds.toFixed(0)} s).`, '');
fs.writeFileSync(`${S}/summary.md`, md.join('\n'));
console.log(md.join('\n'));
