# Codebook decoder (kind 45): exact image against sampling

V = 128 (header 7 bits), skip 0, single cells, N = 1,000,000 random cells per dictionary. |B| is the number of distinct cyclic bigrams of the dictionary; the image of one cell is exactly B^8. H(f(U)) is exact (8 times the bigram entropy under the code distribution). Chao1 is the sampled lower-bound estimate.

| dictionary | bytes | distinct bytes | distinct bigrams | log₂ image (exact) | H(f(U)) bits (exact) | bits consumed | distinct outputs of N | log₂ Chao1 | fixed points |
|---|---|---|---|---|---|---|---|---|---|
| ca-codebook-1 | 200 | 35 | 74 | 49.7 | 37.5 | 87.0 | 997932 | 28.2 | 0.000 % |
| ca-codebook-2 | 200 | 31 | 61 | 47.4 | 31.9 | 87.0 | 971086 | 25.2 | 0.000 % |
| ca-codebook-3 | 200 | 35 | 70 | 49.0 | 26.7 | 87.0 | 764045 | 23.0 | 0.000 % |
| ca-codebook-4 | 512 | 41 | 102 | 53.4 | 38.3 | 87.0 | 999689 | 30.6 | 0.000 % |
| ca-codebook-5 | 512 | 51 | 136 | 56.7 | 38.4 | 87.0 | 996880 | 27.6 | 0.000 % |
| ca-codebook-6 | 512 | 8 | 30 | 39.3 | 35.6 | 87.0 | 999977 | 34.3 | 0.000 % |
| ca-codebook-7 | 512 | 55 | 146 | 57.5 | 39.4 | 87.0 | 997895 | 28.1 | 0.000 % |
| ca-codebook-8 | 512 | 49 | 127 | 55.9 | 43.5 | 87.0 | 999999 | 38.9 | 0.000 % |
| ca-codebook-9 | 512 | 43 | 157 | 58.4 | 49.4 | 87.0 | 1000000 | 38.9 | 0.000 % |
