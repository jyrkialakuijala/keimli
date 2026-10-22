# Round 1: artificial-life and biology reviewer


## 1. The project in my words

A lattice of 128-bit cells; each turn neighbours exchange bits (a bit-conserving crossover), bit planes are majority-voted, and each cell is replaced by what a Brotli-like decoder makes of it against a shared dictionary (or by an emulated CPU). The decoder is a contractive map (H(f(U)) ≤ 93.5 bits, decoder-map.md) with few short cycles and steep funnels, so every cell soon becomes one of a handful of attractor "species". The author argues that the replicators of computational life are fixed points or short cycles of a rewriting map, that their spread is the medium's work, and that late takeover is front propagation and not computation. The decoder is offered as the "entropy reduction without computation" control for Tierra-style and BFF-style systems.

## 2. Strengths

- A clear null model. The idea is good: a rewriting rule with the structured many-to-one character of running code, but no loops and no self-reference.
- Attractors are listed before anything runs: a census of 10⁶ cells, and designed dictionaries with prescribed Gray 8-cycles (3 to 32 of them). "They are not born; they are listed" is a strong and checkable line.
- replicators.md does the right kind of analysis. It separates first appearance (always at the first detectable turn, since every major basin is ≥ 0.26 % ≫ 1/N) from takeover (Brotli 12 fixed point: 50 % at turn 716 at 128² and 1,093 at 256²). It shows the medium picks the winner (a fixed point whose basin is 1/300 of the 3-cycle's wins under the frame).
- The ablation that retracted H1 (hash pinning), and the pre-registration habit.

## 3. Concerns, ranked

1. **"No replication, no selection" is false in the vocabulary of my field, and the paper's own results refute it.** Selection does not need a score. Differential persistence and spread of heritable types is selection (Price; it is also how Tierra works, with no explicit fitness). In replicators.md one type increases its copy number from below notice to 53 % by displacing the others. design-gray3.md states a rule for who wins ("the length of the all-X reading", "the longest cycle wins"). That rule is a fitness. Majority voting plus the funnel turns a neighbour into a copy, and that is replication by templating, as in crystal growth or prion conversion. The honest claim is: *no replication instruction and no imposed fitness*. As written (INTRODUCTION line ~133, INTRODUCTION_MOTIVATION §4/§6, RELATED_WORK §1), the first ALife referee will reject the paper on this sentence alone.
2. **The heredity of these types is limited, and the paper never says so.** Maynard Smith and Szathmáry's distinction between limited and unlimited heredity is the right frame. A perturbed Keimli cell returns to its attractor; the funnel erases variation. The number of possible types is fixed by the dictionary (3 to 32). So no Darwinian evolution, no error threshold and no quasispecies is possible. This is the attractor-replicator class of autocatalytic sets and compositional genomes (Vasas, Szathmáry and Santos 2010, "lack of evolvability"). BFF replicators copy *arbitrary* tape content, mutations included. That is unlimited heredity, and the reduction "replicator = fixed point of the map" throws it away. Being a fixed point is necessary for a replicator but not sufficient. The decoder control can account for the *spread* of a type but not for *evolution* among types.
3. **The analogy to Computational Life is unfair in its numbers as it stands.** Keimli's basins are huge because the map is massively contractive. BFF replicators are astronomically rare among random 64-byte tapes, and Agüera y Arcas et al. argue that they arise through self-modification and a pre-replicator phase, not by being drawn at random. The "present from the start, late takeover" argument carries over only if a BFF replicator's basin under the pair map is ≥ 1/N. That is the processor census, still "*to show*". Until it exists, the sentence "late appearance should not be celebrated" is an extrapolation from a system built to have big basins. Also cite and discuss arXiv:2607.01483 (it is in the bib but not in the text).
4. **Conflict of interest and framing.** The author is a co-author of agueraYarcas2024. That is fine, and even an asset, but the text must declare it and present this as a critique of his own earlier reading, not someone else's.
5. **The "first/second kind" labels flip between files.** INTRODUCTION defines kind one as entropy reduction and kind two as computation, then contribution (v) files cycles, invasion and the rest under the "second kind". MOTIVATION ("What the model is for") makes the same reversal. The central claim depends on these labels, so they must be consistent.
6. **Vocabulary.** "Species" means an attractor class with no lineage and no isolation; use "type" or "attractor class", or define "species" once. "Invasion" is acceptable if borrowed from invasion analysis (the rare type's growth rate), but then measure invasion fitness that way. "Life" in the README's tagline is acceptable for a demo but not for the article.
7. **Whether the separation can be identified.** "Whatever the decoder reproduces is not computation" holds only if the decoder's phenomena arise *for the same reasons* in the CPU systems. A matching phenomenology is not a shared mechanism; the argument needs a shared quantitative signature (funnel depth against takeover time) measured in both arms.

## 4. Questions for the other panelists

- Dynamical systems: is the decoder really "loop-free" when the stream wraps round the cell and copies from its own output (18.2 % of bytes)? That is bounded self-reference.
- Statistical physics: is the takeover (∝ basin^-½, 1.5× from 128² to 256²) front propagation or nucleation? Which exponent would tell them apart?
- Computation theory: under a fixed instruction budget, does the CPU arm differ *in kind* from the decoder? Both are finite maps on 2^128.

## 5. For the methodology round

- Recast the claims in the Maynard Smith and Szathmáry framework and check every use of replicator, selection, species and invasion across the drafts.
- Test whether any variant ever propagates. Seed a mutant state that is *off* the attractor, or on a rare cycle, into a domain and see whether it is copied by the medium or repaired.
- Measure fitness: invasion growth rate of a rare type in a resident domain, against funnel depth and reading length.
- Specify the processor and BFF census that would make concern 3 decisive: basin sizes of BFF self-replicators under the pairwise map, compared with 1/N.

What would change my mind on concern 1: a definition of replication and selection in the text under which the takeover in replicators.md does not count, defended against the Price equation.
