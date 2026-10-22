// Summary of the matched three-pass droplet block: per dictionary, mode, pair, phase and (swap, median), the share of X at
// the last turn as a mean over seeds with a bootstrap 95 % interval, and the mean track; the radius series as share
// against radius; the start-replacement test; the melting-threshold scan as the (swap, median) point where the share at
// 200 turns first drops below one half. Markdown to stdout.
// Usage: node paper/experiments/droplets3-summary.mjs [paper/data/droplets3] [paper/data/start-replace] [paper/data/pstar]
import fs from 'node:fs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const [dDir = dir + '/paper/data/droplets3', sDir = dir + '/paper/data/start-replace', pDir = dir + '/paper/data/pstar'] = process.argv.slice(2);
const mean = a => a.reduce((x, y) => x + y, 0) / a.length, pct = v => (100 * v).toFixed(0) + ' %';
let bs = 12345; const brnd = () => (bs = (Math.imul(bs, 1664525) + 1013904223) >>> 0) / 4294967296;
function ci(a, B = 2000) { if (a.length < 2) return [a[0], a[0]]; const ms = []; for (let b = 0; b < B; b++) { let s = 0; for (let i = 0; i < a.length; i++) s += a[Math.floor(brnd() * a.length)]; ms.push(s / a.length); } ms.sort((x, y) => x - y); return [ms[Math.floor(0.025 * B)], ms[Math.floor(0.975 * B)]]; }
const cell = a => { if (!a.length) return '–'; const [lo, hi] = ci(a); return `${pct(mean(a))} [${pct(lo)}–${pct(hi)}] n=${a.length}`; };
const files = fs.existsSync(dDir) ? fs.readdirSync(dDir).filter(f => f.endsWith('.json')).map(f => JSON.parse(fs.readFileSync(`${dDir}/${f}`))).filter(f => f.centre && Array.isArray(f.runs)) : [];   // droplets3 files only
const out = [`# The matched three-pass droplet block: ${files.length} job files in ${dDir.replace(dir + '/', '')}`, ''];
const byDict = new Map(); for (const f of files) { if (!byDict.has(f.dict)) byDict.set(f.dict, []); byDict.get(f.dict).push(f); }
const name = t => t.period === 1 ? 'fixed point' : t.period + '-cycle';
for (const [dict, fl] of byDict) {
  const types = fl[0].types, T = fl[0].T, P = [...new Set(fl.map(f => f.p))].sort((a, b) => a - b), M = [...new Set(fl.map(f => f.m))].sort((a, b) => a - b);
  out.push(`## ${dict}: ${types.map(t => `#${t.id} ${name(t)}, basin ${(100 * t.basin).toFixed(2)} %`).join('; ')}; ${fl[0].n}², ${T} turns, ${fl[0].passes} passes, disc radius ${fl[0].R}`, '');
  const pick = (mode, X, Y, phase, p, m, r) => fl.filter(f => f.p === p && f.m === m).flatMap(f => f.runs.filter(x => x.mode === mode && x.X === X && x.Y === Y && x.phase === phase && (r === undefined || x.r === r)).map(x => x.xT));
  const table = (title, mode, X, Y, phase, r) => { const rows = [`### ${title}`, '', '| swap \\ median | ' + M.join(' | ') + ' |', '|---|' + M.map(() => '---').join('|') + '|']; let any = false;
    for (const p of P) { const cells = M.map(m => pick(mode, X, Y, phase, p, m, r)); if (cells.some(c => c.length)) any = true; rows.push(`| ${p} | ` + cells.map(cell).join(' | ') + ' |'); } if (any) out.push(...rows, ''); };
  for (const X of types) for (const Y of types) { if (X.id === Y.id) continue; for (const phase of ['coherent', 'random']) table(`#${X.id} (${name(X)}) disc in #${Y.id} (${name(Y)}), ${phase} phases: share of X at turn ${T} (start ${pct(fl[0].runs.find(x => x.mode === 'pair')?.x0 ?? 0)})`, 'pair', X.id, Y.id, phase); }
  for (const Y of types) for (const phase of ['coherent', 'random']) table(`Whole lattice #${Y.id} (${name(Y)}), ${phase} phases: share still on the type at turn ${T}`, 'whole', Y.id, Y.id, phase);
  for (const X of types.filter(t => t.period === 1)) for (const Y of types.filter(t => t.period > 1)) table(`#${X.id} (${name(X)}) planted after #${Y.id} (${name(Y)}) ran alone in random phases for 100 turns: share of X at the end`, 'premelt', X.id, Y.id, 'coherent');
  // the radius series
  const rad = fl.flatMap(f => f.runs.filter(x => x.mode === 'radius').map(x => ({ ...x, p: f.p, m: f.m })));
  if (rad.length) { const radii = [...new Set(rad.map(x => x.r))].sort((a, b) => a - b), sets = [...new Set(rad.map(x => `${x.p}/${x.m}`))];
    for (const X of types.filter(t => t.period === 1)) for (const Y of types.filter(t => t.period > 1)) for (const phase of ['coherent', 'random']) {
      out.push(`### Radius series: #${X.id} (${name(X)}) disc in #${Y.id} (${name(Y)}), ${phase} phases: share of X at the end against the radius`, '', '| swap/median \\ R | ' + radii.join(' | ') + ' |', '|---|' + radii.map(() => '---').join('|') + '|');
      for (const s of sets) { const [p, m] = s.split('/').map(Number); out.push(`| ${s} | ` + radii.map(r => cell(rad.filter(x => x.X === X.id && x.Y === Y.id && x.phase === phase && x.p === p && x.m === m && x.r === r).map(x => x.xT))).join(' | ') + ' |'); } out.push(''); } }
  // mean tracks of the fixed point in the open cycle, coherent, by setting
  const fp = types.find(t => t.period === 1), cyc = types.find(t => t.period > 1);
  if (fp && cyc) { out.push(`### Mean track of #${fp.id} (fixed point) disc in #${cyc.id} (${name(cyc)}), coherent phases: share of X every 200 turns`, '', '| swap/median | ' + [0, 200, 400, 600, 800, 1000, 1500, 2000].filter(t => t <= T).join(' | ') + ' |', '|---|' + [0, 200, 400, 600, 800, 1000, 1500, 2000].filter(t => t <= T).map(() => '---').join('|') + '|');
    for (const p of P) for (const m of M) { const tr = fl.filter(f => f.p === p && f.m === m).flatMap(f => f.runs.filter(x => x.mode === 'pair' && x.X === fp.id && x.Y === cyc.id && x.phase === 'coherent').map(x => x.track)); if (!tr.length) continue;
      out.push(`| ${p}/${m} | ` + [0, 200, 400, 600, 800, 1000, 1500, 2000].filter(t => t <= T).map(t => pct(mean(tr.map(k => (k.find(s => s[0] === t) || k[k.length - 1])[1])))).join(' | ') + ' |'); } out.push(''); }
}
// the start-replacement test
if (fs.existsSync(sDir)) for (const f of fs.readdirSync(sDir).filter(f => f.endsWith('.json'))) { const d = JSON.parse(fs.readFileSync(`${sDir}/${f}`));
  if (!Array.isArray(d.results)) continue;
  out.push(`## Start replacement: ${d.dict}, ${d.n}², ${d.T} turns, ${d.passes} passes, ${d.page ? 'the page frame' : 'uniform'}: ${f}`, '', '| seed | arm | fixed-point cells at start | after replacement | first seen (turn) | fixed-point share at the end |', '|---|---|---|---|---|---|');
  for (const r of d.results) out.push(`| ${r.seed} | ${r.arm} | ${r.fpCellsAtStart} | ${r.fpCellsAfterReplacement} | ${r.firstSeen ?? 'never'} | ${pct(r.finalFixedShare)} |`);
  for (const arm of ['control', 'replaced']) { const a = d.results.filter(r => r.arm === arm); if (a.length) out.push(`| mean | ${arm} | | | ${mean(a.map(r => r.firstSeen ?? d.T)).toFixed(0)} | ${cell(a.map(r => r.finalFixedShare))} |`); } out.push(''); }
// the melting threshold
if (fs.existsSync(pDir)) for (const f of fs.readdirSync(pDir).filter(f => f.endsWith('.json'))) { const d = JSON.parse(fs.readFileSync(`${pDir}/${f}`));
  if (!d.samples) continue;
  const P = [...new Set(d.runs.map(r => r.p))].sort((a, b) => a - b), M = [...new Set(d.runs.map(r => r.m))].sort((a, b) => a - b);
  out.push(`## Melting threshold p*: ${d.dict}, ${d.n}², ${d.T} turns, ${d.passes} passes, ${d.seeds} seeds; the smallest swap at which the share at turn ${d.T} falls below one half, by median`, '', '| type | ' + M.map(m => 'median ' + m).join(' | ') + ' |', '|---|' + M.map(() => '---').join('|') + '|');
  for (const t of d.types) out.push(`| #${t.id} ${name(t)}, basin ${(100 * t.basin).toFixed(2)} % | ` + M.map(m => { for (const p of P) { const s = mean(d.runs.filter(r => r.type === t.id && r.p === p && r.m === m).map(r => r.share[r.share.length - 1][1])); if (s < 0.5) return `p* ≤ ${p} (${pct(s)})`; } return `> ${P[P.length - 1]}`; }).join(' | ') + ' |'); out.push(''); }
process.stdout.write(out.join('\n') + '\n');
