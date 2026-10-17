// Dictionary search on the running lattice, for settings where the cells interact (entropy increase and decrease on),
// so the attractor census of ca-search.mjs no longer describes the dynamics. Each candidate dictionary is run on a
// small lattice with the page's defaults for the entropy stages and scored late in the run on how many different
// kinds of behaviour the picture holds at once (the effective number of 8 x 8 block regimes by change, neighbour
// difference and entropy), behind guards against frozen, blinking, uniform and pure-noise fields. Simulated
// annealing with word-level moves and restarts, within a time budget.
// Usage: node tools/ca-lattice-search.mjs [seed] [seeds] [hours] [kind] [skip] [dictLen] [cursorRead] [pairMode] [grid] [turns]
// Defaults: 1 120 1 45 6 512 256 0 64 150. Writes build/ca-lattice-best*.json and appends to build/ca-lattice*.log.
import fs from 'node:fs';
import { makeSim, evaluate } from './ca-harness.mjs';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const [SEED, N_SEED, HOURS, KIND, SKIP, DLEN, CREAD, PAIR, GRIDN, TURNS] = [1, 120, 1, 45, 6, 512, 256, 0, 64, 150].map((d, i) => Number(process.argv[2 + i] ?? d));
const TAG = `-k${KIND}-s${SKIP}-l${DLEN}-v${CREAD}-p${PAIR}-g${GRIDN}`;
const OUT = dir + `/build/ca-lattice-best${TAG}.json`;
const LOG = m => { console.log(m); fs.appendFileSync(dir + `/build/ca-lattice${TAG}.log`, m + '\n'); };
let seed = SEED;
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
const ri = n => Math.floor(rand() * n), pick = a => a[ri(a.length)];
const LETTERS = 'abcdefghijklmnopqrstuvwxyz';
const fit = s => { s = s.replace(/[^\x20-\x7e\n]/g, ''); while (s.length < DLEN) s += s; return s.slice(0, DLEN); };
const sim = await makeSim({ W: GRIDN, H: GRIDN, changer: KIND, pairMode: PAIR, skip: SKIP, cread: CREAD, coff: 0 });

// ---- dictionary families
const phrase = (alpha, len) => Array.from({ length: len }, () => pick(alpha)).join('');
const families = {
  phrases() { const k = 2 + ri(6), len = 3 + ri(10); const letters = LETTERS.split('').sort(() => rand() - 0.5); const per = Math.max(2, Math.floor(26 / k));
    const ps = Array.from({ length: k }, (_, i) => phrase(letters.slice(i * per, (i + 1) * per), len)); let s = ''; while (s.length < DLEN) s += pick(ps) + ' '; return fit(s); },
  phrasesShared() { const k = 2 + ri(5), len = 4 + ri(10); const alpha = LETTERS.slice(0, 4 + ri(12)).split(''); const ps = Array.from({ length: k }, () => phrase(alpha, len)); let s = ''; while (s.length < DLEN) s += pick(ps) + ' '; return fit(s); },
  branchChain() { const len = 8 + ri(30), nb = 1 + ri(5); const alpha = LETTERS.split('').sort(() => rand() - 0.5).slice(0, len); const base = alpha.join(''); const alts = Array.from({ length: nb }, () => [ri(len), pick(LETTERS)]); let s = '';
    while (s.length < DLEN) { const w = base.split(''); for (const [i, c] of alts) if (rand() < 0.5) w[i] = c; s += w.join('') + ' '; } return fit(s); },
  mixed() { const f = 0.05 + rand() * 0.4; return fit(families.phrases().split('').map(c => rand() < f ? String.fromCharCode(32 + ri(95)) : c).join('')); },
  natural() { const dd = dir + '/src/changers/dict/'; const files = ['../declaration.txt', 'nocturne.txt', 'kalevala-1.txt', 'catullus-5.txt', 'don-quijote.txt', 'nam-quoc-son-ha-viet.txt', 'voluspa.txt', 'qaro-kozum.txt']; const t = fs.readFileSync(dd + pick(files), 'utf8').replace(/[^\x20-\x7e\n]/g, ''); const i = ri(Math.max(1, t.length - DLEN)); return fit(t.slice(i, i + DLEN)); },
  random() { return fit(Array.from({ length: DLEN }, () => String.fromCharCode(32 + ri(95))).join('')); },
  smallAlphabet() { const a = LETTERS.slice(0, 2 + ri(4)).split('').concat([' ']); return fit(Array.from({ length: DLEN }, () => pick(a)).join('')); },
  found() { const dd = dir + '/src/changers/dict/'; const files = fs.readdirSync(dd).filter(f => /^ca-codebook-\d+\.txt$/.test(f)); return files.length ? fit(fs.readFileSync(dd + pick(files), 'utf8')) : families.smallAlphabet(); },
};
// word-level moves, for dictionaries made of repeated words: swap two words everywhere, exchange the places of two words,
// or respell one word everywhere
const wordMoves = t => {
  const words = t.split(' '), vocab = [...new Set(words.filter(w => w.length >= 2))];
  if (vocab.length < 2) return null;
  const r = rand();
  if (r < 0.4) { const [a, b] = [pick(vocab), pick(vocab)]; if (a === b) return null; return fit(words.map(w => w === a ? b : w === b ? a : w).join(' ')); }
  if (r < 0.7) { const i = ri(words.length), j = ri(words.length); [words[i], words[j]] = [words[j], words[i]]; return fit(words.join(' ')); }
  const a = pick(vocab), k = ri(a.length), b = a.slice(0, k) + String.fromCharCode(97 + ri(6)) + a.slice(k + 1); return fit(words.map(w => w === a ? b : w).join(' '));
};
const mutate = t => {
  if (rand() < 0.35) { const w = wordMoves(t); if (w) return w; }
  const a = t.split(''); const r = rand();
  if (r < 0.4) { a[ri(DLEN)] = String.fromCharCode(32 + ri(95)); }
  else if (r < 0.6) { const i = ri(DLEN), j = ri(DLEN), n = 1 + ri(12); for (let k = 0; k < n; k++) if (i + k < DLEN && j + k < DLEN) a[j + k] = t[i + k]; }
  else if (r < 0.75) { const i = ri(DLEN), n = 1 + ri(12), c = pick(t); for (let k = 0; k < n && i + k < DLEN; k++) a[i + k] = c; }
  else if (r < 0.9) { const i = ri(DLEN), n = 2 + ri(10); const seg = t.slice(i, i + n); return fit(t.slice(0, i) + seg + t.slice(i)); }
  else { const i = ri(DLEN), j = ri(DLEN); [a[i], a[j]] = [a[j], a[i]]; }
  return fit(a.join(''));
};

// ---- the lattice score
const win = (x, lo, hi, soft = 0.5) => { if (x >= lo && x <= hi) return 1; const d = x < lo ? (lo - x) / (lo * soft + 1e-9) : (x - hi) / (hi * soft + 1e-9); return Math.max(0, 1 - d); };
function latticeScore(rows) {
  const late = rows.slice(-5), mean = k => late.reduce((s, r) => s + r[k], 0) / late.length;
  const last = rows[rows.length - 1], d1 = last.d1, d2 = last.d2, sp = mean('spatial'), ent = mean('ent'), zip = mean('zip'), act = mean('act'), distinct = mean('distinct');
  const regimes = last.regimes ? last.regimes.effective : 1;
  // many different things at once: the effective number of block regimes (change x neighbour difference x entropy classes)
  // is the score, behind guards that rule out a frozen, a blinking, a uniform and a pure-noise field
  const f = { change: win(d1, 0.005, 0.35), blink: win(d2 / (d1 + 1e-9), 0.5, 10), structure: win(sp, 0.05, 0.42), entropy: win(ent, 1.5, 7.2), compress: win(zip, 0.1, 0.9), variety: win(distinct, 0.05, 0.98), alive: d1 > 0.002 ? 1 : 0 };
  const s = Object.values(f).reduce((a, b) => a * b, 1) * regimes;
  return { score: s, d1, d2, spatial: sp, ent, zip, act, distinct, regimes, f };
}
const assess = text => { const rows = evaluate(sim, text, { turns: TURNS, seed: 11, every: 10 }); return latticeScore(rows); };
const fmt = e => `score ${e.m.score.toFixed(3)} regimes ${e.m.regimes.toFixed(2)} d1 ${e.m.d1.toFixed(3)} d2/d1 ${(e.m.d2 / (e.m.d1 + 1e-9)).toFixed(2)} spatial ${e.m.spatial.toFixed(3)} ent ${e.m.ent.toFixed(2)} zip ${e.m.zip.toFixed(2)} distinct ${e.m.distinct.toFixed(2)} act ${e.m.act.toFixed(2)}`;

// ---- search
const deadline = Date.now() + HOURS * 3600e3, t0 = performance.now();
LOG(`ca-lattice-search: kind ${KIND}, skip ${SKIP}, ${DLEN}-byte dictionaries, cursor read ${CREAD}, pair mode ${PAIR}, ${GRIDN}x${GRIDN}, ${TURNS} turns, entropy stages on (page defaults); seed ${SEED}, ${N_SEED} seeds, ${HOURS} h`);
const names = Object.keys(families), pool = [];
for (let i = 0; i < N_SEED && Date.now() < deadline; i++) { const fam = names[i % names.length], text = families[fam](); pool.push({ text, fam, m: assess(text) }); }
pool.sort((a, b) => b.m.score - a.m.score);
LOG(`seeds done in ${((performance.now() - t0) / 1000).toFixed(0)} s; best per family:`);
for (const f of names) { const b = pool.find(p => p.fam === f); if (b) LOG(`  ${f.padEnd(14)} ${fmt(b)} | ${JSON.stringify(b.text.slice(0, 50))}`); }
const ELITES = 6; let elite = pool.slice(0, ELITES).map(p => ({ ...p, stale: 0 }));
const T0 = 0.6, T1 = 0.05;   // the score is now a regime count of a few units   // annealing: a worse candidate is accepted with probability exp(-loss / T), T falling over the run
const temperature = () => T0 * (T1 / T0) ** Math.min(1, (Date.now() - (deadline - HOURS * 3600e3)) / (HOURS * 3600e3));
const archive = new Map(); const remember = e => { archive.set(e.text, { text: e.text, fam: e.fam, m: e.m }); if (archive.size > 30) { const worst = [...archive.values()].sort((a, b) => a.m.score - b.m.score)[0]; archive.delete(worst.text); } };
let evals = 0, lastLog = 0;
while (Date.now() < deadline) {
  for (const e of elite) {
    const cand = rand() < 0.1 ? (() => { const o = pick(elite).text, i = ri(DLEN); return fit(e.text.slice(0, i) + o.slice(i)); })() : rand() < 0.25 ? mutate(mutate(e.text)) : mutate(e.text);
    const m = assess(cand); evals++;
    if (m.score >= e.m.score || rand() < Math.exp((m.score - e.m.score) / temperature())) { if (m.score > e.m.score) e.stale = 0; if (m.score >= e.m.score) remember({ text: cand, fam: e.fam, m }); e.text = cand; e.m = m; e.fam = e.fam.replace(/\*?$/, '*'); } else e.stale++;
    if (e.stale > 300) { elite.sort((a, b) => b.m.score - a.m.score); remember(e); const fam = pick(names), text = families[fam](); Object.assign(e, { text, fam, m: assess(text), stale: 0 }); }
  }
  if (evals - lastLog >= 120) { lastLog = evals; elite.sort((a, b) => b.m.score - a.m.score); LOG(`climb ${evals} (${((performance.now() - t0) / 60000).toFixed(0)} min): best ${fmt(elite[0])} (${elite[0].fam}) | ${JSON.stringify(elite[0].text.slice(0, 50))}`); fs.writeFileSync(OUT, JSON.stringify({ elite, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1)); }
}
elite.sort((a, b) => b.m.score - a.m.score); for (const e of elite) remember(e);
fs.writeFileSync(OUT, JSON.stringify({ elite, archive: [...archive.values()].sort((a, b) => b.m.score - a.m.score) }, null, 1));
LOG(`done: ${evals} climbs in ${((performance.now() - t0) / 60000).toFixed(1)} min; best ${fmt(elite[0])}\n${JSON.stringify(elite[0].text)}`);
