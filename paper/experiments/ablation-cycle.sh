#!/bin/sh
# The fourth lattice batch: the cycle null models (one global 3-cycle, with the decoder's own states or random ones)
# for MSR at swap p = 0.5, median p in {1, 0.5, 0.2, 0.1, 0.05}, quenched and annealed, seeds 1..5. Usage: ablation-cycle.sh [parallel=28]
cd "$(dirname "$0")/../.."
P=${1:-28}
out=paper/data/ablation; mkdir -p $out
jobs=""
for seed in 1 2 3 4 5; do for salt in 0 1; do for ps in 1 0.5 0.2 0.1 0.05; do for rw in cycle3f cycle3; do
  jobs="$jobs cond=MSR pm=0.5 ps=$ps salt=$salt seed=$seed rewrite=$rw"
done; done; done; done
printf '%s\n' "$jobs" | sed 's/ cond=/\ncond=/g' | grep . | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} n=256 turns=1000 out='"$out"' >> '"$out"'/log-cycle.txt 2>&1'
echo done >> $out/log-cycle.txt
