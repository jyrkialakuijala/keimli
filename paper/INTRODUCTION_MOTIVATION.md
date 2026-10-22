# Motivation: a draft of the article's opening

2026-10-21. Written from the author's framing (`MOTIVATION.md`), from what
the prototype has shown so far (`results/README.md` and the notes it
indexes), and from the related-work map (`RELATED_WORK.md`). Citation
keys are those of `references.bib`; a key in brackets is a claim the
cited work supports, a claim marked *shown* has a table behind it, and a
claim marked *to show* does not yet. Nothing here should survive into the
article that the experiments cannot carry.

## 1. Two kinds of artificial life, and the gap between them

Artificial life has grown along two lines that rarely meet.

The first line runs programs. In Core War [dewdney1984] two warriors
written in Redcode share one circular memory and overwrite each other;
in Tierra [ray1991] and Avida [adami1994, lenski2003] self-copying
programs compete for memory and processor time, and parasites,
hyper-parasites, immunity and arms races appear without being designed.
Later substrates keep the same premise, that memory is at once the
organism and the world and that instructions act on instructions:
Amoeba [pargellis2001], Squirm3 [hutton2002], the Movable Feast Machine
[ackley2011] and, most recently, the finding that self-replicators arise
unbidden in random populations of Brainfuck-like programs
[agueraYarcas2024]. These systems are the richest we have. Their price is
that they are general computation. A configuration's future is not
available except by running it; the halting problem is in the way of any
general statement; the behaviour of a program is, in the worst case,
exponential in its length to enumerate; and no invariant is conserved
that an observer could follow. The phenomena are easy to see and hard to
explain, and the explanations that exist are narratives of particular
runs.

The second line runs rules. The Game of Life, the elementary and
two-dimensional automata of Wolfram [wolfram1984, wolfram2002], Langton's
λ-parameterised rule space [langton1990], Vichniac's voting rules
[vichniac1984], lattice gases and reaction-diffusion systems are maps of
a few bits to one bit, the same everywhere. They are tractable: one can
measure, perturb, classify and sometimes prove, as the edge-of-chaos
literature and its critique show [packard1988, mitchell1993,
crutchfield1993, wuensche1999, shalizi2006]. But the phenomena are those
of pattern formation, domain growth and phase transitions
[bray1994, oliveira1992, toom1980, gacs2001], and both things a running program does are plain in them: the rule's
effect on entropy is simple and transparent, and there is no
computation. In a population of programs both are present and
entangled: the subtler, library-shaped, position-dependent entropy
reduction of running a program, and the finesse of computation itself,
loops, self-reference, universality. Two sources of opportunity, and no
way to tell which phenomenon draws on which.

The gap between the lines is the subject of this article. We ask whether
there is a system that runs programs in the sense that matters for the
phenomena, and is a rule in the sense that matters for the analysis.

## 2. A decompressor as the rule

Our proposal is to make the local rule a decompressor. Every cell of a
lattice holds 128 bits. Once a turn, each cell's bits are read, from the
first to the last, as the commands of a Brotli-like stream [rfc7932,
alakuijala2019]: a header that selects a window of a shared dictionary,
then insert-and-copy commands with distances taken from a short ring or
given explicitly, and the dictionary copies passed through Brotli's word
transforms. The decoded 16 bytes replace the cell. The cell is thus a
program, the dictionary its library, and the lattice a population of
programs that are run, every one of them, every turn.

What this keeps of computational life is that the content of a cell is
code that determines its own successor through a non-trivial interpreter.
What it drops is everything that makes computation hard. The decoder
reads each input bit once and never reads its own output; it has no
loop, no address arithmetic on its memory, no halting question. One turn
of one cell costs a number of decoder steps linear in the cell's size,
whatever the cell holds, and the map from a cell to its successor is a
fixed-depth function of the dictionary. That map can be sampled,
enumerated and inverted. We have done so: for the reference dictionary
the decoder's output has an entropy of at most 93.5 bits over random
inputs, has no fixed points, and sends every random cell onto a single
3-cycle within 35 turns (*shown*, `results/decoder-map.md`,
`data/decoder-map/cycles.md`); shuffling the dictionary's bytes turns that
3-cycle into cycles of 29 or 23 or three competing ones, so the attractor
structure is a property of the dictionary's byte order that a census can
read off (*shown*, `results/ablation-structure.md`). More than that: the
attractor structure can be written down in advance. By placing in the
dictionary the words that a cell's own head points at, we have built
dictionaries whose cells walk Gray-coded cycles of eight states two bits
apart, for three to thirty-two coexisting species and for cycle lengths
from five to twelve, and the lattice behaves as a clock model of as many
species (*shown*, `results/design-gray3.md`). No system of the first line
allows its attractors to be constructed; no system of the second line has
attractors that are programs.

The analogy that guides the choice of a decompressor is one that the
measurement of complexity already lives by. The complexity of real
phenomena, of a genome, an electroencephalogram or a text, is in practice
measured by Lempel-Ziv complexity [ziv1977, kaspar1987] and by
compression distances [cilibrasi2005], not by Kolmogorov complexity,
because the latter is uncomputable and the former is a linear-time,
program-free proxy that is good enough for the purpose [zenil2015,
chaitin2012]. A decompressor is the operational content of that proxy:
the part of "running a program" that can be done in one pass. We place it
inside the dynamics for the same reason the measurement community placed
it inside the measure.

## 3. Managing the entropy, and varying it across the image

A decompressor by itself only repeats. A cell decodes, its output decodes
again, and after a short transient the cell is on a cycle of the
dictionary's map; the lattice is then a field of independent clocks, and
nothing spatial happens. The method we propose is to manage the entropy
around that repetition from outside, with two stages that are each a
classical automaton in their own right. A mixing stage lets neighbours
trade bits: at every position where two neighbouring cells differ, the
bits are exchanged with a probability p, a uniform crossover
[syswerda1989, spears1991] applied by a cellular genetic algorithm
without a fitness [alba2002, alba2008], which raises the entropy of a
cell by giving it its neighbours' bits. A settling stage smooths every
bit plane of the lattice with a majority filter, a voting rule in
Vichniac's sense [vichniac1984, oliveira1992], which lowers the entropy
by making neighbours agree. The decoder then runs inside an entropy
budget that the experimenter sets, and the budget is a parameter of the
experiment, not of the rule.

Both sides of the budget are set per position in the image. The trading
probability runs as a gradient across the columns, the smoothing
probability as a gradient down the rows, so that one lattice holds the
whole two-parameter range at once, entropy supply along one axis and
entropy removal along the other. The picture then shows, in one frame,
the frozen regime, the ordered one, the noisy one and the fronts between
them, and the same dictionary can be read in all its regimes without a
parameter sweep: the frame is the sweep. This is also what lets one judge
the full range of a rule set after a few adjustments of the budget rather
than after a search over rules. It has a control built in: the flat twin,
a second lattice run from the same start with one point of the frame's
parameters everywhere, shows what any one point of the frame does on its
own, and the uniform-parameter runs of the article are the same control
done systematically (*shown* for the median axis: a sharp transition
between a granular phase of mostly transient cells and an ordered
one-phase state, between smoothing probabilities 0.3 and 0.5 under the
page's hashing, `results/ablation-scan.md`; *to show*: the two-parameter
diagram read from one frame against the diagram assembled from uniform
runs).

The decomposition into three stages makes a further thing possible that
neither line of artificial life offers: ablation. Each stage can be
switched off, and each pair run without the third. Doing so has already
corrected our own first hypothesis. We expected the decoder to be what
stops the mixing-and-settling pair from coarsening into one domain; in
fact the pair freezes by itself under the quenched hashing the page uses,
and coarsens as about t^⅓ when the hashing is annealed, so the finite
domain size of the full system is pinning by the hash, a weak quenched
disorder in the sense of [sicilia2008], and what the decoder adds is the
oscillation of the cells on their cycle and the transient that brings a
cell back to it (*shown*, `results/ablation-main.md`). That the first
guess was wrong, and that an experiment could say so, is the point.

## 4. What the model is for

The purpose of the model is to separate the two sources: the subtle
entropy reduction of running a program, which the decompressor has in
full, from the finesse of computation itself, which it has not at all.
Phenomena that need only the first are the consequence of running any
program; phenomena that need the second are the ones to attribute to
computation. A program run on a cell is,
thermodynamically, a local entropy pump: it reduces the entropy of its
own memory and, in a mixing medium, raises it in the surroundings.
Whatever the decompressive automaton reproduces of Core War's and
Tierra's phenomenology is, by construction, of the second kind, because
the decoder cannot compute; and whatever it fails to reproduce under any
entropy budget is a candidate for the first kind.

The prototype gives the comparison both arms. Beside the decoders it
runs twenty-five emulated processors as rewriting rules, the Z80, 6502,
PDP-11, 68000, VAX and Redcode among them, either on single cells or as
persistent machines on every link between neighbouring cells, under the
same mixing and settling and the same gradients. The phenomena the
decoder already shows are cycles and species, the invasion of one species
by another with a rule for which wins (the species whose head is read in
fewer bits), the synchronisation of phase across a domain and the pinning
of phase boundaries, the coexistence of species in a mosaic and the
wetting layer one species forms between two others, and coarsening into
domains when a cell is rewritten together with the vote of its four
neighbours (*shown*, `results/design-gray3.md`, `results/codebook-vote.md`).
Which of these, and which of the processors' phenomena, need a processor
is the question the article's comparison table will answer (*to show*).
The model lacks two things the first line has, replication and
selection, and we do not claim them: a cell is rewritten, never copied,
and nothing is scored. That is deliberate. A phenomenon that appears
without either is one that replication and selection did not cause.

## 5. The claims, stated so that they can fail

1. A decompressor has not been used before as the update rule of a
   lattice. The nearest prior work compresses with automata
   [haukeli2012, macura2006, albury2019] or measures automata by
   compression [kaspar1987, cisneros2019, liao2021], and the closest
   construction, a bit string read as codons modulo a grammar, is
   Grammatical Evolution's genotype-to-phenotype map [ryan1998,
   oneill2001], used once per individual and never iterated on a lattice
   (`RELATED_WORK.md`; two forward-citation searches still owed).
2. The decoder's dynamics is tractable in a way a processor's is not: a
   turn is linear in the cell size, the map is a finite function whose
   image, fixed points and cycles are measured by sampling, and
   dictionaries with a prescribed attractor structure can be built
   (*shown*).
3. The entropy budget set by the two stages, and varied across the image,
   is what turns the field of clocks into a system with spatial
   phenomena, and one frame displays the regimes a uniform sweep would
   take many runs to map (*shown* for one axis, *to show* for the frame
   against the sweep).
4. The three-stage system reproduces a named list of the phenomena of
   computational life without computation, replication or selection, and
   fails to reproduce another named list, which the processor arm shows
   (*to show*).

## 6. Sentences to be careful with

- "O(n) against O(c^n)" should be said as: one turn of a cell is linear
  in the cell's size for any content, while deciding what a Core War or
  Tierra program will do is undecidable in general and, when it can be
  done, exponential in the program's length. The second half is a
  statement about analysis, not about the cost of one step, which is
  constant in both.
- The decoder is Brotli-like (dictionary copies with transforms), not
  Lempel-Ziv 1977; the LZ analogy is about the class, not the format.
- "Easier to analyse" must be backed by what was analysed: the output
  entropy bound, the attractor census, the designed cycles, the
  ablations. It is not a promise.
- The hashing that decides the trades and the votes is a function of the
  neighbouring bits with no random source, so the system is a
  deterministic automaton and p is a fraction of contexts, not a drawn
  probability; the annealed runs are the control for that choice, and
  the article must say which runs are which.
- No replication, no selection, no fitness: on the first page, before a
  referee says it.
