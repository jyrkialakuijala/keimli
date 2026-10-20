// Check the reference decoder on the pair modes against the module: random grids, one turn of the changer alone,
// every pair joined, decoded at width 32 and split back as decode.wat does (flip = turn parity).
// Usage: node paper/experiments/verify-pairs.mjs [dict=ca-swarm-f] [V=4096] [turns=2]
import { makeSim } from '../../tools/ca-harness.mjs';
import { decode36, joinPair, splitPair } from './decode36.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import fs from 'node:fs';
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const id = opt.dict || 'ca-swarm-f', V = Number(opt.V ?? 4096), turns = Number(opt.turns ?? 2);
const bytes = fs.existsSync(id) ? new Uint8Array(fs.readFileSync(id)) : loadDict(id).bytes;
for (const mode of [1, 2, 3, 4, 5]) {
  const sim = await makeSim({ W: 64, H: 64, changer: 36, pairMode: mode, maxlen: 3, skip: 6, cread: V, coff: 0, mixOn: false, settleOn: false });
  sim.setDict(asText(bytes)); sim.reset(7); let mism = 0, n = 0;
  for (let t = 0; t < turns; t++) {
    const before = sim.grid().slice(); sim.step(); const after = sim.grid();
    for (let i = 0; i + 1 < sim.N; i += 2) {
      const a = before.subarray(16 * i, 16 * i + 16), b = before.subarray(16 * i + 16, 16 * i + 32);
      const out = decode36(joinPair(a, b, mode, t & 1), bytes, { skip: 6, V, coff: 0, width: 32 }).out, [a2, b2] = splitPair(out, mode, t & 1);
      n++; for (let k = 0; k < 16; k++) if (a2[k] !== after[16 * i + k] || b2[k] !== after[16 * i + 16 + k]) { mism++; break; }
    }
  }
  console.log(`${id} V ${V} pair mode ${mode}: ${n} pairs over ${turns} turns, ${mism} mismatches`);
}
