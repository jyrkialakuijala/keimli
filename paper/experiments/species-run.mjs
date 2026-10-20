// One lattice run with a designed dictionary (design-dict.mjs): every sampled turn, classify each cell by exact match
// against the designed cycle states (species A/B/C and phase k) and report the species shares, the off-cycle share,
// the phase coherence per species |<exp(2 pi i k / 8)>|, the number of species domains (4-connected components of the
// species label, in the bulk) and d1; write a PNG of the species/phase field at a few turns (species = hue, phase =
// lightness, off-cycle = dark grey). Uniform parameters as in ablation.mjs, or page=1 for the page's gradient frame.
// Usage: node paper/experiments/species-run.mjs design=paper/data/design/ca-gray3.json pm=0.5 ps=1 salt=0 seed=1 n=256 turns=1000 [page=1] out=paper/data/design/runs
import fs from 'node:fs';
import zlib from 'node:zlib';
import { makeSim } from '../../tools/ca-harness.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const design = JSON.parse(fs.readFileSync(opt.design || dir + '/paper/data/design/ca-gray3.json', 'utf8'));
const dictText = fs.readFileSync(`${dir}/paper/data/design/${design.name}.txt`, 'latin1');
const pm = Number(opt.pm ?? 0.5), ps = Number(opt.ps ?? 1), salt = Number(opt.salt ?? 0), seed = Number(opt.seed ?? 1), n = Number(opt.n ?? 256), turns = Number(opt.turns ?? 1000), page = Number(opt.page ?? 0);
const pair = Number(opt.pair ?? design.pairMode ?? 0);   // the Cells setting: 0 each cell on its own, 1 pairs concatenated, 2 bit-interleaved, 3 nibble, 5 byte
const outDir = opt.out || dir + '/paper/data/design/runs', margin = Number(opt.margin ?? n >> 3);
const tag = `${design.name}-${page ? 'page' : `pm${pm}-ps${ps}`}-salt${salt}-n${n}-t${turns}-seed${seed}${pair ? '-pair' + pair : ''}`;
const NSP = design.states.length, NAMES = design.states.map(x => x.species), NLEN = design.states.map(x => x.states.length);
const label = new Map();   // 16-byte latin1 -> { s: species index, k }
design.states.forEach((sp, si) => sp.states.forEach(x => { for (const t of (x.texts ?? [x.text])) label.set(t, { s: si, k: x.k }); }));   // pair designs list both cells of a state
const sim = await makeSim({ W: n, H: n, changer: 36, pairMode: pair, maxlen: 3, skip: 6, cread: design.V ?? 4096, coff: 0, saltMode: salt, swap: page ? [0, 1] : [pm, pm], smooth: page ? [0, 1] : [ps, ps] });
sim.setDict(dictText); sim.reset(seed);
const { W, H, N } = sim;
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
const x0 = margin, x1 = W - margin, y0 = margin, y1 = H - margin;
function classify(g) {   // species per cell (-1 off-cycle), phase per cell
  const sp = new Int8Array(N), ph = new Int8Array(N);
  for (let i = 0; i < N; i++) { const l = label.get(Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1')); if (l) { sp[i] = l.s; ph[i] = l.k; } else { sp[i] = -1; ph[i] = -1; } }
  return { sp, ph };
}
function stats(g, prev, sp, ph) {
  const cnt = new Array(NSP + 1).fill(0), re = new Array(NSP).fill(0), im = new Array(NSP).fill(0); let d1 = 0, nb = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const i = y * W + x; nb++;
    if (sp[i] < 0) cnt[NSP]++; else { cnt[sp[i]]++; re[sp[i]] += Math.cos(2 * Math.PI * ph[i] / NLEN[sp[i]]); im[sp[i]] += Math.sin(2 * Math.PI * ph[i] / NLEN[sp[i]]); }
    if (prev) for (let k = 0; k < 16; k++) d1 += POP[g[16 * i + k] ^ prev[16 * i + k]];
  }
  // species domains: 4-connected components of equal species label in the bulk (off-cycle cells not counted)
  const seen = new Uint8Array(N), stack = []; let domains = 0, big = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const i = y * W + x; if (seen[i] || sp[i] < 0) continue;
    domains++; let size = 0; stack.push(i); seen[i] = 1;
    while (stack.length) { const j = stack.pop(); size++; const jx = j % W, jy = (j - jx) / W;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const qx = jx + dx, qy = jy + dy; if (qx < x0 || qx >= x1 || qy < y0 || qy >= y1) continue; const q = qy * W + qx; if (!seen[q] && sp[q] === sp[i]) { seen[q] = 1; stack.push(q); } } }
    if (size > big) big = size;
  }
  // phase domains: components of equal (species, phase); wall cells: on-cycle cells with a 4-neighbour of another species or phase
  const seen2 = new Uint8Array(N); let phaseDomains = 0, walls = 0;
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const i = y * W + x; if (sp[i] < 0) continue;
    let wall = false; for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const q = (y + dy) * W + x + dx; if (sp[q] !== sp[i] || ph[q] !== ph[i]) wall = true; } if (wall) walls++;
    if (seen2[i]) continue; phaseDomains++; stack.push(i); seen2[i] = 1;
    while (stack.length) { const j = stack.pop(); const jx = j % W, jy = (j - jx) / W;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const qx = jx + dx, qy = jy + dy; if (qx < x0 || qx >= x1 || qy < y0 || qy >= y1) continue; const q = qy * W + qx; if (!seen2[q] && sp[q] === sp[i] && ph[q] === ph[i]) { seen2[q] = 1; stack.push(q); } } }
  }
  return { shares: cnt.map(c => c / nb), coherence: re.map((r, s) => cnt[s] ? Math.hypot(r, im[s]) / cnt[s] : null), d1: prev ? d1 / (128 * nb) : null, domains, largest: big / nb, phaseDomains, walls: walls / nb };
}
// ---- PNG
const CRC = new Int32Array(256); for (let i = 0; i < 256; i++) { let c = i; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; CRC[i] = c; }
const crc32 = b => { let c = -1; for (const v of b) c = CRC[(c ^ v) & 255] ^ (c >>> 8); return (c ^ -1) >>> 0; };
function png(w, h, rgb) {
  const raw = Buffer.alloc((3 * w + 1) * h); for (let y = 0; y < h; y++) { raw[y * (3 * w + 1)] = 0; rgb.copy(raw, y * (3 * w + 1) + 1, 3 * w * y, 3 * w * (y + 1)); }
  const chunk = (type, data) => { const len = Buffer.alloc(4); len.writeUInt32BE(data.length); const td = Buffer.concat([Buffer.from(type), data]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(td)); return Buffer.concat([len, td, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
const HUES0 = [[220, 60, 60], [60, 170, 80], [70, 110, 230], [230, 180, 40], [170, 70, 200], [60, 190, 190], [240, 130, 50]];   // A red, B green, C blue, D yellow, E purple, F cyan, G orange
const hsl = (h, s, l) => { const a = s * Math.min(l, 1 - l), f = n => { const k = (n + h / 30) % 12; return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)))); }; return [f(0), f(8), f(4)]; };
const HUES = NSP <= 7 ? HUES0 : Array.from({ length: NSP }, (_, i) => hsl((360 * i * 0.618034) % 360, 0.75, i % 2 ? 0.45 : 0.6));   // many species: golden-angle hues
function render(sp, ph, scale) {
  const w = W * scale, h = H * scale, rgb = Buffer.alloc(3 * w * h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = Math.floor(y / scale) * W + Math.floor(x / scale); let c;
    if (sp[i] < 0) c = [40, 40, 40]; else { const l = 0.45 + 0.55 * ph[i] / (NLEN[sp[i]] - 1); c = HUES[sp[i]].map(v => Math.round(v * l)); }
    rgb[3 * (y * w + x)] = c[0]; rgb[3 * (y * w + x) + 1] = c[1]; rgb[3 * (y * w + x) + 2] = c[2];
  }
  return png(w, h, rgb);
}
// ---- run
fs.mkdirSync(outDir, { recursive: true });
const sampleTurns = new Set(); for (let t = 1; t <= turns; t++) if (t <= 10 || (t <= 100 && t % 5 === 0) || t % 20 === 0 || t === turns) sampleTurns.add(t);
const pngTurns = new Set([1, 3, 10, 30, 100, 300, Math.min(400, turns), turns, turns - 1, turns - 2].filter(t => t >= 1));
const rows = []; let prev = null; const t0 = Date.now();
for (let t = 1; t <= turns; t++) {
  const r = sim.step();
  if (sampleTurns.has(t) || pngTurns.has(t)) {
    const g = sim.grid(), { sp, ph } = classify(g);
    if (sampleTurns.has(t)) { const s = stats(g, prev, sp, ph); rows.push({ t, moved: r.moved / (128 * N), smoothed: r.smoothed / (128 * N), rewritten: r.rewritten / N, ...s }); }
    if (pngTurns.has(t)) fs.writeFileSync(`${outDir}/${tag}-t${String(t).padStart(4, '0')}.png`, render(sp, ph, n <= 256 ? 2 : 1));
  }
  if (sampleTurns.has(t + 1)) prev = sim.grid().slice(); else prev = null;
}
const res = { design: design.name, pair, pm, ps, salt, seed, n, turns, page, margin, seconds: (Date.now() - t0) / 1000, rows };
fs.writeFileSync(`${outDir}/${tag}.json`, JSON.stringify(res));
const f = v => v == null ? '-' : v.toFixed(3);
console.log(`${tag}: ${res.seconds.toFixed(0)} s`);
console.log(`| t | ${NAMES.join(' | ')} | off | ${NAMES.map(n => 'coh ' + n).join(' | ')} | domains | largest | phase domains | walls | d1 |`);
for (const r of rows.filter(r => [1, 3, 10, 30, 100, 200, 400, 600, 800, 1000, 1500, 2000, 2500, 3000].includes(r.t) || r.t === turns)) console.log(`| ${r.t} | ${r.shares.map(f).join(' | ')} | ${r.coherence.map(f).join(' | ')} | ${r.domains} | ${f(r.largest)} | ${r.phaseDomains} | ${f(r.walls)} | ${f(r.d1)} |`);
