# Entropy decrease through local changers

Source: `src/changers/` — `decode.wat` (the entry point and the LZ
decoder), `codec.js` (code tables, memory layout, the byte colour LUT),
`declaration.txt` (the dictionary), `brainfuck.wat`, `simple.wat`,
`dct.wat`, and `cpu/` for the emulated machines (see [cpus.md](cpus.md)).
Tests: `test/mix.test.mjs` and `test/activity.test.mjs`.

A local changer takes a pixel's 16 bytes and produces 16 bytes. At the end of
every turn `change` runs the selected changer over every pixel and writes
the output back over it, so what the changer makes of a pixel becomes the
pixel's new content: the decompressed text, the Brainfuck tape, the memory
a CPU left behind. `decode_pixel` runs it on one pixel for the inspector and
the views without writing back.

The "Local changer" box picks a mode: none, the LZ decompressor, a transform
(second box: do nothing, invert, reverse, add 17, DCT, inverse DCT) or a CPU
(second box: Brainfuck and the sixteen machines; a "CPU steps" box appears
with it).

## The entry point

`$decode` in `decode.wat` dispatches on the changer number in the parameter
block (`codec.js` keeps the numbering: 0 LZ, 1 and 2 Brainfuck, 3 to 5 the
simple transforms, 6 to 15 and 19 to 24 CPUs, 16 add 17, 17 and 18 DCT),
and is itself the LZ decoder. The parameter block, output buffer, flags
(one byte per output byte, for the inspector) and the dictionary are placed
in memory by `Codec.install`, whose `LAYOUT` is the module's memory map.

## The LZ decompressor

Each pixel's 128 bits are expanded to exactly 128 bits of output against a
static dictionary, the Declaration of Independence, which is not part of
the image. The first ⌈log₂ N⌉ leading bits, 13 for the Declaration's
N = 8,122 bytes, are read as the start cursor, so every byte of the
dictionary is a start position (values past the end wrap to its start), and
the "LZ cursor offset" slider (0 to N, default 600) is added to that cursor,
again wrapping at the end of the text, so the start positions can be
shifted away from the dictionary's opening.

Every command is a prefix-coded copy length of 2..N bytes (N is the
"Decompression" slider, 2 to 16, default 3) followed by a 3-bit skip: the
cursor skips that many bytes, the copy is taken from the dictionary at the
cursor, and the cursor advances past it, wrapping at the end of the text.
Copies are the only source of output: there are no literals and no
distances, and neither the output nor the image is ever read back. The
length code weights all lengths equally, so shorter copies get shorter
codes; the resulting expected rate on random bits is reported, not tuned.
Unused input bits are ignored; a 1024-bit cap on input consumption remains
as a safety net. `codec.js` builds the length-limited code and its lookup
table.

## Brainfuck

Each pixel's 16 bytes run as a Brainfuck program on a 16-cell circular
tape; the tape afterwards is the pixel's new content. Byte values 0–7 are
the commands `> < + - . , [ ]` in that order and any other value is a
comment, so the "Random bytes 0–7" start fills the field with programs. `.`
does nothing, `,` reads the program's own bytes cyclically, unmatched
brackets are ignored, and execution stops after 1024 steps. The tape starts
empty or as a copy of the pixel, selectable. The inspector shows the
disassembled program and the tape with changed cells highlighted.

## Simple transforms

"Do nothing" (identity), "Invert" (all 128 bits flipped), "Reverse bytes"
(the 16 bytes in reverse order) and "Add 17": the smallest of the 16 bytes,
the first one on ties, gains 1, the byte after it gains 17 and the byte
before it gains 5, modulo 256 with the index wrapping around the 16 bytes.
These are useful as controls and as a slow, deterministic drift.

## DCT and inverse DCT

Both treat the cell's bytes as signed samples (byte − 128), N = 16 of
them, or 32 when the changer runs on a joint cell of a pair. The forward
transform replaces them with their N-point DCT-II coefficients at half the
orthonormal scale, so byte 0 becomes the mean and the rest the frequencies
in rising order; the inverse rebuilds the samples from coefficients read the
same way. Both offset by 128 and clamp to 0..255. The cosines come from a
33-entry table cos(πm/64), m = 0..32, that `Codec.install` writes at
`LAYOUT.COS`, extended by symmetry (`$cos64`). A DCT followed by an inverse
DCT returns a pixel, or a pair, to within rounding unless a coefficient
clipped. On a concatenated pair the first cell receives the 16 lowest
frequencies and the second the 16 highest; on the lifting joinings the
transform runs over the sum and difference halves.

## Pairs: two cells changed together

The "Cells" box in the Local changer section can change two neighbouring
cells, columns 2i and 2i + 1, as one. Their 256 bits are joined into a
32-byte joint cell, the changer runs once on it, and the result is split
back by the same mapping in reverse (`$join` and `$split` in `decode.wat`;
the host sets `pairMode` and this turn's `pairFlip` in the parameter block,
and `change` walks the pairs). Five joinings are offered, and each alternates
from turn to turn so that neither cell keeps the first role:

- **Concatenated.** A then B on even turns, B then A on odd turns. A CPU
  then has 32 bytes of memory, so a program in one cell can read and write
  the other; the decompressor reads its cursor and commands from 256 input
  bits and emits 32 bytes.
- **Bit-interleaved.** On even turns A's bits take the even positions of
  the joint cell and B's the odd ones; on odd turns the other way round.
  Every byte of the joint cell then mixes four bits of each cell, so
  whatever the changer does is spread over both.
- **Byte-interleaved.** A's byte k at joint byte 2k and B's at 2k + 1 on
  even turns, the other way round on odd turns. The bytes stay whole, so
  a CPU sees the two cells as alternating memory bytes and the
  decompressor's output alternates between them.
- **Xor then add.** Byte by byte, the first half of the joint cell is
  x = A xor B and the second is y = B + x (mod 256); the way back is
  B = y − x, A = x xor B. The first half holds the difference of the two
  cells, the second a sum.
- **Add then subtract.** Byte by byte, s = A + B and d = A − (s >> 1), the
  way back A = d + (s >> 1), B = s − A: an integer sum-and-difference
  (lifting) step, so the first half is the sum and the second half the
  distance from the mean.

The last two are lifting steps: each is a bijection on the pair of bytes,
so the "do nothing" changer leaves both cells as they were, like the first
two. They differ from concatenation in that the changer's edits to one
half land, through the inverse, in both cells, and in that arithmetic
carries couple the bits within a byte.

The changers see the joint cell through the cell width `$cw` (16 or 32
bytes): memory accesses wrap at it, Brainfuck's program and tape have that
many cells, the simple transforms run over it, and the decompressor's bit
reader covers 256 bits, and the DCT has 32 points. The changers defined on
exactly 128 bits, the PDP-8, the UNIVAC 1101 and the CDC 6600, are handed
the joint cell as two consecutive 16-byte cells. The inspector always
decodes a single cell. A pair never crosses a row (the width is even), so
the band pipeline is unaffected; `test/band.test.mjs` runs pair
configurations through it.

## Links: a persistent CPU per pair of neighbours

The last entry of the "Cells" box, Links, changes the regime for the CPU
changers (Z80 and up, kinds 6 to 15 and 19 to 24). Instead of a fresh
machine running 256 instructions over one cell, every link of the lattice
has a machine of its own whose registers persist from round to round. A
link is directed: the pair of horizontally or vertically adjacent pixels
A, B carries two links, A→B and B→A, with two separate machines. The A→B
machine's memory is A at addresses 0 to 15 followed by B at 16 to 31, the
B→A machine's is B followed by A, read when its instruction runs and written
straight back. A round runs the four link phases in the swap-phase order
(UD0, LR0, UD1, LR1): in each phase every pair of that phase runs one
instruction of its forward machine (left or top pixel first) and then one
of its backward machine, which sees what the forward one wrote. So a pixel
is visited by eight machines a round, four of them running code that starts
in the pixel itself, and each machine advances one instruction a round. A turn makes a number of rounds in a row (the
"Link rounds" box: 1 to 256, 128 by default) before the lattice is drawn, so
by default each machine runs 128 instructions a turn, interleaved with its
neighbours' machines one instruction at a time. The "Link reset" box says
how often the machines are reset to PC 0 and zero registers: at the start
of every turn by default, so that what a turn does is a function of the
pixels alone and the code in them has a meaning by itself; or every 4, 16
or 64 turns, or never, when the registers persist and carry state the
pixels do not show. The steps setting does not apply.

The states live in a buffer of 128 bytes per directed link, 4WH of them
(512 bytes a pixel), allocated the first time the mode runs and reset to fresh
registers (zero; the 6502 with P = 0x24 and S = 0xFF) when the mode starts,
the grid changes size or the CPU kind changes, and on the turns the reset
setting names (`links_reset`). The pair
(x, y), (x + 1, y) has index p = y·W + x, the pair (x, y), (x, y + 1) index
p = W·H + y·W + x; the forward link's state is entry 2p and the backward
link's entry 2p + 1 (`links` in `driver.wat`, which shares the
one-instruction `$step` with the ordinary driver). Machines that keep
registers in the pixel in the ordinary regime (CHIP-8, 4004, RISC-V, PDP-8)
keep them in the link state here instead, and the three 128-bit machines
(PDP-8, UNIVAC 1101, CDC 6600) see only the first pixel of their link, so
the forward machine works on one pixel of the pair and the backward machine
on the other.
Because a vertical link joins two rows, the mode runs on the single-instance
engine; the page switches engines when Links is chosen with workers
configured. With a non-CPU changer the Links setting has no effect and the
changer runs cell by cell.

## How much each changer changes

`test/activity.test.mjs` rewrites a random 64 × 64 grid with every changer,
twice, and reports the share of pixels and bytes changed. It asserts which
changers change fewer than 5% of random pixels: only "do nothing" since the
register spill (before it CHIP-8 and the 4004 were in that set).
