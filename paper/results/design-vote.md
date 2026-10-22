# A dictionary designed for a cell joined with its 4-neighbour vote

2026-10-20. The Life-like preset rewrites every cell through the decoder
together with its 4-neighbour vote, interleaved one bit at a time (the
Cells entry "Self and its 4-neighbour vote, interleaved 1 bit at a time",
pair mode 10). The author asked for a dictionary designed for that use,
keeping the earlier preset with the twenty-cycle single-cell dictionary.
`paper/experiments/design-vote.mjs` builds it; the result is
`ca-vote1` (61,440 bytes, window 60000), the preset "Life-like with the
dictionary designed for it".

**Construction.** In a synchronised domain the vote equals the cell, so
the joint cell the decoder sees is the cell S with every bit doubled, in
either role. A cycle S_0 .. S_7 therefore needs, at the pointer that the
doubled S_k reads, the word dup(S_{k+1}): both halves of the split are
S_{k+1}, and the cell gets it whichever role leads; the vote half of the
output is discarded. The words live in a file the page reads as UTF-8, so
a word byte must stay below 0x80: dup(n) does for the nibbles 0 to 7 (the
bytes 0x00, 03, 0C, 0F and '0', '3', '<', '?'), which fixes bits 6 and 7
of every joint byte to 0 and leaves three doubled pairs free. With the
printable four alone no copy command fits; with the eight, 48 headers and
24 of 22 million command forms fit at the 16-bit header (none at 12 or 14
bits). The chosen head is three copies of 10 + 13 + 9 bytes at distance
49, 68 joint bits; the Gray code runs on three doubled header pairs (bits
4,5, 6,7 and 10,11), so consecutive states differ in one bit of the cell
plus the parity byte. The filler is a constant letter with landing pads
for the doubled cell a filler copy produces (a cell that copied '5'
everywhere is all 0x77, and so on); one type of an 8-cycle fits.

**Census** (10,000 random cells with the vote equal to themselves): 76.6 %
reach the cycle, 73 % within 8 turns, transient mean 5.2, the rest wander;
with a random vote on the first turn 82 %. A cell one phase behind its
four neighbours does not land on a designed state in one step (the mixed
header points elsewhere), so the pull towards neighbours goes through the
filler.

**On the lattice** (256², 400 turns, quenched, settling 4-connected one
pass p = 1, the vote partner, `type-run.mjs`):

| mixing | on the cycle | phase coherence | phase domains | d1 |
|---|---|---|---|---|
| swaps, rotating, p = 0.5 | 100 % | 0.91 | 50 | 0.016 |
| synchronous isotropic, p = 0.5 | 99.5 % | 0.83 | 216 | 0.016 |

Both order the whole lattice onto the cycle; the swaps synchronise the
phase better (50 against 216 phase domains), as they did for the
single-cell dictionaries (`life-vote.md`).

## The other joinings, and the byte-joined two-type dictionary (2026-10-21)

The author found the preset "Pairs byte-interleaved: ten designed types"
boring; on the lattice that design never reaches its cycles under any
coupling (100 % off-cycle under the page frame, under swaps or median
alone, and under the synchronous mixing), as the interleaved pixel-pair
designs do not. The designer was generalised to all four joinings of the
vote partner (`design-vote.mjs mode=2|3|4|5`), now by enumerating the
joint bytes after the header over the allowed doubled images (16.8 to
30 million tails) and parsing them as the decoder does, then taking the
Gray walk on cell bits whose doubled image lies in the skipped or high
header bits only.

| joining | cell byte values | tails that parse | result |
|---|---|---|---|
| bit (mode 2) | 64 | 1,536 | one type (as `ca-vote1`) |
| 2-bit (mode 4) | 49 | 0 | no head fits |
| nibble (mode 3) | 64 | 0 | no head fits |
| byte (mode 5) | 74 (letters excluded) | 4 | two types, `ca-votebyte2` |

The nibble and 2-bit joinings double nibbles or bit pairs into bytes whose
two halves repeat, and no copy command survives that constraint at any
header width tried (10 to 16 bits). The byte joining repeats whole bytes:
four command tails parse, 24 cycle candidates, and two types fit the
slots and pads. Its funnel is the best of the designs: of 5,000 random
cells 99.8 % reach a cycle, 93 % within 8 turns, the two basins 54 and 46
%, and a cell one phase behind its neighbours lands on a designed state in
16 of 80 cases. On the lattice (256², 400 turns, the vote partner byte by
byte) type A wins: under uniform swaps p = 0.5 it holds the whole
lattice by turn 400 (B gone by turn 100, 127 phase domains), under the
page's gradient frame 87 % of the cells are A, 13 % off-cycle in the
noisy band, B gone. The preset "Self and its 4-neighbour vote,
byte-interleaved: two designed types competing" replaces the old one;
the competition is over in the first hundred turns, after which the
picture is one type' phase domains.
