# Round 2: information theory, methodology

Scripts and outputs are in the scratchpad (`/tmp/claude-1000/-home-jyrki-life/1528f620-29d4-4b78-a5f7-6d337385d757/scratchpad/r2/`: `map.mjs`, `ct.mjs`, `pump.mjs`, `pump2.mjs`). Each run is under two minutes and nothing was written to paper/data. The lattice runs are single-seed, 96², bulk margin 12, F, swap p 0.5, median p 1, **rotate** order, with the JS `decode36` as the rewrite (it is bit-exact to the wasm, decoder-map.md §0). They are indicative only.

## (a) Responses to the panel

**Mathematician.** I agree with every point, and my own data sharpen two of them.
- On the bound: it is H(U | f(U)) ≥ 34.5 bits, and |Im f| ≥ 2^H, not ≤. The bound is also loose. The 12 header bits are partly redundant, because different windows copy identical bytes. Averaged over 4,000 cells, varying only the header, E[12 − H(out | rest)] = 5.5 bits for F. That gives **H(f(U)) ≤ 87.5 bits** (2.7 bits of loss for F byte-shuffled, 3.5 for Brotli 13).
- On "never reads its own output": correct. 18.2 % of output bytes are self-copies, and LZ77's overlapping copy *is* reading one's own output. You asked for a class name; information theory supplies one. Each cell's turn is a **single-pass, bounded-work, dictionary-relative decoder**: a straight-line program of at most 1,024 bit reads, whose output entropy cannot exceed the entropy of the bits it reads. That inequality is the property the argument needs; "no loop" is not.
- I have numbers for your planned H(f^k(U)) (2×10⁵ cells, collision entropy H₂): 16.4, 12.6, 9.5, 7.5, 6.2 bits for k = 1–5; 2.6 at k = 10; **1.58 = log₂3 by k = 30**. That is the 3-cycle with its phases equally populated. The plug-in estimate is capped at 17.6 bits until k ≈ 3.

**Physicist, unconnected correlation.** I agree, and I propose the information-theoretic fix. Mutual information I(r) between cell identities (or cycle phases) at distance r is "connected" by construction: it is zero exactly when the two cells are independent. It is not inflated by plane magnetisation, and computed on phase labels it does not depend on the sampling phase. In my quenched run, I(left; right) = 0.91 bits out of H(cell) = 1.19, and H(cell | left) = 0.28. Caveat: plug-in I needs a small alphabet. In the granular regime (median 0.3) it saturates at log₂N and reports 12 bits of pure bias, so the phase map or an LZ estimator is required there (below).

**Professor, LZ76.** You are right, and this strengthens my concern 4. Kaspar–Schuster implement the Lempel–Ziv **1976** production complexity: a *parsing* measure of an observed string. Keimli runs an LZ77-family *decoder* on random bits. The motivation links a measurement to a generator without saying so. Add lempel1976. Your cycle-projection null exists already as `cycle3f`, and it loses everything. In my 96² run it collapses to one cell identity (H = 0, distinct 1.0) under both hashings, while the decoder sustains 1.19 bits and about 2 % off-cycle cells. This agrees with ablation-scan.md §2. The decoder's gradual funnel is what keeps the medium supplied.

**Physicist and professor, "quenched disorder".** In information terms the point is decisive. Under salt 0 the lattice is a deterministic map, so the fine-grained entropy of the configuration ensemble is non-increasing at every stage. Under salt 1 nothing changes in this respect. The salt is a fixed function of the turn number (`ca-harness.mjs` l.35), so the annealed rule is deterministic too, only time-dependent, and it injects zero entropy. A true source would need salts drawn from outside the run. "Entropy supply" is therefore always a coarse-grained quantity, and the text must say so.

**Computation reviewer.** The swap order does not change the qualitative balance below (I ran rotate). The byte-H values in ablation-main.md are from the fixed order and must be relabelled.

**ALife reviewer.** I agree that templating is replication of information. Transfer entropy from neighbour to cell, measured per stage, would quantify "the medium copies". It is the same machinery as the pump test.

## (b) Methodology

**1. A pump definition that can fail.** Let X_t be the state at turn start, Y_t after mixing and settling, Z_t after the rewrite. On the bulk's empirical distribution, measure per stage:
- h(·): entropy density per cell, by plug-in when distinct ≪ N, otherwise by an LZ estimator;
- H(cell | left neighbour) and I(cell; neighbour);
- the erased information H(Y | Z) per cell.

The claim "the rewrite lowers its cell's entropy and raises it around" predicts h(Z) < h(Y) **and** a rise in H(cell | neighbour) or a fall in I at the rewrite. It fails if both fall.

Results (averages over turns 201–299):

| run | h start→pre→post (bits/cell, plug-in) | Brotli bits/cell | I(l;r) pre→post | H(cell\|left) pre→post | H(Y\|Z) |
|---|---|---|---|---|---|
| decoder, salt 0 | 1.19→1.25→1.19 | 1.19→1.34→1.19 | 0.96→0.91 | 0.29→0.28 | 0.062 |
| decoder, salt 1 | 1.14→1.20→1.14 | 1.31→1.48→1.31 | 0.88→0.83 | 0.31→0.30 | 0.057 |
| decoder, salt 3 | 1.18→1.24→1.18 | 1.31→1.45→1.30 | 0.98→0.92 | 0.26→0.26 | — |
| cycle3f, salt 0/1 | 0→0→0 | 0.03 | 0 | 0 | 0 |
| decoder, median 0.3 | plug-in saturated | **41.9→62.1→41.9** | (bias) | (bias) | (bias) |

So the stage that lowers the cell's entropy also lowers every neighbourhood quantity. Nothing rises "around" at the rewrite. The rise happens at the mixing and settling stage, in coarse-grained terms only, and the two balance at stationarity. **The pump sentence fails as written. The source/sink sentence survives.** The throughput, about 0.15 Brotli bits per cell per turn when ordered and about 20 when granular, is a regime observable that d1 does not give: about 46 bits per cell change every turn while about 0.15 bits of entropy flow, roughly 300 times less. The null with an instantaneous funnel has zero throughput.

**2. Landauer accounting.**
- **Transient, ensemble view:** a fresh cell loses at least 128 − 87.5 = 40.5 bits on the first decode and about 126.4 bits by the attractor (H = log₂3). That is the logical irreversibility the kT ln 2 bound refers to.
- **Steady state:** the decoder permutes the cycle and erases only what the medium pushed off it, H(Y | Z) ≈ 0.06 bits per cell per turn (plug-in, ordered regime).
- **Quenched hashing:** the medium is deterministic, so this is the coarse-grained erasure of a closed deterministic system. It is a bookkeeping of copies, not dissipated heat.

The article can state H(Y|Z) and stop there. Physical heat is not in the model.

**3. Coding-theorem shape: no.** The most probable output of F has P ≈ 2^−8.3 (954 of 300,000 samples) while its shortest observed program is 35 bits. Many prefixes, through window redundancy and dead transform bits, collapse onto it, so P(y) ≫ 2^−K_f(y). Levin's upper constant does not hold. H₂ is 16.5 bits for F, against 21.4 for F shuffled and 22.3 for Brotli 13. **Dictionary order acts on the head of the output distribution far more strongly than the 0.25-bit conditional entropy shows:** 4.9 bits of collision entropy and 2.8 bits of header redundancy. Report H₂, H_∞ and the top-output mass per dictionary; Chao1 should go.

**4. Replacing the zeroth-order byte entropy, cheaply.**
- (i) A Brotli-11 or LZMA compressed-bits-per-cell figure on the raster scan (one call, works in every regime; about 2 ms per 96² frame), together with the same quantity on a cell-shuffled frame, so that spatial redundancy is the difference.
- (ii) Plug-in H, I(r) and H(·|·) on cell identities, or better on cycle-phase labels, when distinct < N/20.
- (iii) LZ76 complexity (Kaspar–Schuster) on a Hilbert scan, for comparability with the literature.
- (iv) Per-stage snapshots through the JS `rewrite` hook, as in `pump2.mjs`. No wasm change is needed for the pre/post split. Mixing and settling separately still need a hook in `Band.runTurn`.

Byte H stays as a page display only.

## (c) Text the author can use

**Motivation (replacing "LZ rather than Kolmogorov").** The complexity of a genome, a recording or a text is measured in practice by parsing it, by the Lempel–Ziv production complexity [lempel1976, kaspar1987] or by a compression distance [cilibrasi2005], because Kolmogorov complexity is uncomputable. The dual move is to run a decoder rather than a parser. Fed random bits, a universal machine produces each string with its algorithmic probability [levin1974], and the coding theorem method estimates complexity that way [zenil2015]. A dictionary decoder fed random bits produces a resource-bounded counterpart of that distribution: every output is assembled in one bounded pass from literals, copies of itself and copies from a library. Its output carries no more entropy than the bits it reads. We put that decoder inside the dynamics as the local rule. It keeps the part of running a program that turns random bits into structured, library-shaped output, and it drops unbounded iteration, so the rule's information budget can be measured exactly.

**Entropy sentence (replacing "a local entropy pump").** The decoder is the lattice's entropy sink. It is many-to-one: a random cell loses at least 40 of its 128 bits in one decode and falls onto a short cycle, on which the decoder only permutes states. The mixing and settling stages, which are deterministic under every hashing the page offers, put coarse-grained entropy back, by moving cells off their cycles and spreading differences between neighbours. At stationarity the two flows balance, and the throughput, measured as the information each rewrite erases, is an observable of the regime.

*Bibliography note:* neither lempel1976 (IEEE Trans. IT 22, 1976) nor levin1974 (Probl. Inf. Transm. 10, 1974) is in references.bib yet.
