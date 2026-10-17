(() => {
  // Links mode in the live page: with 4 workers configured, choosing Cells = Links with the Z80 must keep running on the
  // pool (turn time shows 4 thr), report the persistent link CPUs with the chosen rounds, and keep rewriting pixels.
  const T = () => +document.getElementById('turn').textContent.replace(/,/g, '');
  const txt = id => document.getElementById(id).textContent;
  const set = (id, v) => { const s = document.getElementById(id); s.value = v; s.dispatchEvent(new Event('change')); };
  if (T() < 50 || !document.documentElement.dataset.ready) return null;
  if (!window.__l) {
    window.__l = { stage: 'start' };
    set('threads', '4');
    setTimeout(() => {
      set('size', '128x128'); set('changer', 'cpu'); set('cpu', '6'); set('pair', '1'); set('rounds', '16'); const nv = document.getElementById('lnever'); nv.checked = false; nv.dispatchEvent(new Event('change')); set('lreset', '4'); document.getElementById('random').click();   // fresh random bits: the lattice may hold a decoder's text, whose bytes are Z80 loads and jumps that never write
      setTimeout(() => {
        const t0 = T();
        setTimeout(() => {
          Object.assign(window.__l, { turns: T() - t0, linkN: txt('linkN'), rewritten: txt('rewritten'), time: txt('turnTime') });
          const cv = document.querySelector('canvas'), b = cv.getBoundingClientRect();   // inspect the centre cell: the link machines that start there
          cv.dispatchEvent(new MouseEvent('click', { clientX: b.left + b.width / 2, clientY: b.top + b.height / 2, bubbles: true }));
          setTimeout(() => { Object.assign(window.__l, { inspect: txt('selWindow'), done: true }); }, 1500);
        }, 4000);
      }, 2500);
    }, 2500);
    return null;
  }
  return window.__l.done ? JSON.stringify(window.__l) : null;
})()
