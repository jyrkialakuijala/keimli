#!/bin/sh
# Compile each .wat with wat2wasm, then inline the module into its page template
# to produce a single self-contained HTML file that works from file://.
# Pass a directory as $1 to also emit artifact fragments (no document skeleton) there.
set -e
cd "$(dirname "$0")"
wat2wasm life.wat -o life.wasm
wat2wasm mix.wat -o mix.wasm
python3 build.py page.html life.wasm index.html
python3 build.py mix-page.html mix.wasm mix.html --codec mix-codec.js --band mix-band.js --text declaration.txt
if [ -n "$1" ]; then
  python3 build.py page.html life.wasm "$1/life-wasm.html" --artifact
  python3 build.py mix-page.html mix.wasm "$1/bit-swap-lattice.html" --artifact --codec mix-codec.js --band mix-band.js --text declaration.txt
fi
