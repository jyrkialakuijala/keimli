# Nucleation, defined and tested

2026-10-22. `experiments/nucleation.mjs` (batch `nucleation.sh`, summary `nucleation-summary.mjs`, figure
`../figures/nucleation.png` by `nucleation-plot.py`); raw data `../data/nucleation/` (358 jobs, provenance in each).
The leading fixed point X of Brotli 12 (basin 0.26 %) and Brotli 13 (2.77 %) against each dictionary's leading cycle Y
(the 3-cycle, 99.7 %; the 9-cycle, 92.9 %), at the page's three settling passes, uniform (swap, median), the rotating
order, quenched hashing, 10 seeds per cell of every table (3 for the control).

## 1. The definition

Nucleation is growth of a type X inside a domain of another type Y that needs a seed above a critical size. Three
clauses, each a measurement:

- **N1. A critical radius R\* > 1 cell.** Discs of X below R\* shrink to nothing; above it they grow to fill the
  domain. If every disc grows, including a single cell, the growth is seeded but has no barrier.
- **N2. Rare and local starts.** With no X planted, X first appears as a few compact clusters that then grow, at a
  rate per cell and turn; not everywhere at once. The clusters are rare compared with the cells (density ≪ 1).
- **N3. The consequence.** The waiting time to the first X falls with the domain's area (more area, more chances),
  and the time to take the domain is that waiting time plus a growth time set by the wall speed.

In an in-phase domain the spontaneous rate is zero by Lemma 1 (DEFINITION.md §3), so nucleation there can start
only at walls or from planted seeds (heterogeneous); in a disordered domain it can start anywhere (homogeneous).
Appearance everywhere at once, with cluster density of order one, would be instability, not nucleation.

## 2. N1: the critical radius against an in-phase sea

Share of 10 seeds in which a disc of radius R grows to at least half the lattice by turn 1,000 (128²):

| dictionary | swap/median | R = 1–4 | 5 | 6 | 7 | 8 | 10–16 | R\* |
|---|---|---|---|---|---|---|---|---|
| Brotli 12 | 0.1 / 0.5 | 0 % | 0 % | 0 % | 0 % | 100 % | 100 % | 8 |
| Brotli 12 | 0.25 / 0.5 | 0 % | 0 % | 100 % | 100 % | 100 % | 100 % | 6 |
| Brotli 12 | 0.5 / 0.5 | 0 % | 0 % | 0 % | 100 % | 100 % | 100 % | 7 |
| Brotli 12 | 0.1 / 0.75 | 0 % | 0 % | 0 % | 0 % | 0 % | 0 % | none ≤ 16: the disc neither grows nor dies (R = 16 stays at 16–17) |
| Brotli 13 | 0.1 / 0.5 | 0 % | 100 % | 100 % | 100 % | 100 % | 100 % | 5 |
| Brotli 13 | 0.25 / 0.5 | 0 % | 100 % | 100 % | 100 % | 100 % | 100 % | 5 |
| Brotli 13 | 0.5 / 0.5 | 0 % | 0 % | 100 % | 100 % | 100 % | 100 % | 6 |
| Brotli 13 | 0.1 / 0.75 | 0 % | 0 % | 100 % | 100 % | 100 % | 100 % | 6 |

The threshold is sharp: 0 of 10 at one radius, 10 of 10 at the next. R\* is 5–8 cells and depends on the pair and
weakly on the setting. Below it the disc is erased within about 200 turns (R = 8 at (0.1, 0.75): radius 7.8 → 5.2 →
0). N1 holds.

## 3. The growth of a supercritical disc: a constant wall speed

Effective radius √(share · N / π), mean over 10 seeds, for R₀ = 16 (the R₀ = 8 discs give the same slopes):

| dictionary | swap/median | turn 0 | 100 | 200 | 300 | 400 | 600 | wall speed v (cells per turn, turns 100–400) |
|---|---|---|---|---|---|---|---|---|
| Brotli 12 | 0.1 / 0.5 | 15.9 | 18.6 | 23.5 | 29.2 | 35.4 | 47.6 | 0.056 |
| Brotli 12 | 0.25 / 0.5 | 15.9 | 23.8 | 35.1 | 46.7 | 58.9 | 71.2 | 0.117 |
| Brotli 12 | 0.5 / 0.5 | 15.9 | 24.1 | 36.5 | 48.9 | 61.9 | 72.0 | 0.126 |
| Brotli 13 | 0.1 / 0.5 | 15.9 | 22.7 | 30.8 | 39.2 | 48.5 | 64.9 | 0.086 |
| Brotli 13 | 0.1 / 0.75 | 15.9 | 20.5 | 26.1 | 31.4 | 37.2 | 49.4 | 0.056 |
| Brotli 13 | 0.25 / 0.5 | 15.9 | 25.3 | 38.4 | 51.3 | 62.7 | 71.7 | 0.125 |
| Brotli 13 | 0.5 / 0.5 | 15.9 | 22.6 | 33.6 | 45.7 | 58.2 | 71.3 | 0.119 |

The radius grows linearly in time until the disc meets the edges (72 cells is the whole 128² lattice): a wall of
constant speed, 0.06 cells a turn at swap 0.1 and 0.12 at swap 0.25–0.5, where it saturates. The share curves of
`mechanism-v2.md` §4 are this constant speed seen as an area, not a linear growth of share; that sentence is
corrected there. The earlier t₅₀ and "1.35×" statements stay withdrawn.

## 4. N2–N3: spontaneous appearance in a disordered sea, and the in-phase control

A sea of Y with every cell in a random phase (q = 1), no X planted, 2,000 turns, sampled every 10 turns:

| dictionary | swap/median | size | first X cell, turn (median, range) | clusters when X reaches 0.1 % (mean) | most clusters at once | X at the end | n |
|---|---|---|---|---|---|---|---|
| Brotli 12 | 0.1 / 0.5 | 64² | 40 (30–60); **7 of 10 never** | 1.7 | 1.0 | 30 % | 10 |
| Brotli 12 | 0.1 / 0.5 | 128² | 30 (20–80); 2 never reach 0.1 % | 2.6 | 4.0 | 63 % | 10 |
| Brotli 12 | 0.1 / 0.5 | 256² | 20 (20–40) | 4.7 | 8.0 | 69 % | 10 |
| Brotli 12 | 0.25 / 0.5 | 64² | 60 (30–270); 3 never | 1.6 | 3.8 | 70 % | 10 |
| Brotli 12 | 0.25 / 0.5 | 128² | 40 (20–60) | 2.0 | 9.0 | 99 % | 10 |
| Brotli 12 | 0.25 / 0.5 | 256² | 20 (20–30) | 6.2 | 22.1 | 99 % | 10 |
| Brotli 12 | 0.5 / 0.5 | 64² | 40 (20–100); 3 never | 1.0 | 3.5 | 70 % | 10 |
| Brotli 12 | 0.5 / 0.5 | 128² | 30 (20–190) | 2.4 | 9.9 | 100 % | 10 |
| Brotli 12 | 0.5 / 0.5 | 256² | 30 (20–40) | 5.0 | 27.6 | 100 % | 10 |
| Brotli 13 | all three | 64² | 10 (10–60) | 2.8–3.6 | 5.6–6.2 | 99–100 % | 10 |
| Brotli 13 | all three | 128² | 10 (10–10) | 12.5–14.7 | 14–16 | 99–100 % | 10 |
| Brotli 13 | all three | 256² | 10 (10–10) | 47–53 | 49–53 | 99–100 % | 10 |
| both | all three | in phase (q = 0), 128² | never | – | 0 | 0 % | 3 |

- **N2 holds.** X appears as a few compact clusters that grow: in Brotli 12 one to five clusters in a whole 128² or
  256² lattice, in Brotli 13 about one cluster per 1,200 cells (12.5 in 128², 52 in 256²). The density is far below
  one per cell in both: rare and local, not everywhere at once. The cluster counts scale with the area (Brotli 13:
  × 3.5 and × 4.2 for × 4 area; Brotli 12 less than proportionally, because the few clusters merge).
- **N3 holds, where it can be resolved.** Brotli 12's rate is low, roughly 2–4 × 10⁻⁶ appearances per cell and turn
  (2.6 clusters in 16,384 cells by turn 40; 4.7 in 65,536 by turn 40): the median waiting time falls from 40 turns
  at 64² to 30 at 128² and 20 at 256², and at 64² most seeds never nucleate in 2,000 turns, so the sea there keeps
  70 % of its cells. Brotli 13's rate is 20–40 times higher (about 8 × 10⁻⁵: 52 clusters in 65,536 cells within 10
  turns), so the waiting time is below the sampling interval at every size and N3 is satisfied trivially.
- **The control holds exactly.** In an in-phase sea nothing appears in 2,000 turns at any setting (Lemma 1).

## 5. The barrier against the sea's order

Discs of radius 16 (supercritical) and 4 (subcritical in an in-phase sea) in seas with a fraction q of cells in
random phases; share of 10 seeds in which the disc grows to half the lattice by turn 1,000:

| dictionary | swap/median | R₀ | q = 0 | 0.05 | 0.1 | 0.25 | 0.5 | 1 |
|---|---|---|---|---|---|---|---|---|
| Brotli 12 | 0.1 / 0.5 | 16 | 100 % | 100 % | 100 % | 100 % | 100 % | 100 % |
| Brotli 12 | 0.1 / 0.5 | 4 | 0 % | 0 % | 0 % | 0 % | 0 % | 60 % |
| Brotli 12 | 0.5 / 0.5 | 4 | 0 % | 0 % | 0 % | 0 % | 0 % | 90 % |
| Brotli 13 | 0.1 / 0.5 | 4 | 0 % | 10 % | 10 % | 20 % | 100 % | 100 % |
| Brotli 13 | 0.5 / 0.5 | 4 | 0 % | 0 % | 0 % | 70 % | 100 % | 100 % |

The subcritical disc stays subcritical until the sea is largely disordered (q ≥ 0.5 for Brotli 13, q = 1 for Brotli
12), and what "grows" there is not the disc: at those q the sea nucleates X on its own (§4). So the R = 1 "growth
from a single cell" of `mechanism-v2.md` §2 was misread; in a disordered sea X appears spontaneously whatever is
planted. The barrier is a property of the sea's order, and disorder removes it by supplying the nuclei, not by
lowering R\*.

## 6. The verdict

By the definition of §1, **the fixed point nucleates in the cycle's domain**, in both senses:
- **heterogeneous**, from a planted seed above a critical radius of 5–8 cells in an in-phase sea, growing at a
  constant wall speed of 0.06–0.13 cells a turn (N1, §2–3);
- **homogeneous**, spontaneously in a disordered sea, as rare compact clusters at a rate of 10⁻⁶ to 10⁻⁴ per cell
  and turn depending on the dictionary, with the waiting time falling with the area (N2–N3, §4);
- and **not at all** inside an in-phase domain (the control), as Lemma 1 requires.

What this does to the earlier sentences: "closed types nucleate in the melt" was withdrawn by the second panel for
lack of a critical radius and a rate; both are now measured, and the sentence comes back in a precise form: *in a
disordered domain of an open type at partial settling, the leading fixed point nucleates homogeneously; in an
ordered domain it grows only from seeds above R\*, which the medium supplies at walls and in the frame's disordered
band.* The frame's fast, size-independent establishment (replicators-v2.md) is the high-rate homogeneous case; the
slow creep after is the walls advancing into the ordered regions.

## 7. Not shown

- The nucleation rate as a function of (swap, median) beyond the three settings, and its dependence on the sea's
  period (why Brotli 13's 9-cycle nucleates 30 times faster than Brotli 12's 3-cycle: a 9-cycle in random phases is
  less uniform under majority, §1 of mechanism-v2.md).
- R\* and v for the second fixed point of Brotli 12, which loses the wall (mechanism-v2.md §5): presumably R\* = ∞.
- Sizes above 256²; turns beyond 2,000; the critical radius's dependence on the disc's shape.
