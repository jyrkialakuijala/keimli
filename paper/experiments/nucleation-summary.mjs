// Summary of the nucleation tests (paper/data/nucleation/*.json) as Markdown on stdout: the probability that a disc
// grows against its radius and the critical radius R* (N1); the spontaneous appearance of the fixed point in a
// disordered sea: waiting time, clusters at first appearance, final share, against the lattice area (N2, N3); the
// in-phase control; discs against the sea's disorder (R* against order); the effective radius against time of the
// supercritical discs (the growth law).
// Usage: node paper/experiments/nucleation-summary.mjs [paper/data/nucleation]
import fs from 'node:fs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const dDir = process.argv[2] || dir + '/paper/data/nucleation';
const files = fs.readdirSync(dDir).filter(f => f.endsWith('.json')).map(f => JSON.parse(fs.readFileSync(`${dDir}/${f}`)));
const mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : NaN, pct = v => (100 * v).toFixed(0) + ' %';
const med = a => { if (!a.length) return NaN; const s = [...a].sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; };
const grows = r => r.xT >= 0.5, dies = r => r.xT < 0.01;
const out = [`# Nucleation tests: ${files.length} job files`, ''];
for (const dict of [...new Set(files.map(f => f.dict))]) {
  const fl = files.filter(f => f.dict === dict); const f0 = fl[0];
  out.push(`## ${dict}: X = fixed point (basin ${(100 * f0.X.basin).toFixed(2)} %), Y = ${f0.Y.period}-cycle (basin ${(100 * f0.Y.basin).toFixed(1)} %), three passes`, '');
  // N1: radius series
  const rad = fl.filter(f => f.mode === 'radius');
  if (rad.length) {
    const sets = [...new Set(rad.map(f => `${f.p}/${f.m}`))], radii = [...new Set(rad.flatMap(f => f.runs.map(r => r.r)))].sort((a, b) => a - b);
    out.push(`### N1. Discs of X in an in-phase sea of Y: share of seeds in which the disc grows (share ≥ 50 % at turn ${rad[0].T}), by radius; n = seeds`, '', '| swap/median | ' + radii.map(r => 'R=' + r).join(' | ') + ' | R* (first R with P ≥ ½) | n |', '|---|' + radii.map(() => '---').join('|') + '|---|---|');
    for (const s of sets) { const [p, m] = s.split('/').map(Number); const fs_ = rad.filter(f => f.p === p && f.m === m); let rstar = '> ' + radii[radii.length - 1];
      const cells = radii.map(r => { const rr = fs_.flatMap(f => f.runs.filter(x => x.r === r)); const pg = mean(rr.map(grows)); return { r, pg, pd: mean(rr.map(dies)), n: rr.length }; });
      for (const c of cells) if (c.pg >= 0.5) { rstar = String(c.r); break; }
      out.push(`| ${s} | ` + cells.map(c => `${pct(c.pg)}${c.pd > 0 && c.pg > 0 ? ` (${pct(c.pd)} die)` : ''}`).join(' | ') + ` | ${rstar} | ${cells[0]?.n ?? 0} |`); }
    out.push('');
    // growth law: effective radius sqrt(share·N/π) over time for R = 16 (and 8), mean over seeds
    out.push(`### Growth of the supercritical disc: effective radius √(share·N/π) in cells, mean over seeds`, '', '| swap/median | R₀ | ' + [0, 100, 200, 300, 400, 600, 800, 1000].join(' | ') + ' | ΔR per 100 turns (turns 100–400) |', '|---|---|' + [0, 100, 200, 300, 400, 600, 800, 1000].map(() => '---').join('|') + '|---|');
    for (const s of sets) { const [p, m] = s.split('/').map(Number); for (const R0 of [8, 16]) { const tr = rad.filter(f => f.p === p && f.m === m).flatMap(f => f.runs.filter(x => x.r === R0).map(x => x.track)); if (!tr.length) continue; const N = rad[0].n ** 2;
      const at = t => mean(tr.map(k => { const s_ = (k.find(z => z[0] === t) || k[k.length - 1])[1]; return Math.sqrt(s_ * N / Math.PI); }));
      const v = (at(400) - at(100)) / 3; out.push(`| ${s} | ${R0} | ` + [0, 100, 200, 300, 400, 600, 800, 1000].map(t => at(t).toFixed(1)).join(' | ') + ` | ${v.toFixed(1)} |`); } }
    out.push('');
  }
  // N2, N3: spontaneous
  const sp = fl.filter(f => f.mode === 'spontaneous');
  if (sp.length) {
    out.push(`### N2–N3. A sea of Y with no X planted: when and how X appears (q = 1: every cell a random phase; q = 0: in phase, the Lemma 1 control)`, '', '| swap/median | q | size | first X cell (turn; median, range) | X ≥ 0.1 % (turn) | clusters when X ≥ 0.1 % (mean) | most clusters at once (mean) | X at the end | Y at the end | n |', '|---|---|---|---|---|---|---|---|---|---|');
    for (const s of [...new Set(sp.map(f => `${f.p}/${f.m}`))]) for (const q of [0, 1]) for (const n of [64, 128, 256]) {
      const [p, m] = s.split('/').map(Number); const fs_ = sp.filter(f => f.p === p && f.m === m && f.n === n && f.runs[0].q === q); if (!fs_.length) continue;
      const rr = fs_.map(f => f.runs[0]); const firsts = rr.map(r => r.first ?? Infinity), f01 = rr.map(r => r.first01 ?? Infinity);
      const cl01 = rr.map(r => { const k = r.track.find(z => z[1] >= 0.001); return k ? k[3] : NaN; }).filter(v => !isNaN(v));
      const maxcl = rr.map(r => Math.max(...r.track.map(z => z[3] ?? 0)));
      const fmt = a => { const fin = a.filter(v => v !== Infinity); return fin.length ? `${med(fin)} (${Math.min(...fin)}–${Math.max(...fin)})${fin.length < a.length ? `, ${a.length - fin.length} never` : ''}` : 'never'; };
      out.push(`| ${s} | ${q} | ${n}² | ${fmt(firsts)} | ${fmt(f01)} | ${cl01.length ? mean(cl01).toFixed(1) : '–'} | ${mean(maxcl).toFixed(1)} | ${pct(mean(rr.map(r => r.xT)))} | ${pct(mean(rr.map(r => r.yT)))} | ${rr.length} |`); }
    out.push('');
  }
  // q series
  const qq = fl.filter(f => f.mode === 'q');
  if (qq.length) {
    const qs = [...new Set(qq.flatMap(f => f.runs.map(r => r.q)))].sort((a, b) => a - b);
    out.push(`### R* against the sea's order: discs of radius R₀ in a sea with a fraction q of cells in random phases; share of seeds in which the disc grows`, '', '| swap/median | R₀ | ' + qs.map(q => 'q=' + q).join(' | ') + ' | n |', '|---|---|' + qs.map(() => '---').join('|') + '|---|');
    for (const s of [...new Set(qq.map(f => `${f.p}/${f.m}`))]) for (const R0 of [...new Set(qq.flatMap(f => f.runs.map(r => r.r)))].sort((a, b) => b - a)) { const [p, m] = s.split('/').map(Number);
      const cells = qs.map(q => { const rr = qq.filter(f => f.p === p && f.m === m).flatMap(f => f.runs.filter(x => x.q === q && x.r === R0)); return { pg: mean(rr.map(grows)), n: rr.length }; }); if (!cells[0].n) continue;
      out.push(`| ${s} | ${R0} | ` + cells.map(c => pct(c.pg)).join(' | ') + ` | ${cells[0].n} |`); }
    out.push('');
  }
}
process.stdout.write(out.join('\n') + '\n');
