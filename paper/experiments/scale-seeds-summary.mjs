// Tables for paper/results/dictionary-size-seeds.md: per size, the median and interquartile range over the 11 designs
// (seeds 1..11) of the types designed, the types reached by the map, the stray share, the types alive at turn 2,000 on
// the frame, the entropy, the transient share, the domains, the block change and the generation seconds, with seed 1's
// value beside the median. Reads paper/data/design{,-seeds}/*.json, paper/data/scale-seeds/{map,run}-*.json; writes
// paper/data/scale-seeds/summary.{json,md}. Usage: node paper/experiments/scale-seeds-summary.mjs
import fs from 'node:fs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const rd = f => fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : null;
const q = (a, p) => { const s = a.filter(v => v !== null && v !== undefined && !Number.isNaN(v)).sort((x, y) => x - y); if (!s.length) return null; const i = (s.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return s[lo] + (s[hi] - s[lo]) * (i - lo); };
const stat = a => ({ n: a.filter(v => v !== null && v !== undefined).length, median: q(a, 0.5), q1: q(a, 0.25), q3: q(a, 0.75), min: q(a, 0), max: q(a, 1), seed1: a[0] ?? null });
const KEYS = ['designed', 'reached', 'stray', 'alive', 'entropy', 'transient', 'domains', 'blockChange', 'seconds'];
const rows = [];
for (let n = 8; n <= 26; n++) {
  const name = `ca-size-${String(n).padStart(2, '0')}`, designs = [];
  for (let seed = 1; seed <= 11; seed++) {
    const tag = seed === 1 ? name : `${name}-s${seed}`, d = rd(seed === 1 ? `${dir}/paper/data/design/${name}.json` : `${dir}/paper/data/design-seeds/${tag}.json`);
    const m = rd(`${dir}/paper/data/scale-seeds/map-${tag}.json`), r = rd(`${dir}/paper/data/scale-seeds/run-${tag}-frame-s${seed}-n256.json`);
    // seconds: the placement, verification and census without the pattern enumeration (cached and shared by the seeds); seed-1 cold time from its batch log
    const log = seed === 1 && (fs.existsSync(`${dir}/paper/data/design/${name}.log`) || fs.existsSync(`${dir}/paper/data/design/ca-size-${n}.log`)) ? fs.readFileSync(fs.existsSync(`${dir}/paper/data/design/${name}.log`) ? `${dir}/paper/data/design/${name}.log` : `${dir}/paper/data/design/ca-size-${n}.log`, 'utf8').match(/; ([\d.]+) s \{/) : null;
    designs.push({ seed, approach: d?.approach ?? null, designed: d?.nTypes ?? null, kinds: d?.types ?? null, scheduled: d?.scheduled ?? null, seconds: d ? +(d.seconds - (d.times.patterns - d.times.form)).toFixed(1) : null, cold: log ? Number(log[1]) : null, form: d ? `${d.form.lens.join('+')} d${d.form.d} ${d.form.first}` : null, pads: d?.patterns?.distinctPads ?? null,
      reached: m?.designedReached ?? null, stray: m?.strayShare ?? null, transientMap: m?.transientMean ?? null,
      alive: r?.summary.aliveEnd ?? null, entropy: r?.summary.entropyEnd ?? null, transient: r?.summary.transientEnd ?? null, domains: r?.summary.domainsEnd ?? null, blockChange: r?.summary.blockChangeEnd ?? null });
  }
  const row = { n, name, designs }; for (const k of KEYS) row[k] = stat(designs.map(d => d[k]));
  row.failed = designs.filter(d => d.designed === null).length;
  rows.push(row);
}
const prov = provenance(import.meta.url, {});
const S = `${dir}/paper/data/scale-seeds`; fs.mkdirSync(S, { recursive: true });
fs.writeFileSync(`${S}/summary.json`, JSON.stringify({ provenance: prov, rows }));
const f = (v, d = 2) => v === null || v === undefined ? '–' : Number.isInteger(v) ? String(v) : v.toFixed(d);
const pct = v => v === null || v === undefined ? '–' : (100 * v).toFixed(1) + ' %';
const cell = (st, fmt = f) => st.median === null ? '–' : `${fmt(st.median)} [${fmt(st.q1)}–${fmt(st.q3)}] · ${fmt(st.seed1)}`;
const md = [provLine(prov), '', 'Each cell: median [interquartile range] over the 11 designs · the seed-1 (shipped) value.', '',
  '## Designed types, the map alone, and generation time', '',
  '| log2 size | designs | types designed | reached by the map | stray share | placement + verification + census s (the pattern enumeration is cached) | seed 1 cold, s |', '|---|---|---|---|---|---|---|',
  ...rows.map(r => `| ${r.n} | ${11 - r.failed} | ${cell(r.designed, v => f(v, 0))} | ${cell(r.reached, v => f(v, 0))} | ${cell(r.stray, pct)} | ${cell(r.seconds, v => f(v, 0))} | ${f(r.designs[0].cold, 0)} |`),
  '', '## The frame, 256², 2,000 turns, one run per design (lattice seed = design seed)', '',
  '| log2 size | alive at 2,000 | entropy (bits) | transients | domains | block change |', '|---|---|---|---|---|---|',
  ...rows.map(r => `| ${r.n} | ${cell(r.alive, v => f(v, 1))} | ${cell(r.entropy)} | ${cell(r.transient, pct)} | ${cell(r.domains, v => f(v, 0))} | ${cell(r.blockChange, v => f(v, 3))} |`),
  '', '## The approaches per size (seed: form, Gray factor, period cap, pattern order → types designed / alive)', '',
  ...rows.map(r => `- 2^${r.n}: ` + r.designs.map(d => d.designed === null ? `s${d.seed} failed` : `s${d.seed} ${d.form}, ×${d.approach?.grayFactor ?? 1}, p${d.approach?.periods ?? 4}, ${d.approach?.order ?? 'shortest'} → ${d.designed} / ${d.alive ?? '–'}`).join('; ')),
  ''];
fs.writeFileSync(`${S}/summary.md`, md.join('\n'));
console.log(md.join('\n'));
