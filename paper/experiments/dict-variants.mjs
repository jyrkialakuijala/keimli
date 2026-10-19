// Dictionary loading and the control variants shared by the decoder-map and the lattice experiments.
// loadDict(id): the file's bytes as the harness and the searches used them, plus the byte count the page would see
// (the build strips trailing newlines and adds one back). variantOf(bytes, variant, seed): raw, shuffle (the bytes
// permuted), wordshuffle (the maximal non-whitespace runs permuted, the whitespace left in place), reverse.
import fs from 'node:fs';
import path from 'node:path';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
export function loadDict(id) {
  const p = fs.existsSync(id) ? id : fs.existsSync(`${dir}/src/changers/dict/${id}.txt`) ? `${dir}/src/changers/dict/${id}.txt` : `${dir}/src/changers/${id}.txt`;
  const raw = fs.readFileSync(p);
  const page = Buffer.from(fs.readFileSync(p, 'utf8').normalize('NFC').replace(/\n+$/, '') + '\n', 'utf8');
  return { bytes: new Uint8Array(raw), pageBytes: page.length, file: path.relative(dir, p) };
}
export function variantOf(bytes, variant, seed = 1) {
  let rs = (seed * 2654435761 + 12345) >>> 0 || 1;
  const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs / 4294967296; };
  const a = Array.from(bytes);
  if (variant === 'raw') return bytes;
  if (variant === 'reverse') return Uint8Array.from(a.reverse());
  if (variant === 'shuffle') { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return Uint8Array.from(a); }
  if (variant === 'wordshuffle') {
    const s = Buffer.from(bytes).toString('latin1'), words = s.match(/\S+/g) || [], gaps = s.split(/\S+/);
    for (let i = words.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [words[i], words[j]] = [words[j], words[i]]; }
    let out = gaps[0]; for (let i = 0; i < words.length; i++) out += words[i] + gaps[i + 1];
    return Uint8Array.from(Buffer.from(out, 'latin1'));
  }
  throw new Error('unknown variant ' + variant);
}
// the bytes as the latin1 string Codec.build turns back into the same bytes
export const asText = bytes => Buffer.from(bytes).toString('latin1');
