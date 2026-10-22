// Provenance for every experiment output: which code, which build, which command, when. Usage:
//   import { provenance } from './provenance.mjs';  const prov = provenance(import.meta.url, opts);
// and store `prov` in the output JSON (key "provenance") and print provLine(prov) at the top of Markdown outputs.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { execSync } from 'node:child_process';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const sha = p => { try { return crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex').slice(0, 16); } catch { return null; } };
const git = cmd => { try { return execSync(`git -C ${dir} ${cmd}`, { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch { return null; } };
export function provenance(scriptUrl, options = {}) {
  const script = new URL(scriptUrl).pathname;
  return {
    script: script.replace(dir + '/', ''), scriptSha: sha(script), argv: process.argv.slice(2), options,
    commit: git('rev-parse --short HEAD'), dirty: (git('status --porcelain --untracked-files=no') || '').length > 0,
    wasmSha: sha(dir + '/build/keimli.wasm'), harnessSha: sha(dir + '/tools/ca-harness.mjs'), bandSha: sha(dir + '/src/lattice/band.js'),
    node: process.version, date: new Date().toISOString(),
  };
}
export const provLine = p => `<!-- provenance: ${p.script} (${p.scriptSha}) ${p.argv.join(' ')} | commit ${p.commit}${p.dirty ? '+dirty' : ''} | wasm ${p.wasmSha} | ${p.date} -->`;
