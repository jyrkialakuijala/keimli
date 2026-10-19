# Designed dictionary ca-gray3-fast

d = 16, tail Gray 1, filler search 3000 iterations on 400 cells (score 0.766). Census: 10000 random cells, cap 4000.

| species | H0 | states (k: position, header, text, Hamming to next) |
|---|---|---|
| A | 128 | 0: 176, 128, `0 0?0@AAAAAAAAAA`, 2<br>1: 112, 144, `0$0?0@CAAAAAAAAA`, 2<br>2: 128, 176, `0,0?0@CCAAAAAAAA`, 2<br>3: 160, 160, `0(0?0@ACAAAAAAAA`, 2<br>4: 144, 224, `080?0@ACCAAAAAAA`, 2<br>5: 208, 240, `0<0?0@CCCAAAAAAA`, 2<br>6: 224, 208, `040?0@CACAAAAAAA`, 2<br>7: 192, 192, `000?0@AACAAAAAAA`, 2 |
| B | 2176 | 0: 2224, 2176, `1 2?0@PPPPPPPPPP`, 2<br>1: 2160, 2192, `1$2?0@RPPPPPPPPP`, 2<br>2: 2176, 2224, `1,2?0@RRPPPPPPPP`, 2<br>3: 2208, 2208, `1(2?0@PRPPPPPPPP`, 2<br>4: 2192, 2272, `182?0@PRRPPPPPPP`, 2<br>5: 2256, 2288, `1<2?0@RRRPPPPPPP`, 2<br>6: 2272, 2256, `142?0@RPRPPPPPPP`, 2<br>7: 2240, 2240, `102?0@PPRPPPPPPP`, 2 |
| C | 3200 | 0: 3248, 3200, `2 3?0@((((((((((`, 2<br>1: 3184, 3216, `2$3?0@*(((((((((`, 2<br>2: 3200, 3248, `2,3?0@**((((((((`, 2<br>3: 3232, 3232, `2(3?0@(*((((((((`, 2<br>4: 3216, 3296, `283?0@(**(((((((`, 2<br>5: 3280, 3312, `2<3?0@***(((((((`, 2<br>6: 3296, 3280, `243?0@*(*(((((((`, 2<br>7: 3264, 3264, `203?0@((*(((((((`, 2 |

Planes constant along the cycle: 122, 122, 122 of 128 (46 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[22,28],"AC":[43,49],"BC":[43,49]}.

Filler words: `>00?0@6#;A1A4SF}`, `-02?0@P0DGPDPPPP`, `703?0@+ZB&/N ?|W`

## Census

Shares: A 38.9 %, B 27.5 %, C 33.2 %, stray 0.45 %, unsettled 0. Transient mean 18.2, p90 37, max 70 (A 12.2, B 18.5, C 25.0).

| cycle | length | basin | species |
|---|---|---|---|
| `"0 0?0@AAAAAAAAAA"` | 8 | 38.87 % | A |
| `"2 3?0@(((((((((("` | 8 | 33.23 % | C |
| `"1 2?0@PPPPPPPPPP"` | 8 | 27.45 % | B |
| `"0@PP@PPPPPAAAAA?"` | 3 | 0.30 % | stray |
| `"?0@@CCAAAAAA>>0C"` | 2 | 0.15 % | stray |
