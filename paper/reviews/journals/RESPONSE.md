# Response to the editors' concerns: experiments run on 2026-10-21

Started 13:56, finished 18:30 (four and a half hours of the eight budgeted). Each row is one concern from SYNTHESIS.md (journal editors) or
../team/SYNTHESIS.md (internal panel), with the experiment that addresses it, where the result is, and its status. The
results are in ../../results/; the raw data, with a provenance stamp in every output, in ../../data/.

| # | concern (who raised it) | what was done | result | status |
|---|---|---|---|---|
| 1 | No provenance in outputs (all) | `experiments/provenance.mjs` (script hash, argv, commit and dirty flag, wasm hash, date) added to every new and updated script | every new output carries it | done |
| 2 | Fixed swap order in the replicator and species scripts (panel) | `replicators.mjs`, `species-run.mjs` and `ablation.mjs` default to the page's rotating order; old runs reproducible with `order=fixed` | | done |
| 3 | Censored medians (panel; Scientific Reports, BioSystems) | `replicators-summary2.mjs`: Kaplan–Meier medians over seeds, censored at the last turn, with 95 % bootstrap intervals | | done; rerun in progress |
| 4 | The period detector misses long cycles (panel) | detector up to 64 by default (any length via `kmax`), the full period confirmed | | done |
| 5 | Replicator Monte Carlo on the defective pipeline (all) | `replicators-v2.sh` and `-v2b.sh`: 9 dictionaries × 2 settings × 128² and 256², 20 seeds; 3 dictionaries at 512² × 10 seeds; Z80, 6502 and Redcode at 5 seeds | results/replicators-v2.md: rare fixed points take the frame in 99 of 100 seeds against 93–100 % basin cycles; takeover grows 1.35–1.6× for a fourfold side (nucleation, not a front); the first batch's front-speed claim withdrawn | done (CPU rows pending) |
| 6 | Biased correlation length (panel; PRE, Chaos, Physica D) | `ablation.mjs` also records the connected correlation (each bit plane's bias subtracted); `ablation-summary.mjs` gives the connected ξ; `ablation-v2.sh` reruns the stage conditions, 5 seeds | results/ablation-v2.md: the old ξ ≈ 60 was plane bias; connected lengths 10–46 cells with the decoder, 5–35 without (turn salting doubles them) | done |
| 7 | The page's one-thread engine overwrites the vote snapshot (panel) | influence measured before the snapshot copy, as in band.js | | done |
| 8 | Formal definition of the automaton (JCA, Natural Computing, PRE) | ../../DEFINITION.md: state, neighbourhoods, the four phases, settling, rewrite, determinism, period 4, 2 × 2-block translation invariance; three lemmas | Lemma 1 checked on the module (test/lemma.test.mjs) | done |
| 9 | The "image ≤ 2^93.5" error and the first-step bound (panel; Natural Computing) | Lemma 3: H(f(U)) ≤ E[bits read] by the stopping-time identity; the image-size claim withdrawn | 93.5 bits for the decoder; 68–98 bits for look-and-say by base | done |
| 10 | Mechanism of "the medium, not the basin, picks the winner" (every editor) | closure index (`closure.mjs`), droplets and whole-lattice domains (`droplets.mjs`), frame maps (`frame-mechanism.mjs`) over 6 dictionaries | results/mechanism.md: closed types hold domains (10 of 10), open ones melt (3 of 3), r = 0.79 over 15 types; on the frame the closed fixed point nucleates in the melt that mixing makes of the open cycle; figures mechanism-frame.png, mechanism-closure.png | done |
| 11 | Heredity: are mutants copied? (ALife, BioSystems, Royal Society Interface) | `heredity.mjs`: every one-bit mutant of every state of the main types, map alone and as 3 × 3 patches on the lattice | results/mechanism.md §5: repaired 73–100 %, converted 0–27 %, new attractor 0 except 1.6 % for one fixed point; limited heredity quantified | done |
| 12 | Entropy measures that can be trusted (Entropy, Complex Systems) | calibration on rules of exactly known loss (rules 150, 170, 60, 90) | results/entropy-manipulators.md: collision entropy exact, block entropy blind | done |
| 13 | Processor dose–response over instruction budgets (PNAS; panel action 9) | `dose.mjs`: six processors × budgets 1–256, single cells and joined pairs, against the decoder, look-and-say and rule 90 | results/dose-response.md: processors keep information and order locally; on joined pairs Redcode's imp takes over the lattice (6 % → 85 %), a fixed point | done (seed 1; more seeds owed) |
| 14 | Exact fixed points and 2-cycles, random-mapping null, dictionary shuffles (all) | `map-exact.mjs`, `map-null.mjs`, `map-shuffles.mjs` | results/map-spine.md: Swarm F has exactly 68,964,123 fixed points (15,693 families, mostly self-read literals; all checked on the wasm, and a sample checked independently), basins ≤ 2·10⁻⁶; ≥ 51 two-cycles (49 exact in a stated class); matched random maps lose about 1 bit per doubling and wander 170–350 steps, against the decoder's one 3-cycle in about 10, so the attractor structure is not explained by the contraction; F ranks first of 31 against byte shuffles and is typical against word shuffles, so the words carry the structure | done |
| 15 | "You built the replicators in" (anticipated, for constructed rules) | `replicase.mjs`: a factorial ablation of constructed replicase rules (copy mode, self-reference, trait, background map, protection, mutation, medium), 1,150 runs, seeds 1–5 | results/replicase-ablation.md: heredity needs verbatim copying of unread tape (1.00 against 0.00); spreading needs self-reference and protection from the background map; selection needs a heritable trait coupled to the copy rate (Δtrait +4.3); spontaneous emergence needs a background that keeps making new states (rule 90 yes, the decoder never); the page's default media sit above an error threshold (swap ≈ 0.01) and kill every constructed replicator | done |
| 16 | Look-and-say as a worked example | results/look-and-say.md | first-step bound, collapse, the unbounded comparison | done |
| 18 | Information dynamics: make "computation" measurable (Entropy, PNAS) | `infodyn.mjs`: per-bit storage, transfer from neighbouring cells, transfer from the adjacent bits, and the non-local rest (an upper bound on modification), for the decoder, look-and-say, rule 90 and five processors | results/infodyn.md: processors' memories mostly sit still (a bit's past explains nearly all of its 0.1–0.3 bits); the decoder and look-and-say rewrite the whole cell (77–100 % non-local when kept active) | done (plug-in, k = 3, seed 1) |
| 19 | Theorems for the Gray construction (Natural Computing) | ../../DEFINITION.md §4: pointer lemma, existence of the designed 8-cycle, and a proposition that every crossover or majority of a designed type's states returns to the type in one step | proves the measured self-closure of 100 %; stray attractors stay empirical | done |
| 20 | Finite-size series (PRE, Chaos) | `ablation-sizes.sh`: MSR and MS- at two parameter points, quenched and turn-salted, sizes 64–512, 3 seeds, 2,000 turns, connected correlations | results/finite-size.md: quenched freezing at a size-independent length; annealed coarsening limited by size; a uniform absorbing state at 64²–128² with the decoder | done (to 512²) |
| 21 | The BFF census (PNAS, BioSystems) | `bff.mjs`: BFF as in the paper's reference code (cubff bff_noheads; reproduces its regression log exactly), 8 soups, census of 12 evolved replicators plus the paper's Fig. 4 tape | results/bff-census.md: every replicator R makes (R, mirror R) a fixed point of the pair map in one step, for 256 of 256 partners; 80–85 % of random single-byte mutants breed true, and every change to a byte the loop never reads is inherited; the replicators sit on a large neutral set of fixed points, against Keimli's isolated attractors that repair their mutants | done (8 soups, no emergence rate claimed) |
| 17 | A harness defect found on the way: the instruction budget was ignored | fixed in tools/ca-harness.mjs; earlier runs used 256 instructions, which is what they asked for | | done |

## What the experiments change in the paper

1. **The mechanism for the central lattice result** (results/mechanism.md, DEFINITION.md §3–4).
   - A type holds a domain against the medium if its own crossovers stay on the type (the closure index).
   - Fixed points are closed trivially, designed Gray cycles provably; generic cycles are open.
   - Mixing melts the open types, and the closed ones nucleate in the melt. That is why the medium, not the basin,
     picks the winner, now with intervals over 100 seeds (results/replicators-v2.md).
2. **The map census** (results/map-spine.md).
   - Exactly 68,964,123 fixed points for the default dictionary, with tiny basins.
   - Random maps with the same contraction do not reproduce its attractor structure; the dictionary's words do.
3. **The processor arm** (results/dose-response.md, infodyn.md, bff-census.md).
   - Processors keep information and order the lattice locally; the decoder collapses it.
   - The processors' dominant replicators, Redcode's imp and BFF's copy loops, are fixed points of their interaction
     maps, like the decoder's.
   - What distinguishes BFF's: unread bytes copied verbatim, giving heredity. The constructed-rule ablation finds the
     same ingredient necessary (results/replicase-ablation.md).
4. **Retractions.**
   - The first batch's correlation lengths: plane bias.
   - Its front-speed takeover claim: censored medians.
   - The image-size bound.
   - "No fixed points".
   - The instruction budget of every harness run: always 256, now fixed.

## Still not addressed

- 1024² for the full system (only the medium alone was run at 1024²), and the time dependence ξ(t).
- Conditions under which a designed dictionary has no stray attractors (the theorem gives existence and closure).
- Lizier's separable information, to turn the non-local rest into modification proper.
- More seeds for the information dynamics and for the single-cell dose-response (seed 1 only).
- The BFF emergence rate (8 soups only).
- Rewriting the drafts on the claims table. This is writing, not experiment, and can start now.
