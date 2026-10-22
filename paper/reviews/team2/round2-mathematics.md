# Round 2 (second panel) — mathematics

2026-10-22. After reading the other six round-1 notes. New checks of my own are in §0; outputs under
`paper/data/review2/` (`las-digits.json`, `droplet-passes-brotli12.json`, `exact-gray3c-K1.json`); nothing else written.

## 0. Three new checks, prompted by the others

1. **Look-and-say digits (information, round1-information.md §0.4).** With the `lasRef` semantics of
   `test/mix.test.mjs` l.19–27 on 2 × 10⁵ random cells: the digits inside the described runs are 17.07 / 42.56 / 97.94
   (b = 16 / 4 / 2) = 68.27 / 85.13 / 97.94 bits, the table's column; the digits the output *depends on*, which include
   the one that terminates the last described run, are 18.07 / 43.56 / 98.94 = **72.27 / 87.13 / 98.94 bits**. The
   information theorist's 72.27 / 87.11 / 98.92 is right to within sampling.
2. **The fixed-point droplet at three settling passes (physics §2.2).** A reduced `droplets.mjs` with `passes: 3`
   (Brotli 12, 128², 400 turns, R = 16, one realisation each, shares every 40 turns, cycle / fixed point / other in %):
   - fixed point in the coherent 3-cycle sea, (swap 0.1, median 0.5): 95/5/0 → 87/11/3 (t 200) → **72/24/4** (t 400);
     random-phase sea: → 68/28/4; (0.5, 0.5): → **17/77/6**; (0.1, 0.25): the sea melts, 1/0/99, as at one pass.
   - 3-cycle droplet in the fixed-point sea, (0.1, 0.5): 0/100/0 by turn 120.
   - the whole lattice as a random-phase 3-cycle, no droplet, (0.1, 0.5): **97/2/1** at turn 400 (one pass: 1/0/99).
   - the same four runs at one pass reproduce the stored tracks (fixed point 0 % by turn 120, sea 84 % melt).
3. **Exact fixed points of `ca-gray3c`** (professor §2.7, item 2 of his list): `map-exact.mjs paper/data/design/ca-gray3c.txt
   1 4` (positional arguments; a `dict=` key is silently ignored, which is also why my round-1 "headers=1,3232" ran all
   4,096): **2,544 fixed points in 249 families**, 240 isolated and 9 one-free-byte families, all 2,190 stored points
   verified with decode36 and the wasm, 102 s on 4 workers. My first-panel stray `UUUU@@@@@@@@@@@@` is in the list. So
   "no stray cycle" (design-gray3.md l.47) is false for period 1 by 240 isolated strays, and the count is now exact.

## 1. Agreements and disagreements, by note and number

**Physics §2.2 (one pass against three): agree, and it overturns the reading in my finding 8.** `droplets.mjs` l.19,
`closure.mjs` l.18, `heredity.mjs` l.19, `infodyn.mjs` l.20 and `entropy-curves.mjs` l.45 all set `passes: 1`;
`frame-mechanism.mjs` l.17 and `replicators.mjs` l.20 use 3, the harness default (`ca-harness.mjs` l.16). I compared
one-pass droplets with three-pass frame blocks and concluded that the fixed point's seeds must come from the random
start. That comparison was invalid. Check 2 shows what three passes do at the frame's own parameters: **there is no
melt**. The fixed-point droplet grows into the *coherent* cycle sea at a steady wall speed (area 5 → 24 % at swap 0.1,
R from 16 to about 35 cells, v ≈ 0.05 cells/turn; 5 → 77 % at swap 0.5), "other" stays at 2–10 % (a thin wall band,
2πR cells wide), the cycle droplet in the fixed-point sea is erased, and a random-phase cycle sea is repaired to 97 %
instead of melting. At three passes the mechanism is **invasion of the open cycle by the closed fixed point through a
moving domain wall**, with the wall speed set by the exchange rate; melting is the one-pass phenomenon and occurs at
three passes only at median 0.25. This is the first panel's wall picture (my round 2 (c)6; the ALife reviewer's
"competition at interfaces") with numbers, and it fits the computation reviewer's §2 table (t₂₅ and t₄₀ size-independent:
seeds from the start plus a constant wall speed give a size-free takeover, which is Kolmogorov–Johnson–Mehl–Avrami
with site saturation, not nucleation at a rate). I also note that 2 % fixed point appears inside the random-phase cycle
sea with nothing planted, presumably at the phase walls: that is where a rate could be measured.

**Physics §2.3, computation §2, professor §1 ("partly") on 1.35–1.6× and the plateau: agree; my finding 9 is withdrawn**
in favour of "size-independent at every share below the plateau; t₅₀ sits on the plateau". The physicist's "seeded growth
from the melt" should now read "seeded growth into the cycle" at three passes.

**Information §0.4 and §2.9 (Lemma 3, one more digit): agree, confirmed (check 1).** My round-1 check 9 verified the
run-count formula against the run-count measurement; both are one digit short of the quantity Lemma 3 bounds. The
inverted formula in DEFINITION.md l.105 stays wrong; the corrected closed form is 128/(2(1 − 1/b)) + log₂ b, which gives
72.27 at b = 16 and 87.1 at b = 4, equal to check 1. Information §1.6 (a collision figure read as a Shannon loss; H(f(U))
is bracketed in [16.6, 87.5]) and §5.16–17 (the residual is not a bound; the system is deterministic, so
H(next | 3 × 3 neighbourhood, t mod 4) = 0 and the residual is the other 125 bits of the same cell): agree on the
mathematics of both. Information §4.12 says the pointer lemma needs the windows disjoint; it does not, the eight windows
are the eight consecutive slots [H₀ − 16, H₀ + 112) (my round 1, finding 4).

**Optimization §2 finding 4 (eight-step closure makes the 11-cycle 100 % closed yet it dies; mechanism.md l.56 wrong for
the 11-cycle): agree, and I add why the eight-step figure is the wrong quantity rather than a mere sensitivity.**
Eight-step closure asks whether a crossover child *eventually* returns, which is basin membership; the medium disturbs
every turn, so what matters is return within one turn against the disturbance interval. That is the information
theorist's return-time reframing (§4.13), the professor's p* (§2.6) and my round-1 finding 7 in three vocabularies, and
I agree they are one demand. Optimization finding 3 (basin against survival, r = −0.57, is the hypothesis's own quantity
failing) is the right figure to print. Finding 14 (liveliness is in the off-diagonal cross-closures): agree, and see the
corollary below, which makes part of the off-diagonal a theorem.

**Professor §2.6 (the melting threshold p*(type, median) by a whole-turn Monte Carlo on a patch): agree, with two
amendments from check 2.** (a) It must be run at three passes, or the threshold will be the one-pass one that the frame
never uses. (b) At three passes the open 3-cycle survives phase disorder at (0.1, 0.5) and loses only to invasion by a
closed type, so p* should be measured twice: the type alone (melting) and against a closed competitor (invasion speed
as a function of swap). The Eigen analogy then applies to the first and a wall-velocity law to the second. Professor
§2.7 (ii), computation §4 and physics §2.1 call the mutual closure of two Gray types "empirical, not a consequence":
**disagree in part.** The author's own `closure-ca-gray3c.json` has #1 × #2 at 100 % (75/25) and #0 × #1, #0 × #2 at
44 % and 32 %; the species headers are A = 128, B = 2304, C = 3328, so B and C differ in one header bit (bit 10) and A
differs from each in three. A crossover of two headers one bit apart is one of the two headers, so B ∪ C is closed by
the same proof as the proposition, while A × B can select a filler window. My round-1 run gave 43 % and 32 % for A × B and
A × C, equal to the author's. So the mutual closure is a theorem exactly when the H₀ differ in one bit, and the data
show the theorem's boundary. Professor §2.7 (iii) (5–67 % against 6–52 %): agree, trivial.

**Computation §3 and ALife §2.2 (Swarm F's 3-cycle as a fourth open type, 0/0/0/100 at one pass): agree, and check 2
says the same test at three passes may give 100/100/100/100**, as it does for Brotli 12's 3-cycle at median 0.5. The
survival table must be rerun at three passes before any count is printed. ALife §4.3 (BFF's replicators are built, not
listed: a 2^−100 target) and §1.1 ("new attractor" is conversion; heritable mutants are 0 of 2,944): agree, and both fit
the family-dimension statement of my round-1 finding 10: Keimli's fixed-point families have 0–3 free bytes and the
lattice winners have 0; BFF's have 48–54. Computation §5 (the Declaration at kmax 64 is not a measurement): agree.

## 2. What I revise in my own round 1

- **Finding 8**: the inference "the seeds come from the start, not the melt" is withdrawn as argued; the comparison
  mixed one-pass droplets with three-pass frames. The replacement is check 2: at three passes the fixed point invades the
  cycle by wall motion and nothing melts at the frame's parameters. The sentence I proposed for the paper becomes:
  "with three settling passes, an open cycle holds its domain against phase disorder but is invaded by a closed type
  through a moving wall whose speed rises with the exchange rate; with one pass, mixing melts the open type". The
  experiment I proposed (remove the fixed point's basin cells at turn 0) is still the test of where the seeds come from,
  and the physicist's radius series (his item 2) is the test of whether a critical radius exists; both at three passes.
- **Finding 9**: withdrawn (plateau artefact).
- **Check 9 and finding 2**: the look-and-say bound is 72.27, not 68.27, at b = 16; the DEFINITION.md remark needs both
  the inversion fixed and the extra digit.
- **Finding 7**: the closure–survival table is a one-pass table; at three passes the 38 % type survives phase disorder
  at median 0.5. "Closure is necessary for survival" (computation §3) is therefore also a one-pass statement.
- **Finding 4**: strengthened by check 3: the strays of the three-species design are now counted (240 isolated, 9
  families), so "stray attractors stay empirical" is true only for periods ≥ 2.

## 3. The panel's three most important corrections, ranked

1. **The mechanism experiments were run at one settling pass; the frame and the replicator runs use three, and the
   two regimes have different mechanisms** (physics §2.2; check 2). Everything in mechanism.md §2–3 and §5, the
   closure–survival table, the droplet tables and the heredity patches must be rerun at three passes, and the paper's
   central sentence rewritten as invasion, not melting. Cost: the physicist's items 1–4, about 40 CPU-hours.
2. **t₅₀ reads the plateau; the takeover is size-free at every share below it** (physics §2.3, computation §2). Print
   the share curves and t₂₅/t₄₀; drop "1.35–1.6×, nucleation".
3. **r = 0.79 is a dichotomy, and the index must become a per-turn rate with a threshold** (all seven notes). Print the
   2 × 2 count with the two 95 % exceptions, then the whole-turn return probability against the exchange rate at three
   passes, per type.

Below these: the drafts and README (every note), the Declaration rows (computation §5), the one-digit and inverted
look-and-say formulas, the 48-bit prefix.

## 4. Minimum work for my role, consolidated and deduplicated

Already demanded by others and endorsed, not repeated here: the three-pass reruns and radius series (physics 1–2),
the p* threshold (professor 3, physics 3, information 4), the share curves (computation), the exact fixed points of
Brotli 12, 13, gray20c and cyc5to12 (professor 2; check 3 shows about 2 minutes each on 4 workers), the Swarm F row
(ALife 2), the drafts and README rewrite (everyone).

What remains mine:

| # | item | cost |
|---|---|---|
| 1 | DEFINITION.md corrections: 48 / 30 / 80 bits (l.115–116, 147); "mutation off" in the corollary; drop "disjoint" as a hypothesis; state the proposition for any bitwise function of any number of states; Lemma 3 remark: 128/(2(1 − 1/b)) + log₂ b, with 72.27 at b = 16; "5–67 %" → the data's range | 1 hour, no CPU |
| 2 | Add the mutual-closure corollary: types whose H₀ differ in one header bit are jointly closed (proof as the proposition); a species set whose H₀ form a Gray code has no meltable interface. Verified on gray3c (B × C 100 %, A × B 44 %) | 1 hour; a 5-minute check on gray20c and gray32c from the existing closure JSON |
| 3 | The stray count as a theorem-grade statement for every design: the exact search gives period 1; for period 2 the class search (tie 0x3fc) on the designs, 10 min each | 1 CPU-hour |
| 4 | In map-spine.md §3: FO expectations printed beside every measured tail; hash:93 idempotent "by construction"; the P-map as the lead null; the collision-time scale 2^(H2/2)·√(π/2) as the check on both nulls | 1 hour, no CPU |
| 5 | The family-dimension census for the second paper: free (self-read) bytes of each lattice winner (Brotli 12 and 13 fixed points, the imp, the 6502 pair leader) against BFF's 48–54, as one table with the heredity column | half a day, under 1 CPU-hour once the exact lists exist |
| 6 | The seed-origin test at three passes: random start with the fixed point's basin cells replaced at turn 0, 20 seeds, 256², frame; and 2,000-turn tracks of the random-phase cycle sea at (0.1, 0.5) to see whether the 2 % fixed point grows | about 2 CPU-hours |

About one and a half days and under 5 CPU-hours beyond what the others have listed.
