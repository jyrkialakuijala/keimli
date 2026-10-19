#!/bin/sh
# The ablation batch (H1, amended): 256 x 256, 1,000 turns, uniform parameters at six (pm, ps) points, the seven stage
# conditions, quenched (salt 0) and annealed (salt 1) hashing, seeds 1..10, the reference dictionary; plus the hash null
# models (image sizes 2^93 and 2^64) in place of the decoder for the full MSR row. Conditions that do not use a stage
# are run once per parameter of the stages they do use. Usage: ablation-all.sh [parallel=28] [seeds="1 2 ... 10"]
cd "$(dirname "$0")/../.."
P=${1:-28}; SEEDS=${2:-"1 2 3 4 5 6 7 8 9 10"}
out=paper/data/ablation; mkdir -p $out
jobs=""
add() { jobs="$jobs $1"; }
for seed in $SEEDS; do for salt in 0 1; do
  for pm in 0.5 0.2 0.05; do for ps in 1 0.5; do
    add "cond=MSR pm=$pm ps=$ps salt=$salt seed=$seed"
    add "cond=MS- pm=$pm ps=$ps salt=$salt seed=$seed"
    add "cond=MSR pm=$pm ps=$ps salt=$salt seed=$seed rewrite=hash:93"
    add "cond=MSR pm=$pm ps=$ps salt=$salt seed=$seed rewrite=hash:64"
  done; done
  for pm in 0.5 0.2 0.05; do add "cond=M-R pm=$pm ps=1 salt=$salt seed=$seed"; add "cond=M-- pm=$pm ps=1 salt=$salt seed=$seed"; done
  for ps in 1 0.5; do add "cond=-SR pm=0.5 ps=$ps salt=$salt seed=$seed"; add "cond=-S- pm=0.5 ps=$ps salt=$salt seed=$seed"; done
  add "cond=--R pm=0.5 ps=1 salt=$salt seed=$seed"
done; done
printf '%s\n' "$jobs" | sed 's/ cond=/\ncond=/g' | grep . | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} n=256 turns=1000 out='"$out"' >> '"$out"'/log.txt 2>&1'
echo done >> $out/log.txt
