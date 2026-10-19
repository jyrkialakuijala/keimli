# Designed dictionary ca-gray11c

11 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "++'" "';" "?'?" ";3" "+3" "3'" "+/;" "'/" ";/3" "/+" "23", blocks 35972, 38144, 42124, 43272, 46220, 50444, 53380, 53508, 54408, 56452, 57472, bounds 5455, 10909, 16364, 21818, 27273, 32727, 38182, 43636, 49091, 54545, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `++'` | 64 | 35972 | `0!#3$#D++'++'++'` | 1 |
| B | `';` | 64 | 38144 | `1@%3$#D';';';';'` | 1 |
| C | `?'?` | 48 | 42124 | `2#)3$#D?'??'??'?` | 1 |
| D | `;3` | 48 | 43272 | `3B*3$#D;3;3;3;3;` | 1 |
| E | `+3` | 48 | 46220 | `4#-3$#D+3+3+3+3+` | 1 |
| F | `3'` | 62 | 50444 | `5C13$#D3'3'3'3'3` | 1 |
| G | `+/;` | 48 | 53380 | `6!43$#D+/;+/;+/;` | 1 |
| H | `'/` | 64 | 53508 | `7A43$#D'/'/'/'/'` | 1 |
| I | `;/3` | 48 | 54408 | `8"53$#D;/3;/3;/3` | 1 |
| J | `/+` | 48 | 56452 | `9!73$#D/+/+/+/+/` | 1 |
| K | `23` | 60 | 57472 | `: 83$#D232323232` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder).

Filler: the patterns tiled over the regions [[0,5455],[5455,10909],[10909,16364],[16364,21818],[21818,27273],[27273,32727],[32727,38182],[38182,43636],[43636,49091],[49091,54545],[54545,60000]]; landing pads: A 40063..40069 (reads 64 bits, lands on off-cycle (head of state 0)) and 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)) and 44159..44165 (reads 64 bits, lands on off-cycle (head of state 0)); B 40143..40149 (reads 48 bits, lands on off-cycle (head of state 0)) and 527..533 (reads 64 bits, lands on off-cycle (head wrong: "1@%3$#d++'++'++'")); C 4639..4645 (reads 48 bits, lands on off-cycle (head of state 0)) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "2#)3$#d'++'++'++")) and 40127..40133 (reads 48 bits, lands on off-cycle (head wrong: "2#)3$#d'/'/'/'/'")); D 575..581 (reads 48 bits, lands on off-cycle (head wrong: "3b*3$#d++'++'++'")) and 52447..52453 (reads 48 bits, lands on off-cycle (head wrong: "3b*3$#d+/+/+/3b*")); E 44191..44197 (reads 48 bits, lands on off-cycle (head of state 0)) and 52383..52389 (reads 48 bits, lands on off-cycle (head wrong: "4#-3$#d+/+/+/4#-")); F 52367..52373 (reads 62 bits, lands on off-cycle (head wrong: "5c13$#d+/+/+/5c1")) and 40111..40117 (reads 48 bits, lands on off-cycle (head of state 0)); G 543..549 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44229 (reads 48 bits, lands on off-cycle (head wrong: "6!43$#d;//3;/3;/")) and 48255..48261 (reads 48 bits, lands on off-cycle (head of state 0)); H 40095..40101 (reads 48 bits, lands on state 0 of H) and 48223..48229 (reads 64 bits, lands on off-cycle (head of state 0)); I 52351..52357 (reads 48 bits, lands on off-cycle (head of state 0)) and 607..613 (reads 48 bits, lands on off-cycle (head wrong: "8\"53$#d'++'++'++")) and 48319..48325 (reads 48 bits, lands on off-cycle (head wrong: "8\"53$#d/3;;/38\"5")); J 48239..48245 (reads 48 bits, lands on off-cycle (head of state 0)) and 44175..44181 (reads 48 bits, lands on off-cycle (head of state 0)); K 51395..51401 (reads 46 bits, lands on off-cycle (head wrong: ": 83$#d+/: 83$#d")) and 52408..52417 (reads 60 bits, lands on off-cycle (head wrong: ": 83$#d+/+/+/: 8"))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.4 %, 15.6 %, 43.3 %, 64.5 %, 78.1 %, 84.8 %, 89.1 %. After one bit flip of a cycle state (11264 cases): return in 1.7 steps mean, p90 4, max 23, lost (> 100) 0, same species 84.7 %.

## Census

Shares (%): A 18.5, B 2.4, C 3.4, D 0.0, E 6.3, F 1.2, G 15.0, H 13.8, I 18.6, J 16.2, K 4.6, stray 0.01, unsettled 0. Transient mean 5.6, p90 9, max 27.

| cycle | length | basin | species |
|---|---|---|---|
| `"8\"53$#D;/3;/3;/3"` | 8 | 18.60 % | I |
| `"0!#3$#D++'++'++'"` | 8 | 18.49 % | A |
| `"9!73$#D/+/+/+/+/"` | 8 | 16.16 % | J |
| `"6!43$#D+/;+/;+/;"` | 8 | 14.99 % | G |
| `"7A43$#D'/'/'/'/'"` | 8 | 13.75 % | H |
| `"4#-3$#D+3+3+3+3+"` | 8 | 6.34 % | E |
| `": 83$#D232323232"` | 8 | 4.61 % | K |
| `"2#)3$#D?'??'??'?"` | 8 | 3.38 % | C |
| `"1@%3$#D';';';';'"` | 8 | 2.40 % | B |
| `"5C13$#D3'3'3'3'3"` | 8 | 1.23 % | F |
| `"3B*3$#D;3;3;3;3;"` | 8 | 0.04 % | D |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
