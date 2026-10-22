#!/bin/sh
# the replicator Monte Carlo over dictionaries, sizes and the two settings (uniform swap 1/2 median 1, and the page frame)
cd "$(dirname "$0")/../.." || exit 1
P=${1:-12}
{
for d in "ca-swarm-f 4096" "ca-brotli-1 4096" "ca-brotli-12 4096" "ca-brotli-13 4096" "declaration 4096" "ca-gray3c 4096" "ca-gray20c 60000" "ca-gray32c 60000" "ca-cyc5to12 60000"; do
  set -- $d
  for n in 128 256; do
    echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=$n turns=2000 seeds=5 kmax=12 > paper/data/replicators/$1-pm0.5-ps1-n$n.md 2> paper/data/replicators/$1-pm0.5-ps1-n$n.log"
    echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=$n turns=2000 seeds=5 kmax=12 page=1 > paper/data/replicators/$1-page-n$n.md 2> paper/data/replicators/$1-page-n$n.log"
  done
done
} | xargs -P "$P" -I{} sh -c '{}'
