#!/bin/sh
# The decoder-map battery (H4): nine dictionaries at four header ranges, three controls each at the reference range,
# three seeds for the reference dictionary. One JSON line per run under paper/data/decoder-map/.
cd "$(dirname "$0")/../.."
out=paper/data/decoder-map
jobs=""
for d in declaration don-quijote kalevala-1 ca-brotli-1 ca-brotli-9 ca-brotli-13 ca-swarm-a ca-swarm-d ca-swarm-f; do
  for v in 1 8 128 4096; do jobs="$jobs $d:$v:raw:1"; done
  for var in shuffle wordshuffle reverse; do jobs="$jobs $d:4096:$var:1"; done
done
for s in 2 3; do jobs="$jobs ca-swarm-f:4096:raw:$s"; done
for s in 2 3; do jobs="$jobs ca-swarm-f:4096:shuffle:$s"; done
echo $jobs | tr ' ' '\n' | xargs -P 16 -I{} sh -c 'IFS=: read d v var s <<EOT
{}
EOT
node paper/experiments/decoder-map.mjs $d $v 1000000 6 0 $var $s > '"$out"'/$d-V$v-$var-s$s.json 2>> '"$out"'/log.txt'
echo done
