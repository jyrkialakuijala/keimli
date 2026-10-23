#!/bin/sh
# The design series (paper/results/dictionary-size-seeds.md): seeds 2..11 of every size 2^8 .. 2^26 generated into
# paper/data/design-seeds (12 processes x 2 threads; the pattern enumeration is cached per size, so the jobs run
# seed-major), then the map census and one frame lattice run (256², 2,000 turns, lattice seed = design seed) for every
# design, seed 1 included, into paper/data/scale-seeds. Existing outputs are skipped. Usage: paper/experiments/scale-seeds.sh [P] [W]
cd "$(dirname "$0")/../.."
P=${1:-12}; W=${2:-2}
mkdir -p paper/data/design-seeds paper/data/scale-seeds
for seed in $(seq 2 11); do for s in $(seq 8 26); do echo "$s $seed"; done; done |
  xargs -P "$P" -L 1 sh -c '[ -f paper/data/design-seeds/ca-size-$(printf %02d $0)-s$1.txt ] || node paper/experiments/design-scale.mjs sizes=$0 seed=$1 workers='"$W"' 2>> paper/data/design-seeds/batch.log || echo "size $0 seed $1 failed" >> paper/data/design-seeds/batch.log'
for s in $(seq 8 26); do for seed in $(seq 1 11); do echo "$s $seed"; done; done |
  xargs -P 24 -L 1 sh -c 'node paper/experiments/scale-map.mjs size=$0 design=$1 out=paper/data/scale-seeds 2>> paper/data/scale-seeds/batch.log; node paper/experiments/scale-run.mjs size=$0 design=$1 setting=frame out=paper/data/scale-seeds >> paper/data/scale-seeds/batch.log 2>&1'
