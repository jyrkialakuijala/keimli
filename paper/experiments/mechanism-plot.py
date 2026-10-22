#!/usr/bin/env python3
"""Figures for results/mechanism.md: (M1) the fixed point's share over the page frame at turn 50 and 2000, Brotli 12 and
13; (M2) the closure index against the survival of random-phase domains, every type of every dictionary."""
import json, glob, os
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
D = os.path.join(root, 'paper', 'data'); F = os.path.join(root, 'paper', 'figures'); os.makedirs(F, exist_ok=True)
runs = [('ca-brotli-12', 1, 'Brotli 12, seed 1'), ('ca-brotli-12', 2, 'Brotli 12, seed 2'), ('ca-brotli-13', 1, 'Brotli 13, seed 1')]
fig, axes = plt.subplots(2, 3, figsize=(11, 7.4))
for col, (d, s, name) in enumerate(runs):
    r = json.load(open(f'{D}/frame-mechanism/frame-{d}-n256-t2000-seed{s}.json')); B = r['B']
    for row, t in enumerate([50, 2000]):
        snap = next(x for x in r['snaps'] if x['t'] == t)
        f = np.array([b['f'] for b in snap['blocks']]).reshape(B, B); c = np.array([b['c'] for b in snap['blocks']]).reshape(B, B)
        rgb = np.stack([f, np.zeros_like(f), c], axis=-1)   # red the fixed point, blue the cycle, black neither (the melt)
        ax = axes[row, col]; ax.imshow(rgb, interpolation='nearest', extent=(0, 1, 1, 0))
        ax.set_title(f'{name}, turn {t}', fontsize=9); ax.set_xticks([0, 0.5, 1]); ax.set_yticks([0, 0.5, 1])
        if row == 1: ax.set_xlabel('swap slider p (mixing 2p(1−p): strongest at ½)')
        if col == 0: ax.set_ylabel('median probability (settling)')
fig.suptitle(f'Where the fixed point wins on the frame: red = fixed point (basin 0.26 % / 2.8 %), blue = the large-basin cycle (99.7 % / 92.9 %), black = neither (melted)', fontsize=10)
fig.tight_layout(rect=(0, 0, 1, 0.95)); fig.savefig(f'{F}/mechanism-frame.png', dpi=150); plt.close(fig)
# M2: closure against survival
pts = []
for f in glob.glob(f'{D}/droplets/*.json'):
    d = json.load(open(f)); cf = f'{D}/closure/closure-{d["dict"]}.json'
    if not os.path.exists(cf): continue
    c = json.load(open(cf))
    for t in d['types']:
        self = next(x for x in c['rows'] if x['A'] == t['id'] and x['B'] == t['id'] and x['r'] == 0.25 and x['steps'] == 1)['closed']
        surv = np.mean([next(x for x in d['runs'] if x.get('whole') and x['Y'] == t['id'] and x['phase'] == 'random' and x['m'] == m)['xT'] for m in (0, 0.25, 0.5)])
        pts.append((self, surv, t['period'], t['basin'], d['dict']))
fig, ax = plt.subplots(figsize=(6.4, 4.6))
for self, surv, k, b, d in pts:
    ax.scatter(100 * self, 100 * surv, s=30 + 400 * b, c='#c0392b' if k == 1 else '#2e86c1', alpha=0.75, edgecolor='k', lw=0.4)
    if self < 0.99: ax.annotate(f'{d.replace("ca-", "")} {k}-cycle', (100 * self, 100 * surv), fontsize=7, xytext=(4, 4 + 10 * (k == 18)), textcoords='offset points')
ax.set_xlabel('self-closure C(A, A) (%): crossovers of two random states of A\nthat are on A again after one step of the decoder')
ax.set_ylabel('random-phase domain left after 400 turns (%)\n(swap 0.1, median 0 / 0.25 / 0.5, mean)')
ax.set_title('Closed types hold domains, open types melt (red: fixed points, blue: cycles; size: basin)', fontsize=9); ax.grid(alpha=0.3)
fig.tight_layout(); fig.savefig(f'{F}/mechanism-closure.png', dpi=150); plt.close(fig)
print('written mechanism-frame.png, mechanism-closure.png')
