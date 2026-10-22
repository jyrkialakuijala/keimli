# 1 Introduction

*A first pencil draft, 2026-10-21. Citation keys are those of
`references.bib`. Figures are named by what they must show. Numbers are
those of the results notes and will be re-read from the final runs.*

Artificial life has two traditions, and they have little to say to each
other. One runs programs. In Core War, two warriors written in a small
assembly language share a circular memory and try to overwrite each
other [dewdney1984]; in Tierra and Avida, self-copying programs compete
for memory and processor time, and parasites, immunity and arms races
arise that nobody wrote [ray1991, adami1994, lenski2003]; in the most
recent work of this kind, self-replicators emerge unprompted from random
populations of tiny programs [agueraYarcas2024]. The phenomena are the
richest the field has. They are also the hardest to account for. A
population of programs is a general computation: what a configuration
will do is known only by running it, no quantity is conserved that an
observer could follow, and the explanation of why a parasite appeared
in one run is a story about that run. The other tradition runs rules.
The Game of Life, the elementary automata, the voting rules and the
reaction-diffusion systems apply the same map of a few bits to one bit
everywhere [wolfram1984, langton1990, vichniac1984]. They can be
measured, perturbed, classified and in places proved
[mitchell1993, crutchfield1993, shalizi2006], and their phenomena are
those of statistical physics: domains, fronts, coarsening and phase
transitions [bray1994, oliveira1992]. In them both things that a running
program does are plain: the rule's effect on entropy is simple and
transparent, a few bits in and one bit out, and there is no computation
at all. In a population of programs the same two things are present in
full and entangled. Running a program reduces the entropy of its memory
in a way that is subtler and more intricate than any Life-like rule
can, the output being shaped by a library, many-to-one in a structured
way, different at every position of the code; and, on top of that, the
program computes, with loops, self-reference and in principle
universality. Two sources of opportunity, and no way, in the first
tradition, to tell which of the phenomena draws on which.

This article proposes a system between the two, and a method for
reading it. The local rule is a decompressor. Each cell of a lattice
holds 128 bits; once a turn, every cell's bits are read from the first
to the last as the commands of a Brotli-like stream against a shared
dictionary, a header selecting a window of the dictionary and then
insert-and-copy commands with distances from a short ring or given
explicitly [rfc7932, alakuijala2019], and the sixteen decoded bytes
replace the cell. The cell is a program and the dictionary its library,
and the whole lattice is a population of programs that are all run
every turn. What this keeps from the first tradition is that a cell's
content is code which determines its own successor through a
non-trivial interpreter. What it drops is what makes computation hard.
The decoder reads every input bit once and never reads its own output;
it has no loop, no arithmetic on addresses and no halting question. A
turn of a cell is linear in the cell's size whatever the cell holds, and
the map from a cell to its successor is a fixed-depth function of the
dictionary that can be sampled, enumerated and inverted. We will show
that for the dictionaries used here the output of that map over random
inputs carries less than 94 bits of entropy, that it has no fixed points
and a small set of short cycles onto which every cell falls within a few
tens of turns, that shuffling the dictionary's bytes changes the cycles
in a way the census of attractors reads off, and that the cycles can be
prescribed: by placing in the dictionary the words that a cell's own
head points at, one builds dictionaries whose cells walk Gray-coded
cycles of eight states two bits apart, for as many types as the
dictionary has room for (Section 4, Figure 2).

The choice of a decompressor follows an analogy that the measurement of
complexity already lives by. The complexity of a genome, a recording or
a text is measured in practice by Lempel-Ziv complexity and by
compression distances [ziv1977, kaspar1987, cilibrasi2005], not by
Kolmogorov complexity, because the latter is uncomputable and the former
is a linear-time, program-free proxy good enough for the purpose
[zenil2015, chaitin2012]. A decompressor is the operational content of
that proxy, the part of running a program that can be done in a single
pass over the input. We put it inside the dynamics for the reason the
measurement community put it inside the measure.

A decompressor on its own only repeats. A cell decodes, the output
decodes again, and after a short transient the cell is on a cycle of the
dictionary's map; a lattice of such cells is a field of independent
clocks, and nothing spatial happens. The method we propose is to manage
the entropy around that repetition from outside, with two stages that
are each a classical automaton. A mixing stage lets neighbours trade
bits: wherever two adjacent cells differ, the bits are exchanged with a
probability p, the uniform crossover of genetic algorithms
[syswerda1989, spears1991] applied on a lattice without a fitness
[alba2008], which raises a cell's entropy by giving it its neighbours'
bits. A settling stage smooths every bit plane with a majority filter,
a voting rule in Vichniac's sense [vichniac1984], which lowers the
entropy by making neighbours agree. The decoder runs inside the entropy
budget that the two stages set, and the budget is a parameter of the
experiment, not of the rule.

Both sides of the budget are varied across the image. The trading
probability runs as a gradient across the columns and the smoothing
probability as a gradient down the rows, so that one lattice holds the
whole two-parameter range at once, entropy supply along one axis and
entropy removal along the other. One frame then shows the frozen, the
ordered and the noisy regime and the fronts between them, and a
dictionary can be read in all its regimes without a parameter sweep: the
frame is the sweep (Figure 1). The same frame, with one point's
parameters everywhere, is the control, and the uniform-parameter runs of
Section 5 are that control done systematically. Varying the budget in
space rather than in time also lets one judge the full range of a rule
set after a few adjustments, rather than after a search over rules,
which is how the dictionaries of this article were found and, later,
built.

The three-stage construction makes a kind of experiment possible that
neither tradition offers: ablation. Each stage can be switched off and
each pair run without the third. The first thing this did was to correct
our own first hypothesis. We expected the decoder to be what stops the
mixing and settling pair from coarsening into one domain. It is not: the
pair freezes on its own under the deterministic hashing that decides
the trades and the votes, and coarsens as a power law when that hashing
is annealed, so the finite domain size of the full system is pinning by
a weak quenched disorder [sicilia2008], and what the decoder contributes
is the oscillation of the cells on their cycle and the transient that
returns a perturbed cell to it (Section 5). That a hypothesis could be
put and refuted in a system of programs is, to our knowledge, new.

The purpose of all this is to separate the two sources. A decompressor
has the first in full: its effect on a cell's entropy is as subtle as a
program's, shaped by the dictionary, many-to-one in a structured way,
unequal across the positions of the cell, and it lowers the entropy of
its own memory while, in a mixing medium, raising it around, a local
entropy pump. It has the second not at all: it cannot loop, refer to
itself or compute. Whatever the decompressive automaton reproduces of
the phenomena of Core War and Tierra therefore draws on the entropy
reduction of running a program and not on computation; whatever it
fails to reproduce under any entropy budget is a candidate for the
finesse of computation itself. To make the comparison, the same lattice runs emulated
processors as its rewriting rule, the Z80, 6502, PDP-11, 68000, VAX and
Redcode among twenty-five, on single cells or as persistent machines on
every link between neighbours, under the same mixing, settling and
gradients (Section 6). Two things the first tradition has are absent
here on purpose: nothing replicates, a cell is rewritten and never
copied, and nothing is selected, no score is kept. A phenomenon that
appears without either is one that replication and selection did not
cause.

The contributions are these. (i) A lattice whose update rule is a
decompressor, which we believe has not been proposed before; the nearest
prior work compresses with automata [haukeli2012, macura2006] or
measures automata by compression [kaspar1987, cisneros2019], and the
closest construction, a bit string read as codons modulo a grammar
[ryan1998, oneill2001], is a genotype-to-phenotype map applied once per
individual, not an iterated spatial rule. (ii) An analysis of the
decoder as a map: its output entropy, its attractor census, the
dependence of the cycles on the dictionary's byte order, and
dictionaries with a prescribed attractor structure. (iii) The managed
entropy budget, varied across the image, as the method that turns a
field of clocks into a spatial system, with the one-frame phase diagram
and its uniform controls. (iv) The ablation of the three stages, the
retraction of the coarsening hypothesis and the identification of hash
pinning. (v) The comparison between the decoder and the processors on
the same lattice: cycles and types, invasion with a rule for which
type wins, phase synchronisation across domains, coexistence and
wetting layers, and coarsening under a neighbourhood vote, as phenomena
of the second kind; and the list of what needs a processor.

Section 2 defines the lattice, the three stages and the decoder to the
bit, and the deterministic hashing that makes the whole a cellular
automaton. Section 3 relates the construction to the two traditions and
to the compression and edge-of-chaos literatures. Section 4 analyses the
decoder as a map and presents the designed dictionaries. Section 5
reports the ablations, the uniform-parameter scans and the one-frame
diagram. Section 6 runs the processors and draws the comparison. Section
7 discusses what the separation of the two kinds of phenomenon does and
does not establish, and the limits of a model without replication. The
lattice, the decoders, the processors and every experiment of the
article run in the browser from a single page, which is the artifact.
