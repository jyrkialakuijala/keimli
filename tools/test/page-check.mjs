// Load the built page in headless Chrome over the DevTools protocol with real time (so web workers run), wait for its
// self-test to finish and report the console. Serve the repository first (python3 -m http.server 8765 --bind 127.0.0.1).
// Usage: node tools/test/page-check.mjs http://127.0.0.1:8765/index.html#selftest [seconds]
//        node tools/test/page-check.mjs http://127.0.0.1:8765/index.html#selftest-workers [seconds]
// Prints ready (1) or not, the turn count, the window range and whether the flat twin is shown; a clean console is required.
const [url, secs = '60', shot = '', extra = '0'] = process.argv.slice(2);   // shot: a PNG path for a screenshot of the main canvas, taken extra seconds after ready
const { spawn } = await import('node:child_process');
const port = 9333 + Math.floor(Math.random() * 100);
const chrome = spawn('google-chrome', ['--headless=new', '--disable-gpu', '--no-sandbox', `--user-data-dir=/tmp/keimli-page-check-${port}`, `--remote-debugging-port=${port}`, 'about:blank'], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let targets; for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch (e) {} await sleep(200); }
const page = targets.find(t => t.type === "page" && !/extension/.test(t.url)) || targets.find(t => t.type === "page"); const ws = new WebSocket(page.webSocketDebuggerUrl); let id = 0; const waiting = new Map(); const logs = [];
const send = (method, params = {}) => new Promise(res => { const i = ++id; waiting.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
await new Promise(r => ws.onopen = r);
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && waiting.has(m.id)) { waiting.get(m.id)(m.result); waiting.delete(m.id); } else if (m.method === 'Runtime.consoleAPICalled') logs.push(m.params.type + ': ' + m.params.args.map(a => a.value ?? a.description).join(' ')); else if (m.method === 'Runtime.exceptionThrown') logs.push('exception: ' + (m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text)); };
await send('Runtime.enable'); await send('Page.enable'); await send('Page.navigate', { url });
const t0 = Date.now(); let last = '';
while (Date.now() - t0 < Number(secs) * 1000) {
  await sleep(1000);
  const r = await send('Runtime.evaluate', { expression: `location.href.slice(-30) + " " + document.readyState + " " + (document.documentElement.dataset.ready || '0') + ' turn=' + (document.getElementById('turn')||{}).textContent + ' cread=' + (document.getElementById('creadVal')||{}).textContent + ' twinHidden=' + (document.getElementById('twinStage')||{}).hidden`, returnByValue: true });
  last = r?.result?.value; if (last && / complete 1 /.test(last)) break;
}
if (shot) {   // let it run on, then clip the main canvas
  await sleep(Number(extra) * 1000);
  const turn = (await send('Runtime.evaluate', { expression: `document.getElementById('turn').textContent` })).result.value;
  const data = (await send('Runtime.evaluate', { expression: `document.getElementById('view-canvas').toDataURL('image/png')` })).result.value;   // the canvas itself, whatever the compositor shows
  (await import('node:fs')).writeFileSync(shot, Buffer.from(data.split(',')[1], 'base64')); console.log(`canvas ${shot} at turn ${turn}`);
}
console.log(`${url.split('#')[1] || url}: ${last} after ${((Date.now() - t0) / 1000).toFixed(0)} s; console: ${logs.length ? logs.slice(0, 6).join(' | ') : 'clean'}`);
ws.close(); chrome.kill();
