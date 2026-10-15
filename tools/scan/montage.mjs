// montage.mjs <cols> <out.png> <snap png files...>: tile 128x128 RGBA snapshots with a 4px gutter
import fs from 'node:fs'; import zlib from 'node:zlib';
import { png } from './png.mjs';
const [cols, out, ...files] = process.argv.slice(2); const TILE = Number(process.env.TILE || 128);
const C = Number(cols), n = files.length, rows = Math.ceil(n / C), S = TILE, G = 4, W = C * (S + G) + G, H = rows * (S + G) + G;
const img = new Uint8Array(4 * W * H).fill(40); for (let i = 3; i < img.length; i += 4) img[i] = 255;
const decode = f => { const b = fs.readFileSync(f); let p = 8, idat = []; while (p < b.length) { const len = b.readUInt32BE(p), type = b.toString('ascii', p + 4, p + 8); if (type === 'IDAT') idat.push(b.subarray(p + 8, p + 8 + len)); p += 12 + len; } const raw = zlib.inflateSync(Buffer.concat(idat)); const px = new Uint8Array(4 * S * S); for (let y = 0; y < S; y++) px.set(raw.subarray(y * (4 * S + 1) + 1, y * (4 * S + 1) + 1 + 4 * S), 4 * S * y); return px; };
files.forEach((f, k) => { const px = decode(f), x0 = G + (k % C) * (S + G), y0 = G + Math.floor(k / C) * (S + G); for (let y = 0; y < S; y++) img.set(px.subarray(4 * S * y, 4 * S * (y + 1)), 4 * (W * (y0 + y) + x0)); });
fs.writeFileSync(out, png(W, H, img));
