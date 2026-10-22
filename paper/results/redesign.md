# A lively default, built from understood parts

2026-10-22. The page's default had become the twenty Gray 8-cycles (`ca-gray20c`): every type closed, so the lattice
freezes into a static mottle of ~12-cell domains that cycle in place. The aim here is a family of dictionaries built,
not searched, from parts whose behaviour the mechanism results (`mechanism.md`, `closure-vs-survival.md`) explain,
that keep moving to turn 3000 at 512². Five candidates are on the page as presets; the default is unchanged.

Scripts: `experiments/design-live.mjs` (builds a dictionary from a design, checks every code against the reference
decoder, prints the exact closure table and the basins), `experiments/live-run.mjs` (the page's default lattice,
headless, with the liveliness numbers and PNGs in the page's colouring). Raw runs: `../data/redesign/` (not tracked).
Figures: `../figures/redesign/` (the comparison page is `../figures/redesign/README.md`).

## 1. The construction: the decoder as a table over codes

A designed cell has a 6-byte head and a 10-byte tail. The head is byte 0's six skipped bits, a 12-bit header h = 16 u
and the command "copy 10 bytes at distance 16, then 6 more at the same distance" (the head of `design-dict.mjs`, ending
`?0@`). Such a cell decodes to the 16 dictionary bytes before h, its *slot*. Three things follow:

- The 8-bit code u is the only part of a designed cell that f reads. The tail and byte 0's low bits are inert; they
  only set the colour.
- Mixing and settling cannot change the command bits, since all designed cells share them. Among designed cells the
  decoder is therefore a map on codes, and the dictionary is its table.
- A code can be a *state* (head bytes printable) when bit 5 is 0 and bits 3 and 4 differ. The designs also keep bit 7
  at 0, which leaves 32 state codes and five free bits: g (bits 0–2), the pair a (bits 3/4) and hi (bit 6). A class
  (a, hi) is a 3-cube of 8 state codes.

**Slots and the table.**
- No crossover of states sets bit 5 or 7. Every code below 128 still has a slot (bytes 0..2031, slot 0 wrapping to
  the file's last 16 bytes).
- The table therefore says where every crossover child goes, not only where the states go.
- A state's slot holds its successor. Every other code is routed by its expected parentage: for each pair of states,
  the probability that one exchange at rate r = 0.25 makes it, times the design's outcome for that pair of types. The
  route is drawn in proportion to that mass with a fixed seed.

**Outcomes.** An outcome is a weighting over:
- type ids (the child joins that type);
- `parent` (the nearer parent's type);
- `lead` / `lag` (for two phases of one cycle, the child joins the phase ahead of, or behind, the other).

**The funnel.**
- Bytes 2032..4079 are read only by undesigned cells. They hold constant filler regions ('"', '#', '2'). A cell made
  of one of these bytes copies its head from six fixed positions (its landing pad), and the pad holds the head of a
  chosen state.
- Random cells then reach a designed state in 7.5–8.6 decoder steps on average.
- The first version had no funnel: every slot was a routing slot, and it took 47 steps. On the lattice it stayed
  noise past turn 200 and its sea never formed.

**Colour.** A type's tail bytes are the four bytes whose palette colours are nearest a chosen RGB (land olive, sea
three blues, one per phase, invader gold). The colour is a free design choice, not a side effect.

## 2. What froze, and what moved (screening, 128², 1500 turns, the page's gradients)

Liveliness is measured where the picture forms: in the rows from 60 % down (median probability 0.6–1). Above that,
every dictionary shows the same unsettled noise. The measure, **change**, is the share of cells whose 16 bytes differ
from 360 turns before (360 is a multiple of every period here). A cell resting on a cycle inside a static domain
counts as unchanged, so a mottle that cycles in place scores 0. The tag-based turnover (the attractor a cell is on,
phase-blind) and the wall density are recorded too. On this measure at 128²: Brotli 13 0.023 (tag turnover), Brotli 12
0.046, `ca-gray20c` 0.081, Swarm F 0.175.

**The plan as given froze.**
- The tested designs: closed Gray land, a deliberately open 3-cycle sea whose crossover children partly go to a
  fixed-point invader, and rock–paper–scissors between the types (sea erodes land, invader eats sea, land eats
  invader), with nucleation shares of 5, 20 and 50 % and variants with a 2-cycle invader, a 5-cycle sea and a second
  land.
- All of them were static in the settled part by turn ~500: change 0.000–0.01.
- Plain cyclic dominance between three closed Gray types (`x-rps3`) froze the same way.

The reasons are the mechanism results seen from the other side:
- **Lemma 1.** A uniform in-phase domain is invariant under mixing and settling, so an open sea that phase-locks
  never melts again.
- **Settling.** The bitwise majority restores the bits a flat wall's exchange moved, so walls between closed types do
  not advance where settling is strong.
- **Quenched hashing.** A given pair of contents always exchanges the same bits, so a wall between two fixed contexts
  is either always crossed or never.
- **The open sea is absorbed.** A crossover child that lands on a closed type's code is that type, whatever the
  routing says. An open sea whose states span the land's class therefore melts into land, which is what happened in
  the first design.

**What moved: cyclic dominance among the phases of one cycle.**
- With the `lead` rule, a child of two phases joins the phase ahead. Each phase then invades the one behind it, a
  rock–paper–scissors among the three phases of one type, and the phase domains chase each other.
- It moves only when the states are far apart. With the three states 4–6 bits apart, across three classes (`FAR3`),
  change stays at 0.22–0.26 at 128². With the states 2 bits apart in one class, the phases lock into one domain within
  a few hundred turns (change 0.00–0.07). The `lag` rule (the child joins the phase behind) froze even with the
  far states (change 0.000), an asymmetry not yet explained.
- Swarm search F's maroon, green and purple regions look like the three phases of its 3-cycle, with fronts that keep
  moving. A hypothesis, not tested here: Swarm F moves by the same mechanism, found by its search.

**A deviation from the plan.** The "open sea" ingredient became a *chasing* sea. By the closure index it is closed:
C(S, S) = 100 % for `ca-live-phases`, since every child lands on a phase of S. Its liveliness comes from phase
dominance, not from melting. Openness proper (children leaving the type) is used only to nucleate land in the sea.

## 3. The candidates

Every candidate is built by `node paper/experiments/design-live.mjs name=<id>`. The closure entries are on A / on B (%)
for a child of A crossed toward B, one exchange at r = 0.25, after one step of f. They come from the exact table and
agree with `closure.mjs` on the built files. Basins are for f alone on 20,000 random cells. Liveliness is block change
at 512², seed 1, at turns 1000 / 2000 / 3000, with seed 2 at 256² (turn 3000) in brackets. Shares are of the settled
part at turn 3000.

| candidate | design | closure | basins | block change | shares at 3000 |
|---|---|---|---|---|---|
| **Three phases chasing** `ca-live-phases` | one far 3-cycle (states 4–6 bits apart), `lead` | S×S 100 / – | S 100 % (7.5 steps) | **0.23 / 0.24 / 0.24 (0.23)** | S 100 % |
| Archipelago `ca-live-archipelago` | chasing sea + Gray land; 30 % of sea crossovers to land; coast ½ sea, ½ nearer parent | S×S 90.5; S×L 81/19; L×S 67/33 | S 94 %, L 6 % | 0.16 / 0.02 / 0.01 (0.00) | S 46, L 54 % |
| Coast `ca-live-coast` | as archipelago, 10 % nucleation, coast to the nearer parent | S×S 93; S×L 80/20; L×S 76/24 | S 94 %, L 6 % | 0.13 / 0.02 / 0.01 (0.00) | S 41, L 59 % |
| Reef `ca-live-reef` | archipelago with 10 % nucleation + fixed point I: I eats land, sea eats I | S×S 93; L×S 61/34; I×L 52/25; I×S 44/49 | S 91, L 6, I 3 % | 0.18 / 0.05 / 0.02 (0.02) | S 42, L 58, I 0 % |
| Lagoon `ca-live-lagoon` | near 5-cycle sea (`lead`), Gray land the sea erodes, fixed point that eats the sea and is eaten by land | S×S 89; L×S 57/35; I×S 67/12; I×L 51/48 | S 72, L 22, I 6 % | 0.11 / 0.10 / 0.10 (0.06) | L 48, S 29, I 23 % |
| *Swarm search F* (reference) | searched | 3-cycle 33–52 % | 3-cycle 100 % | 0.22 / 0.37 / 0.44 (0.51) | one 3-cycle |
| *Twenty Gray 8-cycles* (reference) | designed, all closed | 100 % | 20 × ~5 % | 0.16 / 0.13 / 0.06 (0.03) | mottle |

**What the pictures show** (`../figures/redesign/sheet.png`, rows in the table's order, columns turns 200 / 1000 / 3000):
- **Three phases chasing.** Rotating spiral waves in three blues fill the middle columns, where mixing is strongest.
  Arms are 10–20 cells wide and keep turning to turn 3000. The low-mixing edges and the bottom rows are a fine phase
  speckle. It is the only candidate whose liveliness does not decay: 0.23–0.24 at every checkpoint, on both seeds and
  both sizes.
- **Swarm F** (512², seed 1). It shows the same thing in maroon, green and purple: rotating spirals of three phase
  domains with thin melt lines between them. That supports the reading in section 2.
- **Archipelago and coast.** By turn 1000 the land (olive) has nucleated in the mixing columns and grown into one
  large continent filling the middle. The sea's spirals survive only in the speckled edge columns. After turn 2000
  nothing moves (block change ≤ 0.02).
- **Reef.** The same. The fixed point is gone by turn 3000.
- **Lagoon.** A static gold block (the fixed point) sits in the middle, flanked by sea speckle and land. The 0.10 is
  speckle at the edges, not moving fronts.

Screening of the mixtures at 128² with 3000 turns tried nucleation at 3, 10 and 20 % and erosion at 75 and 100 %,
with a Gray or a fixed-point land. It found no setting that keeps both types and keeps moving. Either the land is
eroded away and the lattice is one chasing sea (which then freezes too at 128², too small to hold a spiral core), or
the land wins the mixing columns and freezes.

## 4. Recommendation

**Three phases chasing (`ca-live-phases`)** is the only candidate that meets the brief's core requirement: fronts
still moving at turn 3000, at a steady rate, on both seeds. It is also the cleanest for the paper:
- one attractor and one rule ("a child of two phases joins the phase ahead");
- the closure index says it is closed, so it holds domains;
- the cyclic dominance among its own phases explains why the fronts never stop;
- it reproduces by construction what Swarm search F found by search.

Its weaknesses:
- one type, so no "land, sea, sky" story;
- the edges and the bottom are a speckle;
- the sky is magenta, from the filler '"'.

The mixtures (archipelago, coast, reef, lagoon) look like the brief on paper (islands nucleating in a moving sea) and
for the first ~1000 turns on the lattice. All of them then lock into a static map, so as defaults they would repeat
the Gray mottle's problem more slowly.

**Next steps, if the phases picture is liked:**
- choose the three phase colours and the filler byte for the sky (for example '3', navy);
- try a 3-cycle whose phases differ in more bits, or two chasing seas of different periods side by side;
- the open question is how to add land that is itself eroded by the spirals rather than pinning them.

## 5. Caveats

- **The measure is crude.** Change is a 360-turn content difference in the lower 40 % of the frame. It cannot tell
  moving fronts from a wall that jitters in place, and it would count a period-7 cycle as always changing (none of the
  five candidates has one). The pictures decide; the numbers only rule out freezing.
- **The PNGs are raw frames.** They use the page's colouring (the wasm renderer, byte palette, stretch around the
  previous frame's mean) without the page's render buffer and sharpening. On the page the cycles are blended over
  turns, so the three phases of the sea look less speckled and more like smooth colour fields.
- **Few seeds.** One seed at 512² and one more at 256², all with quenched hashing and the default rotating swap order.
  Other settings (uniform sliders, salted hashes) were not tried.
- **The sky.** The unsettled top of the frame takes its colour from the filler bytes ('"' is magenta), which is not
  pretty. Changing the filler to '3' (dark navy, pads at 3263–3268) would need re-runs; not done.
- **Leaking classes.** The routing is by expected parentage of single crossovers. Settling's three-parent majority is
  not modelled, and a child that lands on another type's state code goes there whatever the design says. So the
  realised closure differs from the design's intent. For example, in the reef the fixed point keeps 52 % of its
  crossovers with land instead of taking all of them, because land-class children are land. `closure.mjs` on the
  built dictionaries (`../data/redesign/closure/`) agrees with the exact table of `design-live.mjs` to within a point.
- **Swarm F.** The claim that Swarm F moves by phase dominance is a reading of its pictures; checking it needs the
  closure table of its 3-cycle split by phase.
