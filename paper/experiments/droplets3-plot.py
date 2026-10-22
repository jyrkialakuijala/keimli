# Figure for results/mechanism-v2.md from the three-pass droplet block (paper/data/droplets3/*.json):
# (a) the leading fixed point's share at the end against (swap, median), Brotli 12 and 13, coherent sea;
# (b) the radius series at (0.1, 0.5): share at the end against the disc radius, coherent and random seas;
# (c) the mean tracks of the fixed-point disc in Brotli 12 at median 0.5.
# Usage: python3 paper/experiments/droplets3-plot.py [paper/data/droplets3] [paper/figures/mechanism-v2.png]
import json, glob, sys, os
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ddir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'paper/data/droplets3')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, 'paper/figures/mechanism-v2.png')
files = [json.load(open(f)) for f in glob.glob(os.path.join(ddir, '*.json'))]
files = [f for f in files if 'centre' in f]
def lead_fp(f):   # the fixed point with the largest basin among the chosen types
    fps = [t for t in f['types'] if t['period'] == 1]; return max(fps, key=lambda t: t['basin'])['id'] if fps else None
def lead_cycle(f): return max([t for t in f['types'] if t['period'] > 1], key=lambda t: t['basin'])['id']
fig, ax = plt.subplots(1, 3, figsize=(13, 4))
# (a)
for k, dict_ in enumerate(['ca-brotli-12', 'ca-brotli-13']):
    fl = [f for f in files if f['dict'] == dict_ and not any(r['mode'] == 'radius' for r in f['runs'])]
    if not fl: continue
    P = sorted({f['p'] for f in fl}); M = sorted({f['m'] for f in fl}); X, Y = lead_fp(fl[0]), lead_cycle(fl[0])
    grid = np.full((len(P), len(M)), np.nan)
    for i, p in enumerate(P):
        for j, m in enumerate(M):
            v = [r['xT'] for f in fl if f['p'] == p and f['m'] == m for r in f['runs'] if r['mode'] == 'pair' and r['X'] == X and r['Y'] == Y and r['phase'] == 'coherent']
            if v: grid[i, j] = 100 * np.mean(v)
    a = ax[0]; im = a.imshow(grid, origin='lower', vmin=0, vmax=100, cmap='viridis', extent=[-0.5, len(M) - 0.5, -0.5 + 4.5 * k, len(P) - 0.5 + 4.5 * k], aspect='auto')
    for i, p in enumerate(P):
        for j, m in enumerate(M):
            if not np.isnan(grid[i, j]): a.text(j, i + 4.5 * k, f'{grid[i, j]:.0f}', ha='center', va='center', color='w' if grid[i, j] < 60 else 'k', fontsize=8)
    a.set_yticks([i + 4.5 * kk for kk in range(2) for i in range(len(P))]); a.set_yticklabels([f'{"B12" if kk == 0 else "B13"} p={p}' for kk in range(2) for p in P], fontsize=7)
    a.set_xticks(range(len(M))); a.set_xticklabels([f'm={m}' for m in M])
ax[0].set_title('(a) fixed-point disc (5 %) in the cycle, coherent sea:\nshare at turn 2000, mean of 5 seeds', fontsize=9)
plt.colorbar(im, ax=ax[0], fraction=0.04, label='%')
# (b)
for dict_, ls in [('ca-brotli-12', '-'), ('ca-brotli-13', '--')]:
    fl = [f for f in files if f['dict'] == dict_ and any(r['mode'] == 'radius' for r in f['runs']) and f['p'] == 0.1 and f['m'] == 0.5]
    if not fl: continue
    X, Y = lead_fp(fl[0]), lead_cycle(fl[0])
    for phase, c in [('coherent', 'C0'), ('random', 'C1')]:
        R = sorted({r['r'] for f in fl for r in f['runs']}); ys = []
        for rr in R:
            v = [r['xT'] for f in fl for r in f['runs'] if r['mode'] == 'radius' and r['X'] == X and r['Y'] == Y and r['phase'] == phase and r['r'] == rr]; ys.append(100 * np.mean(v) if v else np.nan)
        ax[1].plot(R, ys, ls, color=c, marker='o', label=f'{"Brotli 12" if "12" in dict_ else "Brotli 13"}, {phase} sea')
ax[1].set_xscale('log', base=2); ax[1].set_xlabel('disc radius R (cells)'); ax[1].set_ylabel('share at turn 1000, %'); ax[1].legend(fontsize=7)
ax[1].set_title('(b) radius series at swap 0.1, median 0.5:\na critical radius against a coherent sea, none against a disordered one', fontsize=9)
# (c)
fl = [f for f in files if f['dict'] == 'ca-brotli-12' and not any(r['mode'] == 'radius' for r in f['runs']) and f['m'] == 0.5]
if fl:
    X, Y = lead_fp(fl[0]), lead_cycle(fl[0])
    for p, c in [(0.1, 'C0'), (0.25, 'C2'), (0.5, 'C3')]:
        tr = [r['track'] for f in fl if f['p'] == p for r in f['runs'] if r['mode'] == 'pair' and r['X'] == X and r['Y'] == Y and r['phase'] == 'coherent']
        if not tr: continue
        t = [s[0] for s in tr[0]]; y = 100 * np.mean([[s[1] for s in k] for k in tr], axis=0)
        ax[2].plot(t, y, color=c, label=f'swap {p}')
    ax[2].set_xlabel('turn'); ax[2].set_ylabel('share of the fixed point, %'); ax[2].legend(fontsize=8)
    ax[2].set_title('(c) Brotli 12, median 0.5: growth into the coherent cycle,\nmean of 5 seeds', fontsize=9)
plt.tight_layout(); plt.savefig(out, dpi=130); print('written', out)
