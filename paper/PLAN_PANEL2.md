# Work plan after the second panel

2026-10-22. From reviews/team2/SYNTHESIS.md and the professor's deduplicated table (reviews/team2/round2-professor.md
§5). Costs are the panel's estimates from stamped run times. "Who" names the notes that demand the item. Status is
kept here as the items are done; results go to results/ and the raw data to data/ (git-ignored).

## Paper 1: the map paper (about eight working days, 55 CPU-hours)

### A. Experiments (the first block decides whether the central sentence stands)

| # | item | days | CPU-h | who | status |
|---|---|---|---|---|---|
| A1 | The mechanism block at three settling passes, seed as a parameter: every ordered pair of types as a disc in a sea (coherent and random phases), whole-lattice domains, the closed type planted in a pre-melted sea; Brotli 12 and 13 (three types), Swarm F and gray3c; swap {0, 0.1, 0.25, 0.5} × median {0.25, 0.5, 1}; 5 seeds; 128², 2,000 turns; share at the end as mean with bootstrap interval, the track every 20 turns | 1 | 35 | physics A, computation Q6, optimization a, ALife 2, information 5 | **running** (`experiments/droplets3.sh`, started 2026-10-22 10:50; data/droplets3/) |
| A2 | Seed origin: the frame from a random start with every fixed-point-basin cell replaced by a cycle-basin cell, Brotli 12, 256², 2,000 turns, 20 seeds, against the unchanged start | 0.3 | 3 | mathematics 8, physics A, computation (3 seeds done in review) | **running** (`experiments/start-replace.mjs`; data/start-replace/) |
| A3 | The radius series R ∈ {1, 2, 4, 8, 16, 32}, the fixed point in the cycle, Brotli 12 and 13, at (0.1, 0.5), (0.5, 0.5), (0.1, 1), 5 seeds, 1,000 turns: a critical radius licenses "nucleation"; growth from R = 1 means no barrier | 0.2 | 3 | physics B | **running** (in droplets3.sh, `modes=radius`) |
| A4 | The whole-turn melting threshold p*(type, median): a 32² patch in random phases, three passes, swap {0.01 … 0.5} × median {0, 0.25, 0.5, 1}, 200 turns, 10 seeds, the share at turns 1, 2, 4, 8 … 200; Brotli 12, 13, Swarm F, gray3c, cyc5to12 | 0.5 | 2 | physics C, information 13, mathematics 7, optimization b–c, professor 6 | **running** (`experiments/pstar.mjs`; data/pstar/) |
| A4b | Heredity patches at three passes, Brotli 12 and 13 | – | 1 | ALife, professor | **running** (`heredity.mjs passes=3`) |
| A5 | Frame maps for Swarm F and gray3c, 256², 3 seeds; the competition matrix and transitivity from the droplet JSON | 0.2 | 1 | optimization c, e; ALife 2.3 | |
| A6 | Exact fixed points of Brotli 12, 13 and every Gray design; the 2-cycle class search for Brotli 12 and 13; the mutual-closure corollary checked on gray3c and gray20c | 0.2 | 1 | professor 12, mathematics 4 | |
| A7 | The Declaration at kmax = 200, 4 settings × 10 seeds, 128² and 256²; first appearance at 32² and 64² | 0.3 | 7 | computation 5, Q6 | |
| A8 | The lattice basin after one three-pass turn on an 8 × 8 (swap, median) grid; the 256² check of the Brotli 12 cell (0.1, 0.5), 3 seeds | 0.1 | 1 | physics §2.6, A | |

What A1–A3 decide (physics A): if the fixed-point disc at (0.1–0.5, 0.25–0.5) grows at three passes, the frame's
mechanism is the three-pass medium and "closed types grow into the open type" stands, with "melt" only where the
whole-lattice runs show dissolution; if it dies, the frame's fixed point is seeded by the strongly settled rows, and
A2 says whether the start matters. The three reviewers' round-2 reruns (n = 1–3, data/review2/) predict growth and
no melt at median ½; the block is the n = 5 version with the pre-melted sea and the radius series added.

### B. Corrections to the formal text, the results and the pipeline

| # | item | days | who | status |
|---|---|---|---|---|
| B1 | DEFINITION.md: the Gray pointer lemma's prefix is 48 bits / 30 command bits / 80-bit tail; "mutation off" in the corollary; Lemma 3's look-and-say formula 128 / (2(1 − 1/b)) and the stopping time one digit longer (72.3 / 87.1 / 98.9 bits); the proposition stated for any bitwise function of any number of same-type states ("pure domain"); cross-type closure marked empirical; the mutual-closure corollary (species whose H₀ differ in one header bit); the Shannon bracket H₂ ≤ H ≤ 87.5 | 0.5 | mathematics 1–4, information 4, 6, 9, 12; professor 7 | |
| B2 | Results regenerated from data with passes stated on every table: mechanism.md (38 / 95; the 11-cycle dies at median 0; the "heritable" column is conversion; the 2 × 2 count with the Swarm F row and the (r, steps) sensitivity in place of r = 0.79; basin-against-survival); replicators-v2.md (share curves and the times to 25 % and 40 % in place of 1.35–1.6× and t₅₀; gray3c's two leaders at 67–69 %; the CPU numbers without files dropped; the Declaration row marked unmeasured); finite-size.md ((½, 1) arrests, (0.2, ½) coarsens at z ≈ 0.26, turn-salted z ≈ 0.36 from series.csv, MSR lengths not printed); decoder-map.md l.38; look-and-say N = 131,044; entropy-manipulators' "110 bits" as a collision figure; infodyn "rest" as neither bound, with the identity-control row; the replicase log₂ definition stated once | 1 | all | |
| B3 | results/README.md rewritten as an index; superseded banners on ablation-main / -scan / -structure, replicators.md, replicators-table.md, design-gray3; the two replicator figures regenerated from v2 or deleted; provenance in entropy-curves output and the lead files; the harness `altOrder` default rotate; the search tools' generator and seed-11 scoring retired with one paragraph; band.js and docs/lattice.md headers; the lemma test in the test list | 1 | computation 1, 6, 8–9; optimization f; physics 3.1 | |

### C, D. Smaller measurements

| # | item | days | CPU-h | who | status |
|---|---|---|---|---|---|
| C | Entropy calibration on a non-flat map of known loss; Poisson intervals on every H₂ within 2 bits of the resolution | 0.5 | 1 | information 3, 8 | |
| D | The design-winner rules at 5 seeds (gray4–6c, cyc567, cyc5to12, the 24/26-species designs), uniform (½, 1) | 0.3 | 4 | optimization d | |
| F0 | The salt-by-position control at 10 seeds, if "deterministic freezing, not disorder pinning" stays | 0.1 | 0.2 | physics F | |

### E. The writing (three to four days)

Abstract, introduction, methods and results written on the claims table (RELATED_WORK.md §0) and the panel's thesis
(SYNTHESIS.md §4). The nine false sentences out of every draft. "No copy instruction, no fitness function, no heredity
of variants" on the first page. The co-authorship of the 2024 study declared. Vocabulary: "melt" defined once as the
dissolution of a domain into transients; attractor types and domain competition; no nucleation, front or coarsening
unless A3 licenses it. Citations: Hopfield 1982, Eigen 1971, Wilke 2001, Vasas–Szathmáry–Santos 2010, Kaneko,
Lempel–Ziv 1976, Levin 1974, the Zenil fix. The heredity contrast table (Keimli's repaired mutants against BFF's
inherited ones) as the closing section. Venue: Artificial Life; Complex Systems or JCA as fall-backs.

## Paper 2: the origin and heredity of replicators (one to two weeks, 80 CPU-hours, an outside co-author)

| # | item | CPU-h | who |
|---|---|---|---|
| F1 | Single-cell dose-response at 5 seeds | 8 | computation Q6, information 5 |
| F2 | Information dynamics at k = 4, five seeds, the identity control, one cell-level variant | 3 | information 5–7 |
| F3 | 6502 and Redcode single-cell reruns with the fixed script, 256² | 10 | ALife 6.3, computation 6 |
| F4 | Redcode pairs at 256² | 2 | computation |
| F5 | The 6502 pair leader decoded and tested as a fixed point | 0 | ALife |
| F6 | The imp mutant census on pairs | 4 | ALife, information |
| F7 | The random-tape self-copier count in BFF, and a mutation walk | 2 | ALife 6.4 |
| F8 | 20 BFF soups at the paper's setting to 16,000 epochs (the emergence rate) | 40 | ALife 6.5, PNAS |
| F9 | Stage-resolved erasure H(Y\|Z) | 10 | information |
| F10 | The family-size census (heritable bits = log₂ family size) for the imp, the 6502 type and the BFF replicators | 1 | mathematics 10 |
| G | An outside co-author from the BFF community; the origin section written from ALife §4.3 | – | professor, ALife |

## Only for a physics paper (the panel advises against)

Turn-salted MS− at 1024² × 3 seeds × 4,000 turns and 2048² × 8,000 turns (z: ⅓ or ½); the phase-field observable for
MSR; salt-by-position at 10 seeds: 1.5 days, 26 CPU-h (physics 5–6).
