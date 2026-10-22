# Twelve quantities against log2 of the dictionary size, read from the three tables of paper/data/scale/summary.md
# (written by scale-summary.mjs): the construction, the map alone and the lattice. Figure paper/figures/dictionary-size-functions.png.
import re, os, sys
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'paper/data/scale/summary.md')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, 'paper/figures/dictionary-size-functions.png')
tables = []
for block in open(src).read().split('\n\n'):
    rows = [r for r in block.split('\n') if r.startswith('|')]
    if len(rows) > 2 and rows[0].startswith('| log2'):
        tables.append([[c.strip() for c in r.strip('|').split('|')] for r in rows[2:]])
con, mp, lat = tables[:3]
num = lambda s: float(re.sub(r'[^\d.]', '', s.split('(')[0].split('/')[0].replace(',', '')) or 'nan')
first = lambda s: num(s.split('(')[0])
L = np.array([num(r[0]) for r in con])
spots = [num(r[2]) for r in con]; pads = [num(r[4]) for r in con]
sched = [sum(float(x) for x in r[5].split('/')) for r in con]; built = [num(r[7]) for r in con]
headbits = [num(r[8]) for r in con]; secs = [num(r[9]) for r in con]
reached = [num(r[3]) for r in mp]; stray_share = [float(re.search(r'\(([\d.]+) %', r[4]).group(1)) for r in mp]
tmean = [num(r[5]) for r in mp]; tp90 = [float(re.search(r'\(([\d.]+)\)', r[5]).group(1)) for r in mp]
cmin = [float(r[7].replace('%', '').split('(')[0]) for r in mp]; empty = [num(r[6]) for r in mp]
alive_f = [first(r[2]) for r in lat]; alive_u = [first(r[8]) for r in lat]
ent_f = [first(r[4]) for r in lat]; ent_u = [first(r[9]) for r in lat]
tr_f = [first(r[5]) for r in lat]; tr_u = [first(r[10]) for r in lat]
dom_f = [first(r[6]) for r in lat]; dom_u = [first(r[11]) for r in lat]
bc_f = [first(r[7]) for r in lat]; bc_u = [first(r[12]) for r in lat]
kinds = np.array([[float(x) for x in r[3].split('/')] for r in lat])   # Gray / chasing / fixed alive on the frame
fig, ax = plt.subplots(3, 4, figsize=(16, 10.5)); ax = ax.ravel()
def panel(i, title, ylabel, log=False):
    a = ax[i]; a.set_title(title, fontsize=9); a.set_ylabel(ylabel, fontsize=8); a.grid(alpha=0.3); a.set_xticks(range(8, 25, 2))
    if log: a.set_yscale('log', base=2)
    return a
a = panel(0, '(a) the construction: what the size offers', 'count', True)
a.plot(L, spots, 'o-', ms=3, label='safe spots (heads the text carries)'); a.plot(L, pads, 's-', ms=3, label='distinct landing pads (period ≤ 4)')
a.plot(L, [2 ** l / 128 for l in L], ':', color='grey', label='spots = size / 128'); a.legend(fontsize=6)
a = panel(1, '(b) types: scheduled, built, reached by the map', 'types', True)
a.plot(L, sched, 'o-', ms=3, color='grey', label='scheduled'); a.plot(L, built, 's-', ms=3, color='C0', label='built (designed)')
a.plot(L, reached, '^--', ms=3, color='C2', label='reached by 16,384 random cells'); a.legend(fontsize=6)
a = panel(2, '(c) types alive on the frame at turn 2,000, by kind', 'types alive')
a.stackplot(L, kinds.T, labels=['Gray 8-cycles', 'chasing 3-cycles', 'fixed points'], colors=['C0', 'C1', 'C3'], alpha=0.8); a.legend(fontsize=6, loc='upper left')
a = panel(3, '(d) types alive at 2,000: frame and uniform (0.25, 0.5)', 'types alive')
a.plot(L, alive_f, '^-', ms=4, color='C1', label='the frame'); a.plot(L, [v if v > 0 else np.nan for v in alive_u], 'v-', ms=4, color='C2', label='uniform (none: no mark)'); a.plot(L, built, ':', color='grey', label='designed'); a.set_yscale('log', base=2); a.legend(fontsize=6)
a = panel(4, '(e) entropy of the type shares at 2,000', 'bits')
a.plot(L, ent_f, '^-', ms=4, color='C1', label='the frame'); a.plot(L, ent_u, 'v-', ms=4, color='C2', label='uniform'); a.plot(L, np.log2(built), ':', color='grey', label='log2 types designed'); a.legend(fontsize=6)
a = panel(5, '(f) share of cells on no designed type at 2,000', '%')
a.plot(L, tr_f, '^-', ms=4, color='C1', label='the frame'); a.plot(L, tr_u, 'v-', ms=4, color='C2', label='uniform'); a.set_ylim(0, 102); a.legend(fontsize=6)
a = panel(6, '(g) domains at 2,000 (4-connected, 256²)', 'domains', True)
a.plot(L, dom_f, '^-', ms=4, color='C1', label='the frame'); a.plot(L, [d if d > 0 else np.nan for d in dom_u], 'v-', ms=4, color='C2', label='uniform (none: no mark)'); a.legend(fontsize=6)
a = panel(7, '(h) block change at 2,000 (8×8 blocks, type differs from 1,800)', 'share of blocks')
a.plot(L, bc_f, '^-', ms=4, color='C1', label='the frame'); a.plot(L, bc_u, 'v-', ms=4, color='C2', label='uniform'); a.set_ylim(0, 0.1); a.legend(fontsize=6)
a = panel(8, '(i) map alone: cells on stray (undesigned) attractors', '% of cells')
a.plot(L, stray_share, 'o-', ms=4, color='C3'); a.set_ylim(0, 32)
a = panel(9, '(j) map alone: steps to the attractor', 'steps')
a.plot(L, tmean, 'o-', ms=4, color='C0', label='mean'); a.plot(L, tp90, 's--', ms=4, color='C0', alpha=0.6, label='p90'); a.legend(fontsize=6)
a = panel(10, '(k) closure C(A,A) at r = 0.25, min of the 20 largest', '%')
a.plot(L, cmin, 'o-', ms=4, color='C4'); a.set_ylim(0, 105); a.text(8.2, 8, 'below 100 %: a stray open cycle is among the 20 largest', fontsize=7)
a = panel(11, '(l) generation time (4 threads) and head bits', 'seconds')
a.bar(L, secs, color='C7', width=0.7); a2 = a.twinx(); a2.plot(L, headbits, 'o-', ms=3, color='C3'); a2.set_ylabel('head bits (quine head length)', color='C3', fontsize=8); a2.set_ylim(0, 70)
for a in ax: a.set_xlabel('log2 of the dictionary size (= header bits)', fontsize=8); a.tick_params(labelsize=8)
fig.suptitle('Functions of the dictionary size, 2^8 .. 2^24: one construction per size; lattice 256², 2,000 turns, three settling passes, 3 seeds', fontsize=11)
fig.tight_layout(); fig.savefig(out, dpi=120); print('written', out)
