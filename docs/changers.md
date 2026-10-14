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

Both treat the 16 bytes as signed samples (byte − 128). The forward
transform replaces them with their 16-point DCT-II coefficients at half the
orthonormal scale, so byte 0 becomes the mean and the rest the frequencies
in rising order; the inverse rebuilds the samples from coefficients read the
same way. Both offset by 128 and clamp to 0..255. The cosines come from a
64-entry table that `Codec.install` writes at `LAYOUT.COS`. A DCT followed
by an inverse DCT returns a pixel to within rounding unless a coefficient
clipped.

## Pairs: two cells changed together

The "Cells" box in the Local changer section can change two neighbouring
cells, columns 2i and 2i + 1, as one. Their 256 bits are joined into a
32-byte joint cell, the changer runs once on it, and the result is split
back by the same mapping in reverse (`$join` and `$split` in `decode.wat`;
the host sets `pairMode` and this turn's `pairFlip` in the parameter block,
and `change` walks the pairs). Two joinings are offered, and each alternates
from turn to turn so that neither cell keeps the first role:

- **Concatenated.** A then B on even turns, B then A on odd turns. A CPU
  then has 32 bytes of memory, so a program in one cell can read and write
  the other; the decompressor reads its cursor and commands from 256 input
  bits and emits 32 bytes.
- **Bit-interleaved.** On even turns A's bits take the even positions of
  the joint cell and B's the odd ones; on odd turns the other way round.
  Every byte of the joint cell then mixes four bits of each cell, so
  whatever the changer does is spread over both.

The changers see the joint cell through the cell width `$cw` (16 or 32
bytes): memory accesses wrap at it, Brainfuck's program and tape have that
many cells, the simple transforms run over it, and the decompressor's bit
reader covers 256 bits. The changers defined on exactly 128 bits, the DCT
and inverse DCT, the PDP-8, the UNIVAC 1101 and the CDC 6600, are handed
the joint cell as two consecutive 16-byte cells. The inspector always
decodes a single cell. A pair never crosses a row (the width is even), so
the band pipeline is unaffected; `test/band.test.mjs` runs pair
configurations through it.

## How much each changer changes

`test/activity.test.mjs` rewrites a random 64 × 64 grid with every changer,
twice, and reports the share of pixels and bytes changed. It asserts which
changers change fewer than 5% of random pixels: only "do nothing" since the
register spill (before it CHIP-8 and the 4004 were in that set).
