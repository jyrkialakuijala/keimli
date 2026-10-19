# Keimli

*Little germs of life: artificial life in hand-written WebAssembly.*

By Jyrki Alakuijala, co-author of Brotli, JPEG XL, Zopfli, Guetzli and
Butteraugli. Keimli is Swiss German for "little germ", in the family of
Brotli, Zopfli and Guetzli.

Every cell of the lattice is a 128-bit string. Each turn the cells swap
bits with their neighbours under a hash rule (a uniform crossover), smooth themselves bit
plane by bit plane, and then inflate their own content: the 16 bytes are
run through an LZ decompressor against a fixed dictionary (the US
Declaration of Independence or one of seventeen short public-domain texts in
many scripts, as UTF-8 bytes), a DCT, a
Brainfuck interpreter, one of twenty-five emulated CPUs, or one of ten
decoders (Deflate, LZ4, Snappy, a Brotli-like coder, a prefix code, Morse,
Rice residuals, WebP's boolean decoder, PNG filters, a JPEG block), and
whatever comes out becomes the cell's new content. The whole thing is an experiment in
life seen as information: entropy, compression and code execution.

The simulation, the changers and the renderer are one WebAssembly module
written by hand in the text format. The pages are self-contained files
with the module inlined as base64, so they run straight from `file://`.

## Run it

Open `index.html` (the lattice) or `life.html` (a Game of Life, the older
and smaller demo) in a browser, or build them yourself (below). Click a
cell to inspect it, shift-drag to paint ones, ctrl-shift-drag to paint
zeros.

The **Preset** menu at the top of the controls sets every control at once
to a named picture: the Brotli front, the dissolving cloud, the foam, the
codebook cycles on pairs, the Motorola 68000, PDP-11 and VAX-11/780 link machines
with the mixing and settling off, the Declaration through the LZ
decompressor. The **Settings** line below it is the same thing as
text, `keimli1 size=1024x1024 dict=ca-gray20c ...`: Copy settings puts
the current state there and on the clipboard, Apply (or Enter) sets the
page from whatever is pasted in, and Copy link gives a URL to the public
page that opens with those settings, as `#s=` after the address. Unknown
keys in a line are ignored and missing ones take the defaults, so lines
survive page updates.

## How it works

The documentation follows the layers of the system, and so does the source
tree.

| Layer | What it is | Documentation | Source |
|---|---|---|---|
| Lattice | 128-bit cells, entropy increase through gene swapping, the swap order, entropy decrease through median filtering, mutation, the worker band pipeline | [docs/lattice.md](docs/lattice.md) | `src/lattice/` |
| Local changers | Entropy decrease through local changers, which rewrite every cell each turn: the LZ decompressor and its code tables, Brainfuck, simple transforms, DCT, the ten decoders; cell pair joinings and the persistent per-link CPUs that run on them | [docs/changers.md](docs/changers.md) | `src/changers/` |
| CPUs | Twenty-five emulated machines that run a cell's 16 bytes as their whole memory, from the 4004 to the CDC 6600 | [docs/cpus.md](docs/cpus.md) | `src/changers/cpu/` |
| Rendering | Views and the byte colour LUT, the temporal render buffer, spatial sharpening, drawing, the byte histogram and entropy trace | [docs/rendering.md](docs/rendering.md) | `src/render/`, `src/page/` |
| Life | Conway's Game of Life in 600 bytes of wasm | [docs/life.md](docs/life.md) | `src/life/` |

A turn, in order: snapshot, four swap phases, smoothing passes, byte
changer, mutation, render. The page's Help button tells the same story section by
section, under the controls it explains.

## Repository map

```
src/
  lattice/        lattice.wat   swap kernels, bit-plane median filtering, grid utilities (module preamble)
                  band.js       a turn, the swap order, bands for worker threads
  changers/       decode.wat    byte-changer entry point and the LZ decoder
                  codec.js      length codes, memory layout (LAYOUT), installer, byte colour LUT
                  declaration.txt   the US Declaration of Independence, the dictionary of the examples
                  dict/         seventeen more texts in many scripts, the codebook-search dictionaries and their manifest.json (title, author, language, source)
                  brainfuck.wat, simple.wat, dct.wat
                  codecs.wat    the decoders: Deflate, LZ4, Snappy, Brotli-like, prefix code, Morse, Rice, VP8, PNG filters, JPEG
    cpu/          common.wat    register file and pixel memory helpers shared by all cores
                  driver.wat    the run loop, register load and spill
                  z80.wat i8080.wat m6502.wat subleq.wat chip8.wat i4004.wat sm83.wat i8051.wat
                  m6809.wat riscv.wat pdp8.wat pdp11.wat m68k.wat u1101.wat vax.wat cdc6600.wat
  render/         render.wat    views, render buffer (blend), sharpening
  page/           lattice.html  the page template (controls, engines, inspector)
  life/           life.wat, life.html
docs/             one document per layer (table above)
tools/build.py    inlines a wasm module and the helper files into a page template
build.sh          assembles the module from the parts, compiles, builds the pages
test/             unit, band, activity and browser smoke tests
build/            assembled keimli.wat and the compiled modules (made by build.sh, not committed)
index.html, life.html   the built pages
```

The wasm module has one source of truth: the parts under `src/`. `build.sh`
concatenates them inside a `(module … )` wrapper into `build/keimli.wat`
and compiles that; edit the parts, never the assembled file.

## Build

    ./build.sh

Requires `wat2wasm` from the WebAssembly Binary Toolkit (wabt) and Python 3.
`./build.sh DIR` also writes page fragments without the document skeleton
into DIR, for embedding.

## Tests

    node test/mix.test.mjs        # code tables, decoder, mixing rule, smoothing, changers, every CPU, render buffer
    node test/band.test.mjs       # worker band pipeline == single-instance grid, bit for bit; the swap order
    node test/activity.test.mjs   # how much each local changer really changes; flags effectively idle ones
    sh test/smoke.sh              # loads both built pages in headless Chromium with #selftest, also with 4 workers

The unit suite decodes every pixel of a 512 × 384 random grid and checks
that no pixel consumes more than the decoder's 1024-bit input cap, that
rendering finishes in bounded time, and that the default random start
keeps moving. `test/cdp-poll.mjs` is the small DevTools-protocol poller the
smoke test uses.
