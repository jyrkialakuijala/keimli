# Round 1: scientific computation (numerics, reproducibility, measurement pipeline)

2026-10-21. Read: README, METHODS, REVIEW_COMPUTATION, results/README, replicators.md and its table, swap-order.md, ablation-main.md (opening), PLAN_AMENDMENTS §1–3, RESULTS_REPLICATORS; code: lattice.wat (hash, ctx, pair), band.js, ca-harness.mjs, replicators.mjs, replicators-summary.mjs, page engine lines in src/page/lattice.html. Ran `node test/band.test.mjs` (all passed) and two 80-turn replicator runs at n = 48 in my scratchpad.

## 1. The project in five lines
A deterministic cellular automaton on 128-bit cells: hashed, bit-conserving neighbour exchanges, then a hashed per-bit-plane majority, then a per-cell rewrite (a Brotli-like decoder against a 4 kB dictionary, or an emulated CPU).
Randomness is quenched: every decision is a splitmix hash of 32 context bits with salt 0 (lattice.wat:15–52), so "p" is a fraction of contexts, not a probability.
The decoder alone is a map on 2^128 cells with a few short cycles (census); the lattice is a medium of coupled oscillators acting on their phase field.
The claim is that this medium separates what any entropy-reducing local map does from what computation adds.
The browser page plus the wasm module is meant to be the primary, re-runnable artifact.

## 2. Strengths
- One wasm module serves the page, the workers and every script (harness loads build/keimli.wasm and band.js via vm); the band pipeline is tested bit-for-bit against whole-grid runs (band.test passes).
- Exact JS reference for the decoder verified against the wasm (decoder-map.md); thresholds exact at p = 0, 1.
- A real pre-registration with decision rules, and the author retracted H1 under it. Nulls (`hash:K`, shuffles, random cycles) exist.
- Quenched-vs-annealed control already built in and already shown to matter (MS− quenched ξ frozen at 5.6, annealed grows to 19.9).

## 3. Concerns, ranked
1. **The replicator batch does not use the page's rule.** `replicators.mjs` never passes `altOrder`, and `makeSim` defaults it to `false`, i.e. the fixed UD0 LR0 UD1 LR1 order (ca-harness.mjs:17, 35). The page's default is `rotate` (lattice.html:1597). swap-order.md says the fixed order is anisotropic and that "the article's runs must be repeated with it". So everything labelled "page frame" in replicators.md is not the page. The same goes for the 1,192 ablation runs (acknowledged), and the page also differs in grid (512²), dictionary default (ca-gray20c) and engine.
2. **Data provenance is not recorded.** Output JSON carries no commit, wasm hash, script version, swap order or dictionary SHA. The tree is uncommitted (lattice.wat, driver.wat, harness all modified), the wasm was rebuilt at 01:02, the harness edited at 03:05 while batches ran from 02:53. Proof that this bites: the 20,000-turn files (`*-t20000.json`, made by an older script with no `changer/steps/salt` fields) report first appearance at turn 32 for *every* species, including fixed points and 3-cycles, while the 2,000-turn runs of the same seeds give 5–10. `replicators-summary.mjs` puts both into `replicators-table.md` as indistinguishable rows (two "ca-brotli-12 page frame 256" rows). Their t50 values are identical (1546, 1093, 1112), so the dynamics agree and the detector differs.
3. **"No late first appearance" is argued from the wrong basin.** The basin is the share under the *isolated* decoder (simB, one grid, seed 99). On the lattice, mixing knocks cells out of a basin every turn, and a cell counts only after 2k quiet turns. At n = 48 (my run) Brotli 12's fixed point (basin 0.26 %, about 6 cells expected) first appears at turn 36, not near turn 2. The 1/(Nb) argument is a statement about the decoder, not the medium. The claim needs N-scaling of first appearance (48, 128, 256, 512), not one size.
4. **Takeover statistics are too thin for their scaling claims.** "About 1.5 times longer at 256² than 128²" rests on medians of 5 seeds (716 vs 1,093) whose seeds alone range from 722 to 1,546. "Roughly as its inverse square root" of the basin is fitted across four *different dictionaries*. With a bounded plane and a gradient frame, "front" and "nucleation" (Avrami: size-independent) are not distinguished. The scaling needs bootstrap CIs and a size series.
5. **Two turn implementations still exist.** The page's single-thread engine (lattice.html:871–872, `mix_from`/`smooth`) is not `Band.runTurn`, and Threads defaults to 1, so the page most viewers see is the copy. REVIEW_COMPUTATION §1 flagged this and it is not fixed. No 1-vs-N-thread parity test.
6. **Quenched hash, finer point.** The exchange decision hashes only the 32 surrounding bits, not the bit index (ctx excludes i, no i in decide). So identical local patterns decide identically at every *bit position* too: the rule is invariant under ring rotation of both cells. This is a hidden symmetry that interacts with the decoder's fixed reading frame, and should be stated and tested (e.g. a salt by bit index).
7. ξ is capped at 64 on a 192-cell bulk, and the rotated order lands at 57–60: these are cap-limited. Bounded plane with clamped edges (no periodic mode yet).

## 4. Questions for the panel
- ALife/theory: is "replicator = attractor of the per-cell map" fair to Tierra/Avida, where copying is *of* a program *into other memory*? The decoder arm has no cross-cell writes except the pair modes.
- Physics: is "front takeover" the right model, or nucleation-and-growth? Which observable separates them on a bounded gradient frame?
- Compression: does the hidden ring-rotation symmetry of the hash (concern 6) matter for the decoder's header?
- Editors: is a browser page an acceptable primary artifact without a pinned, archived build (DOI, wasm hash)?

## 5. Plan for the methodology round
- Rerun small (n = 64–128, short) replicator and ablation points with `altOrder='rotate'` vs fixed to bound how much the order changes winners and t50.
- First-appearance vs N on the lattice (48–256), against the isolated-decoder 1/(Nb) prediction.
- Check the page's single-thread engine against `Band.runTurn` for one seed, turn by turn (posalt, vote partner, pair write, mixSync).
- Audit the decision hash: uniformity of realised exchange rate per bit position in an ordered field, and the effect of adding the bit index.
- Check detector false positives (32-bit FNV state hash, 32-bit species id) and periodOf's ring indexing.
- Write a provenance checklist: commit + wasm SHA + dictionary SHA + scheme in every output JSON, and a regression that regenerates one table row.
