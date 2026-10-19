#!/bin/sh
# The second lattice batch (pre-registered in paper/PLAN_AMENDMENTS.md section 3): the dictionary-structure test
# (F raw against three shuffles, the word shuffle and the reversal, MSR at p = 0.5 / median 1, quenched, 10 seeds) and
# the scaling check (MSR and MS- at 128, 256 and 512 cells, 3 seeds; the margin stays n/8). Usage: ablation-extra.sh [parallel=28]
cd "$(dirname "$0")/../.."
P=${1:-28}
out=paper/data/ablation; mkdir -p $out
jobs=""
add() { jobs="$jobs $1"; }
for seed in 1 2 3 4 5 6 7 8 9 10; do
  for v in shuffle:1 shuffle:2 shuffle:3 wordshuffle:1 reverse:1; do add "cond=MSR pm=0.5 ps=1 salt=0 seed=$seed variant=$v n=256 turns=1000"; done
done
for seed in 1 2 3; do for n in 128 512; do for c in MSR MS-; do add "cond=$c pm=0.5 ps=1 salt=0 seed=$seed n=$n turns=1000"; done; done; done
printf '%s\n' "$jobs" | sed 's/ cond=/\ncond=/g' | grep . | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} out='"$out"' >> '"$out"'/log-extra.txt 2>&1'
echo done >> $out/log-extra.txt
