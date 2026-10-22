# The motivation, as the author framed it (2026-10-21)

This is the argument the article's introduction should make. The author's
framing, written up with the references the bibliography already holds;
the claims marked *to show* are the ones the experiments have to carry.

## Two classes of artificial life

Artificial life divides into two kinds of system. **Computational life**
runs programs: Core War and its Redcode warriors [dewdney1984], Tierra
[ray1991], Avida [adami1994, lenski2003]. Memory is both the organism and
its environment, instructions rewrite instructions, and the phenomena are
rich: replicators, parasites and hyper-parasites, arms races, the growth of
complexity. The price is that the system is a general computation. To
know what a configuration does one must run it, worst-case behaviour is
exponential in the program's size (the author's O(c^n)), no useful
invariant is conserved, and the analysis of why a phenomenon appears is
as hard as the phenomenon itself. **Arithmetic life** runs rules: the
Game of Life and the cellular automata of [wolfram1984, wolfram2002,
langton1990], lattice gases, reaction-diffusion. The rule is a fixed, tiny
arithmetic map, the system is tractable (one can measure, perturb,
classify, prove), but the phenomena are the simpler ones of pattern
formation, and both things a running program does are plain in them:
the rule's effect on entropy is simple and transparent, and there is no
computation. In computational life both are present and entangled: the
subtler, library-shaped entropy reduction of running a program, and the
finesse of computation itself.

## The decompressive automaton sits between them

Keimli's rule is a decompressor: a cell's bits are read once, left to
right, as the commands of a Brotli-like stream against a shared
dictionary, and the output replaces the cell. That is a program being run
(the cell's content is the program, the dictionary its library), so the
phenomena of running code appear: the cycle a cell falls into, the species
that share a dictionary, the invasion of one species by another, the
transients, the dependence on where in the cell a bit sits. But the
decoder is not a general computation. It has no loop that reads its own
output, no address arithmetic, no halting question: it consumes each input
bit once and produces a bounded output, so one turn of a cell is linear in
the cell's size (the author's O(n)), and the map from a cell to its
successor is a fixed-depth function of the dictionary that can be
enumerated, inverted and counted. The model is **information-centric**: a
decoder is a map from bits to bytes whose every step is an act of copying
from a dictionary, and entropy and compressibility are the natural
observables of it, which the mixing and settling stages make explicit
(gene exchange raises entropy, the median lowers it, the rewrite moves it
from the cell into its neighbourhood).

## Why LZ rather than Kolmogorov

The analogy the model is built on is already the working practice of
complexity measurement. The complexity of real-life phenomena, from EEG
and DNA to the structure of a text, is in practice measured by
Lempel-Ziv complexity [ziv1977, kaspar1987] and by compression-based
distances [cilibrasi2005], not by Kolmogorov complexity, because the
latter is uncomputable and the former is a program-free, linear-time proxy
for it that is good enough [zenil2015, chaitin2012]. The decompressive
automaton makes the same move at the level of the dynamics: it keeps the
part of "running a program" that an LZ decoder is, and drops the part
that makes computation hard.

## What the model is for

The purpose is to tell the two sources apart: the subtle entropy
reduction of running a program, which the decompressor has in full,
from the finesse of computation itself (self-reference, loops,
universality), which it has not at all. The first is what any program
does: a program that reduces the entropy of its own cell while
raising it in the cells around it, a local entropy pump in a mixing
medium. Whatever the decompressive automaton reproduces of Core War's
and Tierra's phenomenology is, by construction, of the second kind, and
whatever it cannot reproduce is a candidate for the first. *To show*: a
list of the phenomena of computational life reproduced here (cycles and
species, invasion fronts and domains, the dependence of survival on the
dictionary, the synchronisation of phase across a domain, the coarsening
under the vote partner), measured with the entropy-centric observables
of the article, and the phenomena that need the CPU changers (the link
machines of the Z80, 68000, VAX and the rest) and do not appear with the
decoder, which is the comparison the page's CPU and decoder modes were
built to make.

## Notes for the writing

- The complexity claim should be stated precisely: one turn of one cell
  costs O(cell size) decoder steps, the dictionary lookup included, while
  deciding the behaviour of a Core War program is undecidable in general
  and exponential in practice; and the rewrite map of a given dictionary
  is a finite function whose cycle structure the designed dictionaries
  construct by hand (`results/design-gray3.md`), which no CPU changer
  allows.
- The thermodynamic sentence (local entropy reduction, surrounding
  entropy increase) is measurable here: `ablation.mjs` reports the byte
  entropy, the fraction of distinct cells and the spatial correlation
  per stage, and the stage ablations separate the pump (rewrite) from the
  medium (mixing, settling).
- The LZ analogy needs one sentence of care: Keimli's decoder is
  Brotli-like (dictionary copies with transforms), not Lempel-Ziv 1977
  proper; the point is the class, not the format.

## The method: a managed entropy budget, varied across the image (author, 2026-10-21)

The decompression on its own only repeats: a cell decodes, the output
decodes again, and the cell falls onto a cycle of the dictionary's map.
What we propose as the method is to manage the entropy around that
repetition rather than leave it to the rule. The mixing stage exchanges
bits between neighbours and raises the entropy of a cell; the settling
stage smooths every bit plane with a majority filter and lowers it. The
rewrite is then a decoder running inside an entropy budget set from
outside, and the budget is a parameter of the experiment, not of the
rule. Both sides of it are set per position in the image: the strength
of the smoothing as a gradient down the rows and, in the same way, the
probability with which neighbours trade bits (the mixing stage's uniform
crossover, each differing position exchanged with probability p) as a
gradient across the columns. One lattice then holds the whole
two-parameter range at once, entropy supply along one axis and entropy
removal along the other, from the frozen through the ordered to the
noisy regime, with the fronts between them visible in the picture. That
is why one run shows a larger variety of phenomena than a uniform setting
could, and why the same dictionary can be read off in all its regimes
without a parameter sweep: the frame is the sweep. It is also what lets
us judge the full potential of a rule set after a few adjustments of the
budget, instead of after a search over rules, and the flat twin on the
page is the control that shows one point of the frame on its own.

*To show*: the two-parameter phase diagram of a dictionary read from one
frame against the same diagram assembled from uniform runs
(`ablation.mjs` at fixed p against the page frame), the regimes and the
fronts between them named by the observables, and the same frame for a
CPU changer, where the budget plays the same role for a computation.
