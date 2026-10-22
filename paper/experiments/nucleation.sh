#!/bin/sh
# The nucleation tests (results/nucleation.md), 2026-10-22: the leading fixed point against the leading cycle of Brotli
# 12 and 13 at three settling passes. Radius series in an in-phase sea (R* by setting, 10 seeds); spontaneous
# appearance in a disordered sea at 64², 128² and 256² (rate, clusters, waiting time against area, 10 seeds) and in an
# in-phase sea (the Lemma 1 control); discs of radius 16 and 4 in seas of graded disorder (R* against order).
cd "$(dirname "$0")/../.." || exit 1
P=${1:-28}
O=paper/data/nucleation; mkdir -p $O
R="node paper/experiments/nucleation.mjs out=$O"
{
for seed in 1 2 3 4 5 6 7 8 9 10; do
for d in ca-brotli-12 ca-brotli-13; do
  for s in "0.1 0.5" "0.25 0.5" "0.5 0.5" "0.1 0.75"; do set -- $s; echo "$R dict=$d mode=radius p=$1 m=$2 q=0 seed=$seed 2>> $O/$d-radius.log"; done
  for s in "0.1 0.5" "0.25 0.5" "0.5 0.5"; do set -- $s; for n in 64 128 256; do echo "$R dict=$d mode=spontaneous p=$1 m=$2 q=1 n=$n seed=$seed 2>> $O/$d-spontaneous.log"; done; done
  for s in "0.1 0.5" "0.5 0.5"; do set -- $s; for r in 16 4; do echo "$R dict=$d mode=q p=$1 m=$2 r=$r qs=0,0.05,0.1,0.25,0.5,1 seed=$seed 2>> $O/$d-q.log"; done; done
done; done
for seed in 1 2 3; do for d in ca-brotli-12 ca-brotli-13; do for s in "0.1 0.5" "0.25 0.5" "0.5 0.5"; do set -- $s
  echo "$R dict=$d mode=spontaneous p=$1 m=$2 q=0 n=128 seed=$seed 2>> $O/$d-spontaneous-q0.log"; done; done; done
} | xargs -P "$P" -I{} sh -c '{}'
echo "nucleation batch done"
