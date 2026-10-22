// Exact facts of paper/DEFINITION.md checked on the module. Run: node test/lemma.test.mjs
import fs from 'node:fs';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
let fails = 0; const check = (n, ok) => { console.log((ok ? 'ok  ' : 'FAIL') + ' ' + n); if (!ok) fails++; };
// Lemma 1 of paper/DEFINITION.md: a uniform configuration stays uniform under mixing and settling for any parameters, so the
// lattice applies only the local map; checked with the page's gradient frame, both mixing rules and both salts
{
  const { makeSim } = await import(dir + '/tools/ca-harness.mjs');
  let ok = true, detail = '';
  for (const [mixSync, saltMode] of [[false, 0], [true, 0], [false, 1]]) {
    const sim = await makeSim({ W: 48, H: 40, changer: 36, pairMode: 0, maxlen: 3, skip: 6, cread: 4096, coff: 0, swap: [0, 1], smooth: [0, 1], mixSync, saltMode, altOrder: 'rotate' });
    sim.setDict(text); sim.reset(5);
    const g = sim.grid(), s = g.slice(0, 16); for (let i = 0; i < sim.N; i++) g.set(s, 16 * i);
    const one = await makeSim({ W: 1, H: 1, changer: 36, pairMode: 0, maxlen: 3, skip: 6, cread: 4096, coff: 0, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false });
    one.setDict(text); one.grid().set(s, 0);
    for (let t = 0; t < 12; t++) { sim.step(); one.step(); const want = one.grid().slice(0, 16), h = sim.grid();
      for (let i = 0; i < sim.N && ok; i++) for (let k = 0; k < 16; k++) if (h[16 * i + k] !== want[k]) { ok = false; detail = ` (sync ${mixSync}, salt ${saltMode}, turn ${t}, cell ${i})`; break; } }
  }
  check(`a uniform configuration evolves by the local map alone under the gradient frame, both mixing rules and the turn salt${detail}`, ok);
}
console.log(fails ? fails + ' failures' : 'all passed'); process.exit(fails ? 1 : 0);
