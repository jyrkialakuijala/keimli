#!/bin/sh
# Exact fixed-point counts (map-exact.mjs, K = 1) for the 30 byte shuffles and 30 word shuffles of a dictionary; a
# per-header node cap (default 2 * 10^8, env CAP; Swarm F's largest header needs 1.6 * 10^8) bounds the time, and capped headers are
# listed in each output (count then a lower bound). Usage: sh paper/experiments/map-shuffles-exact.sh [dict] [workers]
D=${1:-ca-swarm-f}; W=${2:-10}
cd "$(dirname "$0")/../.."
for v in shuffle wordshuffle; do for s in $(seq 1 30); do
  [ -f paper/data/map/exact-$D-$v$s-K1.json ] && continue
  node paper/experiments/map-exact.mjs $D 1 $W $v $s all nodecap=${CAP:-200000000} store=200 2>/dev/null
done; done
