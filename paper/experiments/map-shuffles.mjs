// Is Swarm F's attractor structure special, or generic for its byte statistics? (the map spine, deliverable 3)
// For the original dictionary and its 30 byte shuffles and 30 word shuffles (dict-variants.mjs, seeds 1..30): the
// single-cell iteration census from N random cells (seed 1, the same cells for every dictionary): iterate T = 200 steps,
// then look for a return to the state at T within 200 more steps; a cycle found is an attractor reached within the
// budget (canonical id: its smallest state). Reported: attractors reached, their periods, the largest basin share, the
// share not settled, and H2 / H_inf / distinct after 1, 4, 16, 64 steps. The exact fixed-point counts come from
// map-exact.mjs runs on the same variants (paper/data/map/exact-<variant>-K1.json), when present.
// Usage: node paper/experiments/map-shuffles.mjs [N=100000] [workers=8] [dict=ca-swarm-f] [nshuf=30]
//        node paper/experiments/map-shuffles.mjs --table [dict=ca-swarm-f] [nshuf=30]   (assemble the table only)
import fs from 'node:fs';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { loadDict, variantOf } from './dict-variants.mjs';
import { fastF, rng, entropies, hex } from './map-lib.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const outDir = dir + '/paper/data/map';
const KS = [1, 4, 16, 64], T = 200, P = 200;

function census(dict, N) {
  const f = fastF(dict, { skip: 6, V: 4096, coff: 0 }), r = rng(1), X = new Uint8Array(16 * N), tmp = new Uint8Array(16), at = {};
  r.fill(X, 0, 16 * N);
  for (let t = 1; t <= T; t++) {
    for (let i = 0; i < N; i++) { f(X, 16 * i, tmp, 0); X.set(tmp, 16 * i); }
    if (KS.includes(t)) { const m = new Map(); for (let i = 0; i < N; i++) { const k = Buffer.from(X.buffer, 16 * i, 16).toString('latin1'); m.set(k, (m.get(k) || 0) + 1); } at[t] = entropies(m.values(), N); }
  }
  const memo = new Map(), cyc = new Map(), y = new Uint8Array(16), st = new Uint8Array(16); let unsettled = 0;
  for (let i = 0; i < N; i++) {
    const k0 = Buffer.from(X.buffer, 16 * i, 16).toString('latin1');
    let id = memo.get(k0);
    if (id === undefined) {
      st.set(X.subarray(16 * i, 16 * i + 16)); y.set(st); let per = 0; const states = [k0];
      for (let t = 1; t <= P; t++) { f(y, 0, tmp, 0); y.set(tmp); let eq = true; for (let q = 0; q < 16; q++) if (y[q] !== st[q]) { eq = false; break; } if (eq) { per = t; break; } states.push(Buffer.from(y).toString('latin1')); }
      if (!per) { unsettled++; continue; }
      states.length = per; id = states.reduce((a, b) => a < b ? a : b);
      for (const s of states) memo.set(s, id);
      cyc.set(id, { period: per, basin: 0 });
    }
    cyc.get(id).basin++;
  }
  const basins = [...cyc.entries()].sort((a, b) => b[1].basin - a[1].basin);
  const periods = {}; for (const [, c] of basins) periods[c.period] = (periods[c.period] || 0) + 1;
  return { N, T, P, attractors: cyc.size, unsettled: unsettled / N, largestBasin: basins.length ? basins[0][1].basin / N : 0, periods,
    meanPeriodBySample: basins.reduce((s, [, c]) => s + c.period * c.basin, 0) / Math.max(1, N - unsettled),
    top: basins.slice(0, 10).map(([k, c]) => ({ x: hex(Buffer.from(k, 'latin1')), period: c.period, basin: c.basin / N })), at };
}

if (!isMainThread) {
  parentPort.on('message', job => {
    if (job === null) process.exit(0);
    const dict = variantOf(loadDict(job.id).bytes, job.variant, job.seed), t0 = Date.now();
    const res = census(dict, job.N);
    parentPort.postMessage({ ...job, bytes: dict.length, seconds: (Date.now() - t0) / 1000, ...res });
  });
} else {
  const argv = process.argv.slice(2), tableOnly = argv.includes('--table'), pos = argv.filter(a => !a.startsWith('--'));
  const [N, W, ID, NS] = tableOnly ? [0, 0, pos[0] || 'ca-swarm-f', Number(pos[1] || 30)] : [Number(pos[0] || 1e5), Number(pos[1] || 8), pos[2] || 'ca-swarm-f', Number(pos[3] || 30)];
  const name = j => j.variant === 'raw' ? j.id : `${j.id}-${j.variant}${j.seed}`;
  const jobs = [{ id: ID, variant: 'raw', seed: 1, N }];
  for (const v of ['shuffle', 'wordshuffle']) for (let s = 1; s <= NS; s++) jobs.push({ id: ID, variant: v, seed: s, N });
  const file = `${outDir}/shuffles-${ID}.json`;
  let results;
  if (tableOnly) results = JSON.parse(fs.readFileSync(file, 'utf8')).results;
  else {
    results = [];
    const t0 = Date.now();
    await new Promise((resolve, reject) => {
      let next = 0, done = 0;
      for (let w = 0; w < Math.min(W, jobs.length); w++) {
        const wk = new Worker(new URL(import.meta.url));
        const give = () => wk.postMessage(next < jobs.length ? jobs[next++] : null);
        wk.on('message', m => { results.push(m); done++; console.error(`${done}/${jobs.length} ${name(m)}: ${m.attractors} attractors, largest basin ${(100 * m.largestBasin).toFixed(1)} %, H2(1) ${m.at[1].H2.toFixed(2)}, H2(16) ${m.at[16].H2.toFixed(2)}, ${m.seconds.toFixed(0)} s (${((Date.now() - t0) / 1000).toFixed(0)} s)`); if (done === jobs.length) resolve(); give(); });
        wk.on('error', reject); give();
      }
    });
    results.sort((a, b) => jobs.findIndex(j => name(j) === name(a)) - jobs.findIndex(j => name(j) === name(b)));
  }
  // fold in the exact fixed-point counts
  for (const r of results) {
    const p = `${outDir}/exact-${name(r)}-K1.json`;
    if (fs.existsSync(p)) { const e = JSON.parse(fs.readFileSync(p, 'utf8')); r.exact = { complete: e.complete, cappedHeaders: e.cappedHeaders.length, fixedPoints: e.solutions, families: e.familyCount, isolated: e.freeBytesHist[0], headersWithFixedPoints: e.headersWithSolutions, nodes: e.nodes }; }
  }
  const prov = provenance(import.meta.url, { N, W, ID, NS, T, P, KS });
  fs.writeFileSync(file, JSON.stringify({ provenance: prov, results }));
  // ---- the table
  const fmt = v => v === Infinity ? '∞' : v.toFixed(2);
  const md = [provLine(prov), '', `# Attractor census of ${ID} against its shuffles`, '',
    `Census: ${results[0].N} random cells (seed 1, the same cells for every dictionary), T = ${T} steps, then a return to the state at T within ${P} steps. Exact fixed points: map-exact.mjs (complete unless capped headers are listed).`, '',
    '| dictionary | attractors | periods (count) | largest basin | unsettled | H2 k=1 | H2 k=4 | H2 k=16 | H2 k=64 | H_inf k=1 | fixed points (exact) | families | isolated |', '|---|---|---|---|---|---|---|---|---|---|---|---|---|'];
  for (const r of results) md.push(`| ${name(r)} | ${r.attractors} | ${Object.entries(r.periods).map(([p, c]) => `${p}:${c}`).join(' ')} | ${(100 * r.largestBasin).toFixed(1)} % | ${(100 * r.unsettled).toFixed(2)} % | ${fmt(r.at[1].H2)} | ${fmt(r.at[4].H2)} | ${fmt(r.at[16].H2)} | ${fmt(r.at[64].H2)} | ${r.at[1].Hinf.toFixed(2)} | ${r.exact ? r.exact.fixedPoints + (r.exact.complete ? '' : ` (≥, ${r.exact.cappedHeaders} capped)`) : '—'} | ${r.exact ? r.exact.families : '—'} | ${r.exact ? r.exact.isolated : '—'} |`);
  // ranks of the original within each control group
  const stats = [['attractors', r => r.attractors], ['largest basin', r => r.largestBasin], ['unsettled', r => r.unsettled], ['H2 k=1', r => r.at[1].H2], ['H2 k=4', r => r.at[4].H2], ['H2 k=16', r => r.at[16].H2], ['H2 k=64', r => r.at[64].H2], ['H_inf k=1', r => r.at[1].Hinf], ['mean period (by sample)', r => r.meanPeriodBySample],
    ['fixed points (exact)', r => r.exact ? r.exact.fixedPoints : NaN], ['fixed-point families', r => r.exact ? r.exact.families : NaN], ['isolated fixed points', r => r.exact ? r.exact.isolated : NaN]];
  md.push('', '## The original among its controls', '', 'Rank: 1 = smallest value among the original and the 30 controls (ties share the lower rank; the number of controls equal to the original is given); the controls\' median and range.', '',
    '| statistic | original | byte shuffles: median [min, max] | rank among 31 | word shuffles: median [min, max] | rank among 31 |', '|---|---|---|---|---|---|');
  const orig = results[0], ranks = {};
  for (const [label, g] of stats) {
    const o = g(orig); if (Number.isNaN(o)) continue;
    const cells = [];
    for (const v of ['shuffle', 'wordshuffle']) {
      const xs = results.filter(r => r.variant === v).map(g).filter(x => !Number.isNaN(x)).sort((a, b) => a - b);
      if (!xs.length) { cells.push('—', '—'); continue; }
      const rank = 1 + xs.filter(x => x < o).length, ties = xs.filter(x => x === o).length;
      ranks[`${label}/${v}`] = { rank, ties, of: xs.length + 1 };
      const show = x => Number.isInteger(x) ? String(x) : x === Infinity ? '∞' : x < 1 ? x.toFixed(3) : x.toFixed(2);
      cells.push(`${show(xs[xs.length >> 1])} [${show(xs[0])}, ${show(xs[xs.length - 1])}]`, `${rank} of ${xs.length + 1}${ties ? ` (${ties} tied)` : ''}`);
    }
    const show = x => Number.isInteger(x) ? String(x) : x === Infinity ? '∞' : x < 1 ? x.toFixed(3) : x.toFixed(2);
    md.push(`| ${label} | ${show(o)} | ${cells.join(' | ')} |`);
  }
  fs.writeFileSync(`${outDir}/shuffles-${ID}.md`, md.join('\n') + '\n');
  fs.writeFileSync(file, JSON.stringify({ provenance: prov, ranks, results }));
  console.log(md.join('\n'));
}
