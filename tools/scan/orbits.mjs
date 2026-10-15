// Orbit structure of the LZ changer map f (pixel -> decode(pixel)) per cursor offset.
// usage: node orbits.mjs <from> <to> <step> [K pixels] [maxIter]
import fs from 'node:fs'; import vm from 'node:vm';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const { memory, decode_pixel, randomize } = instance.exports;
const io = Codec.install(memory, Codec.build(text, 3));
const L = Codec.LAYOUT, GRID = L.GRID, PRM = L.PRM;
const [from, to, step, K = 256, maxIter = 400] = process.argv.slice(2).map(Number);
const m8 = new Uint8Array(memory.buffer);
const key = (p) => { let s = ''; for (let k = 0; k < 16; k++) s += m8[p + k].toString(16).padStart(2, '0'); return s; };
for (let off = from; off < to; off += step) {
  io.setCursorOffset(off);
  randomize(4 * K, GRID, 99);   // same random start pixels for every offset
  let fixed = 0, cyc = 0, unconv = 0, tsum = 0, csum = 0, cmax = 0; const attractors = new Set();
  for (let i = 0; i < K; i++) {
    const p = GRID + 16 * i, seen = new Map(); let t = 0, c = 0;
    for (; t < maxIter; t++) {
      const k = key(p);
      if (seen.has(k)) { c = t - seen.get(k); break; }
      seen.set(k, t);
      decode_pixel(GRID, i, PRM); m8.copyWithin(p, io.OUT, io.OUT + 16);
    }
    if (c === 0) { unconv++; continue; }
    const trans = t - c; tsum += trans; csum += c; if (c > cmax) cmax = c;
    if (c === 1) fixed++; else cyc++;
    attractors.add(key(p));   // a state on the cycle (the one that closed it)
  }
  const n = K - unconv;
  console.log(JSON.stringify({ off, fixed, cyc, unconv, meanTransient: n ? +(tsum / n).toFixed(2) : null, meanCycle: n ? +(csum / n).toFixed(2) : null, maxCycle: cmax, attractors: attractors.size }));
}
