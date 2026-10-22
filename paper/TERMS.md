# The terms, and how we use them

2026-10-22. One word for each thing, the plainest that fits, and where it comes from. The formal definitions are in
DEFINITION.md; this says which words the paper, the results and the page use for them, and which words we stop
using. When a term has a traditional meaning we keep that meaning and say nothing larger.

## The system

- **Cell.** One site of the lattice. Its **state** is 128 bits, written as 16 bytes.
- **Configuration.** The states of all cells at one moment.
- **Turn.** One update of the whole configuration: mixing, then settling, then rewriting (DEFINITION.md §2).
- **Mixing.** Each of the four phases of a turn pairs every cell with one neighbour (left–right or up–down, two
  offsets), and each bit on which the two differ is exchanged with probability 2p(1 − p). This is uniform crossover
  between neighbours (Syswerda 1989 in the genetic-algorithm literature), one exchange per phase. p is the **mixing
  strength**. We say "mixing" for the operation and "exchange" for what happens to one bit; we do not say
  "recombination" except when naming the genetics idea it corresponds to.
- **Settling.** In each of the 128 bit planes, a cell's bit is set to the majority of its 3 × 3 neighbourhood,
  with a strength m (a threshold; m = 1 every cell, 0 none), in k synchronous passes a turn (k = 3 on the page).
  This is the majority-vote rule of Vichniac (1984) and Toom, applied per bit plane. m is the **settling strength**;
  k the **passes**. The 4-neighbour variant is the **vote**.
- **Rewriting.** Each cell's state is replaced by f(state), where f is the **local map**: the decoder against a
  dictionary (the default), a processor run on the state as memory, or an arithmetic transform. In the pair modes
  two cells are joined, mapped by the **pair map** g on 256 bits, and split.
- **Medium.** Mixing and settling together, as opposed to the local map. The paper's claim is about what the
  medium does to the attractors of f.
- **Uniform settings.** Constant p and m over the lattice. **The frame.** The page's picture: p rising left to
  right, m rising top to bottom, so one frame is a two-parameter sweep. Results say which of the two they used.
- **Dictionary.** The bytes the decoder copies from; the rule's genome. A **word** is a run of dictionary bytes a
  cell's stream points at. **Searched** dictionaries come from the swarm; **designed** ones from construction.
- **Quenched / annealed.** The hash decisions salted by nothing (the default) or by the turn number.

## Attractors of the local map (dynamical-systems words, used as they are)

- **Attractor.** Where iterating f on a single cell ends: a **fixed point** (f(s) = s) or a **cycle** of **period**
  k. The **basin** of an attractor is the fraction of random states that reach it.
- **Type.** The set of states of one attractor. A cell **is on** a type when its state is one of them. We say
  "type" and not "species": a species is defined by reproduction, and these are not reproducing. The designed
  dictionaries' files and the older results keep "species" in their names; the paper does not.
- **Phase.** A cell's position within its cycle. A domain is **in phase** (coherent) when all its cells share
  it, **in random phases** otherwise.
- **Family.** A set of fixed points that differ only in bytes the map never reads. Its size is 2 to the number
  of such bytes. (For a replicator, this is where heredity lives; see below.)
- **Transient.** A state not on any type.

## Regions of the lattice

- **Domain.** A connected region of cells on one type. A **uniform domain** is one in phase: by Lemma 1, mixing and
  settling do nothing to its interior.
- **Wall.** The boundary between two domains. A wall **advances** or **stands**; we do not say "front".
- **Hold, invade, dissolve.** A domain **holds** if its share stays near its starting share; a type **invades**
  another when its wall advances into the other's domain; a domain **dissolves** when its cells become transients.
  These replace "survive", "melt", "nucleate", "coarsen" and "take over". "Takeover" stays only as the name of the
  measured event in the replicator runs (a type reaching half the lattice).

## Closure (our one new term)

- **Closed type.** A type is closed if every bitwise combination of its states (a crossover of two of them, a
  majority over several) is mapped by f back onto the type. Fixed points are closed trivially; the Gray-coded
  designed cycles are closed by DEFINITION.md §4; the searched dictionaries' cycles are not. An **open** type is one
  that is not closed.
- **Closure index C(A, B).** The measured fraction of crossover children of a state of A and a state of B that f
  maps onto A or B. C(A, A) < 1 means open.
- **Threshold p\*(type, m).** The smallest mixing strength at which a domain of the type dissolves under the medium
  at settling strength m. The closure index is a one-step quantity; p\* is the same question asked over whole turns.

## Replication and heredity (von Neumann's words, used narrowly)

- **Replicator.** A state R of a system with a pair map such that g(R, X) contains R twice for almost every partner
  X: joined with anything, it leaves itself and a copy. BFF's evolved loops and Core War's imp are replicators.
  Keimli's types are not: they are fixed points of f, which maintain themselves and copy nothing. We say
  "replicator" only for the former.
- **Variant.** A state differing from a given one in one bit or one byte (the older results say "mutant").
- **Heritable.** A variant R′ of a replicator R is heritable if R′ is also a replicator. A byte of R is heritable
  if every value of it gives a replicator; these are the bytes the map copies without reading.
- **Heritable information.** log₂ of the size of R's family: the number of heritable bytes, times 8. This is
  what Maynard Smith and Szathmáry call the capacity of a heredity system, measured on the map. BFF: 48–54 bytes;
  the imp: 0; Keimli's families: 0–3 bytes, and those are not copied anywhere.
- **Inherited / removed.** On the lattice, a variant is inherited if it is present in the copies after a turn and
  removed if it is not. Settling removes variants (majority over neighbours restores the common value); we say
  "removed by settling", not "repaired", and we do not give the medium an intention.
- **Error threshold.** The settling or mutation strength above which no variant is inherited (Eigen 1971). Used only
  where it is measured.

## Measures

- **Share.** The fraction of cells on a type. Reported as a mean over seeds with a 95 % bootstrap interval, and as
  a curve over turns. "t₅₀" is not reported.
- **Collision entropy H₂.** −log₂ of the probability that two random cells have the same state. Exact against rules
  of known loss; the whole-cell measure. **Block entropy** is the entropy of 8-bit blocks; it is local order and is
  blind to whole-cell loss. A "bits lost" figure is a collision figure unless it says Shannon.
- **Bits read.** The number of input bits the decoder consumes before its output is complete; H(f(U)) ≤ E[bits read]
  (Lemma 3).
- **Correlation length.** The distance at which the connected correlation of a bit plane falls to 1/e, with the
  plane's bias subtracted. Printed only for the medium alone, with the size series that shows it converged.

## Words we stop using

"melt", "nucleate", "front", "coarsening" and any exponent for the full system; "species" for a type; "replicator"
for a Keimli type; "mutant" (say variant); "repair" (say removed by settling); "entropy pump", "computation" as a
measured thing, "self-decoding" as a claim about the cell; "interesting" as a score. "Life-like" stays as the name
of the page preset only.
