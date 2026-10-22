# Round 3: artificial-life and biology reviewer (claims and recommendations)

## 1. Claims table

| # | claim (where) | verdict | wording or experiment |
|---|---|---|---|
| 1 | No one has used a decompressor as a lattice rule (INTRODUCTION (i)) | KEEP | after the two forward-citation searches |
| 2 | "Nothing replicates, nothing is selected" (INTRODUCTION, INTRODUCTION_MOTIVATION §4/§6, RELATED_WORK) | DROP | "There is no copy instruction and no fitness function. The medium copies a type's identity into neighbours (trivial replication in Langton's 1984 sense, with limited heredity), and types are selected." |
| 3 | Replicators are fixed points or short cycles of the rewriting map (RESULTS_REPLICATORS) | KEEP-REWORDED | "Every self-maintaining content is a periodic point of the rewriting map. A replicator in von Neumann's and Langton's sense is more: it is a whole family of such points (its variants) that a copy operation propagates. Keimli has the first and not the second." |
| 4 | "They are not born; they are listed" | KEEP-REWORDED | "The isolated map's attractors can be listed (sampling, plus exact search: the mathematician finds at least 48 fixed points for F). On the lattice the medium also creates cycles with zero isolated basin, and changes effective basins 30 to 100×." |
| 5 | First appearance is never late; waiting time 1/(N·b) (replicators.md) | DROP the formula; NEEDS-EXPERIMENT | My implants: patches of 1 to 4 cells are erased, 16×16 persists. What has to appear is a supercritical nucleus. Measure the first *persistent* cluster against N (32 to 512), rotating order, with unbounded kmax for the texts |
| 6 | Takeover at front speed, "1.5× at 256²" | DROP | The median dropped censored seeds, which reverses the sign of the size effect (computation). The curves do not depend on size and grow logarithmically: creep (physicist) |
| 7 | The medium, not the basin, chooses the winner | KEEP-REWORDED; this is the best result | "Fixed-point domains have no internal walls (mathematician) and survive noise that melts cycle domains (my ps = 0.3 runs): selection on robustness, the 'survival of the flattest' of Wilke et al. 2001." Quantify with the matrix in recommendation 3 |
| 8 | Invasion with a rule for which species wins (design-gray3.md; INTRODUCTION (v)) | NEEDS-EXPERIMENT; reword | No type grew from rare in any setting I tested. Say "domain competition". Test whether "who wins" is transitive (A × C breeds B already). Use 10 seeds, not 1 |
| 9 | Species, coexistence, wetting | KEEP-REWORDED | "Attractor types". Coexistence under the frame is refuge in the gradient's bands, not ecological coexistence: no negative frequency dependence has been shown |
| 10 | Decoder phenomena come from entropy reduction; what fails is a candidate for computation (MOTIVATION, INTRODUCTION) | KEEP-REWORDED | Fix the reversed labels for the two kinds of phenomenon (contribution (v), MOTIVATION). State the professor's bounded-work against unbounded-work dichotomy, and add the heritable-variation split (see 4) |
| 11 | Late or complex replicators should not be credited to computation | NEEDS-EXPERIMENT | The BFF census. Until then, a hypothesis, with the author's co-authorship of the 2024 paper declared beside it |
| 12 | "Refuting a hypothesis in programs is new" | DROP | Avida has done this for decades (Lenski 2003, Wilke 2001) |
| 13 | "Local entropy pump" | DROP | The information theorist measured it: nothing rises "around" the cell at the rewrite. Use "sink" |
| 14 | Designed Gray dictionaries with prescribed cycles | KEEP | drop "no stray cycle" and "clock model" |
| 15 | The comparison with the processors | NEEDS-EXPERIMENT | the professor's dose-response over instruction budgets k |

## 2. Remaining disagreements

- **Professor.** His list of what trivial replication can produce reads "spread, invasion, coexistence, late takeover". I would strike "invasion" and "late takeover". My runs show no growth from rare, and the physicist's data show creep. The honest list is persistence, domain competition decided by robustness, refuge coexistence and slow coarsening. That list is weaker, and it is what the evidence supports.
- **Physicist** (droplets, dR/dt = v∞ − γ/R, as invasion fitness). I agree with the method, but under quenched hashing the walls are pinned: my 32×32 fixed-point patch stayed frozen for 300 turns, so v∞ = 0 and a selection coefficient is undefined. The droplet experiment must be run under annealed hashing as well, and pinning reported as the absence of selection.
- **Computation and physicist on "present from the start".** These do not conflict once lineage is considered. The fixed point is *detected* at turn 7 to 12, but single cells are erased, so the domain that wins at turn 1,000 is most likely not descended from those first cells; the type is re-created. Nothing in Keimli is a lineage. That argues *against* the word "species" and *for* the author's deflation: types recur, they do not descend.
- **Professor** ("Wolfram's equivalence conjecture says to expect universality"). This is speculative for a map that falls to log₂ 3 bits in about 30 steps (mathematician). I would only say "open".

## 3. Top five recommendations, ranked

1. **Rewrite the vocabulary and the central claim** (rows 2, 3, 7 to 11), declare the conflict of interest, and cite von Neumann, Langton 1984, Maynard Smith and Szathmáry 1995, Vasas et al. 2010, Wilke et al. 2001 and Price 1970. *Cost: two days, no computing.*
2. **Repair the replicator pipeline** (the computation reviewer's fixes 1 to 5): rotating order, provenance block, uncensored medians with 10 seeds, unbounded cycle detection, first persistent cluster against N. *Cost: one day of code, about 5 CPU-hours, about 3 hours wall-clock on the busy machine.*
3. **A competition matrix that explains the winners.** For each pair of attractor types, under quenched and annealed hashing, measure the critical nucleus, the velocity of a straight wall, droplet growth, and the half-life of a domain under noise. Test whether "who wins" is transitive, and test whether the matrix predicts the frame's winners in replicators.md. *Cost: two days, about 10 to 20 CPU-hours.*
4. **The heritable-bits test.** Plant variants (all designed dictionaries, 10 seeds, every bit position, three hashings) and count the self-maintaining, propagated contents per type. Expected: at most 5 bits, against about 8 bits per unused byte for BFF. *Cost: one day, a few CPU-hours.*
5. **The BFF census.** Measure how often a random tape is a replicator, compared with 1/(tapes × interactions); whether mutations outside the copy loop are inherited; and the no-mutation control, run in BFF and through Keimli's Brainfuck changer on cell pairs. Discuss arXiv:2607.01483. *Cost: one to two weeks, about 100 CPU-hours.* This is the only experiment that can make claim 11 true.

## 4. Verdict

Yes, there is a publishable paper, but not the one the drafts promise. **Paper A** is the decoder as a map (census, Rényi entropies and how fast the map contracts, designed dictionaries) plus selection without a fitness function: limited-heredity attractor types whose competition the medium decides through robustness and wall mobility, with variation always repaired. That fits an ALIFE conference full paper, or *Artificial Life* as a full article. Minimum work: recommendations 1 to 4, about three weeks. It needs no claim about computation beyond "what this bounded-work map with no copy operation already produces".

**Paper B** is "what computation adds", with the BFF census and the processor dose-response. It could go to *Artificial Life* or a broad journal if recommendation 5 shows BFF replicators are vanishingly rare among random tapes and inherit variation. Then the deflation applies to spread and competition, not to origin or evolution, and that is itself a clean, citable split. Without the census, Paper B is a hypothesis about the author's own earlier paper, and editors in my field would return it.
