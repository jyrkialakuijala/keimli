# Conway's Game of Life

Source: `src/life/life.wat` (about 600 bytes compiled) and the page
template `src/life/life.html`, built into `life.html`.

Cells are one byte each: 0 is dead and 1–255 is a live cell's age in
generations, saturating. Edges wrap (a torus). The host decides the memory
layout and passes the grid addresses in.

Exports: `step` (next generation of `src` into `dst`), `render` (RGBA
image of a grid), `population`, `randomize`.

The page runs the simulation from a self-contained HTML file with the wasm
inlined as base64, and `#selftest` runs 50 generations at boot so the smoke
test can check the generation and population counters.
