# Keimli

*Little germs of life: artificial life in hand-written WebAssembly.*

By Jyrki Alakuijala, co-author of Brotli, JPEG XL, Zopfli, Guetzli and
Butteraugli. Keimli is Swiss German for "little germ", in the family of
Brotli, Zopfli and Guetzli. The cells here are 128-bit strings that swap
bits with their neighbours, smooth themselves bit plane by bit plane, and
inflate their own content every turn through an LZ decompressor, a DCT, or
one of sixteen emulated CPUs, so the whole thing is an experiment in life
seen as information: entropy, compression and code execution.

## Cellular automata in hand-written WebAssembly

Two browser demos whose simulations run in WebAssembly modules written by hand
in the WebAssembly text format. Each page is self-contained: the wasm binary is
inlined as base64, so the files work straight from `file://` with no server.

## Demos

### `index.html` – Conway's Game of Life (`life.wat`, ~600 bytes)

Cells are one byte each; 0 is dead and 1–255 is a live cell's age. Edges wrap.
Exports: `step`, `render`, `population`, `randomize`.

### `mix.html` – Bit swap lattice (`mix.wat`, ~1.8 KB)

Every pixel is a 128-bit string stored as two little-endian 64-bit words.

**A turn.** Each turn runs the four swap phases LR0, UD0, LR1, UD1 once
each, where LR/UD is left–right or up–down pairing and 0/1 the even or odd
offset, so every pixel exchanges once with each of its four neighbours. The
order of the four changes every turn. Left–right and up–down phases always
alternate, which leaves 8 of the 4! = 24 orders (LR or UD first, and the
order within each pair); turn t uses order t mod 8 (`Band.order`), so over
any 8 turns every order has been used once and no fixed order can shape the
long run. The cycle through the 8 is arranged so that consecutive orders
differ as much as possible: measuring the difference of two orders as the
total distance the four phases move between them (at most 8), no cycle
through the 8 keeps every step at 8, and the cycle used (found by
exhaustive search, in `mix-band.js`) has 6 steps of 8 and 2 of 6, the
optimum; each phase goes first twice per cycle and no two consecutive turns
share a first or a last phase. The page shows the current order next to the turn counter. All
four phases decide on a snapshot of the map taken before the first of them (`mix_from` / the `snap`
argument of `mix_zone`): which pair exchanges which bit is settled from the
pre-turn state, and the exchanges are then applied in phase order. An
exchange whose two bits turn out to be equal by the time it is applied,
because an earlier phase already moved one of them, is a no-op and is not
counted. Then come the bit-plane smoothing passes (3 by
default, selectable 0–5), and finally the byte changer: every pixel's 16
bytes are replaced by the changer's output for them (`change` in the wasm
module), so the decompressed text or the Brainfuck tape becomes the pixel's
new content. The changer can be switched off ("None"), in which case it only
feeds the views. The view is refreshed once per turn.

**Render buffer.** The image on screen is not the latest frame but an
exponential average of the rendered frames (`blend` in the wasm module,
run on the main thread in a second instance of the module whose memory
holds three 16.16 fixed-point channels per pixel). The half-time of the
average is 200 ms or 4 turns, whichever is longer: each frame the page
measures the turns and the wall time since the previous frame and keeps
the larger of the two remaining fractions 2^(−ms/200) and 2^(−turns/4), so
at low speeds the display follows within a few turns and at high speeds it
averages about a fifth of a second of turns. By default the image is
integrated twice: a second buffer with its own accumulators reads the
rounded output of the first and integrates it with the same half-time
(two stages in cascade, selectable as one stage or off). The cascade's
step response starts flat instead of with a jump, which damps flicker more
than one stage of the same half-time at the price of a little more lag, so
the slow dynamics carry more weight. Where a pixel's whole 3 × 3
neighbourhood in the new frame has exactly its colour (8-connected flat)
the half-time is 2 × longer by default, so flat regions change on screen a
little more slowly than textured ones; the select also offers 4 ×, the same
half-time everywhere, or 2 × for 4-connected flat and 4 × for 8-connected
flat pixels. The stats panel shows the current
half-time in turns and counts the flat neighbourhoods of the frame. The buffer resets when the grid, the view or
the settings change or a pixel is painted, and it never feeds back into the
lattice.

**Spatial sharpening.** After the render buffer the frame is sharpened a
little (`sharpen` in the wasm module, on by default, switchable): each
channel becomes 2 × the pixel minus the mean of its 4-connected neighbours
(those that exist at the edges), rounded and clamped to 0–255. A flat
region is unchanged, a lone pixel on a flat background is pushed to
saturation and its neighbours slightly away from it. The step works on the
displayed image only.

**Bit-plane smoothing.** A pass is computed synchronously into a scratch buffer. For
every pixel and bit position where the bit disagrees with the majority (the
median) of its neighbourhood, the pixel's
32-bit neighbourhood of that position is hashed; if the hash is below the
smoothing threshold, the bit takes the majority value. The smoothing probability is a per-row
table: a linear gradient from the top-edge value to the bottom-edge value,
each 0 to 1 set in the UI (defaults 0 and 1), sampled at pixel centres so
the first and last rows get (i + 0.5) / H rather than exactly 0 or 1; at 1
every disagreeing bit is replaced each pass. The neighbourhood is
selectable: the pixel and its four 4-connected neighbours (5 votes, majority
at 3), the 3×3 block (9 votes, 5) or the 5×5 block (25 votes, 13).
Coordinates are clamped to the grid, so at an edge the missing neighbours
count as the nearest pixel (the pixel itself for the immediate ones). The
kernel counts votes bit-sliced (`$majority` in `mix.wat`); the band pipeline
budgets one halo row per pass per side for the first two neighbourhoods and
two for 5×5.

**Swapping.** The grid is a plane with edges, not a torus: pairs never
cross a row end or the last row, so the last pixel of a row and the last row
sit out the odd-offset phases. A swap phase pairs every pixel with one
neighbour. For each
pair the two strings are compared position by position. Where the bits
differ, the 32 bits neighbouring that position (16 below, 16 above, wrapping
around the 128-bit ring, the position itself excluded) are hashed separately
for each pixel with a splitmix64 finaliser and the two 64-bit hashes are
added with overflow, so the decision is independent of pixel order. The first
position whose sum is below the threshold has that single bit exchanged
(the comparison and the hashes read the turn's snapshot, the exchange
happens on the live map).
The swap probability is a per-column table: a linear gradient from the
left-edge value to the right-edge value, each a probability from 0 to 1 set
in the UI (defaults 0 and 1), sampled at pixel centres (column x gets
(x + 0.5) / W of the way from left to right) so that the first column is not
frozen at exactly 0; a pair uses the value of its first pixel's column. The
helper is `Band.gradient` in `mix-band.js`, shared with the tests.
Swaps conserve the total number of set bits. Because identical contexts hash
identically, a uniform boundary is all-or-nothing; the optional turn-number
salt (distinct for every phase and pass) breaks the tie.

**Decoding.** Each pixel's 128 bits are also expanded to exactly 128 bits of
output against a static dictionary, the Declaration of Independence, which is
not part of the image. The first ⌈log₂ N⌉ leading bits, 13 for the
Declaration's N = 8,122 bytes, are read as the start cursor, so every byte
of the dictionary is a start position (values past the end wrap to its
start), and the "LZ cursor offset" slider (0 to N, default 600 bytes) is
added to that cursor, again wrapping at the end of the text, so the start
positions can be shifted away from the dictionary's opening. Every command is a prefix-coded copy length of 2..N bytes (N is
the "Decompression" slider, 2 to 16) followed by a 3-bit skip: the cursor
skips that many bytes, the copy is taken from the dictionary at the cursor,
and the cursor advances past it, wrapping at the end of the text. Copies are
the only source of output: there are no literals and no distances, and
neither the output nor the image is ever read back. The length code weights
all lengths equally, so shorter copies get shorter codes; the resulting
expected rate on random bits is reported, not tuned. Unused input bits are
ignored; a 1024-bit cap on input consumption remains as a safety net. The
code table is built by `mix-codec.js`.

**Brainfuck byte changer.** The "Byte changer" box picks a mode: none, the LZ
decompressor, a transform (second box: do nothing, invert, reverse, add 17,
DCT, inverse DCT) or a CPU (second box: Brainfuck and the thirteen machines;
the "CPU steps" box appears with it). Instead of the decompressor, the changer
selector can run each pixel's 16 bytes as a Brainfuck program on a 16-cell
circular tape; the tape afterwards is the pixel's new content. Byte values
0–7 are the commands `> < + - . , [ ]` in that order and any other value is a
comment, so the "Random bytes 0–7" start fills the field with programs. `.`
does nothing, `,` reads the program's own bytes cyclically, unmatched
brackets are ignored, and execution stops after 1024 steps. The tape starts
empty or as a copy of the pixel, selectable. The inspector shows the
disassembled program and the tape with changed cells highlighted.

**Simple byte processors.** The same selector also offers "Do nothing"
(identity), "Invert" (all 128 bits flipped), "Reverse bytes" (the 16
bytes in reverse order) and "Add 17" (the smallest of the 16 bytes, the
first one on ties, gains 1, the byte after it gains 17 and the byte before
it gains 5, modulo 256 with the index wrapping around the 16 bytes), useful
as controls and as a slow, deterministic drift. "DCT" and "Inverse DCT" treat
the 16 bytes as signed samples (byte − 128): the forward transform replaces
them with their 16-point DCT-II coefficients at half the orthonormal scale,
so byte 0 becomes the mean and the rest the frequencies in rising order, and
the inverse rebuilds the samples from coefficients read the same way; both
offset by 128 and clamp to 0..255 (`$dct` in `mix.wat`, cosines from a
64-entry table that `Codec.install` writes at `LAYOUT.COS`). A DCT followed
by an inverse DCT returns a pixel to within rounding unless a coefficient
clipped.

**Z80 byte processor.** A Zilog Z80 core written in the wasm module runs each
pixel's 16 bytes as its entire address space (addresses wrap mod 16, stack
included). Registers start at zero, a selectable number of instructions (32 to
256, "CPU steps") execute from PC = 0, and the memory afterwards is the
pixel's new content. HALT, DI, EI, IM and
all port I/O are NOPs; interrupts do not exist. Implemented: every
unprefixed opcode, every CB opcode, DD/FD (IX/IY) addressing including
DDCB/FDCB, and the ED subset ADC/SBC HL,rp; LD (nn),rp / LD rp,(nn); NEG;
RETN/RETI; LD I/R,A and A,I/R; RRD/RLD; LDI/LDD/LDIR/LDDR; CPI/CPD/CPIR/CPDR.
Other ED opcodes are NOPs. Flags S, Z, H, P/V, N, C follow the documented
behaviour (X/Y bits approximately). A prefix byte followed by another prefix
ends the instruction step, so memory full of prefixes cannot stall the core.
The inspector shows the register file after the run. On a 128×128 grid the
Z80 rewrite phase costs about 74 ms single-threaded. The core lives in `z80.wat` and is spliced into `mix.wat`.

**6502 and 8080 byte processors.** Two more cores in the module (`cpus.wat`)
follow the same conventions: the pixel's 16 bytes are the entire address
space, registers start at zero, 256 instructions run, and the memory is
written back by the rewrite phase. The MOS 6502 implements all 151
documented opcodes including decimal mode, with the stack page wrapping into
the same 16 bytes, BRK vectoring through bytes 14–15, and every undocumented
opcode (the JAM/KIL halts included) as a NOP. The Intel 8080 implements its
full instruction set with 8080 flags (S Z AC P CY, parity always), the
duplicate opcodes behaving as on the real chip (CBh is JMP, D9h is RET,
DDh/EDh/FDh are CALL), and HLT, DI, EI, IN and OUT as NOPs. It shares the
Z80's fetch, stack and register-file helpers.

**Seven more machines.** Subleq (one instruction, every step rewrites
memory), CHIP-8 (2-byte big-endian instructions, no display or keypad), the
Intel 4004 (4-bit; the 16 bytes are the ROM and 32 RAM nibbles), the Game Boy
SM83 (8080/Z80 relative with Z N H C flags), the Intel 8051 (the pixel is the
internal RAM, so register banks, stack and bit area live in it), the Motorola
6809 (every addressing mode, both prefix pages) and RISC-V RV32EC (RV32I plus
the integer C extension, 16 registers). All follow the same conventions:
zeroed registers, the selected instruction budget from PC = 0, halting and
I/O instructions as NOPs, memory written back. CHIP-8, the 4004 and RISC-V
are register machines whose random code rarely stores to memory, so they keep
their registers in the pixel instead (`$load` and `$spill` in `mix.wat`): the
registers are read from the 16 bytes when the run starts, instead of being
zeroed, and written back when it ends, so register state carries from turn to
turn and random code keeps moving. CHIP-8 maps V0..VF to bytes 0..15; the
4004 maps the 16 nibbles ACC, R0..R14 to bytes 0..7 and leaves bytes 8..15 as
memory (a full-state spill converged too fast); RISC-V maps the low bytes of
x1..x15 to bytes 1..15 (zero-extended on load) and leaves byte 0 alone. Cores live in `cpus3.wat`,
`i8051.wat`, `m6809.wat` and `riscv.wat`; the inspector shows each machine's
registers after the run.

**PDP-8, PDP-11 and 68000.** Three more cores (`pdp8.wat`, `pdp11.wat`,
`m68k.wat`), same conventions. The PDP-8 treats the pixel as 8 words of 12
bits (word k is bits 12k..12k+11) and keeps AC, L, PC and MQ in bits 96..123,
loaded at the start and written back at the end like the other register
machines; addresses are taken mod 8, the OPR groups are complete and IOT is a
NOP. The PDP-11 sees 8 little-endian words with all eight addressing modes,
the basic set plus EIS (MUL, DIV, ASH, ASHC), XOR, SOB, SXT and the PSW
moves; registers start at zero. The 68000 sees 16 big-endian bytes with every
68000 addressing mode and the integer instruction set (MOVE, the ADD/SUB/CMP/
AND/OR/EOR families with their immediate, quick, address and extended forms,
shifts and rotates, bit instructions, MULU/MULS/DIVU/DIVS, Bcc/DBcc/Scc,
JSR/RTS, LEA/PEA, LINK/UNLK, MOVEM, EXG); the BCD instructions, CHK, TRAP and
lines A/F are NOPs. Unit tests run small programs on each; on random pixels
they rewrite 84–97% of them in a first pass.

**UNIVAC 1101, VAX-11/780 and CDC 6600.** Three wide-word machines (`u1101.wat`,
`vax.wat`, `cdc6600.wat`), registers starting at zero. The ERA/UNIVAC 1101 sees
5 words of 24 bits (bits 0..119) and runs the 38 operations of the January 1950
ERA instruction list under their octal codes (11 OP clear add ... 71 NP clear add
+1): a 48-bit ones' complement accumulator, Q, circular shifts, the four jumps,
multiply, multiply-add and divide; the skip field picks the next word and y is
taken mod 5. The VAX sees 16 little-endian bytes with every operand specifier
and the integer, address, branch, loop, bit-field and stack instructions; the
floating-point, decimal, string, queue and privileged groups are NOPs and
CALLS/CALLG push only the argument and the PC. The CDC 6600 sees 2 words of 60
bits as 8 parcels of 15 bits and runs the whole central processor set, with the
6600 floating-point format (FX/DX/RX add, subtract, multiply, divide, NX/UX/PX),
ones' complement IX arithmetic and the SA/SB/SX address forms whose A1..A5 loads
and A6/A7 stores are the only memory traffic. Random pixels are rewritten less
often by these two tiny-memory machines (about 12% for the 1101 and 26% for the
6600 on a first pass, against 90% for the VAX) because a 5- or 2-word program
has few places to store to.

**Views.** Byte colours: a 256-entry LUT packed as 4 bits per channel in an
int32 (R at bit 0, G at bit 8, B at bit 16), so a pixel's 16 entries are
summed without carries and scaled to 8 bits, giving the average colour of its
16 raw bytes (default) or of its 16 decoded bytes. Because a mean of 16
colours pulls toward grey, each channel's deviation from the field's mean
colour is stretched 3× and clamped; the mean is taken from the previous
frame's unstretched averages (seeded from the palette), so it adapts to
whatever the field contains, like an auto white balance.  The LUT is designed
around the dictionary's alphabet: a–z take the whole hue circle in order, A–Z
are pastels of the same hues, digits and punctuation are light neutrals,
space is white, byte values 0–7 (the Brainfuck commands) have eight vivid
hues, and every other byte value is coloured by its Z80 opcode class, kept
dimmer than the letters: teal for the x=0 block, blue for LD r,r', red to
orange for the ALU block, violet for control flow and stack, pale lilac for
the CB/DD/ED/FD prefixes. The page shows the legend and
a swatch per dictionary character. Also:
decoded text hashed in thirds (R, G, B); dictionary cursor position; raw
bits hashed 16 at a time; bit density in thirds (set bits of positions 0–42,
43–85 and 86–127 scaled to R, G, B). Clicking a pixel shows
its hex bits, its start cursor, its decoded text as alternating copy
fragments, and how many input bits the decoder consumed.

**Threads.** The page can run the lattice in a pool of Web Workers, one per
horizontal band of rows, each with its own wasm instance. A band keeps D
halo rows above and below (D = 2 + passes, rounded up to even) and receives
them once per turn from its neighbours' edge rows; it then runs the whole
turn locally with the zone kernels `mix_zone` and `smooth_zone`, shrinking
its valid zone by a row on a side whenever an up-down phase pairs across the
zone edge or a smoothing pass reads across it. Pairs on band boundaries are
computed redundantly by both neighbours, which is deterministic, so a turn
costs a single message round trip. `mix-band.js` holds this bookkeeping and
`test/band.test.mjs` checks that the pipeline reproduces the full-grid
functions bit for bit, counts included, for several band counts, pass counts
and changers. Each band snapshots its whole buffer, halos included, into its
scratch area at the start of the turn and decides every swap phase from
that. Changing the thread count (or the smoothing pass count, which
sets the halo depth) rebuilds the worker pool but carries the lattice over
bit for bit: the old engine's cells are read out, the new one is seeded with
them, and the turn counter keeps running; only a new grid size starts over.
Shared-memory wasm threads are not used because they need
cross-origin isolation, which `file://` pages do not have. The kernels walk
only the bit positions where two pixels differ (`$pair`) or where a bit
disagrees with its neighbourhood majority (`$smooth_px`), with a branchless
128-bit rotate for the context, and skip hashing entirely at p = 0 and p = 1.

**Speed notes.** With a byte changer active, the "decoded bytes" view draws
the pixel bytes directly, since they already are the latest decoded output.
The CPU cores' instruction budget is selectable (32 to 256 per pixel).

**Painting.** The wasm module writes RGBA pixels into its own memory; the page
wraps that region in an `ImageData`. "Fit to width" draws it through a W×H
backing canvas scaled by an integer cell size; "1:1 device pixels" sizes the
visible canvas W×H in device pixels and blits the buffer directly with one
`putImageData`, which is the cheapest path and the one to use for the
1024×1024 and 2048×2048 grids.

**Views.** Decoded text hashed in thirds (R, G, B); share of output copied
from the dictionary; raw bits hashed 16 at a time; bit density. Clicking a
pixel shows its hex bits, its dictionary offset, its decoded text with copied
spans highlighted, and how many input bits the decoder consumed.

Exports: `smooth`, `mix`, `decode_pixel`, `render`, `bits`, `randomize`.

## Files

- `life.wat`, `mix.wat` – the simulations.
- `mix-codec.js` – LZ77 parse, length-limited Huffman codes, lookup tables, rate tuning.
- `declaration.txt` – the static dictionary text.
- `page.html`, `mix-page.html` – page sources with `__WASM_BASE64__`, `__WASM_SIZE__`,
  `__CODEC_JS__` and `__DECL_TEXT__` placeholders.
- `build.sh`, `build.py` – compile both modules with `wat2wasm` and inline everything into
  `index.html` and `mix.html`.
- `life.wasm`, `mix.wasm` – compiled modules (produced by the build).

## Build

    ./build.sh

Requires `wat2wasm` from the WebAssembly Binary Toolkit (wabt).

## Tests

    node test/mix.test.mjs   # decoder tables, decoding, mixing rule, smoothing, jam and timing checks
    node test/band.test.mjs  # worker band pipeline == single-instance grid, bit for bit
    node test/activity.test.mjs  # how much each byte processor really changes; flags effectively idle ones
    test/smoke.sh            # loads both built pages in headless Chromium with #selftest (and #selftest-workers)

The Node suite decodes every pixel of a 512×384 random grid and checks that no
pixel consumes more than the decoder's 1024-bit input cap, that rendering
finishes in bounded time, and that the default random start keeps moving under
the default rule. The activity test rewrites a random grid with every processor, twice, and
reports the share of pixels and bytes changed; it asserts which processors
change fewer than 5% of random pixels (only "do nothing" since the register
spill; before it CHIP-8 and the 4004 were in that set). The smoke
test opens `index.html#selftest` and `mix.html#selftest`,
which run 50 steps synchronously at boot, and checks the counters in the DOM.
