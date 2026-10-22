# Designed dictionary ca-votebit1: a cell with its 4-neighbour vote, bit-interleaved

pair mode 10 (self and vote, bit-interleaved), 1 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes. Every word is the next state in its doubled form, so the cell gets it in either role; 64 cell byte values allowed. Heads found by enumerating 1536 command tails.

| species | head (copies, distance, transform) | head bits | Gray bits of cell byte 0 | filler letter | cell letter | reading (bits) | cell state 0 | Hamming per step |
|---|---|---|---|---|---|---|---|---|
| A | 13e+13e+6r d 49 tf 3 | 68 | 6 8 9 | `5` | 0x77 | 64 | "7pv\u0016R\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001" | 2 |

## Census (3000 random cells)

Vote equal to the cell (a synchronised start): on a designed cycle A 29.4 %, none 70.6 %; within 8 turns 28.2 %; transient mean 5.4, p90 8, max 12.
Random vote on the first turn, then equal: A 15.4 %, none 84.6 %; within 8 turns 14.5 %.
