# Round 2 (second panel): scientific computation

2026-10-22. Read the six other round-1 notes. Three things were run for this round, all into `paper/data/review2/`
(scripts in my scratchpad, nothing written elsewhere): the mechanism experiment of `mechanism.md` §2–3 repeated at
three settling passes instead of one (`passes-mechanism-ca-brotli-12-p{1,3}.json`, logs beside them); the frame with
every cell of the fixed point's isolated basin removed at turn 0 (`seeds-from-start-s{1,2,3}-{control,removed}.json`);
and a count of look-and-say digits read with and without the run terminator. One number in my round 1 was wrong and
is corrected in §2.

## 1. Agreements and disagreements, by note and finding

**Physics §2.2 (droplets and closure at one settling pass, the frame at three): confirmed, wider than stated, and it changes the mechanism in kind.**
The pass counts across `paper/experiments/`: `droplets.mjs`, `heredity.mjs`, `dose.mjs`, `infodyn.mjs`,
`entropy-curves.mjs` and `replicase.mjs` settle at one pass; `frame-mechanism.mjs`, `replicators.mjs` and
`ablation.mjs` at three; `closure.mjs` is map-only (settling off), so the pass count does not touch the index itself.
So the whole mechanism set (§2 survival table, §3 droplets, §5 lattice mutants), the dose-response, the information
dynamics, the entropy calibration and the replicase ablation's "the page's default media kill every constructed
replicator" were all run at one third of the page's settling, and no results file says so. I reran the §2–3
protocol for Brotli 12 (128², 400 turns, radius 16, one phase seed) at one and at three passes:

| run (swap, median) | one pass: fp / cycle / other at turn 400 | three passes: same |
|---|---|---|
| whole lattice, cycle in random phases (0.1, 0.25) | 0 / 1 / 99 | 0 / 0.5 / 99.5 |
| whole lattice, cycle in random phases (0.1, 0.5) | 0 / 0.6 / 99.4 | **2.2 / 97.1 / 0.7** |
| whole lattice, cycle in random phases (0.5, 0.5) | 0 / 0.7 / 99.3 | **9.8 / 88.4 / 1.8** |
| fp droplet in coherent cycle sea (0.1, 0.5) | 0 / 15.8 / 84.2 | **22.6 / 73.7 / 3.8** |
| fp droplet in coherent cycle sea (0.5, 0.5) | 0 / 0.6 / 99.4 | **71.1 / 21.4 / 7.5** |
| fp droplet in coherent cycle sea (0.1, 1) | 4.8 / 95.1 / 0.1 | 4.7 / 95.2 / 0.1 |
| fp droplet in random-phase cycle sea (0.5, 0.5) | 0 / 0.9 / 99.1 | **90.7 / 7 / 2.3** |
| fp droplet planted after 200 turns at (0.5, 0.5) | 0 / 0.7 / 99.3 | **99.9 / 0 / 0.1** |

At one pass the published picture reproduces: the cycle melts and the fixed point's droplet dies. At three passes,
the page's setting, the open cycle does not melt at median ½ (it re-coheres from random phases to 97 %), the fixed
point appears inside a pure cycle domain that contained no fixed-point cell (0 → 2.2 % and 9.8 % in 400 turns),
and the fixed point's droplet grows into the coherent cycle sea by a moving interface (4.9 → 22.6 % at swap 0.1,
→ 71 % at swap 0.5). "Mixing melts the open type; the closed type nucleates in the melt and fills it" is therefore
a one-pass phenomenon. At the frame's settling the mechanism is creation of fixed-point cells by the medium inside
cycle domains, followed by invasion of the coherent cycle by the fixed point's domain. Melting is what happens at
weaker settling (median ≤ 0.25 at three passes). I agree with the physicist's §2.6 explanation (the lattice basin,
not the isolated basin) and with her item 1 as the first experiment to run; the table above is one phase seed and
one dictionary, and a second phase seed is running as I write (§5 below).

**Physics §1.2 (the quenched (0.2, ½) medium is coarsening, not frozen): confirmed from `ablation-sizes/series.csv`.**
At 512², ξ_c = 12.2, 15.2, 18.5, 22.2, 26.5, 27.9 at turns 100–2,000 with d1 = 1.3 × 10⁻² throughout; at (½, 1)
it is 11.2 → 12.6 and flat from turn 400 with d1 = 1.0 × 10⁻³. The 1024² "28.47, converged" in `finite-size.md`
is the same trajectory read at the same turn. My round-1 check of that file was a regeneration check, not a
reading of ξ(t); the physicist's reading is right.

**Physics §2.3 and professor finding 1 (t₅₀ on the plateau): agree; my round-1 finding 2 says the same from the 25 % and 40 % marks.** The professor's "no faster than 1.6× for a fourfold side" is safe; "size-free at every share below the plateau" is what the curves show.

**Mathematics finding 8 ("the seeds come from the start, not from the melt"): refuted by experiment.** Brotli 12,
page frame, 128², three passes, 2,000 turns, seeds 1–3. Every cell whose isolated trajectory lands on the fixed
point (44, 63, 65 cells) was replaced at turn 0 by the initial bytes of a random non-basin cell, and the replaced
start was verified to contain zero basin cells under f alone. Fixed-point share at turns 50 / 200 / 500 / 1000 /
2000:

| seed | control | basin cells removed |
|---|---|---|
| 1 | 4.8 / 35.4 / 42.8 / 48.4 / 55.7 | 5.7 / 36.3 / 43.4 / 47.4 / 52.0 |
| 2 | 6.0 / 37.8 / 44.8 / 51.4 / 52.6 | 9.1 / 39.1 / 48.4 / 55.6 / 60.5 |
| 3 | 7.5 / 38.4 / 47.6 / 52.8 / 58.3 | 6.4 / 36.5 / 49.8 / 57.0 / 59.9 |

First sighting at turn 10 in all six runs. The start's basin cells make no difference. The seeds are made by the
medium, as the first panel's 32² result (fixed point by turn 20–58 with no basin cell in the lattice) already
said and as the pure-cycle-domain rows above show directly. The mathematician's test (ii), a droplet in a
pre-melted sea, I ran at both pass counts: at one pass it dies as he inferred from the data; at three passes the
sea never melts and the droplet takes the lattice. His finding 3 (48-bit prefix, 30 command bits) and finding 2
(the look-and-say formula in DEFINITION.md's remark is inverted) do not change the proposition's logic, which I
checked in round 1; I accept both corrections. His finding 10, heredity as the log-size of the fixed-point family,
is the right quantity, and the family histogram I reproduced (15,643 / 4,608 / 1,835,008 / 67,108,864) gives
Keimli's side of it exactly: 0–3 free bytes.

**ALife §1.8 and §7.3, professor "partly" item 6 (the 6502 and Redcode single-cell numbers have no files): confirmed and sharpened.**
`paper/data/replicators-v2/` holds JSON for the uniform setting of cpu6 (Z80) and cpu7 (6502) only; Redcode
single cells (cpu47) have `.md` and `.log` and no JSON; the page-frame runs of all three processors have no JSON.
The cpu7 file postdates the published table. So RESPONSE.md row 5's "Z80, 6502 and Redcode at 5 seeds" is two
files and some overwritten log lines. ALife §7.4 (`bff.mjs validate` writes to a hard-coded path and ignores
`out=`): agreed and added to my list; `ablation-summary.mjs` has the same defect in the other direction (it writes
`summary-final.md`, `series.csv` and `curves.csv` into its input directory, which is why I had to copy
`ablation-sizes/` to rerun it). ALife §1.1 (the "heritable" column is conversion): I did not check the data
columns; the argument is right. ALife §4.3 (BFF's replicators are built, Keimli's listed): my seeds-from-start
result complicates the Keimli side of that sentence. Keimli's fixed point is listed in the map's census, but its
lattice entries are not in the start; the medium makes them at a rate the isolated basin does not predict (zero
basin cells, 5–9 % by turn 50). "Listed" is true of the attractor, not of its occurrence.

**Information finding 4 (look-and-say bound one digit short): confirmed.** 200,000 random 32-digit base-16 cells:
E[bits inside the described runs] = 68.24, E[bits read including the digit that ends the last run] = 72.24. The
last count depends on that digit, so the stopping time of Lemma 3 must include it, and 68.27 is not a proven
bound; 72.27 (and 87.11, 98.92 for bases 4 and 2) is. The closed form 128/(2(1 − 1/b)) is the run-count form.
Finding 16 (the "rest" is not an upper bound): agree. rest = H(X|P) − T̄ − T_S, with T̄ an average over the four
neighbours; it is a lower bound on H(X | P, S) for the best single source S only if T̄ + T_S ≥ I(X; S | P), which an
average of four does not guarantee. It is neither bound; "residual after storage and the pairwise transfers" is the
right name. Finding 5 (identity control, one pass unstated): agree; the pass table above covers it. Finding 1
(N = 131,044, not 131,072): agree, n = 362.

**Optimization finding 10 (gray3c never reaches 90 %): confirmed from the regenerated table**, 90 % > 1,999 at both
sizes under uniform settings, final 67–69 %, two distinct leaders in 20 seeds. Finding 4 (the index depends on its
(r, steps) choice): agree, and the three-pass table above adds that the survival column depends on the pass count
too, so both axes of the correlation are parameter choices. Finding 3 (basin against survival, r = −0.57) is the
better single figure. Finding 12 (tie rule in the shuffle rank): not checked.

**Professor §2 item 2 (exact fixed points of Brotli 12, 13 and the designs, a minute each): agree**, and from my
rerun the full Swarm F search is 3 minutes on 16 threads here, so the five dictionaries are under 20 CPU-minutes.
His melting threshold p*(type, median) (§2, finding 6) and the physicist's item 3 are the same experiment; both
must be run at three passes, or the threshold will be the one-pass artefact again.

## 2. What I revise in my own round 1

1. **Finding 3's statistics were wrong.** A units slip (a 1 % survival read as 1.0) gave Spearman 0.77 and r = 0.57
   over the five generic cycles. Correct values from the table: Pearson 0.79 over 15, Spearman 0.997, r = 0.61 over
   the five generic cycles (the professor's number), 0.98 without the two 95 % types (physics, information). The
   conclusion stands: the correlation is a gap between two clusters and should be a count.
2. **Finding 3's conclusion "open types melt (4 of 4)" holds at one settling pass only.** At three passes Brotli 12's
   3-cycle holds a random-phase domain at median ½ (97 %) and loses it at ¼. The survival column of the closure
   table, and my Swarm F addition, are one-pass numbers. The index still separates closed from open, but what
   "open" costs depends on the settling.
3. **My Q2 answer is downgraded.** I wrote that the result is explained "in this sense: … generic cycles are open
   and melt under mixing with partial settling … and on the frame the closed type nucleates in the melt". At the
   frame's settling the melt does not form at median ½, the fixed point is created inside the cycle's domains and
   invades them. The first half (closure, Lemma 1, the proposition) stands; the second half has to be re-measured
   at three passes before anything is said.
4. **Finding 1 should add the pass count** to the provenance gaps: no stamp records `passes`, and six scripts
   hard-code 1.
5. **My "finite-size summary identical" was a check of the regeneration, not of the claim**; the (0.2, ½) row is
   coarsening (§1).
6. **Q6 estimate** rises from three days and 30 CPU-h to the list in §4.

## 3. The three most important corrections, ranked

1. **The mechanism section was run at one settling pass and the mechanism changes at three.** `mechanism.md` §2–4
   (closure–survival, droplets, "melt then nucleate") have no experiment at the frame's settling, and at that
   settling the open cycle does not melt at median ½, the medium creates fixed-point cells inside cycle domains, and
   the fixed point's domain invades the coherent cycle by a moving interface; the seeds do not come from the start.
   The sentence for the paper is not yet known; the experiments that will give it are the physicist's items 1–4 at
   three passes plus a creation-rate measurement (fixed-point cells made per cycle cell per turn against (swap,
   median)). This also voids the pass-dependent parts of the replicase ablation's "the page's media kill every
   constructed replicator" and the information dynamics' medium rows until rerun.
2. **Three summary numbers that say the wrong thing, all fixable from existing data without CPU:** t₅₀ on the plateau
   (the curves are size-free below it; report the curves or the time to 25 % and 40 %); r = 0.79 (a 2 × 2 table, ten
   of whose fifteen rows are theorems); "converged" at the quenched (0.2, ½) point (coarsening at z ≈ 0.26 with d1 ten
   times the frozen value).
3. **Numbers without files and an index that contradicts the results.** The 6502/Redcode single-cell shares and every
   CPU page-frame row are quoted from logs with no JSON; the Declaration's "no takeover" is a kmax = 64 detector
   looking for periods 154 and 182; the published replicator and finite-size tables predate the last data;
   `results/README.md` and every draft still state the retracted claims. The pipeline needs one regeneration step,
   `out=` honoured everywhere, and `passes` in every stamp.

## 4. Minimum work for my role, consolidated and deduplicated

Items the others already demand and I do not repeat: the drafts rewritten on the claims tables (all); seeds 2–5 for
the dose-response and the information dynamics (physics 7, ALife 6, information 5); 20 BFF soups (physics 7,
professor); the imp's mutant census (ALife 4, information 6); exact fixed points of the other dictionaries
(professor 2); the radius series and the melting threshold (physics 2–3, professor 3); the whole-turn closure over
the (swap, median) plane (mathematics, information 4). Every one of these that touches the lattice must be run at
three passes and say so.

What is mine:

| # | item | days | CPU-h |
|---|---|---|---|
| 1 | `passes` an explicit parameter in droplets, heredity, dose, infodyn, entropy-curves and replicase, recorded in the provenance stamp and stated in every results file; harness default `altOrder: 'rotate'`; `out=` honoured in `bff.mjs validate` and `ablation-summary.mjs` (write beside the inputs, never into them); provenance in `entropy-curves` output and the per-seed lead files; `test/lemma.test.mjs` in `test/smoke.sh` | 0.5 | 0 |
| 2 | One `make tables` that regenerates every results table and figure from the data (the two stale tables, the two pre-v2 replicator figures); superseded banners on `ablation-main/-scan/-structure.md`, `replicators.md`, `replicators-table.md`, `decoder-map.md` l.38; `results/README.md` rewritten as an index; `band.js` l.10–12; the four dictionaries normalised in the repository | 0.5 | 0 |
| 3 | The mechanism set rerun at three passes: whole-lattice survival and droplets for the six dictionaries at the four (swap, median) points that matter, 3 phase seeds, 128² (reduced from physics item 1's 5,000 runs by dropping the noise sweep and the full grid); the seeds-from-start test at 256², 10 seeds, Brotli 12 and 13; the creation rate of the fixed point in pure cycle domains against (swap, median), 5 seeds | 1 | 12 |
| 4 | The Declaration at kmax = 200, 4 settings × 10 seeds, 128² and 256² | 0.25 | 7 |
| 5 | The 6502, Redcode and Z80 single-cell and page-frame replicator rows with the fixed script, 5 seeds, 256² | 0.25 | 12 |
| 6 | Re-analysis, no CPU: share curves and the time to 25 % and 40 % against size; the first-sighting distribution per seed; ξ(t) local slopes per condition from `series.csv`; the look-and-say table with the terminator digit (72 / 87 / 99 bits) | 0.5 | 0 |
| 7 | One turn engine in the page (`Band.runTurn` with one band) and a 1-against-4-thread parity self-test over the vote, pair-write, sync and position-salt modes; the build archived with its hash | 1 | 0 |

About four days and 30 CPU-hours. Items 1–3 come before any mechanism sentence is written; items 4–5 before any
processor or Declaration number is printed.

## 5. Second phase seed for the three-pass table

`passes-mechanism-ca-brotli-12-p3-rs2.json`, three passes, phase seed 2 (the coherent-sea rows draw no random
numbers and are identical to seed 1; the others differ). Fixed point / cycle / other at turn 400: whole lattice in
random phases (0.1, 0.25) 0 / 0.5 / 99.5; (0.1, 0.5) **0 / 100 / 0**; (0.5, 0.5) **37.2 / 55.7 / 7.1**; fixed-point
droplet in a random-phase sea (0.1, 0.5) 28.5 / 67.3 / 4.2 and (0.5, 0.5) 86.9 / 9.2 / 3.9; droplet planted at turn
200 at (0.5, 0.5) 97.3 / 1.4 / 1.3. The qualitative picture of §1 holds in both seeds: at the frame's settling the
cycle re-coheres instead of melting at median ½, the fixed point is created inside the cycle's domain at a rate that
varies strongly between seeds (9.8 % against 37.2 % by turn 400 at (½, ½)), and its droplets grow. The variation in
the creation rate is itself the quantity to measure, with seeds.
