// Does phase coherence decide where the fixed point wins on the gradient frame? Brotli 12 (or any dictionary with a
// large-basin cycle C and a small-basin fixed point F) on the page frame (swap slider 0 -> 1 left to right, the
// exchange rate 2p(1-p) peaking in the middle; median 0 -> 1 top to bottom). Every 50 turns, per block of the frame:
// the share of F, the share of C, and the phase coherence of C: the fraction of C-cells whose phase equals that of
// the majority of the C-cells among their 8 neighbours (1/k for a random phase field of a k-cycle, 1 for a coherent one).
// Usage: node paper/experiments/frame-mechanism.mjs [dict=ca-brotli-12] [cread=4096] [n=256] [turns=2000] [blocks=8] [seed=1]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 256), T = Number(opt.turns ?? 2000), B = Number(opt.blocks ?? 8), seed = Number(opt.seed ?? 1);
const outDir = opt.out || dir + '/paper/data/frame-mechanism'; fs.mkdirSync(outDir, { recursive: true });
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const common = { changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes: 3, nbr: 1, pairMode: 0, altOrder: 'rotate' };
const key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
// the types: the largest-basin cycle C and the largest fixed point F
const simB = await makeSim({ ...common, W: 128, H: 128, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const hist = []; for (let t = 0; t <= 64; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();
for (let i = 0; i < 16384; i++) { const k0 = key(hist[0], i); let p = 0; for (let k = 1; k <= 64; k++) if (key(hist[k], i) === k0) { p = k; break; } if (!p) continue;
  const st = []; for (let k = 0; k < p; k++) st.push(key(hist[k], i)); const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e); }
const list = [...types.values()].sort((a, b) => b.count - a.count);
const C = list.find(e => e.states.length > 1), F = list.find(e => e.states.length === 1);
if (!C || !F) { console.error('needs a cycle and a fixed point'); process.exit(1); }
const phaseOf = new Map(C.states.map((s, k) => [s, k])), fKey = F.states[0], k = C.states.length;
console.error(`${dictId}: C ${k}-cycle basin ${(100 * C.count / 16384).toFixed(2)} %, F basin ${(100 * F.count / 16384).toFixed(2)} %`);
const sim = await makeSim({ ...common, W: n, H: n, swap: [0, 1], smooth: [0, 1] }); sim.setDict(text); sim.reset(seed);
const N = n * n, snaps = [];
for (let t = 1; t <= T; t++) {
  sim.step();
  if (t % 50 === 0 || t === 10 || t === 25) {
    const g = sim.grid(), ph = new Int8Array(N).fill(-1), isF = new Uint8Array(N);
    for (let i = 0; i < N; i++) { const s = key(g, i); if (s === fKey) isF[i] = 1; else { const p = phaseOf.get(s); if (p !== undefined) ph[i] = p; } }
    const bs = n / B, blk = Array.from({ length: B * B }, () => ({ f: 0, c: 0, coh: 0, cohN: 0 }));
    for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) { const i = y * n + x, b = blk[Math.floor(y / bs) * B + Math.floor(x / bs)];
      if (isF[i]) b.f++; if (ph[i] < 0) continue; b.c++;
      const cnt = new Array(k).fill(0); let m = 0; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { if (!dx && !dy) continue; const xx = x + dx, yy = y + dy; if (xx < 0 || yy < 0 || xx >= n || yy >= n) continue; const q = ph[yy * n + xx]; if (q >= 0) { cnt[q]++; m++; } }
      if (m) { let best = 0; for (let q = 1; q < k; q++) if (cnt[q] > cnt[best]) best = q; b.cohN++; if (best === ph[i]) b.coh++; } }
    snaps.push({ t, blocks: blk.map(b => ({ f: b.f / (bs * bs), c: b.c / (bs * bs), coh: b.cohN ? b.coh / b.cohN : null })) });
  }
}
// the frame coordinates of block (bx, by): swap slider p at the block's centre column, exchange rate 2p(1-p) (linear
// slider here: the harness's gradient power 0.2 bends it; the rate is reported from the table the run used), median m at its row
const prov = provenance(import.meta.url, { dictId, cread, n, T, B, seed });
fs.writeFileSync(`${outDir}/frame-${dictId}-n${n}-t${T}-seed${seed}.json`, JSON.stringify({ provenance: prov, dict: dictId, n, T, B, k, basinC: C.count / 16384, basinF: F.count / 16384, snaps }));
const last = snaps[snaps.length - 1], early = snaps.find(s => s.t === 50);
const md = [provLine(prov), `# Frame mechanism: ${dictId}, ${n}², ${T} turns, seed ${seed}`, '', `C: the ${k}-cycle (basin ${(100 * C.count / 16384).toFixed(2)} %); F: the fixed point (basin ${(100 * F.count / 16384).toFixed(2)} %). Blocks of ${n / B}²: columns left to right = swap slider 0 → 1 (mixing strongest in the middle columns), rows top to bottom = median 0 → 1. Each cell: F share / C share / C phase coherence (1/${k} = random phases).`, ''];
for (const s of [early, last]) { md.push(`## turn ${s.t}`, '', '| row \\ column | ' + Array.from({ length: B }, (_, x) => x).join(' | ') + ' |', '|---|' + Array.from({ length: B }, () => '---').join('|') + '|');
  for (let y = 0; y < B; y++) md.push(`| ${y} | ` + Array.from({ length: B }, (_, x) => { const b = s.blocks[y * B + x]; return `${(100 * b.f).toFixed(0)}/${(100 * b.c).toFixed(0)}/${b.coh === null ? '-' : b.coh.toFixed(2)}`; }).join(' | ') + ' |'); md.push(''); }
// correlation across blocks: early C coherence against the final F share
const pairs = early.blocks.map((b, j) => [b.coh, last.blocks[j].f]).filter(p => p[0] !== null);
const mx = pairs.reduce((a, p) => a + p[0], 0) / pairs.length, my = pairs.reduce((a, p) => a + p[1], 0) / pairs.length;
const cov = pairs.reduce((a, p) => a + (p[0] - mx) * (p[1] - my), 0), vx = pairs.reduce((a, p) => a + (p[0] - mx) ** 2, 0), vy = pairs.reduce((a, p) => a + (p[1] - my) ** 2, 0);
md.push(`Across the ${pairs.length} blocks, the correlation between the C phase coherence at turn 50 and the F share at turn ${T}: r = ${(cov / Math.sqrt(vx * vy)).toFixed(2)}.`);
fs.writeFileSync(`${outDir}/frame-${dictId}-n${n}-t${T}-seed${seed}.md`, md.join('\n') + '\n'); console.error('written');
