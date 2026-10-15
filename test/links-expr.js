(() => {
  // Links mode in the live page: with 4 workers configured, choosing Cells = Links with the Z80 must switch to the
  // single-instance engine (turn time shows 1 thr), report the persistent link CPUs with the chosen rounds, and keep rewriting pixels.
  const T = () => +document.getElementById('turn').textContent.replace(/,/g, '');
  const txt = id => document.getElementById(id).textContent;
  const set = (id, v) => { const s = document.getElementById(id); s.value = v; s.dispatchEvent(new Event('change')); };
  if (T() < 50 || !document.documentElement.dataset.ready) return null;
  if (!window.__l) {
    window.__l = { stage: 'start' };
    set('threads', '4');
    setTimeout(() => {
      set('changer', 'cpu'); set('cpu', '6'); set('pair', '6'); set('rounds', '16'); set('lreset', '4');
      setTimeout(() => {
        const t0 = T();
        setTimeout(() => { Object.assign(window.__l, { turns: T() - t0, linkN: txt('linkN'), rewritten: txt('rewritten'), time: txt('turnTime'), done: true }); }, 4000);
      }, 2500);
    }, 2500);
    return null;
  }
  return window.__l.done ? JSON.stringify(window.__l) : null;
})()
