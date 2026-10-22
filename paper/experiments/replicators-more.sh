#!/bin/sh
# the wider replicator Monte Carlo: every CPU kind, every searched and several text and designed dictionaries, ten seeds,
# both settings, and the annealed hashing for a few; 256 cells a side, 2,000 turns
cd "$(dirname "$0")/../.." || exit 1
P=${1:-10}
O=paper/data/replicators
{
for k in 6 7 8 9 10 11 12 13 14 15 19 20 21 22 23 24 25 26 27 28 29 30 43 44 47 2; do
  echo "node paper/experiments/replicators.mjs changer=$k dict=declaration cread=4096 n=256 turns=2000 seeds=10 kmax=12 > $O/cpu$k-pm0.5-ps1-n256.md 2> $O/cpu$k-pm0.5-ps1-n256.log"
  echo "node paper/experiments/replicators.mjs changer=$k dict=declaration cread=4096 n=256 turns=2000 seeds=10 kmax=12 page=1 > $O/cpu$k-page-n256.md 2> $O/cpu$k-page-n256.log"
done
for d in ca-brotli-2 ca-brotli-3 ca-brotli-4 ca-brotli-5 ca-brotli-6 ca-brotli-7 ca-brotli-8 ca-brotli-9 ca-brotli-10 ca-brotli-11 ca-brotli-14 ca-brotli-15 ca-swarm-a ca-swarm-b ca-swarm-c ca-swarm-d ca-swarm-e nam-quoc-son-ha-han iliad-1 kalevala-1 psalm-23 iroha don-quijote; do
  echo "node paper/experiments/replicators.mjs dict=$d cread=4096 n=256 turns=2000 seeds=10 kmax=12 > $O/$d-pm0.5-ps1-n256.md 2> $O/$d-pm0.5-ps1-n256.log"
  echo "node paper/experiments/replicators.mjs dict=$d cread=4096 n=256 turns=2000 seeds=10 kmax=12 page=1 > $O/$d-page-n256.md 2> $O/$d-page-n256.log"
done
for d in "ca-gray4c 4096" "ca-gray6c 4096" "ca-gray8c 60000" "ca-gray12c 60000" "ca-gray16c 60000" "ca-gray24c 60000"; do
  set -- $d
  echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=256 turns=2000 seeds=10 kmax=12 > $O/$1-pm0.5-ps1-n256.md 2> $O/$1-pm0.5-ps1-n256.log"
  echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=256 turns=2000 seeds=10 kmax=12 page=1 > $O/$1-page-n256.md 2> $O/$1-page-n256.log"
done
for d in "ca-swarm-f 4096" "ca-brotli-12 4096" "ca-brotli-13 4096" "ca-gray20c 60000"; do
  set -- $d
  echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=256 turns=2000 seeds=10 kmax=12 salt=1 > $O/$1-pm0.5-ps1-n256-salt1.md 2> $O/$1-pm0.5-ps1-n256-salt1.log"
  echo "node paper/experiments/replicators.mjs dict=$1 cread=$2 n=256 turns=2000 seeds=10 kmax=12 salt=1 page=1 > $O/$1-page-n256-salt1.md 2> $O/$1-page-n256-salt1.log"
done
} | xargs -P "$P" -I{} sh -c '{}'
