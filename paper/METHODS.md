# 2 Methods

*A first pencil draft, 2026-10-21. Deliberately short: the lattice, the
decoders, the processors and every experiment run in the browser from a
single page, and that page, with its WebAssembly module and the scripts
that produced every table, is the primary artifact of this work; the
text below says what the artifact does and where each exact definition
lives, not how it is implemented.*

The lattice is a plane of 128-bit cells with edges, not a torus, 512 ×
512 cells in the figures unless stated. A turn applies three stages to
every cell, in this order, and the view is drawn once per turn.

**Mixing.** Each cell exchanges bits with each of its four neighbours
once a turn, in four phases, left-right and up-down at even and odd
offsets, the pattern turned by ninety degrees each turn so that no
direction acts last. At every position where the two cells differ, the
bits are exchanged with probability p, a uniform crossover; the
exchanges of a turn are decided on a snapshot of the lattice taken
before the first phase. p is a parameter of the cell's column, a
gradient from the left edge's value to the right edge's, mapped to the
rate 2p(1 − p) so that the identity sits at both ends and the strongest
mixing in the middle. Exchanges conserve the number of set bits. An
alternative, synchronous rule, in which every bit where a neighbour
differs is taken from one neighbour and written to the cell alone, is
available for comparison and is isotropic by construction.

**Settling.** Each of the 128 bit planes is smoothed by a majority
filter over the cell and its neighbourhood, the 3 × 3 block by default,
computed synchronously from the previous state. A bit that disagrees
with the majority is replaced with probability p, a parameter of the
cell's row, a gradient from the top edge's value to the bottom edge's.
The pass is applied one to three times a turn.

**Rewriting.** The cell's 128 bits are read as a coded stream and the
decoded 16 bytes replace them. The reference decoder is Brotli-like
[rfc7932]: after six skipped bits, a header of ⌈log₂ V⌉ bits selects a
window of V positions of a shared dictionary, and the stream then
consists of insert-and-copy commands, each a literal count, a copy
length, a distance taken from a ring of the last distances or given in
seven bits, and, for copies from the dictionary, one of Brotli's four
word transforms. The input wraps round the cell, consumption is capped,
and whatever the stream does not produce is left as it was. Two cells
can be joined into one 32-byte stream before decoding and split after,
concatenated or interleaved by bit, bit pair, nibble or byte, with the
two roles alternating by turn; a cell can also be joined with the
bit-plane vote of its four neighbours instead of a neighbour, and only
the cell written back. Other decoders are available as rewriting rules,
among them a plain LZ copier, two codebooks made for cycle dynamics, and
byte-format decoders from Morse to LZ4; and so are twenty-five emulated
processors, from the Z80 and 6502 through the PDP-11, 68000, VAX and
RISC-V to Redcode, each running a fixed number of instructions on the
cell's bytes as its memory or, on cell pairs, as a persistent machine on
every link between neighbours that advances one instruction a round and
reads the round's snapshot. Transforms (inversion, reversal, the DCT, two
sorts and an arithmetic drift) serve as controls.

**Hashing.** No stage draws a random number. A trade or a vote is
decided by hashing the 32 bits that surround the position in the two
cells, or in the one cell, and comparing the hash with the threshold
that p encodes; the hash is a fixed finaliser with a salt of zero. The
same bits therefore decide the same way at every place and every turn,
and the whole is a deterministic cellular automaton whose randomness is
quenched in its configuration; p is the fraction of contexts that
decide to act, not a probability drawn each time. For control, the salt
can be taken from the turn number, from the cell's position, or both,
which breaks the invariance in time or in space and gives annealed
noise; the article says for every run which it used.

**Observables.** The page reports per turn the bits exchanged by mixing,
changed by settling and changed by rewriting, the byte histogram and its
entropy, and the fraction of distinct cells. The scripts under
`paper/experiments` add the spatial correlation of cell contents along
each axis and the correlation length, the share of cells on a known
cycle and their phase coherence, the number and size of domains, and the
attractor census of a decoder over random inputs. Every number in the
article comes from a script run on the same module the page uses, never
from a screenshot.

**Reproducibility.** The page, its module, the dictionaries and the
scripts are at [repository]; each figure names its settings line, a
single string that the page accepts and that restores every control, so
that any figure can be re-run in the browser. The designed dictionaries
are produced by the scripts under `paper/experiments/design-*.mjs` and
reproduced byte for byte by them. Exact definitions of every stage, of
the decoder to the bit, of the processors and of the band-parallel
execution that makes the browser version bit-identical to the
single-threaded one are in the repository's documentation
(`docs/lattice.md`, `docs/changers.md`, `docs/cpus.md`), which the tests
under `test/` check against the module.
