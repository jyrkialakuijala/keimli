#!/bin/sh
# Continuation of replicators-v2.sh after its CPU jobs were stopped (2026-10-21): the dictionaries at 256² and 128² not
# yet run, then the three CPUs with 5 seeds (20 seeds of a 256-instruction CPU at 256² take about 7 hours each).
cd "$(dirname "$0")/../.." || exit 1
P=${1:-8}
O=paper/data/replicators-v2
R="node paper/experiments/replicators.mjs turns=2000 kmax=64 out=$O"
{
for n in 256 128; do
for d in "ca-swarm-f 4096" "ca-brotli-1 4096" "ca-brotli-12 4096" "ca-brotli-13 4096" "declaration 4096" "ca-gray3c 4096" "ca-gray20c 60000" "ca-gray32c 60000" "ca-cyc5to12 60000"; do set -- $d
  for s in "page=1" "pm=0.5 ps=1"; do
    [ "$1 $s $n" = "ca-swarm-f page=1 256" ] && continue
    echo "$R dict=$1 cread=$2 n=$n seeds=20 $s > $O/$1-$(echo $s | tr -d ' =.')-n$n.md 2> $O/$1-$(echo $s | tr -d ' =.')-n$n.log"; done; done; done
for k in 6 7 47; do for s in "page=1" "pm=0.5 ps=1"; do
  echo "$R changer=$k dict=declaration cread=4096 n=256 seeds=5 $s > $O/cpu$k-$(echo $s | tr -d ' =.')-n256.md 2> $O/cpu$k-$(echo $s | tr -d ' =.')-n256.log"; done; done
} | xargs -P "$P" -I{} sh -c '{}'
