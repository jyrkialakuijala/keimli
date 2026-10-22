#!/bin/sh
# The 17 dictionaries 2^8 .. 2^24 as separate processes (P at a time, W worker threads each: P x W = 24 of the 32 cores),
# then the manifest merge. Logs in paper/data/design/ca-size-NN.log. Usage: paper/experiments/design-scale.sh [P] [W]
cd "$(dirname "$0")/../.."
P=${1:-6}; W=${2:-4}
mkdir -p paper/data/design
seq 8 24 | xargs -P "$P" -I{} sh -c 'node paper/experiments/design-scale.mjs sizes={} workers='"$W"' 2> paper/data/design/ca-size-{}.log || echo "size {} failed"'
node paper/experiments/design-scale.mjs merge
