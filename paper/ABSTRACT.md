# Abstract

2026-10-22, from SKETCH.md pass 20 with the sentence-9 correction and the scoping sentence; rewritten to stand on its
own, without "basin", "closed", "copier" or "family" (each said in plain words where it occurs). 250 words. The exact
census count is left to the body: the contrast is what the paper turns on, not the digits. The result of experiment
A9 (a decoder type with one copy command and a free tail; DESIGN_SENTENCES.md E10) is not in the abstract and is
added, as one sentence before the last, only if it is measured.

Lattices of programs produce self-replicators, but with a processor as the rule the attractors cannot be enumerated,
and with a classical cellular-automaton rule a cell holds too little to be a genome; we study a rule between the two:
a genome in each cell and countable attractors. The rule is a dictionary decompressor: each 128-bit cell is
read as a compressed stream and replaced by what it decodes to. We measure which attractors hold when neighbouring
cells exchange bits and settle by majority, and whether any pass on a change. They can be counted exactly: the map
alone sends a random cell to one cycle 99.995 % of the time, otherwise to one of tens of millions of fixed points.
Attractors can also be built in and proved to return to themselves under mixing and majority; that is what holds.
At partial settling the lattice goes, by nucleation, to a fixed point that random cells end on 0.3 % of the time
rather than the cycle they end on 99.7 % of the time (99 of 100 seeds). No one-bit variant of the winners survives:
they grow like crystals. A self-copying state's heritable information is the logarithm of how many of its variants still
copy, eight bits a byte copied verbatim: hundreds for BFF's loops, zero for the decoder's winner. The
decompressor's attractors can be counted, built in and watched taking over, and none inherits: what holds is
what the medium returns to itself, what inherits is what the map copies verbatim.
