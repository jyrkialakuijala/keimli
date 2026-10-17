#!/usr/bin/env python3
"""Spread 257 colours through the RGB cube and print the 256 non-white ones as the byte palette.

The eight corners of the cube are pinned; the other 249 points start at random and a bounded
quasi-Newton optimiser (L-BFGS-B) maximises  sum over colours of  sqrt(sqrt(distance to the nearest
other colour)).  The fourth root is concave, so the colours whose nearest neighbour is closest gain
most from moving, and the optimum spreads every colour as far from its closest one as the cube
allows, near a sphere packing. The nearest distance is smoothed as a power-mean soft minimum
(order -12) so the objective has a gradient; several random starts are tried and the best by the true smallest
gap after rounding is kept. The result is rounded half up to 8 bits a channel. White is one of the
pinned points but is left out of the table, so no byte is white and every byte shows against a
white page.

Which byte value gets which colour is a second optimisation, against the dictionaries in
src/changers/dict/manifest.json: for every dictionary, the byte values that make up at least 0.2 %
of its text are its working set, and the score is the frequency-weighted sum over that set of
sqrt(sqrt(distance to the nearest colour of another byte in the same set)). Summed over the
dictionaries (each counting once, whatever its length) and maximised by simulated annealing over
swaps of two byte values' colours, starting from a hue ordering dealt with a stride of 97. So the
Latin letters of the Declaration, the UTF-8 lead and continuation bytes of the Chinese poem, the
Cyrillic, Armenian, Georgian, Arabic and Devanagari texts all get a broad mix of colours at once.

    python3 tools/palette.py            # prints the JavaScript array for codec.js (about a minute)
    python3 tools/palette.py --stats    # palette statistics and, per dictionary, the colour gaps of its working set
"""
import sys, colorsys, json, os, time
import numpy as np
from scipy.optimize import minimize

N = 257
CORNERS = [(r, g, b) for r in (0, 1) for g in (0, 1) for b in (0, 1)]
fixed = np.array(CORNERS, float)
K = 12   # the soft minimum is the power mean of order -K: always positive, at most the true minimum

def energy(xflat):
    X = np.vstack([fixed, xflat.reshape(-1, 3)])
    diff = X[:, None, :] - X[None, :, :]
    d = np.sqrt((diff ** 2).sum(-1) + 1e-12)
    np.fill_diagonal(d, 1e9)
    m = d.min(1, keepdims=True)
    ratio = (m / d) ** K                             # in (0, 1], 1 for the nearest neighbour
    soft = (m[:, 0] * ratio.sum(1) ** (-1.0 / K))    # (sum_j d_ij^-K)^(-1/K)
    f = -(soft ** 0.25).sum()
    p = ratio * (soft[:, None] / m) ** (K + 1)       # d soft_i / d d_ij = (soft_i / d_ij)^(K+1)
    unit = diff / d[:, :, None]
    coef = 0.25 * soft ** -0.75
    g = -(coef[:, None] * (p[:, :, None] * unit).sum(1)) - ((coef[None, :] * p.T)[:, :, None] * unit).sum(1)
    return f, g[8:].ravel()

def nn_dist(Q):
    Y = np.array(Q, float)
    d = np.sqrt(((Y[:, None, :] - Y[None, :, :]) ** 2).sum(-1)); np.fill_diagonal(d, 1e9)
    return d.min(1)

best = None
for seed in range(8):
    rng = np.random.default_rng(20261017 + seed)
    x0 = rng.random((N - 8) * 3)
    res = minimize(energy, x0, jac=True, method='L-BFGS-B', bounds=[(0.0, 1.0)] * len(x0), options={'maxiter': 20000, 'maxfun': 40000, 'ftol': 1e-14, 'gtol': 1e-8})
    X = np.vstack([fixed, res.x.reshape(-1, 3)])
    Q = np.floor(X * 255 + 0.5).astype(int)          # round half up to 8 bits
    Q[:8] = fixed.astype(int) * 255
    score = nn_dist(Q).min()
    if '--debug' in sys.argv: print('seed', seed, res.message, 'nit', res.nit, 'objective', round(-res.fun, 4), 'min gap after rounding', score)
    if best is None or score > best[0]: best = (score, Q, res)
score, Q, res = best
assert len({tuple(q) for q in Q}) == N, 'two colours rounded onto one 8-bit cell'
white = (255, 255, 255)
colours = [tuple(int(v) for v in q) for q in Q if tuple(q) != white]
assert len(colours) == 256

def hue_key(c):
    h, l, s = colorsys.rgb_to_hls(*(v / 255 for v in c))
    return (h if s > 0.05 else 2.0 + l, l)
by_hue = sorted(colours, key=hue_key)
C = np.array([(v * 97) % 256 for v in range(256)])          # byte value -> index into by_hue, the starting deal
PAL = np.array(by_hue, float)
DM = np.sqrt(((PAL[:, None, :] - PAL[None, :, :]) ** 2).sum(-1))   # colour-to-colour distances, 8-bit units

# the dictionaries' byte distributions
here = os.path.dirname(os.path.abspath(__file__))
dict_dir = os.path.join(here, '..', 'src', 'changers', 'dict')
manifest = json.load(open(os.path.join(dict_dir, 'manifest.json'), encoding='utf-8'))
dicts = []
for entry in manifest:
    data = open(os.path.join(dict_dir, entry['file']), 'rb').read()
    counts = np.bincount(np.frombuffer(data, np.uint8), minlength=256).astype(float)
    pd = counts / counts.sum()
    S = np.nonzero(pd >= 0.002)[0]
    dicts.append((entry.get('titleLatin') or entry['id'], S, pd[S]))

def dict_score(C, S, w):
    sub = DM[np.ix_(C[S], C[S])].copy()
    np.fill_diagonal(sub, np.inf)
    return (w * sub.min(1) ** 0.25).sum()

def total_score(C):
    return sum(dict_score(C, S, w) for _, S, w in dicts)

members = [set(S.tolist()) for _, S, _ in dicts]
touching = [[k for k in range(len(dicts)) if v in members[k]] for v in range(256)]   # the dictionaries each byte value matters to
rng = np.random.default_rng(7)
scores = np.array([dict_score(C, S, w) for _, S, w in dicts])
start_total = scores.sum()
best_C, best_total = C.copy(), start_total
T0, T1, STEPS = 0.05, 0.0005, 1000000
t_start = time.time()
for step in range(STEPS):
    a, b = rng.integers(256, size=2)
    if a == b: continue
    ks = sorted(set(touching[a]) | set(touching[b]))
    if not ks: continue
    C[a], C[b] = C[b], C[a]
    new = np.array([dict_score(C, dicts[k][1], dicts[k][2]) for k in ks])
    delta = new.sum() - scores[ks].sum()
    T = T0 * (T1 / T0) ** (step / STEPS)
    if delta >= 0 or rng.random() < np.exp(delta / T):
        scores[ks] = new
        if scores.sum() > best_total: best_total, best_C = scores.sum(), C.copy()
    else:
        C[a], C[b] = C[b], C[a]
C = best_C
table = [by_hue[C[v]] for v in range(256)]
packed = [(c[2] << 16) | (c[1] << 8) | c[0] for c in table]

if '--stats' in sys.argv:
    print('optimiser:', res.message, 'iterations', res.nit, 'objective', round(-res.fun, 4))
    inside = sum(1 for c in colours if all(0 < v < 255 for v in c))
    print('colours strictly inside the cube:', inside, 'of 256; on a face:', 256 - inside)
    nn = nn_dist(colours)
    print('nearest neighbour (8-bit units): min %.1f  median %.1f  max %.1f' % (nn.min(), np.median(nn), nn.max()))
    print('corners present:', all(tuple(int(v) * 255 for v in c) in set(colours) for c in CORNERS if c != (1, 1, 1)), ' white absent:', white not in set(colours))
    print('nearest-neighbour histogram (steps of 4):', np.bincount((nn / 4).astype(int)).tolist())
    print('assignment: score %.3f from %.3f (hue stride) in %.0f s' % (best_total, start_total, time.time() - t_start))
    print('per dictionary, working set size, the smallest colour gap within it, the frequency-weighted mean gap (8-bit units):')
    for name, S, w in dicts:
        sub = DM[np.ix_(C[S], C[S])].copy(); np.fill_diagonal(sub, np.inf); nn = sub.min(1)
        print('  %-34s %3d bytes  min %5.1f  mean %5.1f' % (name[:34], len(S), nn.min(), (w * nn).sum() / w.sum()))
else:
    rows = [', '.join('0x%06x' % p for p in packed[i:i + 8]) for i in range(0, 256, 8)]
    print('  const BYTE_PALETTE = new Uint32Array([\n    ' + ',\n    '.join(rows) + ']);')
