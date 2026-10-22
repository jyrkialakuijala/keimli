# Why the medium, not the basin, picks the winner

2026-10-21. The mechanism experiments the editors asked for: Lemmas 1–2 (DEFINITION.md), the closure index, droplets,
whole-lattice domains, mutants and the frame maps. Scripts and raw data:

| script | output |
|---|---|
| `experiments/closure.mjs` | `../data/closure/` |
| `experiments/closure-vs-survival.mjs` | (table printed) |
| `experiments/droplets.mjs`, `droplets-summary.mjs` | `../data/droplets/` |
| `experiments/heredity.mjs` | `../data/heredity/` |
| `experiments/frame-mechanism.mjs` | `../data/frame-mechanism/` |

Figures: `../figures/mechanism-frame.png` (where the fixed point wins on the frame, turns 50 and 2000) and `../figures/mechanism-closure.png` (closure against domain survival). Every output carries a provenance stamp; all runs use the rotating swap order and quenched hashing. The attractor types
of each dictionary are the largest-basin types from 16,384 random cells under the decoder alone, plus the largest
fixed point.

## 1. Exact: the medium acts only on boundaries

**Lemma 1** (proved in DEFINITION.md, checked on the module in `test/lemma.test.mjs`).
- A uniform configuration is untouched by mixing and settling, for any parameters and either salt.
- So a uniform fixed point is a fixed point of the lattice map, and an in-phase cycle is a periodic orbit.
- Interiors of uniform domains evolve by f alone (Lemma 2). Everything the medium does, it does at boundaries.

**For a cycle**, a domain whose cells sit in different phases is all boundary. Whether such a domain survives depends
on what bit exchange between its own states produces.

## 2. The closure index predicts which types hold domains in random phases

**Definition.** The self-closure C(A, A) is the share of crossover children of two random states of A (each differing
bit exchanged with probability 0.25, as one mixing exchange does) that are again states of A after one step of f.

| dictionary | type | period | basin | C(A, A) | random-phase domain survives (swap 0.1; median 0 / 0.25 / 0.5 / 1), % | in-phase domain, % |
|---|---|---|---|---|---|---|
| Brotli 12 | #0 | 3 | 99.72 % | 39 % | 1 / 1 / 1 / 99 | 100 everywhere |
| Brotli 12 | #1 | 1 | 0.26 % | 100 % | 100 everywhere | 100 everywhere |
| Brotli 12 | #2 | 1 | 0.02 % | 100 % | 100 everywhere | 100 everywhere |
| Brotli 13 | #0 | 9 | 92.90 % | 11 % | 0 / 0 / 0 / 25 | 100 everywhere |
| Brotli 13 | #1 | 18 | 4.18 % | 6 % | 0 everywhere | 100 everywhere |
| Brotli 13 | #2 | 1 | 2.77 % | 100 % | 100 everywhere | 100 everywhere |
| 5-to-12 cycles | #0 | 5 | 27.65 % | 95 % | 100 / 0 / 0 / 100 | 100 everywhere |
| 5-to-12 cycles | #1 | 11 | 20.40 % | 94 % | 1 / 1 / 1 / 100 | 100 everywhere |
| 5-to-12 cycles | #2 | 1 | 0.28 % | 100 % | 100 everywhere | 100 everywhere |
| 20 Gray 8-cycles | #0, #1 | 8 | 15.8, 14.6 % | 100 % | 100 everywhere | 100 everywhere |
| 20 Gray 8-cycles | #2 | 1 | 0.01 % | 100 % | 100 everywhere | 100 everywhere |
| 3 Gray 8-cycles | #0–#2 | 8 | 42.6, 30.6, 26.8 % | 100 % | 100 everywhere | 100 everywhere |

- **Closed types survive.** All ten types with C(A, A) ≥ 99 % hold random-phase domains at every setting: every fixed
  point (trivially closed: one state) and every Gray-coded cycle (closed by construction, since the designed states of
  a cycle differ only in the bits mixing exchanges among them).
- **Open types die.** All three clearly open types die under any partial settling: Brotli 12's 3-cycle (39 %) and
  Brotli 13's 9- and 18-cycles (11 % and 6 %). Brotli 13's 9-cycle keeps a quarter of the lattice even at full
  settling, and its 18-cycle dies there too.
- **The correlation.** Across the 15 types, self-closure and mean random-phase survival at median below 1 correlate at
  r = 0.79 (`closure-vs-survival.md`).
- **Borderline types are partly explained.** The two generic cycles of the 5-to-12 design are at 94–95 %. They survive
  mixing alone but die under partial settling. That settling is also a crossover (a bitwise majority over neighbours in
  different phases) does not explain it: their majority closure is 99–100 %. So the borderline cases depend on the whole
  turn (exchange, then majority, then f), and the one-operator index leaves them open.
- **Self-closure under mixing for the other generic cycles:** Swarm F's 3-cycle 33–52 %, Brotli 13's 9-cycle 11–34 %
  and its 18-cycle 5–35 % (r from 0.5 to 0.05).

## 3. Droplets: a closed rare type beats an open common one

Brotli 12 on 128², 400 turns, a disc of radius 16 (5 % of the cells) of type X in a sea of type Y. Final shares X / Y /
other in %:

| X in Y | swap 0.1, median 0.5 | swap 0.1, median 1 | swap 0.5, median 1 |
|---|---|---|---|
| 3-cycle (basin 99.7 %) in fixed point #1 (0.26 %), in phase | 0 / 68 / 32 | 0 / 100 / 0 | 0 / 100 / 0 |
| fixed point #1 in 3-cycle, in phase | 0 / 16 / 84 | 5 / 95 / 0 | 5 / 95 / 0 |
| fixed point #1 in 3-cycle, random phases | 0 / 1 / 99 | 6 / 93 / 0 | 6 / 94 / 0 |

- **Full settling.** The fixed point's droplet holds inside the cycle's sea, and grows slightly when the sea is out of
  phase. The cycle's droplet is erased from the fixed point's sea.
- **Partial settling.** The cycle sea melts (84–99 % "other"), while the fixed-point sea mostly holds (68 %).
- **The general pattern, all dictionaries.**
  - With no mixing nothing moves: Lemma 2 at work, with straight-enough boundaries.
  - With mixing and partial settling, an interface between two mutually open types melts the whole lattice into
    transients.
  - With full settling, the sea wins by majority.
  - Two mutually closed types (Gray #1 and #2: C = 100 %) never melt. One invades the other (up to fifteenfold) or
    they hold a stand-off, depending on the setting.

## 4. The frame: the fixed point nucleates in the melt and fills it

Brotli 12 on the page frame, 256², 2,000 turns, 3 seeds (`frame-ca-brotli-12-*.md`). Blocks of 32²:
- columns run left to right from swap slider 0 to 1, so mixing is strongest in the middle columns;
- rows run top to bottom from median 0 to 1.

Fixed-point share at turn 2000, seed 1:

| row \ column | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| 0 (no settling) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2 | 82 | 89 | 61 | 48 | 43 | 58 | 91 | 91 |
| 3 | 86 | 100 | 100 | 100 | 100 | 100 | 100 | 70 |
| 4 | 78 | 100 | 100 | 100 | 100 | 100 | 100 | 65 |
| 5 | 37 | 92 | 100 | 100 | 100 | 100 | 96 | 21 |
| 6 | 0 | 14 | 82 | 100 | 100 | 99 | 36 | 5 |
| 7 (full settling) | 8 | 5 | 4 | 38 | 40 | 18 | 0 | 7 |

- **Turn 50.** The 3-cycle has already melted out of the mixing columns of rows 1–4, and isolated fixed-point cells sit
  in the melt.
- **Turn 2000.** The fixed point fills every block where mixing is strong and settling partial to strong. The 3-cycle
  survives only where mixing is weak (the edge columns), at the top where nothing settles, and in the bottom row, where
  full settling repairs its crossovers.
- **Seeds and dictionaries.** Seeds 2 and 3 and Brotli 13 (fixed point against the 9-cycle, C = 11–34 %) all show the
  band of 100 % fixed point. The edge columns and the bottom row vary with the seed: in the bottom row the fixed point
  takes 0–53 % of most blocks, but 100 % of the middle blocks in seed 2. Brotli 13's fixed point, whose rival cycle is
  more open, takes more of the bottom row (40–100 %).
- **A negative result.** Local phase coherence of the cycle at turn 50 predicts the final fixed-point share only
  weakly (r = 0.19–0.53 over blocks). Surviving cycle cells are almost always in phase with their cycle neighbours.
  What matters is whether the cycle is there at all, that is, whether mixing has melted it.

**Statement for the paper.** Which attractor type takes a region is decided by whether bit exchange between its own
states stays on the type (the closure index), not by its basin. Mixing melts the open types. Closed types (fixed
points always, designed cycles by construction) nucleate in the melt and fill it. Where mixing is weak or settling
complete, the large-basin open type keeps its ground. This replaces "fixed points are favoured by strong settling"
with a mechanism that predicts the designed cycles' robustness as well.

## 5. Mutants: limited heredity, quantified

Every one-bit mutant of every state of each main type, iterated by f alone for 300 turns (`../data/heredity/`):

| dictionary | type (period, basin) | repaired | converted to another type | a new attractor (heritable) |
|---|---|---|---|---|
| Swarm F | 3-cycle, 100 % | 100 % | 0 | 0 |
| Brotli 12 | 3-cycle, 99.7 % | 100 % | 0 | 0 |
| Brotli 12 | fixed point, 0.26 % | 82.8 % | 17.2 % | 0 |
| Brotli 13 | 9-cycle, 92.9 % | 98.6 % | 1.4 % | 0 |
| Brotli 13 | 18-cycle, 4.2 % | 73.0 % | 27.0 % | 0 |
| 3 Gray 8-cycles | three cycles | 90.8–99.2 % | 0.8–9.2 % | 0 |
| 20 Gray 8-cycles | two cycles | 84.6–88.3 % | 11.7–15.4 % | 0 (0.8 % land on another state of a cycle) |
| 20 Gray 8-cycles | fixed point, 0.01 % | 80.5 % | 18.0 % | 1.6 % |

- **Almost no mutation is inherited.** Mutants are repaired or converted to another existing type; only one fixed
  point of one design yields new attractors, from 1.6 % of its mutants. This is limited heredity, as the panel put it.
- **The lattice.** A 3 × 3 mutant patch in an in-phase domain (64², 200 turns, 12 trials per setting) is erased at full
  settling in every trial, for every type. Under mixing with partial settling it destroys the domain in up to half the
  trials for open types. In Brotli 12 the 3-cycle's domain was lost in 1–4 of 12 trials at settling 0.25–0.5, while the
  fixed point's was lost in none at settling ≥ 0.25.
