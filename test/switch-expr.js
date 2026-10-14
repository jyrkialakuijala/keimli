(() => {
  const T = () => +document.getElementById('turn').textContent.replace(/,/g, '');
  const sum = () => { const c = document.getElementById('view-canvas'); const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let h = 0; for (let i = 0; i < d.length; i += 4) h = (h * 31 + d[i] + d[i + 1] * 7 + d[i + 2] * 13) >>> 0; return h; };
  const sw = v => { const sel = document.getElementById('threads'); sel.value = v; sel.dispatchEvent(new Event('change')); };
  if (T() < 50 || !document.documentElement.dataset.ready) return null;
  if (!window.__s) {
    window.__s = { stage: 'paused' };
    document.getElementById('step').click();   // pauses the animation and runs one more turn
    setTimeout(() => { const v = document.getElementById('view'); v.value = '0'; v.dispatchEvent(new Event('change')); }, 500);   // an unstretched view, so the image depends on the lattice alone
    setTimeout(() => {
      Object.assign(window.__s, { turnBefore: T(), sumBefore: sum() });
      sw('4');
      setTimeout(() => {
        Object.assign(window.__s, { turnAfter: T(), sumAfter: sum(), thr: document.getElementById('turnTime').textContent });
        sw('1');
        setTimeout(() => { Object.assign(window.__s, { turnBack: T(), sumBack: sum(), done: true }); }, 2500);
      }, 2500);
    }, 1500);
    return null;
  }
  return window.__s.done ? JSON.stringify(window.__s) : null;
})()
