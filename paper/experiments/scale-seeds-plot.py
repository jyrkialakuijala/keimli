# Figure for results/dictionary-size-seeds.md from paper/data/scale-seeds/summary.json: the median over the 11 designs
# with the interquartile band against log2 size for the types designed, the types alive at 2,000, the entropy, the domains
# and the stray share, seed 1 marked; and every design's alive count per size.
import json, os
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
rows = json.load(open(os.path.join(root, 'paper/data/scale-seeds/summary.json')))['rows']
n = [r['n'] for r in rows]
C = {'median': '#2a78d6', 'band': '#2a78d6', 'seed1': '#eb6834', 'points': '#52514e'}   # the reference palette: blue, orange, grey
def band(a, key, log=False, fmt=None):
    med = [r[key]['median'] for r in rows]; q1 = [r[key]['q1'] for r in rows]; q3 = [r[key]['q3'] for r in rows]; s1 = [r[key]['seed1'] for r in rows]
    nz = lambda v: [np.nan if (x is None or (log and x == 0)) else x for x in v]
    a.fill_between(n, nz(q1), nz(q3), color=C['band'], alpha=0.18, lw=0, label='interquartile range')
    a.plot(n, nz(med), '-', color=C['median'], marker='o', ms=4, lw=1.5, label='median of 11 designs')
    a.plot(n, nz(s1), 'none', color=C['seed1'], marker='^', ms=6, label='seed 1 (the shipped dictionary)')
    if log: a.set_yscale('log', base=2)
    a.set_xticks(range(8, 27, 2)); a.grid(alpha=0.25, lw=0.5)
fig, ax = plt.subplots(2, 3, figsize=(14, 7.5))
band(ax[0, 0], 'designed', True); ax[0, 0].set_title('(a) types designed', fontsize=10); ax[0, 0].set_ylabel('types'); ax[0, 0].legend(fontsize=7, loc='upper left')
band(ax[0, 1], 'alive', True); ax[0, 1].set_title('(b) types alive at turn 2,000 on the frame (share ≥ 0.1 %)', fontsize=10)
band(ax[0, 2], 'entropy'); ax[0, 2].set_title('(c) entropy of the type shares at 2,000 (bits)', fontsize=10)
band(ax[1, 0], 'domains', True); ax[1, 0].set_title('(d) domains at 2,000 (4-connected, 256²)', fontsize=10); ax[1, 0].set_xlabel('log2 of the dictionary size')
band(ax[1, 1], 'stray'); ax[1, 1].set_title('(e) stray share of 16,384 random cells, the map alone', fontsize=10); ax[1, 1].set_xlabel('log2 of the dictionary size'); ax[1, 1].set_ylim(0, None)
a = ax[1, 2]
for r in rows:
    pts = [(d['seed'], d['alive']) for d in r['designs'] if d['alive'] is not None]
    a.scatter([r['n'] + (s - 6) * 0.06 for s, _ in pts], [max(v, 0.5) for _, v in pts], s=14, color=C['points'], alpha=0.7, lw=0)
    s1 = [v for s, v in pts if s == 1]
    if s1: a.scatter([r['n'] - 5 * 0.06], [max(s1[0], 0.5)], s=36, marker='^', color=C['seed1'], zorder=3)
a.set_yscale('log', base=2); a.set_xticks(range(8, 27, 2)); a.grid(alpha=0.25, lw=0.5); a.set_title('(f) every design: types alive at 2,000 (0 drawn at ½)', fontsize=10); a.set_xlabel('log2 of the dictionary size')
fig.suptitle('Eleven designs per size, 2^8 .. 2^26: the frame at 256², 2,000 turns, three settling passes, rotating order, quenched hashing, one lattice run per design', fontsize=10)
fig.tight_layout(); fig.savefig(os.path.join(root, 'paper/figures/dictionary-size-seeds.png'), dpi=130); print('dictionary-size-seeds.png')
