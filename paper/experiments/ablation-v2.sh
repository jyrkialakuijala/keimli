#!/bin/sh
# The ablation rerun on the corrected pipeline (2026-10-21): the rotating swap order, connected correlations (the bias of
# each bit plane subtracted), provenance; the stage conditions with the decoder at the six (pm, ps) points, quenched and
# annealed hashing, seeds 1..5, 256², 1,000 turns. Summary: ablation-summary.mjs dir=paper/data/ablation-v2.
cd "$(dirname "$0")/../.."
P=${1:-8}; SEEDS=${2:-"1 2 3 4 5"}
out=paper/data/ablation-v2; mkdir -p $out
{ for seed in $SEEDS; do for salt in 0 1; do
  for pm in 0.5 0.2 0.05; do for ps in 1 0.5; do echo "cond=MSR pm=$pm ps=$ps salt=$salt seed=$seed"; echo "cond=MS- pm=$pm ps=$ps salt=$salt seed=$seed"; done; done
  for pm in 0.5 0.2 0.05; do echo "cond=M-R pm=$pm ps=1 salt=$salt seed=$seed"; done
  for ps in 1 0.5; do echo "cond=-SR pm=0.5 ps=$ps salt=$salt seed=$seed"; done
done; done; } | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} n=256 turns=1000 out='"$out"' >> '"$out"'/log.txt 2>&1'
echo done >> $out/log.txt
