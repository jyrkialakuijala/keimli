# Designed pair dictionary ca-pairnib2

pair mode 3 (nib), 2 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 2 + 6 + 12 + 12 at distance 55, transform 1; head 83 bits; Gray bits 6, 7, 8; 69 head bytes allowed.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `2` | 128 | 6152 | `´c´c·c·"""""""""""""""""""""` | "\"FCss#\"\"\"\"\"\"\"\"\"\"" "\u0000°¶¶¶ \"\"\"\"\"\"\"\"\"\"" | 2 |
| B | `3` | 82 | 35848 | `#´c´c·c·#####################` | "\"CCss33333333333" "\u0000²¶¶¶ \"\"\"\"\"\"\"\"\"\"" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 52.1 %, B 1.7 %, none 46.2 %; within 8 turns 40.0 %; transient mean 7.0, p90 10, max 17.

