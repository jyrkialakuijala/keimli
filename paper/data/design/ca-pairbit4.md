# Designed pair dictionary ca-pairbit4

pair mode 2 (bit), 4 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 10 + 10 + 12 at distance 33, transform 1; head 70 bits; Gray bits 10, 11, 12; 69 head bytes allowed.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `7` | 64 | 16928 | `33;11111111111111111111111` | "\u0004TTTTUUUUUUUUUUU" " PRrBDDDDDDDDDDD" | 2 |
| B | `?` | 64 | 16896 | `33;22222222222222222222222` | "\u0004TTTDDDDDDDDDDDD" "PRrRUUUUUUUUUUU" | 2 |
| C | `9` | 133 | 25152 | `33;33333333333333333333333` | "DTTTTUUUUUUUUUUU" "RRrRUUUUUUUUUUU" | 2 |
| D | `3` | 82 | 49344 | `0033;44444444444444444444444` | "DTTTdfffffffffff" "@TRrBDDDDDDDDDDD" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 0.1 %, B 55.6 %, C 14.4 %, D 28.6 %, none 1.3 %; within 8 turns 81.0 %; transient mean 7.0, p90 10, max 29.

