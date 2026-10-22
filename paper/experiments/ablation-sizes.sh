#!/bin/sh
# Finite-size series (2026-10-21; PRE, Chaos): the full system (MSR) and the decoder-free MS-, at swap 1/2 and median 1
# and at swap 0.2 and median 0.5, quenched and turn-salted hashing, sizes 64, 128, 256, 512, seeds 1..3, 2,000 turns;
# connected correlations. Summary: ablation-summary.mjs dir=paper/data/ablation-sizes.
cd "$(dirname "$0")/../.."
P=${1:-8}
out=paper/data/ablation-sizes; mkdir -p $out
{ for n in 512 256 128 64; do for seed in 1 2 3; do for salt in 0 1; do for pp in "0.5 1" "0.2 0.5"; do set -- $pp
  echo "cond=MSR pm=$1 ps=$2 salt=$salt seed=$seed n=$n margin=$((n / 8))"; echo "cond=MS- pm=$1 ps=$2 salt=$salt seed=$seed n=$n margin=$((n / 8))"
done; done; done; done; } | xargs -P $P -I{} sh -c 'node paper/experiments/ablation.mjs {} turns=2000 out='"$out"' >> '"$out"'/log.txt 2>&1'
echo done >> $out/log.txt
