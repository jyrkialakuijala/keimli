#!/bin/sh
# The matched three-pass mechanism block (second panel, A1–A4, 2026-10-22): droplets3.mjs over the (swap, median) grid,
# 5 seeds, 128², 2,000 turns, three settling passes, for Brotli 12 and 13 (three types each, pairs, whole-lattice
# domains and the pre-melted sea), Swarm F and ca-gray3c (whole-lattice domains and pairs); the radius series for
# Brotli 12 and 13 at three settings; the start-replacement test on the frame at 256², 20 seeds; heredity patches at
# three passes; the melting-threshold scan. One job per (dictionary, setting, seed); jobs already written are skipped.
cd "$(dirname "$0")/../.." || exit 1
P=${1:-28}
O=paper/data/droplets3; mkdir -p $O paper/data/start-replace paper/data/pstar
D="node paper/experiments/droplets3.mjs n=128 turns=2000 passes=3 out=$O"
{
for seed in 1 2 3 4 5; do
for p in 0 0.1 0.25 0.5; do for m in 0.25 0.5 1; do
  for d in ca-brotli-12 ca-brotli-13; do echo "$D dict=$d p=$p m=$m seed=$seed modes=pairs,whole,premelt 2>> $O/$d.log"; done
  for d in ca-swarm-f ca-gray3c; do echo "$D dict=$d p=$p m=$m seed=$seed modes=pairs,whole 2>> $O/$d.log"; done
done; done
for s in "0.1 0.5" "0.5 0.5" "0.1 1"; do set -- $s; for d in ca-brotli-12 ca-brotli-13; do
  echo "$D dict=$d p=$1 m=$2 seed=$seed modes=radius turns=1000 2>> $O/$d-radius.log"; done; done
done
for s in 1-5 6-10 11-15 16-20; do echo "node paper/experiments/start-replace.mjs dict=ca-brotli-12 n=256 turns=2000 seeds=$s page=1 2>> paper/data/start-replace/ca-brotli-12.log"; done
for d in ca-brotli-12 ca-brotli-13; do echo "node paper/experiments/heredity.mjs dict=$d passes=3 2>> paper/data/heredity/$d-pass3.log"; done
for d in "ca-brotli-12 4096" "ca-brotli-13 4096" "ca-swarm-f 4096" "ca-gray3c 4096" "ca-cyc5to12 60000"; do set -- $d
  echo "node paper/experiments/pstar.mjs dict=$1 cread=$2 2>> paper/data/pstar/$1.log"; done
} | xargs -P "$P" -I{} sh -c '{}'
echo "droplets3 batch done"
