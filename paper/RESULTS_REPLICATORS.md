# 5.x Replicators are fixed points and short cycles

*A pencil draft of one results subsection, 2026-10-21, from the author's
point: the "replicators" born in computational life are, mathematically,
fixed points or short cycles of the rewriting map that recreate
themselves. Numbers from `results/decoder-map.md`,
`data/decoder-map/cycles.md`, `results/ablation-structure.md` and
`results/design-gray3.md`; items marked to show are not yet measured.*

The organisms of computational life are called replicators because a
program, run, leaves a copy of itself in memory. Seen as a dynamical
system the statement is simpler. The interpreter is a map from the
content of a memory to its content after a run; a program that recreates
itself is a fixed point of that map, and a program that recreates itself
after k runs, passing through k − 1 intermediate contents, is a point on
a k-cycle. Whatever else a replicator is, it is first an attractor of the
rewriting map, and the question of where replicators come from splits
into two: which attractors the map has, and how a population reaches
them.

The decompressive automaton answers the first question by census. The
rewriting map of a dictionary is a function on 2^128 cells that can be
sampled: a million random cells are decoded until each has returned to a
content already seen, and the cycles are counted (Section 4). Under the
reference dictionary every random cell reaches one 3-cycle within 35
turns, and there is no fixed point; each of the searched dictionaries
gives one dominant short cycle; natural texts give long cycles and many
competing attractors; the codebook decoders, made for the purpose, give
many short attractors with balanced basins; and the designed
dictionaries give exactly the 8-cycles they were built to give, three to
thirty-two of them, with consecutive states two bits apart and a
transient of about five turns (Table 3). In this system, then, the
replicators are known before the lattice runs, their number and length
are properties of the dictionary that a shuffle of its bytes changes,
and they can be prescribed. They are not born; they are listed.

The second question, how a population reaches them, is where the lattice
comes in, and the answer separates two things that computational life
shows together. A cell on a cycle recreates itself in place; it does not
spread. Spreading is the work of the medium: the mixing stage carries a
cycle state's bits into its neighbours, the settling stage makes
neighbours agree, and the decoder's funnel, the transient that returns a
perturbed cell to the cycle, turns an approximate copy into an exact one.
Under this budget a cycle takes over a domain, a domain's phase
synchronises, two cycles compete at a front with a rule for which wins
(the one whose head the decoder reads in fewer bits), and types
coexist in a mosaic or one wets the boundary between two others (Section
5.y). None of this involves an instruction that copies; the copying is
done by exchange and majority, and the program's only contribution is to
be an attractor with a steep enough funnel. The dictionaries whose cycles
are the same but whose funnel is shallow never take hold (Section 4),
which is the same statement from the other side: a replicator that is
an attractor of the map but not of its neighbourhood does not replicate.

Two corollaries follow, both testable on the processor arm. First, a
processor's rewriting map has attractors too, and they can be counted
the same way: a cell run as a Z80, a 68000 or a Redcode warrior for a
fixed number of instructions is a map on cells, and its fixed points and
short cycles are its replicators in the same sense (*to show*: the
attractor census for the processors, which the existing tools apply to
any changer; the expectation from the decoder is many fixed points,
since most random code halts or loops on itself, and few cycles). The
self-replicators that emerge in random populations of small programs
[agueraYarcas2024] should appear in that census as the attractors of the
pairwise map, and the spread they show in a population as the work of
whatever medium the population has, which there is the random pairing of
programs. Second, what a processor adds over a decoder is not
replication but the dependence of the attractor on the run: a processor
can reach different fixed points from the same memory under different
numbers of instructions and can carry state in registers the memory
does not show, which the link machines of Section 6 do, and the
phenomena that need this, if any, are the ones to attribute to
computation proper (*to show*: the comparison table).

A third point concerns time. In the computational systems a replicator
that appears late, or that is elaborate when it appears, is often read
as evidence that something was computed on the way to it: that the
population searched, learned or built. The decompressive automaton
shows late and elaborate appearances without any such thing, and a
Monte Carlo over the dictionaries says what they are
(`results/replicators.md`). First appearance is never late for an
attractor that matters: every type that ever held one per cent of
the cells was present at the earliest turn the detector allows, in
every run, because the first of N cells to fall into a basin b is
expected after 1 / (N b) turns and no detectable basin is below 1 / N.
What is late is takeover. A type present from the start at a share
below notice takes the lattice at the pace of a front, half of a 256²
lattice after a thousand turns for the fixed point of one searched
dictionary under the page frame, about 1.5 times longer than at 128²;
and which type that is depends on the entropy budget rather than on
the basin: under strong uniform settling the attractor with the largest
basin wins within a few tens of turns, under the frame a fixed point
whose basin is a three-hundredth of the leading cycle's wins instead,
because the majority filter propagates what makes neighbours agree. The
sharpest-looking structures of the page, the type mosaics of the
designed dictionaries, are those that never finish taking over at all.
Neither the lateness nor the elaboration is the mark of a computation;
both are the marks of a slow medium choosing among attractors that were
all there from the start, and the decompressive automaton, which cannot
compute, produces them on schedule (*to show*: the long runs for any
type whose basin is below 1 / N, which would be the only genuine
late appearances, and the takeover time against the lattice size and
the budget as the curves a computational system's late replicators
should be compared with before anything is attributed to the
computation).

The statement to carry into the discussion is therefore this. In the
decompressive automaton, replication decomposes into an attractor of the
rewriting map, which is a matter of enumeration, and a spread through an
entropy budget, which is a matter of statistical physics; nothing in it
is a replicator in the sense of a program that copies itself, and yet
the lattice shows the type, the invasions and the coexistence that
replicators are credited with. The burden is on the processor arm to
show what is left when those two are taken away.
