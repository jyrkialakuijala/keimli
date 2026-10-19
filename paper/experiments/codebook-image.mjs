// The codebook decoder (kind 45) as a map: its image computed exactly and compared with sampling (pre-registered in
// paper/PLAN_AMENDMENTS.md section 3, H4). With a dictionary shorter than 1,024 bytes every 10-bit code position
// (window + floor(code * L / 1024)) mod L reaches every byte of the dictionary from every window, so the set of bigrams
// a code can produce is the set B of the dictionary's cyclic bigrams whatever the window, and the image of a single
// 16-byte cell is exactly B^8: |image| = |B|^8, and H(f(U)) = 8 H(bigram) where a bigram's probability is the share of
// the 1,024 codes landing on its positions (the window and the fold change which input maps where, not the image).
// Sampling 10^6 random cells through the wasm shows how far a distinct count falls short of the exact image.
// Usage: node paper/experiments/codebook-image.mjs [V=128] [N=1000000]
import fs from 'node:fs';
import vm from 'node:vm';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const [V = 128, N = 1e6] = process.argv.slice(2).map(Number);
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const wasm = instance.exports, L = Codec.LAYOUT, GRID = L.GRID;
let rs = 12345; const rnd32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
const rows = [];
for (let k = 1; k <= 9; k++) {
  const id = `ca-codebook-${k}`, bytes = new Uint8Array(fs.readFileSync(`${dir}/src/changers/dict/${id}.txt`)), tl = bytes.length;
  if (tl >= 1024) { console.error(`${id}: ${tl} bytes, the exact argument needs L < 1024`); continue; }
  // the code -> bigram distribution
  const prob = new Map(); for (let c = 0; c < 1024; c++) { const p = Math.floor(c * tl / 1024) % tl, key = bytes[p] << 8 | bytes[(p + 1) % tl]; prob.set(key, (prob.get(key) || 0) + 1 / 1024); }
  let Hb = 0; for (const p of prob.values()) Hb -= p * Math.log2(p);
  const distinctBytes = new Set(bytes).size, B = prob.size;
  // sampling through the wasm
  const io = Codec.install(wasm.memory, Codec.build(Buffer.from(bytes).toString('latin1'), 3));
  io.setChanger(45); io.setSkipBits(0); io.setCursorRead(V); io.setCursorOffset(0);
  const m8 = new Uint8Array(wasm.memory.buffer), seen = new Map(); let fixed = 0, consumed = 0;
  for (let i = 0; i < N; i++) {
    for (let j = 0; j < 16; j += 4) { const v = rnd32(); m8[GRID + j] = v & 255; m8[GRID + j + 1] = (v >> 8) & 255; m8[GRID + j + 2] = (v >> 16) & 255; m8[GRID + j + 3] = v >>> 24; }
    const r = wasm.decode_pixel(GRID, 0, L.PRM); consumed += r >> 8;
    const out = m8.subarray(io.OUT, io.OUT + 16); let same = true; for (let j = 0; j < 16; j++) if (out[j] !== m8[GRID + j]) { same = false; break; }
    if (same) fixed++;
    const key = Buffer.from(out).toString('latin1'); seen.set(key, (seen.get(key) || 0) + 1);
  }
  let f1 = 0, f2 = 0; for (const c of seen.values()) { if (c === 1) f1++; else if (c === 2) f2++; }
  const chao1 = seen.size + (f2 ? f1 * f1 / (2 * f2) : f1 * (f1 - 1) / 2);
  rows.push({ id, bytes: tl, distinctBytes, bigrams: B, log2Image: 8 * Math.log2(B), HfU: 8 * Hb, consumedMean: consumed / N, distinct: seen.size, log2Chao1: Math.log2(chao1), fixed: fixed / N });
}
const md = [`# Codebook decoder (kind 45): exact image against sampling\n`, `V = ${V} (header ${Codec.rangeBits(V)} bits), skip 0, single cells, N = ${N.toLocaleString()} random cells per dictionary. |B| is the number of distinct cyclic bigrams of the dictionary; the image of one cell is exactly B^8. H(f(U)) is exact (8 times the bigram entropy under the code distribution). Chao1 is the sampled lower-bound estimate.\n`,
  '| dictionary | bytes | distinct bytes | distinct bigrams | log₂ image (exact) | H(f(U)) bits (exact) | bits consumed | distinct outputs of N | log₂ Chao1 | fixed points |', '|---|---|---|---|---|---|---|---|---|---|'];
for (const r of rows) md.push(`| ${r.id} | ${r.bytes} | ${r.distinctBytes} | ${r.bigrams} | ${r.log2Image.toFixed(1)} | ${r.HfU.toFixed(1)} | ${r.consumedMean.toFixed(1)} | ${r.distinct} | ${r.log2Chao1.toFixed(1)} | ${(100 * r.fixed).toFixed(3)} % |`);
fs.mkdirSync(`${dir}/paper/data/decoder-map`, { recursive: true });
fs.writeFileSync(`${dir}/paper/data/decoder-map/codebook-image.md`, md.join('\n') + '\n');
fs.writeFileSync(`${dir}/paper/data/decoder-map/codebook-image.json`, JSON.stringify({ V, N, rows }, null, 1));
console.log(md.join('\n'));
