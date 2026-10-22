# The paper, outlined on the two axes

2026-10-22. The structure paper 1 is written to, replacing the framing of MOTIVATION.md and the two introductions
(kept as the record of the question first asked). Terms as in TERMS.md; definitions as in DEFINITION.md; every claim
names its results file; numbers are re-read from the v2 and three-pass data when those are in.

## Title candidates

- *Closed types and crystals: selection without heredity in a lattice whose rule is a decompressor*
- *What persists and what inherits: a dictionary decoder as a cellular-automaton rule*
- *Self-maintenance and heredity are two properties of a map, measured in a decompressive cellular automaton*

## The abstract

ABSTRACT.md, drawn from the ten sentences.

## The paper in ten sentences

SKETCH.md, pass 20, is the current ten-sentence version; the sections below follow it.

## The claim in one sentence

In a lattice where cells exchange bits and settle by majority, what persists is what is closed under its own
recombination, and what inherits is what is copied verbatim; a dictionary decoder as the local rule has the first
property in abundance and the second not at all, a byte-copying program has both, and a decoder can be designed to
have both.

## Figure 1 (the paper in one picture)

The plane of **self-maintenance** (a type closed or open under the medium; the measured threshold p\* on a continuous
axis once A4 is in) against **heritable information** (bits, log₂ of the copier's family). Points, each from a
results file:

| state | self-maintenance | heritable bits | file |
|---|---|---|---|
| Swarm F's 3-cycle, Brotli 12's and 13's cycles | open (dissolve in random phases at partial settling; hold in phase) | 0 | mechanism-v2 |
| the decoders' fixed points | closed | 0 | mechanism-v2, map-spine |
| the Gray designs | closed by proof | 0 | design-gray3, DEFINITION §4 |
| Core War's imp | closed | ≈ 1.6 | dose-response |
| BFF's evolved loops | closed (absorb any partner) | 384–432 | bff-census |
| the constructed replicase, by variant | closed | 0 to 8 × tape | replicase-ablation |
| the designed heritable decoder type (A9) | closed | 8k | to run |
| rule 90's configurations | open | everything (trivial) | entropy-manipulators |

## Sections

1. **Introduction.** The question (a decompressor as a rule; the dictionary as genome). The two properties this
   paper measures and why they are separate. What is claimed (the sentence above) and what is not (computation,
   exponents, emergence rates). The co-authorship of the 2024 study, declared.
2. **The automaton.** DEFINITION.md §1–2 in prose: cells, mixing, settling, rewriting, the frame. The page as the
   primary artifact; one paragraph of methods, the rest in the appendix.
3. **The map.** The exact census (68,964,123 fixed points, 15,693 families, one 3-cycle at 99.995 %); the structure
   is in the words (random-map null, byte and word shuffles); the entropy bound (Lemma 3) and what the collision
   entropy measures. Files: map-spine, decoder-map, entropy-manipulators, look-and-say.
4. **Designed attractors and closure.** The Gray construction; the closure proposition and the mutual-closure
   corollary; what a design can and cannot prescribe (strays, the winner among closed types). Files: design-gray3,
   design-vote, DEFINITION §4.
5. **Selection by the medium.** Lemma 1 (uniform domains are untouched) and what follows: closed types hold, open
   types dissolve at one settling pass and re-cohere at three; the medium creates closed types inside open domains
   and advances their walls (A1–A3, with intervals); the start does not matter (A2); the threshold p\* (A4); the
   conditional rule where no closed type is present (Swarm F). Share curves, no t₅₀, no exponent. Files:
   mechanism-v2, replicators-v2, closure-vs-survival.
6. **Copiers, replicators and crystals.** DEFINITION §6 in prose. The decoder's types are crystals: 0 of 2,944
   variants inherited. BFF's loops are replicators: 80–85 % inherited, by the bytes copied verbatim; the replicase
   ablation finds the same ingredient necessary; the imp is a copier without heredity. The designed heritable type
   (A9): one copy command, no processor, and the line is crossed; on the lattice, inheritance against settling
   strength. Figure 1 closes the section. Files: heredity (three-pass), bff-census, replicase-ablation, A9.
7. **Related work.** RELATED_WORK.md §0's table in prose: Wolfram and the loss of entropy; Kauffman and Wuensche's
   basins; Hopfield's prescribed attractors; Langton's trivial and non-trivial replication; von Neumann's tape;
   Maynard Smith and Szathmáry's limited and unlimited heredity; Eigen's threshold; Syswerda's crossover; Vichniac's
   voting rules; Munafo's one-frame sweep; decompression quines; the 2024 study and its 2026 follow-up.
8. **Discussion.** The question as first asked (computation against entropy reduction) and the answer the
   measurements gave (two other axes; no measurement of computation doing anything). What the frame is for. What a
   decoder as a rule is good for: countable, designable, and now heritable by construction. Open: the winner among
   closed types; stray-free designs; the origin of BFF's copiers (paper 2).
9. **Appendix.** Methods in full (passes, order, seeds, sizes, detectors, provenance); the lemmas' proofs; the
   census method; the tables.

## Figures

1. The plane (above).
2. The frame at turn 2,000 for Swarm F, with the (p, m) axes and the regimes labelled.
3. The census: families by size, the 3-cycle's basin, the random-map and shuffle nulls.
4. Closure: the 2 × 2 count with the Swarm F row and the two 95 % exceptions; p\* by type and median.
5. Invasion: the fixed point's share curves at 128², 256², 512² on the frame; the three-pass droplet tracks; the
   start-replacement arms.
6. Heredity: variant inheritance for the decoder's types, the imp, BFF and the designed type; on the lattice,
   inheritance against settling strength.

## What each claim rests on

| claim | status | file |
|---|---|---|
| the scoping sentence: a processor's attractors cannot be enumerated (universal rule; 9,400–16,384 types per 16,384 random cells), a classical CA's cell holds too little to be a genome (genomes there are many-cell patterns: Langton 1984, von Neumann 1966), the decoder's cell carries a genome and its map terminates in bounded time (≤ 128 bits read), so the census is exact | shown; the undecidability side needs its citation (Rice; Kari 1994 for 2D CA) | dose-response, map-spine, DEFINITION §3 |
| exact census; words carry the structure | shown, reproduced by three reviewers | map-spine |
| designed cycles are closed | proved | DEFINITION §4 |
| closed types hold, open ones dissolve (one pass) | shown, 10 of 10 and 4 of 4 | mechanism, closure-vs-survival |
| at three passes: disordered open domains dissolve and are filled, in-phase ones are invaded by a wall; the medium makes the seeds (n = 20) | shown, n = 5 | mechanism-v2 |
| nucleation, by a stated definition: R* = 5–8 cells and a constant wall speed against an ordered sea; spontaneous rare clusters at 10⁻⁶–10⁻⁴ per cell-turn in a disordered sea; nothing inside an in-phase domain | shown, n = 10 | nucleation |
| closure decides who holds, not who wins a wall (Brotli 12's second fixed point holds and loses) | shown | mechanism-v2 §5 |
| rare fixed points take the frame; establishment size-independent | shown, 99 of 100 seeds | replicators-v2 |
| the decoder's types inherit nothing | shown, 0 of 2,944 | heredity |
| BFF's loops inherit through the bytes they copy verbatim | shown, cubff-exact | bff-census, replicase-ablation |
| a decoder type can be given heredity by one copy command | to show | A9 |
| anything about computation | not claimed | |
