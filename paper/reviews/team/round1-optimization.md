# Round 1: optimization and search (quality-diversity, objectives, overfitting)

Reviewer: optimization specialist. Read: the three search tools and the harness, the design scripts, results/README.md, design-vote.md, design-gray3.md (sections 5–10), ablation-structure.md, RESEARCH_PLAN.md §2/§4, PLAN_AMENDMENTS.md, the ALife postdoc's review, the draft PDF. Two small checks run (below); nothing written outside this file.

## 1. The project in my words

A lattice CA whose local rule is "trade bits, majority-smooth, then decode the cell against a shared dictionary". The dictionary is the rule's genome. Early dictionaries were found by black-box search on hand-made "interestingness" scores; later ones are constructed so the decoder, iterated on one cell, has a prescribed attractor set (Gray-coded 8-cycles). The article wants the decoder to separate "computation" from "local entropy reduction", and uses ablations, shuffle controls and attractor censuses to do it. From my side the question is what the searches actually optimised, and whether design replaces search.

## 2. Strengths

- **The turn from search to design is the right move.** The census (decode random cells until they repeat; count cycles, basins, transients, strays) is a cheap, exact, per-cell objective with a clear meaning. Design-gray3's rule, "no stray cycles first" (design-gray3.md l.292–297: 6–10 % strays never order, <0.5 % always does), is the kind of falsifiable design rule a search never gives you.
- The construction is honest about being constrained search: design-vote enumerates 16.8–30 M tails and keeps the ones that parse (design-vote.md, table: 1,536 / 0 / 0 / 4), and design-gray3 uses a randomised packing search (l.171–172). That is constraint satisfaction with an exact feasibility test. It is a principled alternative to the lattice scores.
- The author already admits that score and eye disagree (RESEARCH_PLAN l.32–36: modes 21→47 on one lineage that looks like one picture; the chosen default scored 14). He also cut H6 (PLAN_AMENDMENTS l.86–92).
- The swarm keeps neutral moves (`>=` acceptance), applies alphabet bijections as neutral operators and caps parents at two per score. These are sensible choices.

## 3. Concerns, ranked

1. **The search objective and what it found disagree, and the draft states both without connecting them.** The searches maximised the effective number of block regimes (ca-lattice-search l.215–223; ca-swarm l.339–360). Yet the census says "each of the searched dictionaries gives one dominant short cycle" (draft §1, results/README "H4"). So the diversity the score rewarded is not in the dictionary's map. It comes from the frame: the swap and median gradients sweep the parameters across the 128² harness, so the 8×8 block classes vary with position for any rule. My hypothesis: the score's top end measures transients and the gradient, not the rule. Test: re-score the menu with uniform parameters (gradients off). If the ranking collapses, the searched dictionaries are "found by a score" only in a weak sense, and the paper should say so.
2. **The two older searches have a broken RNG.** In ca-search.mjs l.17 and ca-lattice-search.mjs l.161, `seed = (seed*1103515245+12345) & 0x7fffffff` runs in doubles. The product exceeds 2^53, so precision is lost. I measured the result: **period 10,466, and seeds 1, 2, 3 and 7 all fall into the same cycle** (after 689 to 6,805 draws). The swarm's comment at l.281 admits this and fixes it only there. Codebook 1–9 and Brotli 1–15 (the swarm's starting stock, ca-swarm l.379) came from searches whose "different seeds" were one operator sequence replayed. The defect does not invalidate the dictionaries as objects. It does invalidate any statement about search reliability or about independent runs.
3. **One evaluation seed means a winner's curse.** Every candidate is judged on `seed: 11` (ca-lattice-search l.225, ca-swarm l.340), with quenched hashing, so the score is deterministic and the climber can fit seed-11 idiosyncrasies. My check (128², 200 turns, modes score without novelty, seeds 11 then 1–5):
   - Swarm F: 14.34 | 12.60 14.36 14.45 13.04 14.46 (robust)
   - Swarm G: **31.33** | 27.51 22.56 22.53 24.80 24.89 (seed 11 is 28 % above the held-out mean)
   - Swarm A: 31.14 | 40.11 33.80 23.73 23.07 25.82 (held-out CV ≈ 25 %)
   - Brotli 13: 19.70 | 18.19 15.83 20.13 17.33 23.07

   Score differences of a few units between menu dictionaries are inside seed noise. G's selection was partly seed fitting.
4. **The dictionaries were optimised for a rule that has since changed.** They were found at 64²/128², 200 turns, with the fixed phase order (the harness still defaults to `altOrder=false`, ca-harness l.433). The page now uses the rotating order, synchronous options and 512². Four files are also 4,400 bytes in search and 4,401 on the page. Any claim that F is "good" refers to an obsolete objective under an obsolete dynamics.
5. **Novelty is calibrated on one pair.** The 0.3–0.6 ramp rests on one visual judgement, A vs E = 0.34 (ca-swarm l.354–357). The references are the fixed menu, not the visited archive. And the swarm reseeds from every earlier best file (l.380), so the "six swarm results" are one lineage tree, not replicates.
6. **"Built, not searched" is slightly overstated** (draft l.78–79). The designs need packing searches and enumerations. The honest contrast is an exact, interpretable per-cell objective with feasibility constraints against a noisy, hand-windowed lattice objective. Say that; it is the stronger claim.

## 4. Questions for the other panelists

- Physics/CA: is the one dominant 3-cycle of F plus quenched hash pinning enough to explain the whole regime histogram the score rewarded? If so, concern 1 is settled.
- ALife: should the dictionary paper present the searches at all, or only as provenance ("human-selected from a hand-scored swarm", in the Picbreeder spirit)?
- Compression: is "no stray cycles, steep funnel" a property expressible in decoder terms (header geometry, reachable copy commands), so that the design objective could be derived rather than packed?
- Statistics: what seed count makes menu-level rankings meaningful, given CV ≈ 25 %?

## 5. What I will examine in depth

- Re-score the menu (searched, designed, texts) on held-out seeds, uniform versus gradient frame, and the current rotating order. Quantify the seed variance and the frame's contribution to the modes score. I will run only short jobs and propose the batch.
- Audit the design scripts' internal search (design-dict packing, design-vote enumeration) for objective, constraints and completeness. Is "no head fits" (nibble and 2-bit joinings) an exhaustive result or a sampled one?
- Check whether the census objective transfers to the lattice: rank correlation between census features (stray share, funnel at 8 steps, reading length) and lattice outcomes across the design-gray3 tables.
- Write a concrete QD redesign for the dictionary paper: MAP-Elites over census descriptors (number of cycles, period, stray share, transient), with lattice evaluation as a second, multi-seed stage.

What would change my mind on concern 1: modes-score rankings that survive uniform-parameter frames and five or more seeds with rank correlation ≥ 0.7.
