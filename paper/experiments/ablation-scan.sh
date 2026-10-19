#!/bin/sh
# The third lattice batch: a scan along the median probability at swap p = 0.5, added after the first seed of the
# main batch showed the three-stage lattice nearly uniform at median p of 1 and 0.5 (paper/PLAN_AMENDMENTS.md
# section 4). MSR, MS-, and the hash93 and hashdict93 null models at median p in {0.3, 0.2, 0.1, 0.05, 0.02}, quenched
# and annealed, seeds 1..5; plus hashdict93 at the main batch's six points, quenched, seeds 1..5. Usage: ablation-scan.sh [parallel=28]
cd "$(dirname "$0")/../.."
P=${1:-28}
out=paper/data/ablation; mkdir -p $out
jobs=""
add() { jobs="$jobs $1"; }
for seed in 1 2 3 4 5; do for salt in 0 1; do for ps in 0.3 0.2 0.1 0.05 0.02; do
  add "cond=MSR pm=0.5 ps=$ps salt=$salt seed=$seed"
  add "cond=MS- pm=0.5 ps=$ps salt=$salt seed=$seed"
  add "cond=MSR pm=0.5 ps=$ps salt=$salt seed=$seed rewrite=hash:93"
  add "cond=MSR pm=0.5 ps=$ps salt=$salt seed=$seed rewrite=hashdict:93"
done; done; done
for seed in 1 2 3 4 5; do for pm in 0.5 0.2 0.05; do for ps in 1 0.5; do add "cond=MSR pm=$pm ps=$ps salt=0 seed=$seed rewrite=hashdict:93"; done; done; done
printf '%s\n' "$jobs" | sed 's/ cond=/\ncond=/g' | grep . | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} n=256 turns=1000 out='"$out"' >> '"$out"'/log-scan.txt 2>&1'
echo done >> $out/log-scan.txt
