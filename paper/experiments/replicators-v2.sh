#!/bin/sh
# The replicator Monte Carlo rerun on the corrected pipeline (2026-10-21): the rotating swap order, the period detector
# to 64, provenance in every output, 20 seeds (10 at 512²); summarised censoring-aware by replicators-summary2.mjs.
cd "$(dirname "$0")/../.." || exit 1
P=${1:-10}
O=paper/data/replicators-v2; mkdir -p $O
R="node paper/experiments/replicators.mjs turns=2000 kmax=64 out=$O"
{
for d in "ca-brotli-12 4096" "ca-brotli-13 4096" "ca-swarm-f 4096"; do set -- $d
  echo "$R dict=$1 cread=$2 n=512 seeds=10 page=1 > $O/$1-page-n512.md 2> $O/$1-page-n512.log"; done
for k in 6 7 47; do for s in "page=1" "pm=0.5 ps=1"; do
  echo "$R changer=$k dict=declaration cread=4096 n=256 seeds=20 $s > $O/cpu$k-$(echo $s | tr -d ' =.')-n256.md 2> $O/cpu$k-$(echo $s | tr -d ' =.')-n256.log"; done; done
for n in 256 128; do
for d in "ca-swarm-f 4096" "ca-brotli-1 4096" "ca-brotli-12 4096" "ca-brotli-13 4096" "declaration 4096" "ca-gray3c 4096" "ca-gray20c 60000" "ca-gray32c 60000" "ca-cyc5to12 60000"; do set -- $d
  for s in "page=1" "pm=0.5 ps=1"; do
    echo "$R dict=$1 cread=$2 n=$n seeds=20 $s > $O/$1-$(echo $s | tr -d ' =.')-n$n.md 2> $O/$1-$(echo $s | tr -d ' =.')-n$n.log"; done; done; done
} | xargs -P "$P" -I{} sh -c '{}'
