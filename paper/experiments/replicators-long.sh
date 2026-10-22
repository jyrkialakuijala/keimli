#!/bin/sh
# the long Monte Carlo: 20,000 turns under the page frame, for the late appearances the author saw after ten thousand turns
cd "$(dirname "$0")/../.." || exit 1
P=${1:-6}
{
for d in "ca-gray20c 60000" "ca-gray32c 60000" "ca-brotli-12 4096" "ca-brotli-13 4096" "declaration 4096" "ca-swarm-f 4096"; do
  set -- $d
  for n in 256 512; do
    echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=$n turns=20000 seeds=3 kmax=16 page=1 > paper/data/replicators/$1-page-n$n-t20000.md 2> paper/data/replicators/$1-page-n$n-t20000.log"
  done
done
} | xargs -P "$P" -I{} sh -c '{}'
