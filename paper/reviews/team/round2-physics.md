# Round 2: statistical physics and experimental design (methodology)

All checks are read-only on `paper/data/`. My scripts and eight small runs are in my scratchpad (`xi.mjs`, `slope.mjs`, `runs/`). Each run was 128², 400 turns, about 5 s.

## (a) Responses to the other panelists

**Computation (the 1/(N·b) argument).** Agreed, and the data make it stronger. Under the frame, Brotli 12's "rare" fixed point (isolated basin 0.26–0.34 %) already holds 3–10 % of cells at turn 50 and 16–25 % at turn 100, in all ten `*-lead.json` runs. Its effective basin on the lattice is therefore 30–100× the isolated one, and the medium creates it. "Present from the start below notice" is false. The isolated basin is the wrong variable for both appearance and growth (agreeing with mathematics, concern 6).

**Information (entropy cannot rise under deterministic rules).** Correct, and it goes further than the note says. "Annealed" hashing is also deterministic: the salt is a fixed function of the turn number (`ca-harness.mjs:36`). It injects zero bits of fine-grained entropy, and mutation is salted the same way. Both modes are deterministic maps. They differ in time-invariance, not in entropy. So "entropy budget" must mean a stated coarse-grained entropy (per-cell marginal, block, or conditional on the neighbourhood). Otherwise call it an "activity budget". I accept the information theorist's wording.

**Professor (excitable-media lineage).** Agreed on citations, but the mapping must be exact.
- F's medium is not Greenberg–Hastings. GH has a resting state, excitation and refractoriness, which gives waves.
- It is not the Fisch–Gravner–Griffeath cyclic CA either. There, k is eaten by k+1 above a threshold, which gives cyclic dominance and spirals.
- Here every on-cycle cell advances every turn: identical oscillators under a global clock. Only phase differences matter, so the class is Z₃ ordering of a phase field (3-state Potts/clock, Kaneko-style coupled-map synchronisation). Z₃ defects can form vortices, and those can be counted.

Two corrections for the professor's reduction proposal. First, the cycle-projection null already exists (`cycle3f`), and it fails: it orders at median p = 0.05, where the decoder stays granular (`ablation-scan.md` §2). So "F is a 3-state cyclic CA plus noise" is already refuted; the transient matters. Second, the Gray designs are not clock models at all (§b4).

**Mathematics / professor ("is it pinning by quenched disorder?").** I tested this. MS− at swap ½, median 1, salt modes 0/1/2/3, two seeds each:

| salt | C(8) | d1 at 400 |
|---|---|---|
| 0 (content only) | 0.327 | 0 |
| 2 (by position, true quenched disorder) | 0.331 | 0 |
| 1 (by turn) | 0.727 | 8 × 10⁻⁴ |
| 3 (both) | 0.740 | 1.0 × 10⁻³ |

Adding real spatial disorder changes nothing; breaking time-invariance unfreezes the system. So the freezing is that of a time-independent deterministic rule: blocked states of a zero-temperature vote (Vichniac; Spirin–Krapivsky–Redner). It is not disorder pinning in the Sicilia et al. sense. So: drop "quenched disorder" and the `sicilia2008` citation from the Introduction (`INTRODUCTION.md:114`), and write "freezing of the deterministic (time-invariant) rule".

**ALife.** Invasion fitness should be measured as droplet growth (E6b), which gives a selection coefficient in physical units.

## (b) Methodology deep dive

**b1. The unconnected correlation inflates ξ for every decoder run; the bias is decisive.** C(r) = ⟨m²⟩ + G(r). Using the saved `planeMag` (mean |m| over planes), C̃ = (C − M̄²)/(1 − M̄²) gives an *upper bound* on the connected length, since ⟨m²⟩ ≥ M̄². Reference MSR (swap ½, median 1, 256², 10 seeds, turn 1,000):

| condition | reported ξ | connected ξ ≤ | C(64) |
|---|---|---|---|
| MSR, quenched | 39.8 | 9.5 | 0.49 |
| MSR, annealed | 62.5 | 24.3 | 0.59 |
| MSR swap 0.05, quenched | 17.3 | 6.2 | 0.48 |
| MSR median 0.3, annealed (t 400 → 1,000) | 64 → 57.6 | 13.7 → 24.4 | 0.65 → 0.50 |
| −SR median 1 | 20.1 | 3.7 | 0.50 |
| MS− annealed (|m| ≈ 0.2) | 19.9 | 18.9 | 0.02 |

C(64) sits at about 0.49, right on the ½ threshold, so the reported ξ measures whether the magnetisation plateau lies above or below ½. Hence the seed band [19.5, 64] and the mod-3 dependence. The MS− numbers survive within 5 %. Every decoder ξ in `ablation-main.md` §3, `ablation-scan.md` §1 and `ablation-structure.md` must be recomputed. Most of the "one domain across the bulk" verdicts are not established. The quenched-vs-annealed ordering survives, at about 9.5 vs 24.

**b2. t^⅓ is not a stable exponent.** These are local slopes of the connected ξ (geometric mean of x and y), annealed MS−, 10 seeds:

| interval (turns) | 20–100 | 100–200 | 200–400 | 400–600 | 600–1,000 |
|---|---|---|---|---|---|
| z | 0.34–0.37 | 0.37 | 0.33 | 0.28 | 0.24 |
| d1 exponent | −0.77 to −0.69 | −0.66 | −0.61 | −0.58 | −0.49 |

At median p = ½ the slope falls from 0.44 to 0.32. The seed s.d. of ξ at turn 1,000 is only 0.2, so the drift is systematic, not noise. Candidates: finite size (|m| reaches 0.2), crossover, creep. d1 does not track 1/ξ (it should go as t^−z). "Consistent with Kawasaki" is unsupported: the non-conserved median acts every turn, so model A, with exponent ½, is the default expectation.

**b3. Transition.** With the connected measure, median 0.3 annealed is *coarsening* (13.7 → 24.4), not ordered. The "sharp jump from 1 to 64" rests on the biased ξ and on two scan points.

**b4. The Gray designs are not q = 8 clock models.** I computed the Hamming matrix of the `ca-gray3c` states from the design JSON. Row 0 is 0 2 4 2 4 6 4 2: phase offset +3 is 2 bits away and −3 is 6 bits. The metric is that of the 3-cube. Gray-coded states are cube vertices, and the plane-wise majority votes each Gray bit separately. The ordered "phase mosaic" is therefore three coupled Ising fields driven round a Hamiltonian cycle (Ashkin–Teller-like), with domain walls and no vortices. Drop "clock" and "Potts-like" (`design-gray3.md:84–99`, `INTRODUCTION_MOTIVATION.md:87`); do not expect spirals. A genuine Z₈ clock needs a Johnson (thermometer) code, 0000 → 0001 → 0011 → 0111 → 1111 → 1110 → 1100 → 1000, where Hamming distance equals cyclic distance.

**b5. Takeover is neither a front nor nucleation-limited growth; it is creep, and t₅₀ is ill-posed.** Shares of Brotli 12's fixed point under the frame (5 seeds):

| size | turn 200 | turn 400 | turn 800 | turn 1,600 | asymptote |
|---|---|---|---|---|---|
| 128² | 0.35–0.44 | 0.41–0.52 | 0.45–0.55 | 0.46–0.58 | 0.46–0.58 |
| 256² | 0.37–0.39 | 0.43–0.46 | 0.47–0.51 | 0.50–0.54 | 0.52–0.56 |

The curves are the same at both sizes. A front from an edge would take twice as long at 256²; these curves do not depend on size at all. After turn 200 the share grows by about 0.04 per doubling of t, which is logarithmic (interface creep or coarsening of an already space-filling mosaic). The asymptote straddles 0.5, so t₅₀ is a plateau-crossing statistic. Hence the "1.5×" and the 722–1,546 seed range.

## (c) Experimental plan

Costs are measured: about 1.3 × 10⁶ cell-turns/s for MS− and about 2.5 × 10⁵ for MSR, per core. Periodic boundaries are a prerequisite (`README` item 4). Every run uses the rotating order, records commit, wasm and dictionary SHA, and saves per-plane m_j and the phase-labelled field.

| # | experiment | sizes | seeds | turns | CPU-h | decides |
|---|---|---|---|---|---|---|
| E0 | Recompute every decoder ξ from saved rows (bound) and rerun the reference points with connected G(r), Z₃ phase coherence, on-cycle share | 256², 512² | 10 + 3 | 1,000 | 10 | whether any MSR length claim survives (b1) |
| E1 | Salt 0/1/2/3 × MS−, MSR at 3 points, plus 5 fixed nonzero salts as rule replicas | 256² | 10 | 1,000 | 9 | "deterministic freezing" vs "disorder pinning"; does the frozen ξ depend on the rule replica? |
| E2 | Coarsening: MS− with salt 3 and a true-RNG flag; median-only + noise (model A) and swaps-only (model B) as references; S(k,t), L(t) = 1/⟨k⟩, interface density | 256², 512², 1,024², 2,048² | 10, 10, 5, 3 | 10⁴ | 50 | the exponent with CI from scaling collapse over ≥ 1.5 decades; t^⅓ vs ½ vs log |
| E3 | Granular→ordered: median 0.25–0.5 in 9 steps, both salts, random vs ordered start (hysteresis); Binder U₄ of Z₃ coherence, susceptibility | 128², 256², 512² | 10, 10, 4 | 2,000 / 2,000 / 3,000 | 190 | location ± error, continuous vs first order, critical regime or not |
| E4 | Frame vs uniform: 8 × 8 uniform grid vs strips of the 512² frame; gradient power 1 and 0.2 | 256² uniform, 512² frame | 5 | 1,000 | 25 | "the frame is the sweep": strip observables within CIs of uniform; ξ vs gradient length |
| E5 | Gray cube vs Johnson-coded Z₈ cycle; defect and vortex counts | 256² | 10 | 3,000 | 6 | whether a clock-model claim can be made at all |
| E6a | Takeover size series under the frame and at the frame's winning uniform point; cluster count of the winner vs t | 64²–512², 1,024² | 10, 3 | 3,000 | 45 | front (t ∝ L) vs nucleation vs creep (size-free); growth law |
| E6b | Droplets: disk radius R ∈ {4, 8, 16, 32, 64} of type X in resident Y, 3 pairs | 256² | 5 | 1,000 | 6 | front velocity v∞ and line tension (dR/dt = v∞ − γ/R): invasion fitness |
| E7 | First appearance vs N with lattice-verified f-cycles (with computation, mathematics) | 48²–512² | 10 | 500 | 4 | whether the 1/(N·b_eff) model holds with the lattice's own b_eff |

Total about 345 CPU-hours, about 13 hours wall-clock on 28 cores; E3 dominates. Run order: E0, E1, E5 (cheap; each can kill a sentence), then E2, E6, E4, E3.

## Statistics checklist

1. Report means with bootstrap 95 % CIs and n; the 10th–90th percentile band of 10 seeds is a description, not a test.
2. Use no threshold-crossing statistic (ξ at C = ½, t₅₀) near a plateau. Use integral lengths (∫G), the first moment of S(k), and full curves with asymptotes.
3. Use connected correlations, or the phase field, never raw Hamming C.
4. Treat capped values (ξ = 64) as censored: report the share at the cap, take the range to L/4 or more, and use survival-style summaries.
5. Sample oscillator observables at equal phase, or average over one period.
6. Rule replicas (salts) and initial seeds are separate variance components.
7. Exponents come only from scaling collapse over at least three sizes, with local-slope plots and a fit window fixed in advance.
8. Pre-register E0–E6 decision rules before running, and mark which current numbers are exploratory (all design and replicator ones).
9. Provenance fields in every output.
10. Four dictionaries do not make a scaling law.
