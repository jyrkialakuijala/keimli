#!/bin/sh
# A second worker on the replicators-v2b job list (2026-10-21): the CPU runs and the 128² runs first; replicators.mjs
# skips any configuration already done or claimed (lock file), so the two batches share the list without duplicates.
cd "$(dirname "$0")/../.." || exit 1
P=${1:-8}
O=paper/data/replicators-v2
R="node paper/experiments/replicators.mjs turns=2000 kmax=64 out=$O"
{
for k in 6 7 47; do for s in "page=1" "pm=0.5 ps=1"; do
  echo "$R changer=$k dict=declaration cread=4096 n=256 seeds=5 $s > $O/cpu$k-$(echo $s | tr -d ' =.')-n256.md 2> $O/cpu$k-$(echo $s | tr -d ' =.')-n256.log"; done; done
for d in "ca-swarm-f 4096" "ca-brotli-1 4096" "ca-brotli-12 4096" "ca-brotli-13 4096" "declaration 4096" "ca-gray3c 4096" "ca-gray20c 60000" "ca-gray32c 60000" "ca-cyc5to12 60000"; do set -- $d
  for s in "page=1" "pm=0.5 ps=1"; do
    echo "$R dict=$1 cread=$2 n=128 seeds=20 $s > $O/$1-$(echo $s | tr -d ' =.')-n128.md.c 2> $O/$1-$(echo $s | tr -d ' =.')-n128.log.c"; done; done
} | xargs -P "$P" -I{} sh -c '{}'
