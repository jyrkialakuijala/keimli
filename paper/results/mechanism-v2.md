# The mechanism at the page's settling: the three-pass block (second panel, A1–A4)

2026-10-22. Replaces the mechanism statement of `mechanism.md` §2–5, whose uniform-parameter experiments ran at one
settling pass while the frame runs at three (second panel, `../reviews/team2/SYNTHESIS.md` §2). Scripts
`experiments/droplets3.mjs` (batch `droplets3.sh`), `start-replace.mjs`, `pstar.mjs`, `heredity.mjs passes=3`;
summary `droplets3-summary.mjs`; figure `../figures/mechanism-v2.png` (`droplets3-plot.py`); raw data
`../data/droplets3/`, `start-replace/`, `pstar/`, `heredity/*-pass3*` (git-ignored, provenance in every file).

**Settings.** 128², 2,000 turns, **three settling passes**, the rotating order, quenched hashing, uniform swap p ∈
{0, 0.1, 0.25, 0.5} × median m ∈ {0.25, 0.5, 1}, **5 seeds** (the seed sets the phases and the disc's centre); the disc
has radius 16 (5 % of the lattice). Shares at the end are means over seeds with bootstrap 95 % intervals (all in the
summary; quoted here when they are not within a point or two of the mean). Types as in `droplets.mjs`: Brotli 12
(#0 3-cycle, basin 99.72 %; #1 fixed point, 0.26 %; #2 fixed point, 0.02 %), Brotli 13 (#0 9-cycle, 92.9 %; #1
18-cycle, 4.2 %; #2 fixed point, 2.8 %), Swarm F (its 3-cycle only; no fixed point among 16,384 random cells), gray3c
(three Gray 8-cycles, all closed).

## 1. What happens, by settling strength

**Weak settling (m = 0.25) with any mixing.** Both types dissolve. The random-phase cycle sea alone goes to 0–1 %;
the fixed-point disc, coherent or random, goes to 0 %. Only an in-phase sea holds (100 %, Lemma 1). Nothing is
selected: the lattice is transients.

**Intermediate settling (m = 0.5) with mixing: the fixed point wins everything.** Brotli 12's #1 disc fills the
lattice at p = 0.1, 0.25 and 0.5, in a coherent sea (100, 100, 100 %), in a random-phase sea (100, 99, 100 %) and
when planted after the sea has run alone in random phases for 100 turns (100, 99, 100 %). Brotli 13's #2 does the
same (100, 99, 100 %). Meanwhile:
- the **random-phase sea alone dissolves** under stronger mixing: Brotli 12's 3-cycle holds 42 % [2–81] at p = 0.1
  and 0 % at p = 0.25 and 0.5; Brotli 13's 9-cycle 0 % at every p > 0;
- the **coherent sea alone holds** (100 % at every p), and the disc invades it anyway: the wall advances into a sea
  that would not dissolve on its own.

So at m = 0.5 both things the panel argued about happen, in different places: a disordered sea dissolves and is
filled, an ordered sea is invaded by a moving wall. Either way the fixed point ends with the lattice.

**Strong settling (m = 1).** Walls stand. The disc stays at its starting 5 % (4–5 %) and the sea at 100 %; the
radius series keeps every disc at its starting share (R = 32: 20 %). The lattice is frozen. One exception: Brotli
13's random-phase 9-cycle at m = 1 lets the fixed point grow to 40–62 % [32–73], because a 9-cycle in random phases
is not uniform enough for Lemma 1 and partial majority over phases makes transients that the fixed point fills.

**No mixing (p = 0).** Everything holds, with the same exception: the random-phase 9-cycle dissolves under settling
alone at m = 0.25 (11 % left), and the fixed point planted in it reaches 95 %.

## 2. The radius series: a critical radius against an ordered sea, none against a disordered one

Brotli 12's fixed point in the 3-cycle at (0.1, 0.5), 1,000 turns, share at the end against the disc radius:

| sea | R = 1 | 2 | 4 | 8 | 16 | 32 |
|---|---|---|---|---|---|---|
| coherent | 0 % | 0 % | 0 % | 57 % [56–59] | 79 % [75–81] | 97 % [96–98] |
| random phases | 9 % [0–20] | 32 % [11–54] | 48 % [20–74] | 73 % [68–82] | 89 % [84–94] | 99 % [97–100] |

Brotli 13 (coherent): 0, 0, 0, 95, 98, 100 %. At (0.5, 0.5) in a random-phase sea a single cell suffices (R = 1:
99 % [98–99]); in a coherent sea R ≤ 4 still dies and R = 8 fills.

So against an **in-phase** sea there is a critical radius between 4 and 8 cells: below it the disc is erased, above
it it grows to fill the lattice. The "growth from one cell" against a **disordered** sea is not the disc growing:
such a sea nucleates the fixed point on its own, whatever is planted (`nucleation.md` §4–5). The full nucleation
tests, with the definition, the critical radius at one-cell resolution (5–8 cells), the wall speed (0.06–0.13 cells
a turn) and the spontaneous rate, are in `nucleation.md`.

## 3. The seeds come from the medium, not the start

`start-replace.mjs`: Brotli 12 on the page frame, 256², 2,000 turns, 20 seeds, every cell whose decoder-alone
attractor is a fixed point replaced at turn 0 by a copy of a random cycle-basin cell (none remain; verified), against
the unchanged start.

| seeds | control: fixed-point share at 2,000 | replaced | first seen (both arms) |
|---|---|---|---|
| 1–5 | 55 % [53–57] | 55 % [52–58] | turn 20 |
| 6–10 | 54 % [53–56] | 54 % [52–55] | turn 20 |
| 11–15 | 56 % [55–57] | 56 % [55–57] | turn 20 |
| 16–20 | 53 % [51–55] | 54 % [53–56] | turn 20 |

No difference, in level or in timing. The frame creates the fixed-point cells by the first sample at turn 20, from a
start that contains none. The mathematician's round-1 hypothesis (seeds from the start) is refuted at n = 20.

## 4. The growth curves

Brotli 12, fixed-point disc in the coherent 3-cycle, m = 0.5, mean share over 5 seeds:

| swap | turn 0 | 200 | 400 | 600 | 800 | 1,000 | 1,500 |
|---|---|---|---|---|---|---|---|
| 0.1 | 5 % | 11 | 24 | 43 | 61 | 79 | 100 |
| 0.25 | 5 % | 24 | 57 | 87 | 99 | 100 | 100 |
| 0.5 | 5 % | 26 | 62 | 94 | 100 | 100 | 100 |

The disc's radius grows linearly in time (`nucleation.md` §3: a wall of constant speed, 0.06 cells a turn at swap
0.1 and 0.12 at 0.25–0.5), so the share grows as the square of the time until the disc meets the edges. The earlier
t₅₀ and "1.35×" statements stay withdrawn.

## 5. Closure says who holds, not who invades

Brotli 12 has a second fixed point, #2 (basin 0.02 %). It is closed like #1, holds its own domain like #1, and
**loses the wall** to the 3-cycle: at m = 0.5 its disc ends at 15 % (p = 0.1, coherent), 9 % (random), and 0 % at
p ≥ 0.25. gray3c's three closed cycles, planted in each other, stand or shrink (5 % → 0–11 %) and never invade.

So the closure dichotomy is confirmed as a condition for holding (every open type dissolves at m ≤ 0.5 with mixing;
every closed type holds its own domain at every setting), and it does not decide the contest between two closed
types, or between a closed type and a cycle at a wall. Which fixed point advances is a property of the pair, not of
the type; it is the open question of this paper's lattice section (candidates: the cross-closure C(fixed point,
cycle), the reading length; both single-seed in the older results).

## 6. The melting threshold p\* (`pstar.mjs`: 32² patch in random phases, three passes, 200 turns, 10 seeds)

The smallest swap at which the share on the type at turn 200 falls below one half:

| type | m = 0 | 0.25 | 0.5 | 1 |
|---|---|---|---|---|
| Brotli 12, 3-cycle | ≤ 0.02 | ≤ 0.02 | > 0.5 | > 0.5 |
| Brotli 13, 9-cycle | ≤ 0.01 | ≤ 0.01 | ≤ 0.01 | > 0.5 |
| Brotli 13, 18-cycle | ≤ 0.01 | ≤ 0.01 | ≤ 0.01 | ≤ 0.01 |
| cyc5to12, 5-cycle | ≤ 0.5 | ≤ 0.02 | > 0.5 | > 0.5 |
| cyc5to12, 11-cycle | ≤ 0.02 | ≤ 0.02 | ≤ 0.05 | > 0.5 |
| Swarm F, 3-cycle | ≤ 0.02 | ≤ 0.05 | > 0.5 | > 0.5 |
| every fixed point; gray3c's three Gray cycles | > 0.5 | > 0.5 | > 0.5 | > 0.5 |

Open types dissolve at the smallest mixing tried (0.01–0.05) wherever the settling is partial, and hold wherever it
is strong enough (m = 1 for all but the 18-cycle; m ≥ 0.5 for the two 3-cycles). Closed types never dissolve. So the
threshold is in the settling strength, not the mixing: p\* does not grade the open types, it separates them from the
closed ones as the one-step index did, and it adds the settling strength at which each open type is rescued. On a
32² patch over 200 turns; the 128² whole-lattice runs above agree (Brotli 12's 3-cycle holds at m = 0.5 only with
p = 0.1, and partially).

## 7. Swarm F: the conditional rule holds

With no closed competitor, Swarm F's random-phase 3-cycle dissolves at m = 0.25 with any mixing (0 %) and holds 100 %
at m = 0.5 and 1 at every p. Where no closed type is present and the settling is at least half, the open cycle
re-forms in phase; this is the frame's lower half for the default dictionary.

## 8. Heredity at three passes

`heredity.mjs passes=3`, Brotli 12 and 13: the one-bit variant patches in an in-phase domain are erased in 12 of 12
trials at m ≥ 0.5 for every type (one spread in 288 trials, Brotli 12's #2 at (0.1, 0.5)); at m ≤ 0.25 the
"domain lost" column is the domain itself dissolving. Same as at one pass. Under the map alone (pass-independent)
the 3-cycle repairs 100 % of 384 variants, the fixed points 82–83 % of 128 and convert the rest to another type; no
variant founds a new attractor. The decoder's types inherit nothing at the page's settling either.

## 9. The mechanism, stated

At the page's settling (three passes):

1. Uniform (in-phase) domains of any type are untouched by the medium (Lemma 1); their walls are where everything
   happens.
2. With weak settling (m ≤ 0.25) and mixing, every type dissolves into transients. Nothing is selected.
3. With partial settling (m ≈ 0.5) and mixing, open types in random phases dissolve, in-phase open domains hold, and
   the leading closed type grows into both: it fills what dissolved and advances its wall into what did not. Against
   an in-phase sea the growth needs a seed above a critical radius of 5–8 cells and proceeds at a constant wall
   speed; in a disordered sea the fixed point nucleates spontaneously, as rare compact clusters, at a rate of 10⁻⁶
   to 10⁻⁴ per cell and turn (`nucleation.md`). The seeds are made by the medium in the first turns, not inherited
   from the start.
4. With strong settling (m = 1) walls stand and the lattice freezes.
5. Closure decides who holds; it does not decide who wins a wall. Brotli 12's second fixed point holds and loses.
6. Where no closed type exists, the open type re-forms in phase at m ≥ 0.5 (Swarm F).

What this changes in the drafts' words: "melt" becomes dissolve and is true only for disordered domains at partial
settling; "nucleate" is now defined and measured (`nucleation.md`): heterogeneous above R* in ordered domains, homogeneous in disordered ones, never inside an in-phase domain; "the medium, not the
basin, picks the winner" stands, and its mechanism is wall advance by a closed type; the frame shows regimes 2, 3
and 4 from top to bottom.

## 10. Not shown

- Which closed type wins a wall, and why (§5).
- Sizes other than 128² for the uniform block (the frame runs are 128²–512²); times beyond 2,000 turns.
- The disc's growth law.
- Anything at one settling pass is now a different automaton and is labelled so in `mechanism.md`.
