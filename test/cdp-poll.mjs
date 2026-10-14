// Poll a page through the DevTools protocol: launch chromium headless with remote debugging,
// evaluate an expression repeatedly until it is truthy or the time runs out.
import { spawn } from 'node:child_process';
const [url, expr, maxMs = '20000'] = process.argv.slice(2);
const port = 9333 + Math.floor(Math.random() * 500);
const chrome = spawn('chromium', ['--headless=new', '--no-sandbox', '--disable-gpu', `--remote-debugging-port=${port}`, url], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws;
try {
  let targets = null;
  for (let i = 0; i < 50 && !targets; i++) { await sleep(200); try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch {} }
  const page = targets.find(t => t.type === 'page');
  ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);
  let id = 0; const pending = new Map();
  ws.onmessage = e => { const m = JSON.parse(e.data); if (pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
  const send = (method, params) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const t0 = Date.now(); let last = null;
  while (Date.now() - t0 < Number(maxMs)) {
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true });
    last = r.result?.result?.value;
    if (last) break;
    await sleep(500);
  }
  console.log(JSON.stringify(last));
  process.exitCode = last ? 0 : 1;
} finally { ws?.close(); chrome.kill(); }
