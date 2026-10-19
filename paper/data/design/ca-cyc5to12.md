# Designed dictionary ca-cyc5to12

8 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "??3" ";7" "37" "3?" "?7" "3;" "7" ";?", blocks 44168, 36876, 59648, 45196, 34952, 32908, 47232, 39048, bounds 7500, 15000, 22500, 30000, 37500, 45000, 52500, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | cycle length | state 0 | Hamming per step |
|---|---|---|---|---|---|---|
| A | `??3` | 48 | 44168 | 5 | `0"+3$#D??3??3??3` | 2 |
| B | `;7` | 48 | 36876 | 6 | `1$3$#D;7;7;7;7;` | 2 |
| C | `37` | 48 | 59648 | 7 | `2@:3$#D373737373` | 2 |
| D | `3?` | 48 | 45196 | 8 | `3#,3$#D3?3?3?3?3` | 2 |
| E | `?7` | 48 | 34952 | 9 | `4""3$#D?7?7?7?7?` | 2 |
| F | `3;` | 48 | 32908 | 10 | `5# 3$#D3;3;3;3;3` | 2 |
| G | `7` | 48 | 47232 | 11 | `6 .3$#D777777777` | 2 |
| H | `;?` | 48 | 39048 | 12 | `7"&3$#D;?;?;?;?;` | 2 |

Planes constant along the cycle: 124 of 128 (48 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[16,18],"AC":[16,18],"AD":[14,16],"AE":[11,15],"AF":[14,18],"AG":[14,18],"AH":[11,15],"BC":[14,18],"BD":[12,16],"BE":[11,15],"BF":[16,20],"BG":[18,22],"BH":[9,13],"CD":[12,16],"CE":[17,21],"CF":[18,22],"CG":[10,14],"CH":[17,21],"DE":[21,25],"DF":[8,12],"DG":[14,18],"DH":[9,13],"EF":[21,25],"EG":[9,13],"EH":[12,16],"FG":[20,24],"FH":[13,17],"GH":[17,21]}.

Filler: the patterns tiled over the regions [[0,7500],[7500,15000],[15000,22500],[22500,30000],[30000,37500],[37500,45000],[45000,52500],[52500,60000]]; landing pads: A 52415..52421 (reads 48 bits, lands on off-cycle (head wrong: "0\"+3$#d777777777")) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "0\"+3$#d??3??3??3")) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "0\"+3$#d??3??30\"+")); B 591..597 (reads 48 bits, lands on off-cycle (head wrong: "1\u0003$3$#d?3??3??3?")) and 56527..56533 (reads 48 bits, lands on off-cycle (head wrong: "1\u0003$3$#d;?;?;?;?;")); C 52431..52437 (reads 48 bits, lands on off-cycle (head wrong: "2@:3$#d7777772@:")) and 56495..56501 (reads 48 bits, lands on off-cycle (head wrong: "2@:3$#d;?;?;?;?;")); D 52463..52469 (reads 46 bits, lands on off-cycle (head wrong: "3#,3$#d7777773#,")) and 4655..4661 (reads 48 bits, lands on off-cycle (head wrong: "3#,3$#d??3??3??3")); E 4671..4677 (reads 48 bits, lands on off-cycle (head wrong: "4\"\"3$#d?3??3??3?")) and 56543..56549 (reads 48 bits, lands on off-cycle (head wrong: "4\"\"3$#d;?;?;?;?;")); F 52447..52453 (reads 48 bits, lands on off-cycle (head wrong: "5# 3$#d7777775# ")) and 575..581 (reads 48 bits, lands on off-cycle (head wrong: "5# 3$#d??3??3??3")); G 56511..56517 (reads 48 bits, lands on off-cycle (head wrong: "6 .3$#d;?;?;?;?;")); H 623..629 (reads 48 bits, lands on off-cycle (head wrong: "7\"&3$#d??3??3??3")) and 4687..4693 (reads 48 bits, lands on off-cycle (head wrong: "7\"&3$#d3??3??3??"))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.0 %, 16.4 %, 46.6 %, 66.0 %, 75.6 %, 80.4 %, 85.6 %. After one bit flip of a cycle state (8704 cases): return in 1.7 steps mean, p90 3, max 27, lost (> 100) 24, same species 85.5 %.

## Census

Shares (%): A 28.6, B 7.7, C 3.6, D 5.9, E 11.1, F 3.6, G 20.7, H 18.5, stray 0.35, unsettled 0. Transient mean 5.9, p90 10, max 38.

| cycle | length | basin | species |
|---|---|---|---|
| `"0\"+3$#D??3??3??3"` | 5 | 28.58 % | A |
| `"6 .3$#D777777777"` | 11 | 20.66 % | G |
| `"7\"&3$#D;?;?;?;?;"` | 12 | 18.48 % | H |
| `"4\"\"3$#D?7?7?7?7?"` | 9 | 11.10 % | E |
| `"1\u0003$3$#D;7;7;7;7;"` | 6 | 7.70 % | B |
| `"3#,3$#D3?3?3?3?3"` | 8 | 5.90 % | D |
| `"5# 3$#D3;3;3;3;3"` | 10 | 3.65 % | F |
| `"2@:3$#D373737373"` | 7 | 3.58 % | C |
| `"?#d?7;7;7;7;7?7?"` | 1 | 0.32 % | stray |
| `"3ãÏÎÏ;7;7;7;7;7;"` | 4 | 0.02 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
