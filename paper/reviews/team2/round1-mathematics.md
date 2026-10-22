# Round 1 (second panel) — mathematics: the formal automaton, the proofs, the random-mapping null, the mechanism

2026-10-22. Continuity with my first-panel notes (../team/round1-, round2-, round3-mathematics.md): I asked there for
an exact fixed-point count, a decay curve against a random-mapping null, shuffle distributions, a precise global map,
and a theorem behind the Gray cycles. All five were done. This note checks them.

## 0. What I checked myself, and what I took on trust

Checked (scripts in my scratchpad; outputs under `paper/data/review2/`, nothing else written outside this folder):

1. `node test/lemma.test.mjs`: passes (Lemma 1 on the module, gradient frame, both mixing rules, both salts).
2. **The Gray construction on `ca-gray3c`** with `decode36.mjs` (`gray3c-check.json`): all 24 states map S_k → S_{k+1};
   the pointer lemma holds for 12,000 random tails (500 per state) after either a 46- or a 48-bit prefix; the closure
   proposition holds for 20,000 random-phase crossovers per type at r = 0.25 and at r = 0.5 and for 20,000 three-way
   bitwise majorities per type: 100 % in every case. The decoder consumes 42 bits after the 6 skipped ones in every
   state (see finding 3).
3. **The exact fixed-point count of Swarm F** (`exact-h1-h3232.json`; I asked for two headers but the script ran all
   4,096, 166 s on 2 workers): 68,964,123 fixed points, 15,693 families, free-byte histogram 15,643 / 4,608 / 1,835,008 /
   67,108,864, 64,163 stored points verified, 0 bad. Identical to map-spine.md §1.
4. **The H2 decay of Swarm F** on 2^16 uniform cells with `map-lib.mjs`'s `fastF` (`swarm-f-decay-2e16.json`):
   16.28 / 7.47 / 3.49 / 1.80 / 1.585 bits at k = 1 / 4 / 8 / 16 / 64, against 16.50 / 7.50 / 3.50 / 1.80 / 1.58 from 10⁶
   (the 0.2 bits at k = 1 is sample scatter; 1.585 = log₂ 3).
5. **The closure index for Brotli 12** (`closure.mjs`, 4,096 samples, `closure-ca-brotli-12.md`): 3-cycle 38 %,
   fixed points 100 % and 100 % at r = 0.25, as the table says; also 66 % at r = 0.05 and a majority closure of 76 %.
6. **The Flajolet–Odlyzko constants** by direct computation: ½ ln 2^128 = 44.36 cycles, cyclic nodes 2^64.33,
   rho 2^64.33, 1 − τ_k against 2/k, and the row 127.0, 126.4, 125.7, 124.8, 123.9, 123.0, 122.0, 120.0 from
   128 − log₂(k+1). All as printed in map-spine.md §3.
7. **The Kaplan–Meier median 731** (Brotli 12, frame, 128², 20 seeds) from the raw rows in
   `data/replicators-v2/ca-brotli-12-page-n128-t2000.json`: the sorted t50 are 235 … 719 731 743 … 1336, all 20 seeds
   reach 50 %, so the KM median is the 10th value, 731. Correct.
8. The droplet time series (`data/droplets/droplets-ca-brotli-12-n128-t400.json`, field `track`) and the frame time
   series (`data/frame-mechanism/frame-ca-brotli-12-n256-t2000-seed{1,2}.json`, 42 snapshots), read for finding 6.
9. Look-and-say's bound at b = 16: 128 / (2(1 − 1/16)) = 68.27, equal to the measured 68.27 ± 0.02.

Taken on trust: the 2-cycle class search and its node estimates, the 60 shuffles' exact counts, the BFF reproduction
against cubff's log, the replicase ablation's 1,150 runs, the information-dynamics table, the connected correlation
lengths and the finite-size series.

## 1. DEFINITION.md: the definition and Lemmas 1–3

**Finding 1 (the global map, §2).** Correct and now matches the code. Two details to add. (a) The corollary of Lemma 1
("a fixed point of every F_t") needs "with mutation off": Mut is part of F_t in §2 and does not fix a uniform
configuration. (b) Lemma 2's range "k·r + 1 cells" is right for *which cells change*, and I checked why: every
mixing decision of a turn is read from the snapshot (`lattice.wat` l.53–57, 143–145), so a pair whose snapshot bits
agree never exchanges, and a cell two steps inside a uniform domain is untouched by all four phases. But a bit's
*value* can travel two cells in one turn (0 → 1 in LR0, then 1 → 2 in LR1 when c⁰₁ ≠ c⁰₂). Any statement of the
automaton's neighbourhood radius must therefore say 2 per axis for mixing, plus k·r for settling; the lemma as
stated is fine.

**Finding 2 (Lemma 3).** The proof is right: the stopped prefix (U₁ … U_τ) of fair bits has probability 2^−τ, so its
entropy is E[τ] exactly; calling it "Wald's identity" is loose but not wrong. The remark under it is wrong as printed:
"look-and-say's bound, about 128 · 2(1 − 1/b) bits read in base b" gives 240 bits at b = 16. The correct expression is
128 / (2(1 − 1/b)), which is what results/look-and-say.md uses and which matches the measurement to 0.01 bit at
b = 16 (check 9). Fix the formula in DEFINITION.md l.105–106.

## 2. DEFINITION.md §4: the Gray construction and the closure proposition

**Finding 3 (the prefix is 48 bits, not 46).** The pointer lemma says a 46-bit prefix with 28 command bits and a tail
in {0,1}^82. From `decode36.mjs`, the first copy ("10 at distance 16", explicit distance) costs 2 + 5 + 7 + 2 = 16
bits, the second ("6 at the ring's last distance", short code 0) costs 2 + 5 + 5 + 2 = 14 bits: 30 command bits,
because the second copy also has d > opos and so reads a 2-bit transform code. Measured: every one of the 24 states
consumes 42 bits after the 6 skipped ones (check 2), so the fixed prefix is 48 bits (6 bytes, which is why "the six
command bytes are printable") and the free tail is 80 bits. The lemma also *held* for a 46-bit prefix in my test, but
only because this design's window bytes contain no letters, so the second transform code is inert; for a design whose
states contain letters a 46-bit statement would be false. State 48 / 30 / 80 at l.115–116 and l.147.

**Finding 4 (the theorem and the proposition are correct; the proposition is stronger than stated).** With the
prefix fixed, the proof of f(S_k) = S_{k+1} is the pointer lemma applied eight times; the eight windows
[h_k − 16, h_k) are the eight consecutive 16-byte slots [H₀ − 16, H₀ + 112), so "disjoint" is automatic and can be
dropped as a hypothesis. The closure proof is right and proves more than it claims: the set
T = {P(h_k)·τ : k, τ} is closed under *every* bitwise function of any number of states of a type (crossover, 3-way
majority, the 9-cell majority of the 3 × 3 settling, the 5-cell cross), and f(T) is the type. So the proposition
covers settling at any radius, not only "a majority of three". Verified 100 % on 120,000 crossovers and 60,000
majorities (check 2). Two things it does not give, both worth saying in the paper: (i) nothing about a type's
contact with cells outside T (the melt, or another type); (ii) my cross-type run shows a design rule the author has
not stated. Types B and C of `ca-gray3c` have H₀ = 2304 and 3328, one header bit apart, and their crossovers never
leave B ∪ C (10,000 of 10,000 at r = 0.25, after 1 and after 8 steps: 75 % / 25 %). Type A (H₀ = 128) differs from
B in three header bits, and A × B makes a stranger 57 % of the time after one step (all back on A, B or C after
8 steps). **Corollary for the author:** a set of species whose H₀ form a Gray code over the header bits above bit 6
is *mutually* closed, and no interface between them can melt. That is a constructive answer to the editors' "conditions
under which a design has no strangers at interfaces", stronger than the within-type proposition, and costs one line.

## 3. The random-mapping null (map-spine.md §3)

**Finding 5 (the comparison is sound; three remarks).** Every Flajolet–Odlyzko constant quoted is right (check 6).
The law "H2(f^k(U)) ≈ log₂ n − log₂(k+1)" is the correct *collision-entropy* statement for the k-th iterate of a
uniform random map: two independent walks coincide at equal times with probability ≈ (k+1)/n (one chance per step,
including the start). The image-size statement 1 − τ_k ≈ 2/k is a different quantity; the paper has both and does not
confuse them. The uniform null matched at n = 2^(H2+1) = 185,734 follows the law to 0.05 bits up to k = 64
(predicted 15.92, 15.18, 14.33, 13.42, 12.46, 11.48 against the table's 15.91, 15.17, 14.30, 13.38, 12.45, 11.54),
departing only at k = 256 (9.50 predicted, 9.77 measured), where k is no longer small against √n = 431. The P-random
map's mean tails of 263–351 steps are what the collision-time scale gives for a map with that one-step law,
√(π/2) · 2^(H2/2) ≈ 377. So both nulls behave as theory says, and the decoder's mean tail of 9.6 is a genuine
thirty-fold departure. I correct my own round 2, which quoted the loss as log₂(k/2): that is the image-size form; in
H2 the loss is log₂(k+1), as the author has it. Remarks: (a) `hash:93`'s idempotence is exact by construction (the
kept 93 bits are unchanged and the rest is a function of them), so say "by construction", not "checked on 10⁵
samples"; (b) the n = 2^20 graphs' mean tails (335, 363, 471) all sit below the FO expectation √(πn/8) = 642. The
per-realisation mean has a wide law and three seeds prove nothing, but the paper should print the expectation beside
each measured tail so a reader can see this; (c) the matched-n null is a device (a random map on 2^17.5 points is not
a map on 2^128 cells); the P-random map is the null that carries the argument, and the text should lead with it.

**Finding 6 (the exact census).** Reproduced in full (check 3). The text's reading is right: the raw total is set by
four families of 2^24, and the counts to rank are families and isolated points. One remark the paper should make
explicit, because it connects the two arms (see finding 10): a "family" is a set of fixed points that differ only in
bytes the decoder reads at the very moment it writes them. Those bytes are copied verbatim without being used, which
is exactly the BFF replicators' heredity mechanism in miniature; Keimli's largest family has 3 such bytes, BFF's
replicators 48–54. For 2-cycles the "class" statement is honest and the lower bound 51 is right.

## 4. The central result: is "the medium, not the basin" now explained?

**Finding 7 (what the closure index explains: melting).** Closed types hold random-phase domains at every setting;
the three clearly open types (38 %, 11 %, 6 %) lose theirs under any partial settling. That part is sound and I
confirmed the index (check 5). But the summary statistic is not evidence. Of the 15 "types" in
closure-vs-survival.md, 10 are closed by theorem (7 Gray cycles) or trivially (3 fixed points) and survive at 100 %;
they are one fact repeated ten times. The empirical content is five types from two dictionaries, and two of those
(the 5-to-12 design's 5- and 11-cycles, closure 95 %) die under partial settling just as the 38 % one does. So the
index is in effect binary with its threshold at 100 %, and "r = 0.79" should go. What the data actually show is a
rate competition: a 5 % leak per turn compounds to 0.6 % survival in 100 turns unless settling repairs it, and the
Brotli 12 3-cycle (38 %) does survive at median 1 (99 %). The right quantity is the closure of the *whole turn*
(mixing, settling, f) as a function of (swap, median), which `closure.mjs` can measure by switching the medium on;
I expect a threshold line in that plane where domains start to survive. Also: the one case where a *cycle* with a
smaller basin wins (the 5-to-12 design's 12-cycle, 18.6 %, replicators-v2.md) is not among the types the closure
table analyses (it takes the 5-cycle, the 11-cycle and a fixed point), so the claim is untested there.

**Finding 8 (what it does not explain: the winner).** mechanism.md §4 says "closed types nucleate in the melt and
fill it". The data do not show that. From the droplet tracks (`track` fields, 128², 400 turns, Brotli 12): the
fixed-point droplet in the coherent 3-cycle sea falls 5 → 2 → 1 → 0 % by turn 120 at (swap 0.1, median 0.5) while
the sea is still 80 % coherent cycle; the sea then melts to 84 % "other" by turn 400 and **no fixed point forms from
the melt** in 400 turns at any of (0.1, 0.25), (0.1, 0.5), (0.25, 0.5) or (0.5, 0.5): the final fixed-point share is
0 % in all four. On the frame (seed 1 and 2, blocks of 32²) the same parameter region goes 0 % fixed point at turn 25,
10–50 % at turn 100, 100 % by turn 150–250. The seeds of the fixed point on the frame are therefore not born in the
melt: they are the random start's own cells in its basin (0.26 % ≈ 2.7 per block) and the domains that form in the
strongly settled rows while the cycle is still coherent there (block r5c2: 21 % at turn 50 with the cycle at 61 %),
which then grow into the melt. That is consistent with replicators-v2's "every major type appears at once" and with
the first panel's "no late first appearance", and it is a different mechanism from nucleation. It is also decidable
cheaply: (i) a random start with every cell in the fixed point's basin replaced by a cycle-basin cell at turn 0, 20
seeds, 256², 2,000 turns, frame: if the fixed point still wins, the melt nucleates it; if not, the seeds come from the
start; (ii) a fixed-point droplet planted in a *pre-melted* sea (not a coherent one) at (0.1, 0.5): does it grow? About
40 runs, 1–2 CPU-hours. Until this is run, the sentence for the paper is: "mixing with partial settling melts the open
type; the closed type's domains, seeded by the start, grow into the melt", and the word "nucleation" should not be used.

**Finding 9 (takeover against size).** The ratio 1.35–1.6 for a fourfold side (replicators-v2.md) is between a single
front (4×) and homogeneous nucleation-and-growth (1×); it fits a few seeds per lattice growing at a fixed speed. The
Brotli 12 intervals [560, 912] and [688, 1445] overlap, so only the Brotli 13 ratio (1.57, intervals disjoint) is
established. Say "weakly size-dependent" and give the intervals.

## 5. The processor arm

**Finding 10.** From the dynamics side the four pieces do make a result, but only once they are stated as one
quantity. In BFF, g(R|X) = (R | mirror R) for 256 of 256 partners: the pair map is *constant* on the slice {R} × Σ,
so the fixed point absorbs any partner in one step. In Keimli the winning fixed point attracts 0.26 % of random cells
and absorbs nothing. Both are "fixed points", but the fixed-point *sets* differ in dimension: BFF's replicator sits in
a family with 48–54 free bytes (every non-instruction byte, inherited 100 %), Keimli's in families with 0–3 free bytes
(finding 6), Redcode's imp with none (a memory of identical instructions). The replicase ablation says the same in a
constructed rule (verbatim unread tape: heredity 1.00; derived: 0.00). The statement to make, and to measure in every
system, is: *the heritable information of a replicator is log₂ of the size of the fixed-point family it belongs to,
which is the number of bytes the map copies without reading.* That is a definition plus a census, not a programme, and
the BFF numbers already fit it (80–85 % of random single-byte mutants breed true, against 48–54 of 64 positions being
free). What is missing is the same census for the imp and for the 6502's 16-instruction type, and seeds beyond 1 for
dose-response and infodyn, which are supporting tables rather than the claim. The per-bit information dynamics show
processors doing *less* non-local rewriting than the decoder; that undercuts "computation" as the distinguishing
word and supports "copying of unread bytes" as the word.

## 6. The questions, briefly

1. **Settled:** "no fixed points" (exact); the image bound (withdrawn, Lemma 3 right); the global map (with findings 1–2);
   Lemma 1 (tested); the Gray theorem and closure (proved and checked, with finding 3's numbers); the random-map null
   (finding 5); shuffles; censored medians (check 7); provenance; connected correlation lengths. **Partly:** the
   mechanism (melting yes, the winner no: findings 7–8); the closure statistic; 2-cycles (class only); finite size
   with the decoder (not converged, said so); the processor arm (finding 10, seed 1). **Not:** the drafts and docs
   (finding 11); the transitivity test of the pairwise winner relation; conditions for stray attractors in designs
   (admitted open; the mutual-closure corollary of finding 4 covers interfaces, not strays).
2. Explained in its first half (melting), not its second (who grows). The closure index is the right *kind* of
   quantity but should be the whole-turn closure, and r = 0.79 is not evidence. The proof in §4 is correct, with the
   48-bit correction, and generalises as in finding 4.
3. **Retractions in `results/`: complete.** In the drafts and docs: not started. Still present: INTRODUCTION.md
   l.50–56 ("reads every input bit once and never reads its own output; no loop", "less than 94 bits", "no fixed
   points"), l.115 (quenched disorder), l.125 (entropy pump); INTRODUCTION_MOTIVATION.md l.70–77 (same), l.87 (clock
   model), l.149 (t^⅓), l.164 (entropy pump); MOTIVATION.md l.16, 38–43, 70; RESULTS_REPLICATORS.md l.26 ("there is no
   fixed point") and l.87–89 ("at the pace of a front … about 1.5 times longer than at 128²", the censored number);
   results/README.md l.43 and 89 (t^⅓), l.73 ("q = 8 clock model") and the H4 paragraph ("no fixed points");
   docs/lattice.md l.105 and src/lattice/band.js l.11 still describe the fixed swap order (first panel, defect 9).
   results/design-gray3.md l.85, 99, 122 ("clock model") and the raw ξ tables of ablation-main/-scan/-structure carry
   no superseded banner, though README's index now points to the corrected files.
4. Yes, if written as finding 10's one quantity; otherwise it is three tables and an analogy.
5. Thesis unchanged from the first panel's verdict, and now better supported: a dictionary decoder as a CA rule whose
   attractors are exactly countable, designable and provably closed, in a medium that melts open types. Venue:
   Artificial Life or Complex Systems; Natural Computing becomes possible with DEFINITION.md fixed, since it now holds
   three correct theorems. The second paper's claim is finding 10.
6. For paper 1: the two mechanism runs of finding 8 (half a day, 1–2 CPU-h); whole-turn closure over the (swap,
   median) plane for the five generic cycles plus the 12-cycle (half a day, ~1 CPU-h); DEFINITION.md corrections
   (findings 1–4, an hour); README/docs/band.js lines (an hour); the drafts rewritten on the two claims tables (2
   days). About 4 days and under 5 CPU-hours. For paper 2: the family census of the imp and the 6502 type, and 5 seeds
   for dose-response and infodyn (2–3 days, ~20 CPU-h).
7. The errors found: the 46/28/82 bit counts (finding 3); the look-and-say formula in Lemma 3's remark (finding 2);
   "nucleate in the melt" against the droplet tracks (finding 8); r = 0.79 as a statistic (finding 7). Numbers that
   check: 68,964,123 and its histogram; the decay curve; the closure 38/100/100; every FO constant; the KM median 731;
   the 68.27-bit look-and-say bound.
