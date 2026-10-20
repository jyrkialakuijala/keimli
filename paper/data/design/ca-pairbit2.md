# Designed pair dictionary ca-pairbit2

pair mode 2 (bit), 2 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 10 + 10 + 12 at distance 33, transform 1; head 70 bits; Gray bits 10, 11, 12; 69 head bytes allowed.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `7` | 64 | 16928 | `33;11111111111111111111111` | "\u0004TTTTUUUUUUUUUUU" " PRrBDDDDDDDDDDD" | 2 |
| B | `?` | 64 | 16896 | `33;22222222222222222222222` | "\u0004TTTDDDDDDDDDDDD" "PRrRUUUUUUUUUUU" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 0.1 %, B 34.1 %, none 65.8 %; within 8 turns 26.2 %; transient mean 7.5, p90 11, max 29.

