# Round 2 (second panel): statistical physics and statistics

2026-10-22. After reading the other six round-1 notes. One new data read (Brotli 13's share curves by size, in §2.4);
otherwise everything here is argument over numbers already in round 1 of the seven of us.

## 1. Agreements and disagreements, by note and finding

**Mathematics, finding 8 ("the seeds come from the start, not from the melt").** Agree on the fact and the test, with
one correction and one reservation. The fact: at one settling pass no fixed point forms from the melt in 400 turns at
any of the four partial-settling points; I read the same tracks. The correction: the droplet and closure scripts run
`passes: 1` while the frame and replicator scripts run 3 (my round 1 §2.2), so the tracks cannot yet say anything
about the frame at all; the mathematician's reading treats them as the same medium. The reservation: the fixed point
holds 18 % of the frame at turn 20 and 29 % at turn 50 (my §0.4), which is too much, too early, for 2.7 basin cells per
block growing at a wall speed of order one cell per turn into a region that is still mostly coherent cycle; some of
it must be the three-pass medium creating basin entries in the melt. His test (i), replacing every fixed-point-basin
cell of the random start, decides between us and costs 3 CPU-h; it goes into the matched block in §4. His test (ii),
a droplet in a pre-melted sea, is in my specification too. On finding 9 ("weakly size-dependent, 1.35–1.6×"): disagree;
see the computation reviewer below.

**Mathematics, findings 1(b) and 3.** Accept both: a bit's value can travel two cells per turn under sequential
mixing, which is the right neighbourhood radius to print, and the prefix is 48 bits, not 46. Neither changes my
reading of the proposition. Finding 4's corollary (species whose H₀ form a Gray code over the high header bits are
mutually closed) is the best new line in any of the notes and answers the "no strangers at interfaces" question for
designs.

**Computation, finding 2 (time to 25 % and 40 % size-independent).** Agree; it is the same observation as my share
curves (18 / 29 / 31 / 37–39 % at turns 20 / 50 / 100 / 200 at all three sizes). Disagree with the last clause, "the
nucleation signature without qualification". Size-free times are the signature of seeds distributed throughout the
lattice at a fixed density, whatever made them; seeds from the random start (the mathematician's reading) give the
same signature as seeds born in the melt. Nothing in a size series can distinguish nucleation from seeded growth;
only a radius series or the start-replacement test can. Finding 5 (the Declaration at kmax = 64 against periods 154
and 182) is a statistics defect I missed and endorse. Finding 6 (CPU rows with no files behind them) likewise.

**Optimization, finding 3 (basin against survival, r = −0.57).** Disagree that it is the number to report. It has the
same degeneracy as r = 0.79: ten points at survival 100 % with basins from 0.01 % to 43 %, five near 0 % with basins
from 4 % to 99.7 %. A correlation over points that are theorems is not evidence, whichever axis carries the basin.
The hypothesis's own quantity failing is better shown per dictionary: the winner's basin against the loser's, in the
five dictionaries where they differ (0.26 against 99.7, 2.8 against 92.9, 18.6 against 27.7, 4.8 against 15.8,
1.4 against the rest), which is what replicators-v2.md already prints. Finding 4 (the eight-step closure gives
r = 0.73, and the 11-cycle is 100 % closed at eight steps yet dies): agree, and it is the strongest argument in the
panel that the one-step index is a rate, not a property; it joins the information theorist's finding 13 and the
professor's finding 6 in pointing at the same experiment (§4, item B). Finding 6 (a frame map for Swarm F as the
missing control): agree; the ALife reviewer's §2.3 shows why: with no closed type present, the 3-cycle re-forms in
phase and holds 62–66 % of the frame, so "the melt" is a transient that re-crystallises when nothing else takes it.
That changes the vocabulary: the melt is not a phase.

**Professor, finding 6 (p*, the melting threshold per type).** Agree; it is my round-1 §6 item 3 and the
mathematician's "whole-turn closure" with the swap rate as the axis. One consolidated specification is in §4, item B.
Disagree with the professor's "say no faster than 1.6×" for the size dependence: the right sentence is "size-free
below the plateau" (Brotli 12) and "size-free to turn 100, 256² and 512² equal to turn 300, a lag of 2–3 points at
512² after that" (Brotli 13, §2.4). Agree, and I change my own position (§2.3), that Physical Review E should be
dropped and the voting model's physics confined to a paragraph.

**Information, finding 5 (infodyn.mjs and entropy-curves.mjs also at one pass).** Agree, and it widens my round-1
§2.2: four scripts at one pass (closure, droplets, infodyn, entropy-curves), three at three (frame, replicators,
ablation), no results file says which. Findings 16–17 (the "rest" is a residual, not a bound, and "non-local" is
mostly within-cell): agree, and finding 19's point that k = 3 cannot represent a period-4 medium is one I should have
made. Finding 8 (Poisson error on H₂ near the resolution): agree; a statistics item. Finding 14 (Fisher 1/286):
I would still not print it; the rows are not exchangeable, ten being theorems.

**ALife, §2.4 ("the KM medians say when").** Disagree: t₅₀ is a plateau crossing (final shares 51–62 %), and "when"
is the share curve. §2.3 (the conditional rule, "where a closed type exists at detectable share it wins the mixed
region; otherwise the open type re-forms in phase"): agree, and it is the sentence the paper should carry. §4.3 (BFF's
replicators are built, not listed, by the 2⁻¹⁰⁰ argument): agree with the arithmetic; the panel's physicist adds only
that the same argument makes the BFF emergence rate the one number a referee will ask for. §7.5 (the 80–85 % heredity
is conditional on the slot) and §8 (two definitions of log₂ up/down, 11.47 against 7.48): statistics items, both
adopted in §4.

## 2. What the others' notes make me revise

1. **The pass mismatch is broader than I wrote.** Four scripts at one pass, not two (information, finding 5). My
   ranking of corrections (§3) changes accordingly: it is a pipeline defect, not a droplet defect.
2. **"Seeded growth from the melt" was too strong in the other direction.** I replaced "nucleation" by "seeded growth"
   in round 1; the mathematician's finding 8 and the ALife reviewer's Swarm F point show that the seeds' origin is
   open and that the melt itself is transient. The neutral sentence until the matched block is run: "mixing with
   partial settling dissolves the open type's domains; where a closed type is present it fills the dissolved
   region; where none is, the open type re-forms in phase."
3. **Drop PRE and the coarsening programme.** The professor is right that the voting model is not the author's
   result. My round-1 §6 item 5 (1024² and 2048² turn-salted series) becomes optional. What stays is one paragraph:
   arrest at (½, 1) with ξ_c converged to 12.6 cells, slow coarsening at (0.2, ½) with z ≈ 0.26, annealed coarsening
   with z = 0.34–0.42 at 512²; no exponent claimed. The phase-field observable for MSR (my item 6) becomes optional
   too, because the recommendation is to print no MSR length at all.
4. **Brotli 13 has a real, small, late size effect** (new read, §0 of this note's data): mean fixed-point share
   at turns 100 / 300 / 600 / 1,999 is 14.5 / 41.8 / 58.6 / 65.2 % at 128², 13.5 / 36.8 / 53.3 / 63.5 % at 256²,
   13.3 / 36.7 / 50.8 / 63.1 % at 512². Establishment is size-free; 128² is faster from turn 200 on (its blocks are
   16 cells wide, so the strongly settled rows are nearer every point); 512² lags 256² by 2–3 points from turn 400 at
   equal plateau. The t₅₀ ratio 505 → 584 is therefore not pure artefact for Brotli 13, and it fits the
   mathematician's picture of domains from the strongly settled rows creeping into the melt over a distance that
   scales with L. I retract "artefact" for Brotli 13 and keep it for Brotli 12.
5. **The 2 × 2 table has sixteen rows, not fifteen.** Swarm F's 3-cycle (ALife §2.2, optimization check 4,
   computation finding 3, all three ran it): closure 34 %, dies at median ≤ ½, holds at 1. Adopt.

## 3. The panel's three most important corrections, ranked

1. **Settling passes are not uniform across the pipeline, and the mechanism's two halves sit on different sides
   of the split.** closure.mjs, droplets.mjs, infodyn.mjs and entropy-curves.mjs run one pass; frame-mechanism.mjs,
   replicators.mjs and ablation.mjs run three; no results file states it. The droplet tracks (fixed point dies in
   40–200 turns at every partial-settling point) and the frame maps (fixed point at 100 % at the same (swap, median))
   are therefore not in contradiction and not in agreement; they are not comparable. Everything in mechanism.md §2–3,
   the r = 0.79 table, the infodyn table and the entropy curves must be rerun at three passes or relabelled as a
   different medium. Until then the central sentence has a proof (Lemma 1, the proposition), a measured melting, and
   no measured filling.
2. **The statistics of the mechanism and the takeover are the wrong statistics.** r = 0.79 over 15 rows of which
   10 are theorems, with a one-step index whose eight-step variant reverses one verdict (optimization finding 4);
   t₅₀ read on a plateau of 51–67 % and turned into a size exponent (computation finding 2, my §0.4); droplet tables
   at n = 1; two definitions of one selection statistic (ALife §8); the Declaration's "no takeover" from a detector
   that cannot see its periods (computation finding 5); processor rows quoted from overwritten logs. Replace them
   with: the 2 × 2 count with the two 95 % exceptions and Swarm F; the whole-turn melting threshold p*(type, median);
   share curves with the asymptote and the time to 25 % and 40 % by size; 5 seeds on every droplet cell; one
   definition per statistic; kmax = 200 for the Declaration; files behind every number.
3. **The index and the drafts contradict the results.** results/README.md still asserts "no fixed points", "hash
   pinning", t^⅓, "takeover at front speed", "q = 8 clock"; six results files carry the raw ξ with no superseded
   banner; two replicator figures encode the withdrawn basin^−½ relation; every draft carries every retracted
   sentence (all seven notes list the lines). Physics additions to that list: finite-size.md point 1 is wrong at
   (0.2, ½), where the quenched medium coarsens at z ≈ 0.26; point 3's "larger lattices avoid" the absorbing orbit is
   unshown; ablation-v2's "10–46 cells" must not be printed as a property of the system (the professor says the same).

## 4. Consolidated minimum work for my role (physics and statistics), deduplicated

Already demanded by others and not repeated here: the Declaration rerun at kmax = 200 (computation); closure and
whole-lattice runs for every named dictionary (optimization a); the Swarm F and gray3c frame maps (optimization c);
exact fixed points of Brotli 12 and 13 and the designs (professor 2); the imp mutant census (ALife, information);
seeds for dose-response and infodyn, with the identity control, k = 4 and the passes stated (information 5);
the rewrite and the README (everyone). Speeds: MS− 2.3 × 10⁶ cell-turns/s per core; the decoder about 2.5 × 10⁵,
so a 128² × 2,000-turn decoder run is about 130 s.

**A. The matched three-pass droplet block.** One batch, one script (`droplets.mjs` with `passes` and `seed` as
parameters; the start's phase assignment and the disc's centre take the seed; the hashing stays quenched, salt 0, as
on the frame), rotating order, `nbr = 1`, `passes = 3`, 128², 2,000 turns, the `track` kept every 20 turns.
- Dictionaries: Brotli 12 and Brotli 13 in full (3 types each); Swarm F (one open type, no closed competitor) and
  ca-gray3c (closed types only) with the whole-lattice runs and one ordered pair each.
- Settings: swap ∈ {0, 0.1, 0.25, 0.5} × median ∈ {0.25, 0.5, 1}; swap 0 is the Lemma 2 control.
- Configurations per dictionary and setting: every ordered pair of types as a disc of radius 16, coherent and random
  phases (12 for three types); the whole-lattice random-phase domain of each type (3); the fixed point planted in a
  pre-melted sea (the open type run alone in random phases for 100 turns first), coherent (1).
- Seeds: 5 per cell.
- Count: Brotli 12 and 13: 2 × 12 settings × 16 configurations × 5 seeds = 1,920 runs; Swarm F and gray3c: 2 × 12 ×
  5 × 5 = 600. About 2,520 runs, 90 CPU-h, 3.5 h on 28 cores. Halve it by dropping swap 0.25 if needed.
- Also in the same batch, the mathematician's start-replacement test on the frame (every fixed-point-basin cell of
  the random start replaced by a cycle-basin cell at turn 0; Brotli 12, 256², 2,000 turns, 20 seeds, 3 CPU-h), and
  the 256² check of the one Brotli 12 cell (0.1, 0.5), 3 seeds, to rule out a 128² absorbing-orbit effect.
- What decides it. (a) If the fixed-point disc at (0.1–0.5, 0.25–0.5) grows to fill the dissolved sea at three
  passes, as the frame does, "closed types fill the melt" stands and the three-pass medium is the reason the one-pass
  tracks disagreed. (b) If it still dies, the frame's fixed point is seeded by the start or by the strongly settled
  rows (the mathematician), and the start-replacement run says which: no takeover without the start's basin cells
  means the medium does not create entries; takeover anyway means it does. (c) The pre-melted sea separates "the
  melt is where the fixed point is born" from "the fixed point must exist before the melt". (d) Swarm F's
  whole-lattice runs at three passes must re-form the cycle in phase (ALife §2.3) for the conditional rule to hold.
- Statistics: share at turn 2,000 as mean with a bootstrap 95 % interval over the 5 seeds, and the track as a
  curve; "holds / shrinks / vanishes" is replaced by the number.

**B. The radius series (nucleation or seeded growth).** Same script, `R ∈ {1, 2, 4, 8, 16, 32}`, fixed point in
the 3-cycle, coherent and random phases, Brotli 12 and 13, at (0.1, 0.5), (0.5, 0.5) and (0.1, 1), three passes,
5 seeds, 1,000 turns: 2 × 6 × 2 × 3 × 5 = 360 runs, 6.5 CPU-h. Decides: a critical radius R* (growth above, death
below) licenses "nucleation"; growth from R = 1 at every setting where it grows at all means no barrier, and the word
goes. The measured dR/dt at R = 32 gives the wall speed v, and with R* the line tension, which is the selection
coefficient in physical units I asked for in the first panel (E6b).

**C. The whole-turn melting threshold p\*(type, median).** One specification merging the professor's 6, the
mathematician's 7, the information theorist's 13 and my round-1 item 3. `closure.mjs` with the medium switched on: a
32² patch of one type in random phases, three passes, one whole turn (exchange, settling, f) repeated for 200 turns;
swap ∈ {0.01, 0.02, 0.05, 0.1, 0.2, 0.5} × median ∈ {0, 0.25, 0.5, 1}; the 6 generic cycles (Brotli 12's 3-cycle,
Brotli 13's 9- and 18-cycles, the 5-to-12's 5- and 11-cycles, Swarm F's 3-cycle) and, as controls, two fixed points
and two Gray cycles; 10 seeds; output the share on the type at turns 1, 2, 4, 8, 200 (the return-time curve of
information finding 13 and the eight-step column of optimization finding 4 fall out of the same runs). 10 types × 24
settings × 10 seeds × 32² × 200 turns: about 2 CPU-h. Decides: whether each open type has a threshold p* above which
it dissolves and whether 1 − C(one step) orders the six p* values; the 95 % pair is the test. If it does, the
closure index becomes a quantity; if not, it stays a sufficient condition and the paper says so.

**D. Statistics, no CPU.** Replace t₅₀ by the share curves with the asymptote by size and the time to 25 % and 40 %
(computation finding 2's table extended with Brotli 13's lag, §2.4); report the 2 × 2 count with 16 rows and the two
95 % exceptions, with the (r, steps) choice stated and the eight-step column beside it; print r nowhere; one
definition of log₂ up/down (the per-mutant one, 7.48) and the slot condition on BFF's 80–85 %; Poisson intervals on
every H₂ within 2 bits of the resolution; n stated on every table cell; "never" counted as censored, as now.

**E. Physics corrections, no CPU.** finite-size.md: (½, 1) quenched arrests (z = 0.00 from turn 400, ξ_c 12.6
converged at 1024²); (0.2, ½) quenched coarsens at z ≈ 0.26 and is not converged; turn-salted z = 0.34–0.42 at
512² over 1.2 decades, exponent not claimed; MSR lengths not printed; the absorbing orbit at 64²–128² stated as an
orbit, with "later at 256²" in place of "avoided". ablation-v2.md: the connected length defined as the C(1)/e
crossing, said in one line, and every MSR row marked "not size-converged". Vocabulary: "melt" defined once as the
dissolution of a domain into transients, with the ALife reviewer's conditional rule; "nucleation", "coarsening" of
the takeover and "front" removed until B is run; "crossover" kept as in DEFINITION.md §5.

**F. The salt-by-position control at 10 seeds**, if the sentence "deterministic freezing, not disorder pinning"
stays: MS− at (½, 1), salt modes 0 and 2, 256², 1,000 turns, 10 seeds each: 20 runs, 0.2 CPU-h. My first-panel
two-seed result is the only evidence for it.

**Optional, not minimum:** 1024² × 3 seeds and 2048² × 1 seed turn-salted to 8,000 turns for the exponent
(14 CPU-h); the Z₃ phase-field correlation for MSR (one day of code, 12 CPU-h), only if an MSR length is ever
printed.

Total for my role: about 100 CPU-h (A dominates; 4 h on 28 cores) and two working days of analysis and text,
after which the central sentence is either measured at the frame's own medium or replaced by the conditional rule.
