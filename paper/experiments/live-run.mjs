// Liveliness of a dictionary on the page's default lattice (512 x 512 or smaller, swap gradient 0..1 left to right,
// median gradient 0..1 top to bottom, 3 settling passes, rotating swap order, quenched hashing, decoder kind 36, skip 6).
// Every cell gets a tag each turn: the smallest hash of its contents over the last 24 turns, the same for every phase
// of a cycle of period up to 24, so the tag names the attractor a cell sits on (or changes while it is in transit).
// Reported every 40 turns, over the settled part (rows from 60 % down) and the whole: change (share of cells whose content differs from 360 turns before), turnover (share of cells whose tag differs from 120 turns before), wall density (share of
// right and down neighbour pairs with different tags), the tags above 3 % of the settled part, block change (8 x 8 blocks whose most common content differs from 360 turns
// before), and, for a design JSON,
// the shares of the designed types there. Frames are written as PNGs with
// the page's colouring (view "Byte colours, raw bytes": the wasm renderer, the LUT average stretched around the
// previous frame's mean) but without the page's render buffer and sharpening.
// Usage: node paper/experiments/live-run.mjs dict=ca-live-tide [n=256] [turns=3000] [seed=1] [cread=4096] [png=200,1000,3000]
//        [out=paper/data/redesign/runs] [figs=paper/figures/redesign]
import fs from 'node:fs';
import zlib from 'node:zlib';
import { Codec, Band } from '../../tools/ca-harness.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-live-tide', n = Number(opt.n ?? 256), turns = Number(opt.turns ?? 3000), seed = Number(opt.seed ?? 1);
const dictPath = fs.existsSync(opt.dict) ? opt.dict : `${dir}/src/changers/dict/${dictId}.txt`;
const id = dictId.replace(/^.*\//, '').replace(/\.txt$/, '');
const manifest = JSON.parse(fs.readFileSync(`${dir}/src/changers/dict/manifest.json`, 'utf8'));
const cread = Number(opt.cread ?? (manifest.find(d => d.id === id)?.cread || 4096));
const pngTurns = new Set((opt.png ?? '200,1000,3000').split(',').filter(Boolean).map(Number));
const outDir = opt.out || `${dir}/paper/data/redesign/runs`, figDir = opt.figs || `${dir}/paper/figures/redesign`;
fs.mkdirSync(outDir, { recursive: true }); fs.mkdirSync(figDir, { recursive: true });
const designPath = `${dir}/paper/data/redesign/${id}.json`, design = fs.existsSync(designPath) ? JSON.parse(fs.readFileSync(designPath, 'utf8')) : null;
// ---- the lattice, as tools/ca-harness.mjs makeSim, plus the renderer
const L = Codec.LAYOUT, W = n, H = n, N = W * H, passes = 3, nbr = 1, S = 16 * W, D = Band.depthFor(passes, nbr);
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const wasm = instance.exports, GRID = L.GRID, GRID2 = GRID + (H + 2 * D) * S + 64, PIX = GRID2 + (H + 2 * D) * S + 64, PAL = PIX + 4 * N + 64, need = PAL + 4 * 129 + 65536;
if (need > wasm.memory.buffer.byteLength) wasm.memory.grow(Math.ceil((need - wasm.memory.buffer.byteLength) / 65536));
const st = { wasm, W, H, y0: 0, rows: H, D, GRID, GRID2, PRM: L.PRM, THR: L.THR, THRY: L.THRY };
const thrSwap = Band.gradient(0, 1, W, Band.mixRate, 0.2), thrSmooth = Band.gradient(0, 1, H);
const text = fs.readFileSync(dictPath, 'latin1');
const io = Codec.install(wasm.memory, Codec.build(text, 3)); io.setChanger(36); io.setSkipBits(6); io.setCursorRead(cread); io.setCursorOffset(0);
const base = GRID + D * S;
wasm.randomize(4 * N, base, seed);
let turn = 0;
function step() {
  const r = Band.runTurn(st, { haloTop: null, haloBottom: null, order: Band.order(turn, 'rotate'), alt: turn & 1, mixSync: false, passes, nbr, thrSwap, thrSmooth,
    salts: Array.from({ length: 4 + passes }, () => 0n), posalt: false, changer: true, pair: { mode: 0, flip: turn & 1, write: 3 }, mut: null });
  turn++; return r;
}
const grid = () => new Uint8Array(wasm.memory.buffer).subarray(base, base + 16 * N);
// ---- PNG
const CRC = new Int32Array(256).map((_, k) => { let c = k; for (let j = 0; j < 8; j++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; return c; });
const crc32 = b => { let c = -1; for (const v of b) c = CRC[(c ^ v) & 255] ^ (c >>> 8); return (c ^ -1) >>> 0; };
function png(w, h, rgba) {
  const raw = Buffer.alloc((3 * w + 1) * h); for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) for (let k = 0; k < 3; k++) raw[y * (3 * w + 1) + 1 + 3 * x + k] = rgba[4 * (y * w + x) + k];
  const chunk = (type, data) => { const len = Buffer.alloc(4); len.writeUInt32BE(data.length); const td = Buffer.concat([Buffer.from(type), data]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(td)); return Buffer.concat([len, td, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
function render() {
  wasm.render(N, base, PIX, PAL, 4, L.PRM);
  const s = io.frameSums(); if (s.n) io.setMean(4, Math.round(s.r / s.n) | (Math.round(s.g / s.n) << 8) | (Math.round(s.b / s.n) << 16));
  return new Uint8Array(wasm.memory.buffer).slice(PIX, PIX + 4 * N);
}
// ---- tags
const K = 24, ring = new Uint32Array(N * K);
const h32 = (g, i) => { let h = 2166136261; for (let k = 0; k < 16; k++) { h ^= g[16 * i + k]; h = Math.imul(h, 16777619); } return h >>> 0; };
const tagsNow = () => { const t = new Uint32Array(N); for (let i = 0; i < N; i++) { let m = 0xffffffff; for (let k = 0; k < K; k++) { const v = ring[i * K + k]; if (v < m) m = v; } t[i] = m; } return t; };
const stateType = new Map(); if (design) for (const s of design.states) stateType.set(s.text, s.type);
// phase-aware change: a cell whose content differs from LAG = 360 turns before (360 is a multiple of every period up to
// 6 and of 8, 9, 10, 12, 18), so a cell resting on a cycle in a static domain counts as unchanged
const LAG = 360, snaps = new Map();
const tagHist = new Map(); const rows = []; const t0 = Date.now();
for (let t = 1; t <= turns; t++) {
  step(); const g = grid();
  for (let i = 0; i < N; i++) ring[i * K + (t % K)] = h32(g, i);
  if (t % 40 === 0) snaps.set(t, grid().slice()), snaps.delete(t - LAG - 40);
  if (t % 40 === 0 && t >= K) {
    const tags = tagsNow(); tagHist.set(t, tags);
    const old = tagHist.get(t - 120); tagHist.delete(t - 160);
    const g0 = snaps.get(t - LAG); let change = null, changeLow = null;
    if (g0) { const g1 = grid(); let c = 0, cl = 0; for (let i = 0; i < N; i++) { let same = true; for (let k = 0; k < 16; k++) if (g1[16 * i + k] !== g0[16 * i + k]) { same = false; break; } if (!same) { c++; if (i >= Math.floor(0.6 * H) * W) cl++; } } change = c / N; changeLow = cl / ((H - Math.floor(0.6 * H)) * W); }
    // block change: 8 x 8 blocks of the settled part whose most common content differs from 360 turns before; a mottle
    // that cycles in place with flickering walls keeps its blocks' modes, moving fronts and growing islands do not
    let blockChange = null;
    if (g0) { const g1 = grid(), mode = (g, bx, by) => { const m = new Map(); for (let y = by; y < by + 8; y++) for (let x = bx; x < bx + 8; x++) { const h = h32(g, y * W + x); m.set(h, (m.get(h) || 0) + 1); } let best = 0, bh = 0; for (const [h, v] of m) if (v > best) { best = v; bh = h; } return bh; };
      let nb = 0, cb = 0; for (let by = Math.ceil(0.6 * H / 8) * 8; by + 8 <= H; by += 8) for (let bx = 0; bx + 8 <= W; bx += 8) { nb++; if (mode(g1, bx, by) !== mode(g0, bx, by)) cb++; } blockChange = cb / nb; }
    // the settled part: rows from 60 % down (median probability 0.6 to 1); above it every dictionary shows the same unsettled noise
    const y0 = Math.floor(0.6 * H), NL = (H - y0) * W;
    let turnover = null, turnoverLow = null; if (old) { let c = 0, cl = 0; for (let i = 0; i < N; i++) if (tags[i] !== old[i]) { c++; if (i >= y0 * W) cl++; } turnover = c / N; turnoverLow = cl / NL; }
    let walls = 0, wallsLow = 0; for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const i = y * W + x; const w = (x + 1 < W && tags[i] !== tags[i + 1] ? 1 : 0) + (y + 1 < H && tags[i] !== tags[i + W] ? 1 : 0); walls += w; if (y >= y0) wallsLow += w; }
    const cntL = new Map(); for (let i = y0 * W; i < N; i++) cntL.set(tags[i], (cntL.get(tags[i]) || 0) + 1);
    const bigLow = [...cntL.values()].filter(v => v > 0.03 * NL).sort((a, b) => b - a).map(v => v / NL);
    const cnt = new Map(); for (let i = 0; i < N; i++) cnt.set(tags[i], (cnt.get(tags[i]) || 0) + 1);
    const big = [...cnt.values()].filter(v => v > 0.01 * N).sort((a, b) => b - a);
    const types = {}; if (design) { for (let i = y0 * W; i < N; i++) { const k = Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1'); const T = stateType.get(k) ?? '-'; types[T] = (types[T] || 0) + 1; } for (const k in types) types[k] /= NL; }
    rows.push({ t, change, changeLow, blockChange, turnover, walls: walls / (2 * N - W - H), turnoverLow, wallsLow: wallsLow / (2 * NL), tagsOver1: big.length, top: big.slice(0, 6).map(v => v / N), bigLow, types });
    if (t % 520 === 0) console.error(`${id} n${n} t${t} low: change ${changeLow?.toFixed(3)} blocks ${blockChange?.toFixed(3)} turnover ${turnoverLow?.toFixed(3)} walls ${(wallsLow / (2 * NL)).toFixed(3)} tags>3% ${bigLow.map(v => v.toFixed(2)).join(',')} ${JSON.stringify(Object.fromEntries(Object.entries(types).map(([k, v]) => [k, +v.toFixed(3)])))} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
  }
  if (pngTurns.has(t)) { render(); fs.writeFileSync(`${figDir}/${id}-n${n}-s${seed}-t${String(t).padStart(4, '0')}.png`, png(W, H, render())); }
}
// ---- summary: the liveliness numbers over turns 1000..3000 (or the last two thirds)
const late = rows.filter(r => r.t >= Math.min(1000, turns / 3) && r.turnover !== null);
const mean = a => a.length ? a.reduce((s, v) => s + v, 0) / a.length : null;
const last = rows[rows.length - 1];
const lateC = rows.filter(r => r.t >= Math.min(1000, turns / 3) && r.changeLow !== null);
const summary = { dict: id, n, turns, seed, cread, blockChangeLate: mean(lateC.map(r => r.blockChange)), blockChangeMinLate: Math.min(...lateC.map(r => r.blockChange)), blockChangeAt: Object.fromEntries([1000, 2000, 3000].map(t => [t, rows.find(r => r.t === t)?.blockChange ?? null])), changeLate: mean(lateC.map(r => r.changeLow)), changeMinLate: Math.min(...lateC.map(r => r.changeLow)), changeWholeLate: mean(lateC.map(r => r.change)), turnoverLate: mean(late.map(r => r.turnoverLow)), turnoverMinLate: Math.min(...late.map(r => r.turnoverLow)), turnoverWholeLate: mean(late.map(r => r.turnover)),
  wallsAt: Object.fromEntries([200, 1000, 2000, 3000].map(t => [t, rows.find(r => r.t === t)?.wallsLow ?? null])), bigLowEnd: last.bigLow, typesEnd: last.types,
  typesOver3End: design ? Object.entries(last.types).filter(([k, v]) => k !== '-' && v > 0.03).length : last.bigLow.length };
fs.writeFileSync(`${outDir}/${id}-n${n}-s${seed}-t${turns}.json`, JSON.stringify({ provenance: provenance(import.meta.url, { id, n, turns, seed, cread }), summary, rows }));
console.log(JSON.stringify(summary));
