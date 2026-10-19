# Designed dictionary ca-gray16c

16 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "7?" "7??" "+3" ";?" ";7" "9" "+';" "?'" "?+" "';" ";" "3\"2" "?3" "&3" "'+3" "+7", blocks 34052, 35076, 35972, 37000, 40192, 41100, 41228, 42112, 45192, 48260, 51456, 54400, 55424, 56584, 57480, 58636, bounds 3750, 7500, 11250, 15000, 18750, 22500, 26250, 30000, 33750, 37500, 41250, 45000, 48750, 52500, 56250, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `7?` | 48 | 34052 | `0A!3$#D7?7?7?7?7` | 1 |
| B | `7??` | 48 | 35076 | `1A"3$#D7??7??7??` | 1 |
| C | `+3` | 48 | 35972 | `2!#3$#D+3+3+3+3+` | 1 |
| D | `;?` | 48 | 37000 | `3"$3$#D;?;?;?;?;` | 1 |
| E | `;7` | 48 | 40192 | `4@'3$#D;7;7;7;7;` | 1 |
| F | `9` | 59 | 41100 | `5#(3$#D999999999` | 1 |
| G | `+';` | 64 | 41228 | `6C(3$#D+';+';+';` | 1 |
| H | `?'` | 64 | 42112 | `7 )3$#D?'?'?'?'?` | 1 |
| I | `?+` | 48 | 45192 | `8",3$#D?+?+?+?+?` | 1 |
| J | `';` | 64 | 48260 | `9!/3$#D';';';';'` | 1 |
| K | `;` | 48 | 51456 | `:@23$#D;;;;;;;;;` | 1 |
| L | `3"2` | 60 | 54400 | `; 53$#D3"23"23"2` | 1 |
| M | `?3` | 48 | 55424 | `< 63$#D?3?3?3?3?` | 1 |
| N | `&3` | 58 | 56584 | `=B73$#D&3&3&3&3&` | 1 |
| O | `'+3` | 64 | 57480 | `>"83$#D'+3'+3'+3` | 1 |
| P | `+7` | 48 | 58636 | `?C93$#D+7+7+7+7+` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder).

Filler: the patterns tiled over the regions [[0,3750],[3750,7500],[7500,11250],[11250,15000],[15000,18750],[18750,22500],[22500,26250],[26250,30000],[30000,33750],[33750,37500],[37500,41250],[41250,45000],[45000,48750],[48750,52500],[52500,56250],[56250,60000]]; landing pads: A 56543..56549 (reads 48 bits, lands on off-cycle (head wrong: "0a!3$#d+7+7+7+7+")) and 4671..4677 (reads 48 bits, lands on off-cycle (head wrong: "0a!3$#d??7??7??7")); B 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "1a\"3$#d7??77??7?")) and 56511..56517 (reads 48 bits, lands on off-cycle (head wrong: "1a\"3$#d+7+7+7+7+")) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "1a\"3$#d7??7????7")); C 44191..44197 (reads 48 bits, lands on off-cycle (head of state 0)) and 52383..52389 (reads 48 bits, lands on off-cycle (head wrong: "2!#3$#d&3&3&32!#")); D 623..629 (reads 48 bits, lands on off-cycle (head wrong: "3\"$3$#d7?7?7?7?7")) and 4687..4693 (reads 48 bits, lands on off-cycle (head wrong: "3\"$3$#d?7??7??7?")); E 591..597 (reads 48 bits, lands on off-cycle (head wrong: "4@'3$#d7?7?7?7?7")) and 56527..56533 (reads 48 bits, lands on off-cycle (head wrong: "4@'3$#d+7+7+7+7+")); F 58590..58573 (reads 59 bits, lands on off-cycle (head of state 0)); G 543..549 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44229 (reads 64 bits, lands on off-cycle (head wrong: "6c(3$#d23\"23\"233")) and 40063..40069 (reads 48 bits, lands on off-cycle (head of state 0)); H 4607..4613 (reads 64 bits, lands on off-cycle (head wrong: "7 )3$#d7??7??7??")) and 40159..40165 (reads 48 bits, lands on off-cycle (head of state 0)); I 4623..4629 (reads 48 bits, lands on off-cycle (head wrong: "8\",3$#d??7??7??7")) and 44239..44245 (reads 48 bits, lands on off-cycle (head of state 0)); J 40143..40149 (reads 48 bits, lands on off-cycle (head of state 0)) and 527..533 (reads 64 bits, lands on off-cycle (head wrong: "9!/3$#d7?7?7?7?7")); K 607..613 (reads 48 bits, lands on off-cycle (head wrong: ":@23$#d7?7?7?7?7")); L 51327..51333 (reads 58 bits, lands on off-cycle (head of state 0)) and 52409..52417 (reads 54 bits, lands on off-cycle (head of state 0)) and 35004..35017 (reads 60 bits, lands on off-cycle (head of state 0)); M 4655..4661 (reads 48 bits, lands on off-cycle (head wrong: "< 63$#d7??7??7??")) and 52463..52469 (reads 46 bits, lands on off-cycle (head wrong: "< 63$#d&3&3&3< 6")); N 39091..39097 (reads 48 bits, lands on off-cycle (head of state 0)) and 52361..52372 (reads 58 bits, lands on off-cycle (head wrong: "=b73$#d3&3=b73$#")); O 52351..52357 (reads 48 bits, lands on off-cycle (head of state 0)) and 40127..40133 (reads 64 bits, lands on off-cycle (head wrong: ">\"83$#d;;;;;;;;;")) and 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)); P 44207..44213 (reads 48 bits, lands on off-cycle (head of state 0)) and 56463..56469 (reads 48 bits, lands on off-cycle (head wrong: "?c93$#d+7+7+7+7+"))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.0 %, 10.5 %, 25.8 %, 37.8 %, 53.9 %, 63.2 %, 72.6 %. After one bit flip of a cycle state (16384 cases): return in 1.7 steps mean, p90 4, max 35, lost (> 100) 420, same species 83.4 %.

## Census

Shares (%): A 0.1, B 0.1, C 1.9, D 6.6, E 2.0, F 2.4, G 1.7, H 3.6, I 2.6, J 32.7, K 14.4, L 8.3, M 1.7, N 3.8, O 5.5, P 3.0, stray 9.75, unsettled 0. Transient mean 6.8, p90 11, max 42.

| cycle | length | basin | species |
|---|---|---|---|
| `"9!/3$#D';';';';'"` | 8 | 32.67 % | J |
| `":@23$#D;;;;;;;;;"` | 8 | 14.36 % | K |
| `"7+7+7+7+7+7+7+7+"` | 2 | 9.71 % | stray |
| `"; 53$#D3\"23\"23\"2"` | 8 | 8.28 % | L |
| `"3\"$3$#D;?;?;?;?;"` | 8 | 6.58 % | D |
| `">\"83$#D'+3'+3'+3"` | 8 | 5.54 % | O |
| `"=B73$#D&3&3&3&3&"` | 8 | 3.81 % | N |
| `"7 )3$#D?'?'?'?'?"` | 8 | 3.56 % | H |
| `"?C93$#D+7+7+7+7+"` | 8 | 3.00 % | P |
| `"8\",3$#D?+?+?+?+?"` | 8 | 2.56 % | I |
| `"5#(3$#D999999999"` | 8 | 2.36 % | F |
| `"4@'3$#D;7;7;7;7;"` | 8 | 2.03 % | E |
| `"2!#3$#D+3+3+3+3+"` | 8 | 1.93 % | C |
| `"6C(3$#D+';+';+';"` | 8 | 1.67 % | G |
| `"< 63$#D?3?3?3?3?"` | 8 | 1.65 % | M |
| `"0A!3$#D7?7?7?7?7"` | 8 | 0.14 % | A |
| `"1A\"3$#D7??7??7??"` | 8 | 0.11 % | B |
| `"23\"2;23\"2;Ì\u00112;Ì"` | 2 | 0.02 % | stray |
| `"?+?+?+?+?+?+?"` | 1 | 0.01 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
