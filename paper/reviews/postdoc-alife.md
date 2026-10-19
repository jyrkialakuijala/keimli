# Review of RESEARCH_PLAN.md, from a postdoc in open-endedness and ALife

Read against commit 3241330, the docs, the harness and both search tools. I like the object; my concerns are the search and the measures, where an ALife referee will dig.

## 1. Where this sits

The nearest relative is not another CA but the IMGEP work on Lenia by Reinke, Etcheverry and Oudeyer (ICLR 2020). Their lesson applies to section 6 and H6 directly: the space you explore in and the space you evaluate diversity in must differ, or diversity is defined into existence; they evaluated in a separate analytic behaviour space, while you search and judge with the same block histogram. Flow Lenia (Plantec, Hamon, Chan, Oudeyer, Moulin-Frier et al., ALIFE 2023; verify authors) matters twice: mass conservation (your swaps conserve set bits, so mixing is a conservative flow on bit planes) and parameter localisation; your 12-bit header selecting a dictionary window is a localised rule parameter in disguise, and I would say so. Growing neural CA (Mordvintsev et al., Distill 2020) is the contrast: a rule optimised toward a target. Agüera y Arcas et al. 2024 (Brainfuck soups; verify arXiv number) is the reference the referee reaches for first; they measured soup complexity with a compressor (verify which), whereas here the compressor is the rule, a nice inversion. Sayama's swarm chemistry and Picbreeder (Secretan et al.; verify year) are the precedents for humans picking, which you did informally with the default. Kumar et al. 2024 on foundation-model search for artificial life (ASAL; verify) asks exactly H6's question and must be cited.

## 2. The search as quality-diversity

Done well: whole-alphabet bijections (neutral moves in the Schuster and Wagner sense), crossover with a pool of real texts, restartable runs, the two-per-score parent cap, and admitting the scale gap in section 4.

Naive by the field's standards: the objective is one scalar of hand-set soft windows multiplied by the modes count; the swarm's "archive" is a top-40 hall of fame, not a behaviour archive; novelty is distance to a fixed menu of about twenty dictionaries, not to everything visited, so it penalises re-finding the menu but not re-finding yourself; each candidate is scored on one seed (11), one grid (64 or 128) and one frame pair (turn T and T minus 10); runs are bounded by wall clock, so the evaluations behind F are unknown and unrepeatable; and the operator behind each accepted child is not logged. The field expects a MAP-Elites archive over two or three behaviour axes, coverage and QD-score curves, evaluation counts, re-evaluation of elites on fresh seeds (noisy QD, Flageat and Cully; verify), and held-out evaluation at 1024 and 1,000 turns for every named dictionary.

## 3. The measures

The modes score is the exponential entropy of a joint (now, before) class per 8×8 block, with 4×4×3 hand thresholds. Three circularities. First, the gradient layout of claim 2 guarantees a spread of block classes for any dictionary, because p sweeps across the frame; part of the score measures the gradient, not the text. Score every dictionary again with both gradients flat. Second, the novelty factor uses the same histogram as the quality term, and its 0.3 to 0.6 ramp was calibrated on one pair (A and E). Third, exponential entropy is maximised by equal occupation, which rewards fine churn exactly as H6 predicts; the 21-to-47 climb is probably this. Validate before printing a number: seed variance for a fixed dictionary; scale dependence 64 to 1024; invariance under the H7 bijections and the shuffled controls (if shuffled bytes score the same, the measure does not see the text); agreement with the Shalizi-style replacement on the same frames. For H6, ranking twenty stills is the weakest design; people judge motion. Use short clips at display scale, pairwise forced choice with Bradley–Terry, Kendall W for agreement, bootstrap intervals on tau, controls among the items, blinded authors, a preregistered question. Six to ten raters give wide intervals; say so in the caption.

## 4. Reproducibility and the artifact

The settings line in every caption is the best idea in the plan; add the build tag and a hash of the dictionary file, since `dict=ca-swarm-f` silently changes meaning if the file does. Expected: seed lists, pinned Node and wabt versions, one command regenerating every CSV and figure, a tagged release on Zenodo, and the search budget (evaluations, CPU hours). Two conflicts to resolve now: the plan's table says torus, `docs/lattice.md` says a plane with edges; `docs/changers.md` says the page starts at 128×128 while the plan pins 1024×1024 (verify against the page). Say plainly that the searches are not reproducible and that the shipped dictionaries plus logs are the record; for the paper, rerun with a generation budget.

## 5. Recommendations

1. Re-score every named dictionary at 1024×1024, 1,000 turns, 10 seeds, gradients on and flat; report that, not the search score.
2. Replace the hall of fame with a MAP-Elites grid over (d1, spatial, byte entropy) or a clustering of block features frozen on texts, not on searched dictionaries; report coverage and QD-score.
3. Compute novelty against the running archive in a space other than the objective's features; compression distance between frames (Cilibrasi and Vitányi) is already on your list.
4. Log operator and parent of every accepted child; report operator success rates in section 6.
5. Average over three seeds during search; re-evaluate elites on held-out seeds before promotion to the menu.
6. Run the shuffled, histogram-matched and bijection controls on the score itself before H3 and H7, as a validation figure.
7. Redesign H6 as pairwise choice on clips with Bradley–Terry and agreement statistics.
8. Switch runs to evaluation budgets and report the total budget behind every dictionary.
9. Fix the torus and grid-size discrepancies against the code.
10. Add Reinke et al. 2020, Flow Lenia, ASAL and Picbreeder to thread D; frame section 6 as QD with a hand-made behaviour characterisation and name its limits.
11. `fit` tiles the text to length, so dictionaries are periodic, which interacts with copy distances; state it or pad instead.

## 6. What would excite me

A clean H4 plus H1: a measured image size for the decoder, a coarsening exponent that turns over at a length set by the dictionary, and one figure where the shuffled dictionary loses the arrest and the bijected one keeps it. That is a real mechanism, text structure arresting coarsening through a many-to-one map. The score-versus-eye result I will believe only after the controls above; if it survives them it is the most useful thing in the paper for the rest of us.
