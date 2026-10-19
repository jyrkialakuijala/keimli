# Designed dictionary ca-gray3

d = 16, tail Gray 1, filler search 2500 iterations on 400 cells (score 1.224). Census: 10000 random cells, cap 4000.

| species | H0 | states (k: position, header, text, Hamming to next) |
|---|---|---|
| A | 128 | 0: 176, 128, `0 0?0@AAAAAAAAAA`, 2<br>1: 112, 144, `0$0?0@CAAAAAAAAA`, 2<br>2: 128, 176, `0,0?0@CCAAAAAAAA`, 2<br>3: 160, 160, `0(0?0@ACAAAAAAAA`, 2<br>4: 144, 224, `080?0@ACCAAAAAAA`, 2<br>5: 208, 240, `0<0?0@CCCAAAAAAA`, 2<br>6: 224, 208, `040?0@CACAAAAAAA`, 2<br>7: 192, 192, `000?0@AACAAAAAAA`, 2 |
| B | 2176 | 0: 2224, 2176, `1 2?0@PPPPPPPPPP`, 2<br>1: 2160, 2192, `1$2?0@RPPPPPPPPP`, 2<br>2: 2176, 2224, `1,2?0@RRPPPPPPPP`, 2<br>3: 2208, 2208, `1(2?0@PRPPPPPPPP`, 2<br>4: 2192, 2272, `182?0@PRRPPPPPPP`, 2<br>5: 2256, 2288, `1<2?0@RRRPPPPPPP`, 2<br>6: 2272, 2256, `142?0@RPRPPPPPPP`, 2<br>7: 2240, 2240, `102?0@PPRPPPPPPP`, 2 |
| C | 3200 | 0: 3248, 3200, `2 3?0@((((((((((`, 2<br>1: 3184, 3216, `2$3?0@*(((((((((`, 2<br>2: 3200, 3248, `2,3?0@**((((((((`, 2<br>3: 3232, 3232, `2(3?0@(*((((((((`, 2<br>4: 3216, 3296, `283?0@(**(((((((`, 2<br>5: 3280, 3312, `2<3?0@***(((((((`, 2<br>6: 3296, 3280, `243?0@*(*(((((((`, 2<br>7: 3264, 3264, `203?0@((*(((((((`, 2 |

Planes constant along the cycle: 122, 122, 122 of 128 (46 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[22,28],"AC":[43,49],"BC":[43,49]}.

Filler words: `000?0@?AA#AT{)AY`, `/02?0@2!EP=Z@6PQ`, `"03?0@XA%7T(Y;21`

## Census

Shares: A 31.5 %, B 29.6 %, C 38.1 %, stray 0.74 %, unsettled 0. Transient mean 26.0, p90 49, max 110 (A 22.0, B 22.7, C 31.8).

| cycle | length | basin | species |
|---|---|---|---|
| `"2 3?0@(((((((((("` | 8 | 38.09 % | C |
| `"0 0?0@AAAAAAAAAA"` | 8 | 31.53 % | A |
| `"1 2?0@PPPPPPPPPP"` | 8 | 29.64 % | B |
| `",0PÐ0?AAAA^JPAAA"` | 4 | 0.37 % | stray |
| `"0@PP@PPPPPAAAAA?"` | 3 | 0.32 % | stray |
| `"?0@@CCAAAAAA000?"` | 2 | 0.05 % | stray |
