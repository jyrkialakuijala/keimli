# Designed dictionary ca-gray14c

14 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "7??" "+3" ";7" "9" "+';" "?'" "?+" "';" ";" "3\"2" "?3" "&3" "'+3" "+7", blocks 35076, 35972, 40192, 41100, 41228, 42112, 45192, 48260, 51456, 54400, 55424, 56584, 57480, 58636, bounds 4286, 8571, 12857, 17143, 21429, 25714, 30000, 34286, 38571, 42857, 47143, 51429, 55714, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `7??` | 48 | 35076 | `0A"3$#D7??7??7??` | 1 |
| B | `+3` | 48 | 35972 | `1!#3$#D+3+3+3+3+` | 1 |
| C | `;7` | 48 | 40192 | `2@'3$#D;7;7;7;7;` | 1 |
| D | `9` | 59 | 41100 | `3#(3$#D999999999` | 1 |
| E | `+';` | 64 | 41228 | `4C(3$#D+';+';+';` | 1 |
| F | `?'` | 64 | 42112 | `5 )3$#D?'?'?'?'?` | 1 |
| G | `?+` | 48 | 45192 | `6",3$#D?+?+?+?+?` | 1 |
| H | `';` | 64 | 48260 | `7!/3$#D';';';';'` | 1 |
| I | `;` | 48 | 51456 | `8@23$#D;;;;;;;;;` | 1 |
| J | `3"2` | 60 | 54400 | `9 53$#D3"23"23"2` | 1 |
| K | `?3` | 48 | 55424 | `: 63$#D?3?3?3?3?` | 1 |
| L | `&3` | 58 | 56584 | `;B73$#D&3&3&3&3&` | 1 |
| M | `'+3` | 64 | 57480 | `<"83$#D'+3'+3'+3` | 1 |
| N | `+7` | 48 | 58636 | `=C93$#D+7+7+7+7+` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder).

Filler: the patterns tiled over the regions [[0,4286],[4286,8571],[8571,12857],[12857,17143],[17143,21429],[21429,25714],[25714,30000],[30000,34286],[34286,38571],[38571,42857],[42857,47143],[47143,51429],[51429,55714],[55714,60000]]; landing pads: A 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "0a\"3$#d+3+3+3+3+")) and 56511..56517 (reads 48 bits, lands on off-cycle (head wrong: "0a\"3$#d+7+7+7+7+")) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "0a\"3$#d+3+3+3+3+")); B 44191..44197 (reads 48 bits, lands on off-cycle (head of state 0)) and 52383..52389 (reads 48 bits, lands on off-cycle (head wrong: "1!#3$#d+3'+3'1!#")); C 591..597 (reads 48 bits, lands on off-cycle (head wrong: "2@'3$#d??7??7??7")) and 56527..56533 (reads 48 bits, lands on off-cycle (head wrong: "2@'3$#d+7+7+7+7+")); D 58590..58573 (reads 59 bits, lands on off-cycle (head of state 0)); E 543..549 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44229 (reads 64 bits, lands on off-cycle (head wrong: "4c(3$#d3?3?3?3?3")) and 40063..40069 (reads 48 bits, lands on off-cycle (head of state 0)); F 4607..4613 (reads 64 bits, lands on off-cycle (head wrong: "5 )3$#d+3+3+3+3+")) and 40159..40165 (reads 48 bits, lands on off-cycle (head of state 0)); G 4623..4629 (reads 48 bits, lands on off-cycle (head wrong: "6\",3$#d+3+3+3+3+")) and 44239..44245 (reads 48 bits, lands on off-cycle (head of state 0)); H 40143..40149 (reads 48 bits, lands on off-cycle (head of state 0)) and 527..533 (reads 64 bits, lands on off-cycle (head wrong: "7!/3$#d7??7??7??")); I 607..613 (reads 48 bits, lands on off-cycle (head wrong: "8@23$#d?7??7??7?")); J 51327..51333 (reads 58 bits, lands on off-cycle (head of state 0)) and 52409..52417 (reads 54 bits, lands on off-cycle (head of state 0)) and 35004..35017 (reads 60 bits, lands on off-cycle (head of state 0)); K 4655..4661 (reads 48 bits, lands on off-cycle (head wrong: ": 63$#d+3+3+3+3+")) and 52463..52469 (reads 46 bits, lands on off-cycle (head wrong: ": 63$#d'+3'+3: 6")); L 39091..39097 (reads 48 bits, lands on off-cycle (head of state 0)) and 52361..52372 (reads 58 bits, lands on off-cycle (head wrong: ";b73$#d3'+;b73$#")); M 52351..52357 (reads 48 bits, lands on state 0 of M) and 40127..40133 (reads 64 bits, lands on off-cycle (head wrong: "<\"83$#d323\"23\"2\"")) and 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)); N 44207..44213 (reads 48 bits, lands on off-cycle (head of state 0)) and 56463..56469 (reads 48 bits, lands on off-cycle (head wrong: "=c93$#d+7+7+7+7+"))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.1 %, 11.8 %, 33.5 %, 51.9 %, 65.9 %, 74.4 %, 80.0 %. After one bit flip of a cycle state (14336 cases): return in 1.7 steps mean, p90 4, max 22, lost (> 100) 299, same species 83.3 %.

## Census

Shares (%): A 0.1, B 11.8, C 2.3, D 2.3, E 4.2, F 2.5, G 2.8, H 5.4, I 21.9, J 10.5, K 8.3, L 1.9, M 14.7, N 5.7, stray 5.64, unsettled 0. Transient mean 6.1, p90 10, max 27.

| cycle | length | basin | species |
|---|---|---|---|
| `"8@23$#D;;;;;;;;;"` | 8 | 21.90 % | I |
| `"<\"83$#D'+3'+3'+3"` | 8 | 14.66 % | M |
| `"1!#3$#D+3+3+3+3+"` | 8 | 11.83 % | B |
| `"9 53$#D3\"23\"23\"2"` | 8 | 10.50 % | J |
| `": 63$#D?3?3?3?3?"` | 8 | 8.31 % | K |
| `"=C93$#D+7+7+7+7+"` | 8 | 5.66 % | N |
| `"7+7+7+7+7+7+7+7+"` | 2 | 5.57 % | stray |
| `"7!/3$#D';';';';'"` | 8 | 5.38 % | H |
| `"4C(3$#D+';+';+';"` | 8 | 4.16 % | E |
| `"6\",3$#D?+?+?+?+?"` | 8 | 2.80 % | G |
| `"5 )3$#D?'?'?'?'?"` | 8 | 2.52 % | F |
| `"3#(3$#D999999999"` | 8 | 2.33 % | D |
| `"2@'3$#D;7;7;7;7;"` | 8 | 2.31 % | C |
| `";B73$#D&3&3&3&3&"` | 8 | 1.87 % | L |
| `"0A\"3$#D7??7??7??"` | 8 | 0.13 % | A |
| `"'+3'<\"8'+3'9Y+3"` | 1 | 0.04 % | stray |
| `"23\"2923\"29Ì\u001129Ì"` | 2 | 0.02 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
