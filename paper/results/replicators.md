# The replicator Monte Carlo: when attractors appear and how fast they take over

2026-10-21. `experiments/replicators.mjs`, batch `replicators-all.sh`
(nine dictionaries, 128² and 256², 2,000 turns, five seeds, under uniform
swap ½ and median 1 and under the page's gradient frame), summary
`replicators-summary.mjs` → `replicators-table.md`. The long batch
(`replicators-long.sh`: 20,000 turns under the frame at 256² and 512²)
is running and will be added. Raw data `../data/replicators/`.

**The detector.** No knowledge of a dictionary's cycles is used. A cell is
on a k-cycle (k ≤ 12 here) when its content has repeated with period k
over the last 2k turns; the cycle's identity is the canonical rotation of
its k state hashes, so a type is the same wherever and whenever it is
found. A k-cycle can therefore be seen from turn 2k − 1 on: a 3-cycle from
turn 5, an 8-cycle from turn 15. The basin of a type is its
share of random cells after 200 turns of the decoder alone.

## What the 2,000-turn batch shows

**No late first appearance.** Every type that ever held 1 % of the
cells was present as soon as it could be seen, in every run of every
dictionary: Swarm F's 3-cycle at turn 8, Brotli 12's fixed point at
turn 10, the Gray 8-cycles at turn 16 and the twelve-cycle at turn 30,
each a few turns after its period's first possible detection, the
difference being the decoder's own transient. This is what the basins predict: the smallest basin of a
major types is 0.26 % (a fixed point of Brotli 12), and with 16,384 or
65,536 cells the expected waiting time 1 / (N b) for the first cell to
fall into any such basin is below one turn. A first appearance after
thousands of turns needs a basin below 1 / N, about 10⁻⁵ at 256², and no
detectable type of these dictionaries has one. The author's
observation of replicators appearing after ten thousand turns is
therefore not, in this batch, a first appearance; the long batch will
say whether any type with such a basin exists.

**Lateness is takeover, and the medium sets its pace.** What does happen
late is that a type present from the start at a share below notice
takes the lattice slowly. Which type that is depends on the entropy
budget, and under the frame how long it takes falls with the basin
(`figures/replicators-takeover.png`,
`figures/replicators-basin-vs-takeover.png`):

| dictionary | setting | n | winner | its basin | 50 % at turn | 90 % at turn |
|---|---|---|---|---|---|---|
| Brotli 12 | swap ½, median 1 | 256 | the 3-cycle | 99.6 % | 24 | never (84 %, three types) |
| Brotli 12 | page frame | 128 | a fixed point | 0.26 % | 716 | never (53 %) |
| Brotli 12 | page frame | 256 | the same fixed point | 0.34 % | 1,093 | never (53 %) |
| Brotli 13 | swap ½, median 1 | 256 | the 9-cycle | 92.9 % | 80 | never (78 %) |
| Brotli 13 | page frame | 128 | a fixed point | 2.8 % | 354 | never (61 %) |
| Brotli 13 | page frame | 256 | the same fixed point | 2.8 % | 585 | never (59 %) |
| Swarm F | swap ½, median 1 | 256 | the 3-cycle | 100 % | 24 | 31 |
| Swarm F | page frame | 256 | the 3-cycle | 100 % | 31 | never (66 %) |
| 20 Gray 8-cycles | swap ½, median 1 | 256 | one 8-cycle | 4.8 % | 36 | 62 |
| 20 Gray 8-cycles | page frame | 256 | one 8-cycle | 4.8 % | never (23 %, mosaic) | never |
| 32 Gray 8-cycles | page frame | 256 | one 8-cycle | 1.4 % | 249 | never (54 %) |
| 3 Gray 8-cycles (window 4096) | swap ½, median 1 | 256 | one 8-cycle | 26.8 % | 64 | never (58 %, three types) |

Under uniform strong settling the attractor with the largest basin wins
and wins fast: Swarm F's 3-cycle holds 90 % of the cells by turn 31, the
twenty-cycle design's leading type by turn 62, the thirty-two-cycle
design's by turn 74. Under the page frame the winner of Brotli 12 is a
fixed point whose basin is a three-hundredth of the 3-cycle's, and it
takes half the lattice after a thousand turns, about 1.5 times longer at
256² than at 128², as a front sweeping across would. A fixed point is
what the frame's strongly-settled rows favour: the majority filter makes
neighbours agree, a fixed point's neighbours agree once and for all, and
a cycle's neighbours disagree whenever their phases do. The winner under
a budget is therefore not the attractor that most random cells fall into
but the one the medium propagates best, and the slow part is the
propagation. Under the uniform setting the takeover takes 24 to 80 turns
whatever the basin; under the frame it takes about a thousand turns for
a basin of 0.3 % (Brotli 12), six hundred for 2.8 % (Brotli 13), two
hundred and fifty for 1.4 % (the thirty-two-cycle design) and forty for a
basin near 100 % (Swarm F, Brotli 1), so within the frame the time does
fall with the basin, roughly as its inverse square root, while the
budget sets the scale.

**Coexistence is the frame's rule, takeover the uniform setting's.**
Under the frame no run of any dictionary reached 90 % for one type
except the Gray 3-cycle design, and the designed dictionaries hold their
type mosaics (the twenty-cycle design's leader at 23 %); under the
uniform setting every single-attractor dictionary and every designed
dictionary with a clear funnel gave one type at 95 % or more in all
five seeds. The frame's frozen and noisy bands are where the others
survive.

**The texts.** The Declaration gives no cell on a cycle of period 12 or
less in 2,000 turns under either setting (1.3 % under the decoder
alone): its cycles are long, as the census found, and the detector would
need a longer window.

## Figures

- `figures/replicators-takeover.png`: every type that reached 5 % of
  the cells, its share against the turn, one panel per dictionary, every
  seed a line, blue the uniform setting and orange the frame, dotted 128²
  and solid 256²; the type leading at the end in a full line, the
  others thin, so that a change of leader shows as two curves crossing
  (Brotli 12 and 13 under the frame: the large-basin cycle rises first
  and gives way to the fixed point around turn 100 to 200; the
  twenty-cycle design under the frame: the first leader loses ground
  after turn 300 to later type).
- `figures/replicators-basin-vs-takeover.png`: the turn at which the
  leader held half the cells against its basin under the decoder alone,
  per seed and setting.

## For the draft

The paragraph of `RESULTS_REPLICATORS.md` on late appearance is to be
rewritten on these numbers: first appearance is immediate for every
type with a basin above 1 / N, and what is late is takeover, a
front-propagation time of order the lattice size under the budget, with
the winner chosen by the medium (settling favours fixed points, mixing
with weaker settling favours the large-basin cycle). The waiting-time
formula applies only to basins below 1 / N, which the long batch is
looking for.
