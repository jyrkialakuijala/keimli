# The swap order and the lattice's anisotropy

2026-10-20. Runs by `paper/experiments/ablation.mjs ... altorder=0|1` into
`paper/data/design/order/`: Swarm F, all three stages, swap p = ½, median
p = 1, quenched hashing, 256², 400 turns, seeds 1 to 3, bulk margin 32.

The four swap phases of a turn have run in the fixed order UD0 LR0 UD1 LR1
since the lattice was built, so the two left–right exchanges always came
last before the settling passes and the rewriting. The author saw more
lateral than vertical propagation on the page and proposed alternating the
order by turn parity, odd turns running the mirror LR0 UD0 LR1 UD1.

Schemes (`Band.SCHEMES`, harness `altOrder`, `ablation.mjs altorder=`):
fixed UD0 LR0 UD1 LR1; alternate (the mirror LR0 UD0 LR1 UD1 on odd turns);
palindrome (UD0 LR0 LR1 UD1 and LR0 UD0 UD1 LR1 in alternation, each turn
symmetric in the distance of the two directions from the settling); cycle4
(the four orders in turn); rotate (the pattern turned by 90° each turn, the
four variations, the brick offsets turning with the directions: UD0 LR0 UD1
LR1, LR0 UD0 LR1 UD1, UD1 LR1 UD0 LR0, LR1 UD1 LR0 UD0); random (one of the
six orders by a hash of the turn).

| scheme | seeds | ξx | ξy | ξy/ξx | C(1) x / y | C(8) x / y | d1 |
|---|---|---|---|---|---|---|---|
| fixed | 6 | 37.7 | 44.9 | 1.19 | 0.954 / 0.963 | 0.680 / 0.735 | 0.354 |
| alternate | 6 | 37.3 | 34.8 | 0.93 | 0.964 / 0.965 | 0.741 / 0.750 | 0.363 |
| palindrome | 6 | 47.1 | 45.1 | 0.96 | 0.967 / 0.967 | 0.771 / 0.768 | 0.383 |
| cycle4 | 3 | 29.0 | 56.1 | 1.93 | 0.966 / 0.967 | 0.758 / 0.767 | 0.362 |
| **rotate** | 6 | 57.5 | 59.7 | 1.04 | 0.974 / 0.975 | 0.816 / 0.822 | 0.405 |
| random | 3 | 60.0 | 49.7 | 0.83 | 0.968 / 0.967 | 0.776 / 0.764 | 0.378 |

(ξ: the distance at which the Hamming correlation C(r) crosses ½, mean over
seeds, capped at 64; near the cap ξ is noisy at six seeds, and C(1), C(8)
along the two axes are the steadier measure.)

The fixed order is the only anisotropic one by the steady measures: C(8)
0.680 along x against 0.735 along y, C(1) 0.954 against 0.963. Every scheme
that moves the lateral phases away from the last place equalises both to
within 0.01. Among them the 90° rotation, the author's suggestion, is the
most symmetric in construction (over four turns each direction and each
brick offset takes each position once) and gave the most ordered lattice
(C(8) 0.82 both ways, ξ near the cap, d1 0.405). It is the page's default
from 2026-10-20 (Mixing, More settings, "Swap order"); the harness keeps the
fixed order unless told otherwise, so the recorded data stand, and the
article's lattice runs must be repeated under the rotating order
(`PLAN_AMENDMENTS.md`, section 5). The pair modes keep one anisotropy no
order can remove: the pairs are horizontal; turning the pairing by 90° on
alternate turns would need the join in `decode.wat` to pair (i, i + W).
