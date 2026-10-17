#!/bin/sh
# Build Keimli: assemble the wasm module from its parts, compile both modules with wat2wasm,
# and inline everything into two self-contained pages that work from file://.
#   index.html  the bit swap lattice (src/page/lattice.html + build/keimli.wasm + codec, band, dictionary)
#   life.html   Conway's Game of Life (src/life/life.html + build/life.wasm)
# Pass a directory as $1 to also emit artifact fragments (no document skeleton) there.
set -e
cd "$(dirname "$0")"
mkdir -p build

# The module parts, in the order of the documentation: lattice, changers, render, CPU cores.
# Each part is a bare list of module fields; the wrapper (module ... ) is added here.
PARTS="
  src/lattice/lattice.wat
  src/changers/decode.wat
  src/changers/brainfuck.wat
  src/changers/simple.wat
  src/changers/dct.wat
  src/changers/codecs.wat
  src/render/render.wat
  src/changers/cpu/common.wat
  src/changers/cpu/driver.wat
  src/changers/cpu/z80.wat
  src/changers/cpu/i8080.wat
  src/changers/cpu/m6502.wat
  src/changers/cpu/subleq.wat
  src/changers/cpu/chip8.wat
  src/changers/cpu/i4004.wat
  src/changers/cpu/sm83.wat
  src/changers/cpu/i8051.wat
  src/changers/cpu/m6809.wat
  src/changers/cpu/riscv.wat
  src/changers/cpu/pdp8.wat
  src/changers/cpu/pdp11.wat
  src/changers/cpu/m68k.wat
  src/changers/cpu/u1101.wat
  src/changers/cpu/vax.wat
  src/changers/cpu/cdc6600.wat
  src/changers/cpu/x86.wat
  src/changers/cpu/i860.wat
  src/changers/cpu/pic1640.wat
  src/changers/cpu/alpha.wat
  src/changers/cpu/parisc.wat
"
{
  echo ";; Assembled by build.sh from the parts under src/; edit those, not this file."
  echo "(module"
  for f in $PARTS; do
    echo ""
    echo "  ;; ======================================================================== $f"
    cat "$f"
  done
  echo ")"
} > build/keimli.wat

wat2wasm build/keimli.wat -o build/keimli.wasm
wat2wasm src/life/life.wat -o build/life.wasm
python3 tools/build.py src/life/life.html build/life.wasm life.html
python3 tools/build.py src/page/lattice.html build/keimli.wasm index.html --codec src/changers/codec.js --band src/lattice/band.js --text src/changers/declaration.txt --dicts src/changers/dict/manifest.json
if [ -n "$1" ]; then
  python3 tools/build.py src/life/life.html build/life.wasm "$1/life-wasm.html" --artifact
  python3 tools/build.py src/page/lattice.html build/keimli.wasm "$1/bit-swap-lattice.html" --artifact --codec src/changers/codec.js --band src/lattice/band.js --text src/changers/declaration.txt --dicts src/changers/dict/manifest.json
fi
