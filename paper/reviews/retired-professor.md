# Review of the research plan, from a retired professor of statistical physics

I read the plan and skimmed the three documents it points to. It is better than most I referee: one claim, a pinned reference system. It also contains a factual error about its own system, a measurement that will mislead for a reason the authors have not seen, and several wheels turned in the 1980s.

## 1. What the thing is

Strip the vocabulary. A cell is 128 Ising spins. Mixing exchanges spin k of cell A with spin k of cell B: Kawasaki spin-exchange dynamics, conserved, run separately on each of the 128 bit planes. Settling is a synchronous majority rule on the 3 x 3 block, again plane by plane: Vichniac's voting rule (Physica D, 1984), the zero-temperature dynamics everyone knows freezes into flat-interfaced blocked states instead of coarsening to completion (Vichniac's twisted "annealing" rule exists for exactly that reason; Spirin, Krapivsky and Redner have the Ising freezing story, around 2001, verify). Toom's theorem says why: a symmetric square neighbourhood is not an eroder, his NEC rule is; Gacs's reliable automata are the harder one-dimensional cousin and not needed here. With mixing on, each plane is a majority-vote model with exchange noise, de Oliveira's model (J. Stat. Phys. 1992) with conserved noise; Grinstein, Jayaprakash and He (PRL 1985, verify) is the result that such up-down symmetric PCA are Ising-class, Bennett and Grinstein (1985, verify) the irreversibility angle, and Domany and Kinzel (1984) the reference PCA with an active-to-frozen directed-percolation transition.

Two things are not textbook. First, with the decoder off the planes are coupled only through the hash contexts, so the control is 128 nearly independent two-dimensional majority-vote models, and the decoder is the only stage that couples the planes nonlinearly. That is your mechanism; say it on page one. Second, the plan nowhere says that the "probabilistic" decisions are hashes of the 32 neighbouring bits with salt 0 (lattice.md). The noise is quenched in the configuration, not annealed: a flat interface with a given context flips all-or-nothing, forever. Quenched randomness pins interfaces; coarsening in random-field and random-bond Ising systems is logarithmic. An arrested domain size in your reference run may be pinning by your own hash, not by the decoder. I would stake money on this pitfall.

The decoder is a fixed self-map on 2^128 states with a 4,400-byte parameter. The null for a self-map is Harris's random mapping (1960, verify): image fraction 1 - 1/e, cycles of order 2^64. Kauffman and Derrida-Pomeau (1986) are the dynamical vocabulary. Thread A (Wolfram, Langton, Mitchell-Hraber-Crutchfield, Wuensche, Crutchfield-Hanson) is right, but do not write "the dictionary is a lambda knob". It is a 35,000-bit parameter; lambda was a scalar and even that did not order rule space.

## 2. H1 and H4: the right quantities

H1 (section 2) says the control coarsens as t^(1/2) and goes quiet. Half of that is wrong by prediction: at full settle it freezes, at intermediate values it crosses an Ising-like critical line (above the critical noise there are no domains), and frozen versus active is an absorbing-state transition whose clean quantities are the activity rho(t) and its decay exponent, not "d1 bounded away from zero" at turn 1,000 (Hinrichsen's 2000 review). Bray (Adv. Phys. 1994) will also tell you that an exponent from 1,000 turns on 256^2 is noise; the test is the scaling collapse S(k, t) = L^2 f(kL). Arrest shows as a plateau in L and a failure of collapse.

Order parameter: do not label domains by dominant byte (section 4). Bytes are an artefact of the skip bits and the command frame. Use the Hamming correlation C(r) = 1 - 2 <d_H(x, x + r)>/128, the spin correlation averaged over planes, and report it per plane, because the decoder treats header bits and tail bits differently and that difference is the result. Measure along x, y and the diagonals separately: four sequential swap phases in fixed order are anisotropic (your own docs record the down-right streaks), and a plateau along one axis is not a plateau.

Confounders. Section 1 says torus; lattice.md says a plane with edges, clamped neighbours for the median, edge pairing for the swaps. The frozen floor sits on reflecting rows and on the end of the settle gradient at once. The 2p(1-p) mapping folds the x axis, p = 0 and p = 1 being both the identity, so the "phase diagram" is mirror-symmetric in rate, and at gradient power 0.2 the mixing lives in a narrow central column. A clean experiment: homogeneous parameters, periodic boundaries, a grid of (rate, p_settle) values, 10 seeds, three sizes, L kept below a quarter of the system, an annealed-salt control at every point. Then show the gradient frame as a picture of the diagram, never as its source.

H4: sampling 10^6 inputs counts the heavy part of the image, not its size. Use Good-Turing or Chao-type unseen estimators, or compute it: for the codebook decoder the output is eight window-dependent bigrams and the image is a count. Report log2(image)/128 against 1 - 1/e, and H(Y) under uniform X: 128 - H(Y) is what "the decoder lowers entropy" has to mean. Mixing is a bijection on the pair and raises no global entropy at all, only per-cell marginal entropy, so H5 must be written in Shannon quantities or renamed an activity budget.

## 3. Reinvented wheels, and what is new

"Every frame is a phase diagram" is gradient percolation (Sapoval, Rosso, Gouyet, 1985, verify). d1 is activity; the chaos measure is damage spreading between two replicas (Derrida and Stauffer, 1986, verify). The block classifier is Wuensche-lite; byte-labelled domains are a worse correlation function. Genuinely new: a decoder as the local rule, a text as its parameter, and whether a many-to-one self-map coupling 128 planes arrests or merely pins exchange-driven Ising coarsening. That is a paper if the control is honest.

## 4. Cut and add

Cut Q6 and Q7 from the physics paper: the pilot is a paragraph, and H7 is near a tautology, since copy codes see bytes as bytes and only the case transforms can break under a bijection. Add the quenched-versus-annealed control, the homogeneous torus scan, the absorbing-state analysis, damage spreading, the random-mapping null and per-plane correlations.

## 5. Recommendations

1. Correct section 1: bounded plane, not torus; add a periodic mode for measurements.
2. Run every quantitative experiment homogeneous and periodic; gradient frames are figures 2 and 3, not data.
3. Add salt-by-turn and repeat the H1 control annealed; if arrest survives only at salt 0, it is hash pinning.
4. Replace byte domains with C(r) and the structure factor, per plane and per axis.
5. Test coarsening by scaling collapse at three sizes; report exponent bands, not points.
6. Treat frozen versus active as an absorbing-state transition: rho(t), survival probability, a noise scan.
7. Measure damage spreading beside d1.
8. Compute the codebook image, estimate the Brotli-like one with unseen estimators, compare both to 1 - 1/e.
9. Restate H5 in Shannon quantities or call it activity.
10. Alternate or randomise the swap-phase order in measurement runs and show C(r) anisotropy before and after.
11. Verify every citation flagged above; I wrote them from memory and so did you.
12. Move Q6 and Q7 to the dictionary paper.

## 6. On scope

You have two papers and are writing one and a half. The physics paper is H1, H4, H5 on one decoder, one dictionary, a homogeneous torus, with the gradient frames as the invitation; it stands in Physica D or Chaos. The dictionary paper is Q2, Q3, Q6, Q7 and the gallery. Fold them together and each referee finds the half he knows underdone. Pick the quantity, build the reference system, measure it properly; the pictures will still be there when you are done.
