# Research status, 2026-10-18

The plan is `../RESEARCH_PLAN.md`; the reviews are in `../reviews/`; the
amendments and the pre-registration are `../PLAN_AMENDMENTS.md`; the
bibliography with verification flags is `../references.bib` and the
related-work map with the prior-art search log is `../RELATED_WORK.md`
(started 2026-10-19: 16 entries verified, 19 partly, 33 from memory; no
prior use of a decoder as a lattice rule found). This file
is the index of what has been measured and what each hypothesis looks like
now. Every number below comes from a table under `../data/` produced by a
script under `../experiments/`; nothing is from a screenshot.

## Measured

| write-up | what | data |
|---|---|---|
| `decoder-map.md` | the Brotli-like decoder as a map: bit-exact JS reference verified against the wasm; consumed bits, output sources, entropies, reachability, controls; the codebook's exact image | `../data/decoder-map/` |
| `ablation-main.md` | the seven-condition ablation matrix at six uniform parameter points, quenched and annealed, 10 seeds, with the hash nulls; the decoder's attractor census | `../data/ablation/`, `../data/decoder-map/cycles.md` |
| `ablation-structure.md` | F against its byte shuffles, word shuffle and reversal at the lattice level; the 128/256/512 scaling check | same |
| `ablation-scan.md` | the median-probability scan 0.02 to 0.3 with all nulls, and the cycle null models | same |
| `codebook-vote.md` | the codebook cycles on isolated pairs break under any swap or median noise; coupled through the 4-neighbour vote partner they coarsen into domains (two page presets) | scratch run |
| `life-vote.md` | the author's synchronous 4-neighbour vote equals the 4-connected median at one pass; without swaps it is isotropic but leaves F's phases uncorrelated beyond 8 cells, while the designed dictionaries order under it | `../data/design/life/` |
| `swap-order.md` | the fixed phase order UD0 LR0 UD1 LR1 is anisotropic (ξy/ξx 1.37 for F at swap ½, median 1); turning the pattern by 90° each turn, the page's default from 2026-10-20, makes C(1) and C(8) equal along x and y and gives the most ordered lattice of six schemes; the article's runs must be repeated with it | `../data/design/order/` |
| `design-gray3.md` | dictionaries built, not searched: three to thirty-two Gray-coded 8-cycles (3 to 6 at the page's window, 7 to 32 with a 61 kB dictionary and a 16-bit window), the invasion tables, the lattice's phase mosaics and species coexistence, the reading-length rule for which species wins, the stray-cycle rule for whether the lattice orders at all, cycle lengths 5 to 12 (the longest cycle wins at equal reading length), and the pair modes (concatenated pairs designed at the 16-bit window; bit-interleaving impossible in printable bytes; pairs over-synchronise) | `../data/design/` |

Run counts: 67 + 9 decoder-map runs of 10⁶ cells, 9 + 6 attractor censuses,
1,192 lattice runs of 256 × 256 × 1,000 turns (plus 12 at 128 and 512).

## Hypotheses after today

- **H1 (decoder arrests coarsening).** Retracted under the pre-registered
  rule. The two-stage control freezes under the page's quenched hashing (ξ 3
  to 6 cells, size-independent) and coarsens as about t^⅓ when annealed; the
  three-stage system's finite domain length at median p = 1 is hash pinning
  (annealed runs go to one domain). What the decoder adds is an oscillation.
- **H4 (the decoder is many-to-one with an image of thousands).** Wrong as
  stated, as the compression review said: H(f(U)) ≤ 93.5 bits, no fixed
  points, the skeleton independent of the dictionary. The right
  dictionary-dependent quantity is the attractor census: F gives one 3-cycle
  reached from every cell in ≤ 35 turns; all searched dictionaries give one
  dominant short cycle; texts give long cycles and many attractors.
- **Q3 (structure of the dictionary, not only its alphabet).** Supported in
  a precise form: the dictionary's byte order sets the decoder's cycle
  (shuffling F's bytes turns the 3-cycle into 29-, 23- or three competing
  cycles) and the lattice inherits the cycle (d1 outside the seed band for
  every control). Whether it sets any spatial length is open.
- **Claim 2 (every frame a phase diagram).** The median axis has a sharp
  transition between a granular phase (ξ = 0.5, 95 % distinct cells, cells
  mostly in transients) and an ordered one-phase state, between p = 0.3 and
  0.5 quenched and 0.2 and 0.3 annealed; no critical regime with a finite
  un-pinned length was found at the scan's resolution.
- **Null models.** Image-size-matched hash maps are idempotent and fail
  qualitatively. The decoder's own 3-cycle with instant collapse orders
  where the decoder stays granular; a random 3-cycle does not order. The
  decoder's ten-turn transient and the plane-sharing geometry of its cycle
  states are the two properties that matter.
- **H5** demoted to the activity figure; **H6** cut; **H7** moved to the
  dictionary paper (`PLAN_AMENDMENTS.md`).
- **Design (post-hoc, 2026-10-18 evening).** The decoder's attractor
  structure can be written down: `ca-gray3c` has exactly three 8-cycles with
  consecutive states two bits apart, no stray cycle, a 5-turn transient and
  93 % of random cells on a cycle within 8 steps (F: 50 %). On the lattice it
  gives a q = 8 clock model (phase mosaics that coarsen annealed and pin
  quenched) and, at median p = 1, three coexisting species with a slow
  collective invasion by C and a B wetting layer between A and C. The
  steepness of the funnel (a tiny alphabet) is what the lattice selects on;
  the same cycles with a hill-climbed filler never take hold.

## Decisions needed from the author

1. Four dictionary files (`ca-brotli-1`, `ca-brotli-9`, `ca-brotli-13`,
   `ca-swarm-d`) lack a trailing newline, so the page decodes against 4,401
   bytes and the harness and searches against 4,400. Append the newline, or
   stop the build from normalising.
2. The page's quenched hashing makes its pictures hash-pinned. Keep it as the
   default (it is what makes the lattice a cellular automaton) and show both
   in the article, or change the default.
3. Which paper first: the physics paper now has three measurable results
   (attractor census, hash pinning against t^⅓ coarsening, the
   granular-to-ordered transition of relaxing oscillators) and needs the
   transition located; the dictionary paper has the census as its new
   backbone.

## Next experiments, in order

0. On the designed dictionaries (`design-gray3.md` sections 5 to 10): a
   census-scored packing search with one reading length and no stray cycle,
   so that many species coexist (the 24-species dictionary keeps seven in a
   quenched mosaic; the ones with 6 to 10 % stray cycles never order); a header
   geometry with cyclic dominance (A × B → C, B × C → A, C × A → B) and a
   look for spiral waves; longer Gray cycles.
1. Locate the transition: median p ∈ {0.32, 0.35, 0.38, 0.4, 0.45} at 128,
   256 and 512 cells, both hashings, 10 seeds; measure ξ at equal cycle
   phase and extend the correlation range past 64 cells; the order parameter
   should be the phase coherence (fraction of cells on the cycle and the
   distribution of their phases), not the Hamming C(r) alone.
2. A null with the decoder's cycle states and a tunable relaxation time (a
   cell off the cycle moves k bits towards its target state per turn) to
   separate the transient from the state geometry.
3. The attractor census for every dictionary in the manifest and for the
   pair variant (the two-turn map g₁ ∘ g₀), as the dictionary paper's table.
4. A periodic-boundary mode in the module, so that the bulk margin can go.
5. The scaling collapse for the annealed two-stage coarsening (three sizes,
   S(k, t)), to turn the t^⅓ band into a statement.

## Reproduction

```
node paper/experiments/decoder-map.mjs ca-swarm-f 4096 1000000 6 0 raw 1 --verify
paper/experiments/decoder-map-all.sh && node paper/experiments/decoder-map-summary.mjs
node paper/experiments/decoder-cycles.mjs 10000
node paper/experiments/codebook-image.mjs 128 1000000
paper/experiments/ablation-all.sh 28 && paper/experiments/ablation-extra.sh 28 && paper/experiments/ablation-scan.sh 28 && paper/experiments/ablation-cycle.sh 28
node paper/experiments/ablation-summary.mjs
node paper/experiments/design-dict.mjs name=ca-gray3c mode=const letters=123 && node paper/experiments/invasion.mjs design=paper/data/design/ca-gray3c.json
node paper/experiments/species-run.mjs design=paper/data/design/ca-gray3c.json pm=0.5 ps=1 salt=1 seed=1 n=256 turns=3000
```

Node v22.22.1, `build/keimli.wasm` built from the working tree of
2026-10-18 (lattice.wat with `salt_by_position`); the lattice batches took
about three hours on 28 of 32 cores.
