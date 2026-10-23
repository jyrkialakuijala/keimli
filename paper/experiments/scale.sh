#!/bin/sh
# The dictionary-size experiment (paper/results/dictionary-size.md): the map alone and the lattice runs for every size
# 2^8 .. 2^26, one process per (size, setting, seed), P at a time; existing outputs are skipped. Then the 512 x 512 run of
# 2^24 in the frame. Usage: paper/experiments/scale.sh [P]
cd "$(dirname "$0")/../.."
P=${1:-24}
mkdir -p paper/data/scale
seq 8 26 | xargs -P "$P" -I{} sh -c 'f=paper/data/scale/map-ca-size-$(printf %02d {}).json; [ -f "$f" ] || node paper/experiments/scale-map.mjs size={} 2>> paper/data/scale/batch.log'
for s in $(seq 8 26); do for setting in frame uniform; do for seed in 1 2 3; do echo "$s $setting $seed"; done; done; done |
  xargs -P "$P" -L 1 sh -c 'node paper/experiments/scale-run.mjs size=$0 setting=$1 seed=$2 >> paper/data/scale/batch.log 2>&1'
node paper/experiments/scale-run.mjs size=24 setting=frame seed=1 n=512 >> paper/data/scale/batch.log 2>&1
