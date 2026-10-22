# Twelve journal editors: synthesis

2026-10-21. Twelve simulated handling editors each read the project (BRIEF.md, the drafts, results, the internal panel's
SYNTHESIS.md, the related-work map) and checked their journal's scope and rules on the web. The reports are beside
this file. Where a journal's own pages were blocked, the reports say which facts are unconfirmed.

## Verdicts

| journal | desk decision on the current drafts | score after the required work | the paper it wants |
|---|---|---|---|
| Entropy (MDPI) | invite resubmission | 8 | information loss of the decoder map, calibrated entropies, census, designed attractors |
| Artificial Life | invite resubmission | 7 (8 with a small BFF comparison) | designed attractors and a medium that chooses its self-maintaining types |
| Complex Systems | invite resubmission | 7 | decompression as a CA rule: census, designed cycles, domain competition |
| Journal of Cellular Automata | invite resubmission | 7 | decoders as CA rules, formally defined |
| BioSystems | return, invite resubmission | 7 (8 with a BFF census) | self-maintenance without copying: limited heredity, selection by the medium |
| Scientific Reports | reject, encourage resubmission | 7 | narrow map paper; every conclusion backed by statistics |
| Physical Review E | reject, invite narrower resubmission | 6 (7 with quantitative Ising mapping) | designable attractors and deterministic freezing, with finite-size scaling |
| Chaos | reject, invite resubmission | 6 (7–8 with scaling, damage spreading) | the decompressor as a local map of a coupled lattice |
| Physica D | return, invite resubmission | 6 | coupled-map-lattice paper with an analysis section |
| Natural Computing | reject, invite re-scoped paper | 6 (7 with proofs) | the decoder as a CA rule, with theorems |
| J. Royal Society Interface | reject, invite narrower resubmission | 5 (6–7 with BFF census or a biologist co-author) | the medium, not the basin, selects |
| PNAS | reject; 2 as it stands | 6 (7–8 if the processor and BFF results are clean) | the second paper: self-replicators as attractors, erasure versus computation |

No editor would send the current drafts to referees. Every one would invite a narrower paper.

## What all twelve require

1. **Rewrite on the internal panel's claims table.** Drop "rule systems compute nothing", "never reads its own output",
   "no fixed points", the 2^93.5 image bound and "the frame is the sweep". Move the computation-versus-entropy thesis
   to an outlook paragraph or a second paper. Declare the co-authorship of the 2024 Computational Life study.
2. **Fix the pipeline before any number is quoted.**
   - A provenance block in every output.
   - The rotating swap order in every script.
   - The page's single-thread snapshot bug.
   - Censoring-aware statistics with bootstrap intervals and at least 10–20 seeds at several sizes.
   - Connected (bias-subtracted) correlations.
   - An unbounded period detector.
   - Code and data archived with a DOI; the browser page is a companion, not the method.
3. **The map spine.**
   - An exact enumeration of the default dictionary's fixed points and 2-cycles.
   - A random-mapping null model.
   - Byte and word shuffles of the dictionary.
   - The entropy calibration on rules 60, 90 and 150 (welcomed by Entropy, Complex Systems and Chaos).
4. **The mechanism behind "the medium, not the basin, picks the winner"**, the result every editor singled out: droplet
   and noise experiments and a competition matrix.
5. **Cite and engage:** Langton 1984, Kaneko, Wuensche–Lesser, Schaper–Louis, Dingle, Knierim et al. 2026,
   Martin–Odlyzko–Wolfram 1984. Fix the zenil2015 citation; Complex Systems' managing editor is Zenil.

## What each kind of journal adds

- **Physics** (PRE, Chaos, Physica D): finite-size and time scaling, periodic boundaries, sizes 64–1024, a Glauber or
  majority-vote control in the same code, a front-velocity argument; a transition without finite-size scaling must be
  called a crossover.
- **CA and mathematics** (JCA, Natural Computing, Complex Systems): a formal definition of the automaton (states,
  neighbourhood, a global map of period 4 in time and non-uniform in space) and theorems: the Gray-cycle construction
  with conditions for stray cycles, fixed-point domains as fixed points of the lattice map, the first-step entropy bound.
- **Biology** (BioSystems, Royal Society Interface): a heredity experiment (are injected mutants repaired, dissolved or
  converted?), framing in genotype–phenotype terms (attractor frequency against complexity), a trimmed bibliography.
- **Broad** (PNAS): only the second paper, with the processor dose–response over instruction budgets of 1 to 256 against a
  random map of matched entropy loss, and a census of the BFF soup's attractors.

## Recommendation

**First paper: the map paper, at Artificial Life.** It scored 7–8. Its readers are the community whose phenomena the
thesis is about. It needs the common core only, with no scaling theory and no proofs. Fall-backs in order:
- **Complex Systems** (7; free open access; CA and algorithmic-complexity scope; the Wolfram 1983 calibration fits);
- **Entropy** (8 and fastest, but the venue carries less weight in this field);
- **Physical Review E**, if the scaling work is done.

A short ALIFE or AUTOMATA conference paper first would establish priority while the journal paper is reviewed.

**Second paper: computation versus entropy reduction**, aimed at PNAS or Artificial Life. It needs the processor
dose–response and the BFF census. An outside co-author from the BFF community would help both the work and its
reception (PNAS, Royal Society Interface).

**Effort for the first paper**, by the editors' estimates: 3–4 weeks of work and about 80–150 CPU-hours. Then 6–9 months
from submission to acceptance at Artificial Life.

## Titles proposed

- Decompressive Cellular Automata: Designed Attractors and a Medium That Chooses Its Self-Maintaining Types (Artificial Life)
- Decompression as a Cellular-Automaton Rule: Information Loss, Attractor Census and Designed Attractors of an LZ77 Decoder Lattice (Entropy)
- Decompression as a cellular-automaton rule: attractor census, designed cycles and domain competition on a lattice of LZ77 decoders (Complex Systems)
- Self-maintenance without copying: designed attractors, limited heredity and selection by the medium in a decompressive cellular automaton (BioSystems)
- The medium, not the basin, selects: attractor competition in a lattice of decompressing cells (Royal Society Interface)
- Self-replicators as attractors: separating erasure from computation in artificial life (PNAS, the second paper)
