# Rendering

Source: `src/render/render.wat` (`render`, `blend`, `sharpen`) and the
byte colour LUT in `src/changers/codec.js` (`Codec.byteLut`). The page
(`src/page/lattice.html`) drives the pipeline: render a frame, average it
in the render buffer, sharpen it, draw it. Nothing here feeds back into the
lattice.

## Views

**Byte colours.** A 256-entry LUT packed as 4 bits per channel in an int32
(R at bit 0, G at bit 8, B at bit 16), so a pixel's 16 entries are summed
without carries and scaled to 8 bits, giving the average colour of its 16
raw bytes (default) or of its 16 decoded bytes. Because a mean of 16
colours pulls toward grey, each channel's deviation from the field's mean
colour is stretched 3 × and clamped; the mean is taken from the previous
frame's unstretched averages (seeded from the palette), so it adapts to
whatever the field contains, like an auto white balance.

The LUT is designed around the dictionary's alphabet: a–z take the whole
hue circle in order, A–Z are pastels of the same hues, digits and
punctuation are light neutrals, space is white, byte values 0–7 (the
Brainfuck commands) have eight vivid hues, and every other byte value is
coloured by its Z80 opcode class, kept dimmer than the letters: teal for
the x=0 block, blue for LD r,r', red to orange for the ALU block, violet
for control flow and stack, pale lilac for the CB/DD/ED/FD prefixes. The
page shows the legend and a swatch per dictionary character.

**Other views.** Decoded text hashed in thirds (R, G, B); dictionary cursor
position; raw bits hashed 16 at a time; bit density in thirds (set bits of
positions 0–42, 43–85 and 86–127 scaled to R, G, B). With a local changer
active, the "decoded bytes" view draws the pixel bytes directly, since
they already are the latest decoded output.

**Inspector.** Clicking a pixel shows its hex bits, its start cursor, its
decoded text as alternating copy fragments, how many input bits the decoder
consumed, and for the CPUs the register file after the run.

## Render buffer

The image on screen is not the latest frame but an exponential average of
the rendered frames (`blend`), run on the main thread in a second instance
of the module whose memory holds three 16.16 fixed-point channels per
pixel, so the average converges exactly.

The half-time of the average is 200 ms or 4 turns, whichever is longer:
each frame the page measures the turns and the wall time since the previous
frame and keeps the larger of the two remaining fractions 2^(−ms/200) and
2^(−turns/4), so at low speeds the display follows within a few turns and
at high speeds it averages about a fifth of a second of turns.

By default the image is integrated twice: a second buffer with its own
accumulators reads the rounded output of the first and integrates it with
the same half-time (two stages in cascade, selectable as one stage or off).
The cascade's step response starts flat instead of with a jump, which damps
flicker more than one stage of the same half-time at the price of a little
more lag, so the slow dynamics carry more weight.

Where a pixel's whole 3 × 3 neighbourhood in the new frame has exactly its
colour (8-connected flat) the half-time is 2 × longer by default, so flat
regions change on screen a little more slowly than textured ones; the
select also offers 4 ×, the same half-time everywhere, or 2 × for
4-connected flat and 4 × for 8-connected flat pixels. The stats panel shows
the current half-time in turns and counts the flat neighbourhoods of the
frame. The buffer resets when the grid, the view or the settings change or
a pixel is painted.

**Threads.** With the worker pool, each band runs the render buffer and
the sharpening on its own rows inside its worker (`Band.postFrame`, shared
with the single-thread path), using three neighbour rows from each side
that the main thread passes along with the render message; the per-frame
constants are still decided on the main thread. The result is identical to
the whole-frame computation, band edges included.

## Spatial sharpening

After the render buffer the frame is sharpened a little (`sharpen`, on by
default, switchable): each channel becomes 2 × the pixel minus the mean of
its 4-connected neighbours (those that exist at the edges), rounded and
clamped to 0–255. A flat region is unchanged, a linear ramp is unchanged
inside, and a lone pixel on a flat background is pushed to saturation with
its neighbours moved slightly away from it.

## Drawing

The wasm module writes RGBA pixels into its own memory; the page wraps that
region in an `ImageData`. "Fit" draws it through a W × H backing canvas
scaled by an integer cell size, and on landscape screens the square is also
limited by the window height so it stays fully visible; "1:1 device pixels"
sizes the visible canvas W × H in device pixels and blits the buffer
directly with one `putImageData`, which is the cheapest path and the one to
use for the 1024 × 1024 and 2048 × 2048 grids.

## Byte histogram and entropy

Beside the square the statistics column shows the distribution of the
lattice's bytes and how its entropy develops. Every turn's reply carries the
counts of the 256 byte values over the grid (`hist`, run by each band on its
own rows and summed on the main thread, so the worker pool pays no extra
round trip), and the page logs the Shannon entropy of that distribution,
H = −Σ p(b) log₂ p(b) in bits per byte, turn by turn. A random start sits
near 8 bits; the LZ decompressor pulls the lattice towards the dictionary's
letter frequencies, around 4.5 bits; a frozen floor of identical cells
drives it down further.

The histogram is drawn on a log scale (bar height ∝ log₂(1 + count)) in the
byte view's colours, so the letters, digits and punctuation of the
dictionary can be told apart from machine-code bytes, with the most common
byte and its share named above it; pointing at a bar names that byte. The
entropy trace uses a fixed 0 to 8 bit axis with gridlines at 2, 4 and 6,
one turn per device pixel while the log is shorter than the chart and,
after that, the whole history compressed to the width as a min–max band per
column with the column means as a line. The log restarts with every new
start pattern or grid size.
