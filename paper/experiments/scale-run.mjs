// Richness of a designed dictionary ca-size-NN on the lattice (paper/results/dictionary-size.md): the page's turn
// (three settling passes, the rotating swap order, quenched hashing, decoder 36, skip 6, window range V = the size)
// at 256 x 256 for 2,000 turns, in the page's frame (swap 0..1 left to right at the page's shaping, median 0..1 top
// to bottom) or uniform (swap 0.25, median 0.5). Every 50 turns, with every cell labelled by the designed type whose
// state it is on (else a transient): the types alive (share >= 0.1 %), the Shannon entropy of the type shares (over the
// cells on a type), the transient share, the number of domains (4-connected components of same-type cells) and the
// block change (the share of 8 x 8 blocks whose most common label differs from 200 turns earlier). At the end the
// border matrix: how many 4-neighbour pairs each ordered pair of labels makes. PNG snapshots in the page's colouring
// (view "Byte colours, raw bytes", as live-run.mjs) at the turns given.
// Usage: node paper/experiments/scale-run.mjs size=16 [design=1] [dict=path.txt] [json=design.json] [setting=frame|uniform] [seed=design] [n=256] [turns=2000] [png=200,1000,2000] [out=paper/data/scale]
import fs from 'node:fs';
import zlib from 'node:zlib';
import { Codec, Band } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
// design=K (default 1): the design seed; seed 1 is the shipped dictionary (src/changers/dict, paper/data/design), the others
// are paper/data/design-seeds/ca-size-NN-sK.{txt,json}; dict= and json= name the files directly
const size = Number(opt.size ?? 16), NAME = `ca-size-${String(size).padStart(2, '0')}`, DSEED = Number(opt.design ?? 1), DTAG = DSEED === 1 ? NAME : `${NAME}-s${DSEED}`;
const setting = opt.setting || 'frame', seed = Number(opt.seed ?? DSEED), n = Number(opt.n ?? 256), turns = Number(opt.turns ?? 2000);
const dictPath = opt.dict || (DSEED === 1 ? null : `${dir}/paper/data/design-seeds/${DTAG}.txt`), jsonPath = opt.json || (DSEED === 1 ? `${dir}/paper/data/design/${NAME}.json` : `${dir}/paper/data/design-seeds/${DTAG}.json`);
const pngTurns = new Set((opt.png ?? '200,1000,2000').split(',').filter(Boolean).map(Number)), outDir = opt.out || `${dir}/paper/data/scale`;
fs.mkdirSync(`${outDir}/png`, { recursive: true });
const tag = `${DTAG}-${setting}-s${seed}-n${n}`, outFile = `${outDir}/run-${tag}.json`;
if (fs.existsSync(outFile) && !opt.force) { console.error(`${tag}: exists`); process.exit(0); }
const design = JSON.parse(fs.readFileSync(jsonPath, 'utf8')), V = design.V;
const text = asText(loadDict(dictPath || NAME).bytes);
// ---- the lattice, as tools/ca-harness.mjs makeSim, plus the renderer; the dictionary past the lattice when it is big
const L = Codec.LAYOUT, W = n, H = n, N = W * H, passes = 3, nbr = 1, S = 16 * W, D = Band.depthFor(passes, nbr);
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const wasm = instance.exports, GRID = L.GRID, GRID2 = GRID + (H + 2 * D) * S + 64, PIX = GRID2 + (H + 2 * D) * S + 64, PAL = PIX + 4 * N + 64, need = PAL + 4 * 129 + 65536;
if (need > wasm.memory.buffer.byteLength) wasm.memory.grow(Math.ceil((need - wasm.memory.buffer.byteLength) / 65536));
const st = { wasm, W, H, y0: 0, rows: H, D, GRID, GRID2, PRM: L.PRM, THR: L.THR, THRY: L.THRY };
const [swapA, swapB, medA, medB] = setting === 'frame' ? [0, 1, 0, 1] : [0.25, 0.25, 0.5, 0.5];
const thrSwap = Band.gradient(swapA, swapB, W, Band.mixRate, 0.2), thrSmooth = Band.gradient(medA, medB, H);
const io = Codec.install(wasm.memory, Codec.build(text, 3), undefined, 3, need); io.setChanger(36); io.setSkipBits(6); io.setCursorRead(V); io.setCursorOffset(0);
if (io.textLen !== V) throw new Error('dictionary length');
const base = GRID + D * S;
wasm.randomize(4 * N, base, seed);
let turn = 0;
function step() {
  const r = Band.runTurn(st, { haloTop: null, haloBottom: null, order: Band.order(turn, 'rotate'), alt: turn & 1, mixSync: false, passes, nbr, thrSwap, thrSmooth,
    salts: Array.from({ length: 4 + passes }, () => 0n), posalt: false, changer: true, pair: { mode: 0, flip: turn & 1, write: 3 }, mut: null });
  turn++; return r;
}
const grid = () => new Uint8Array(wasm.memory.buffer).subarray(base, base + 16 * N);
// ---- PNG (as live-run.mjs)
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
// ---- labels: the designed type of every cell (T = the number of types; T means transient)
const T = design.nTypes, typeOf = new Map(); design.typeTable.forEach(t => t.states.forEach(s => typeOf.set(s, t.index)));
const kindOf = design.typeTable.map(t => t.kind);
const labels = () => { const g = grid(), lab = new Int32Array(N); for (let i = 0; i < N; i++) { const t = typeOf.get(Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1')); lab[i] = t === undefined ? T : t; } return lab; };
function measure(lab, old) {
  const cnt = new Float64Array(T + 1); for (let i = 0; i < N; i++) cnt[lab[i]]++;
  const onType = N - cnt[T]; let alive = 0, H2 = 0; const shares = {};
  for (let t = 0; t < T; t++) { if (cnt[t] / N >= 0.001) { alive++; shares[t] = cnt[t] / N; } if (cnt[t] && onType) { const p = cnt[t] / onType; H2 -= p * Math.log2(p); } }
  const byKind = { gray: 0, chase: 0, fixed: 0 }; for (let t = 0; t < T; t++) if (cnt[t] / N >= 0.001) byKind[kindOf[t]]++;
  // domains: 4-connected components of same-label cells on a type
  const seen = new Uint8Array(N), stack = new Int32Array(N); let domains = 0, sizes = [];
  for (let i = 0; i < N; i++) {
    if (seen[i] || lab[i] === T) continue; domains++; let sp = 0, sz = 0; stack[sp++] = i; seen[i] = 1;
    while (sp) { const c = stack[--sp]; sz++; const x = c % W, y = (c - x) / W; for (const d of [x > 0 ? c - 1 : -1, x + 1 < W ? c + 1 : -1, y > 0 ? c - W : -1, y + 1 < H ? c + W : -1]) if (d >= 0 && !seen[d] && lab[d] === lab[c]) { seen[d] = 1; stack[sp++] = d; } }
    sizes.push(sz);
  }
  sizes.sort((a, b) => b - a);
  // block change: 8 x 8 blocks whose most common label differs from 200 turns earlier
  let blockChange = null;
  if (old) { const mode = (l, bx, by) => { const m = new Map(); for (let y = by; y < by + 8; y++) for (let x = bx; x < bx + 8; x++) m.set(l[y * W + x], (m.get(l[y * W + x]) || 0) + 1); let best = -1, bl = 0; for (const [k, v] of m) if (v > best || (v === best && k < bl)) { best = v; bl = k; } return bl; };
    let nb = 0, cb = 0; for (let by = 0; by + 8 <= H; by += 8) for (let bx = 0; bx + 8 <= W; bx += 8) { nb++; if (mode(lab, bx, by) !== mode(old, bx, by)) cb++; } blockChange = cb / nb; }
  return { alive, byKind, entropy: H2, transient: cnt[T] / N, domains, domainMean: onType / Math.max(1, domains), domainTop: sizes.slice(0, 5).map(v => v / N), blockChange, shares };
}
function borders(lab) {   // ordered label pairs of 4-neighbours with different labels, sparse
  const m = new Map(); const add = (a, b) => { if (a === b) return; const k = `${a},${b}`; m.set(k, (m.get(k) || 0) + 1); };
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const i = y * W + x; if (x + 1 < W) { add(lab[i], lab[i + 1]); add(lab[i + 1], lab[i]); } if (y + 1 < H) { add(lab[i], lab[i + W]); add(lab[i + W], lab[i]); } }
  return Object.fromEntries([...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, 2000));
}
const rows = [], hist = new Map(), t0 = Date.now();
for (let t = 1; t <= turns; t++) {
  step();
  if (t % 50 === 0) {
    const lab = labels(); hist.set(t, lab); const old = hist.get(t - 200); hist.delete(t - 250);
    const m = measure(lab, old); rows.push({ t, ...m });
    if (t % 500 === 0) console.error(`${tag} t${t}: alive ${m.alive} (${JSON.stringify(m.byKind)}) H ${m.entropy.toFixed(2)} transient ${(100 * m.transient).toFixed(1)} % domains ${m.domains} blocks ${m.blockChange?.toFixed(3)} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
  }
  if (pngTurns.has(t)) { render(); fs.writeFileSync(`${outDir}/png/${tag}-t${String(t).padStart(4, '0')}.png`, png(W, H, render())); }
}
const last = rows[rows.length - 1], lab = labels();
const summary = { name: NAME, tag: DTAG, designSeed: DSEED, log2: size, V, setting, seed, n, turns, nTypes: T, kinds: design.types, aliveEnd: last.alive, byKindEnd: last.byKind, entropyEnd: last.entropy, transientEnd: last.transient, domainsEnd: last.domains, blockChangeEnd: last.blockChange,
  blockChangeLate: rows.filter(r => r.t >= 1000 && r.blockChange !== null).reduce((s, r, _, a) => s + r.blockChange / a.length, 0), aliveAt: Object.fromEntries([200, 1000, 2000].map(t => [t, rows.find(r => r.t === t)?.alive ?? null])), seconds: (Date.now() - t0) / 1000 };
fs.writeFileSync(outFile, JSON.stringify({ provenance: provenance(import.meta.url, { size, design: DSEED, dictPath, jsonPath, setting, seed, n, turns, passes, nbr, order: 'rotate', salt: 'quenched', changer: 36, skip: 6, cread: V, swap: [swapA, swapB], median: [medA, medB], gpow: 0.2 }), summary, rows, borders: borders(lab) }));
console.log(JSON.stringify(summary));
