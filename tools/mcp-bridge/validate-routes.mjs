/**
 * Cross-check the routing table against the vendored addon sources.
 *
 * Parses `get_commands()` and the param reads (require_string / optional_* /
 * params.get / params.has) out of addons/godot_mcp/commands/*.gd and verifies
 * that every method and param name in routing.js actually exists.
 *
 * Run after updating the vendored addon:  node validate-routes.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { ROUTES, knownMethods, routedMethods } from './routing.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CMD_DIR = path.resolve(__dirname, '../../addons/godot_mcp/commands');

// Params read through helper indirections that the naive scanner cannot see.
const EXTRA_PARAMS = {
  select_nodes: ['node_paths', 'node_path'],
};

function parseAddon() {
  const spec = {};
  for (const file of fs.readdirSync(CMD_DIR).filter((f) => f.endsWith('.gd') && f !== 'base_command.gd')) {
    const src = fs.readFileSync(path.join(CMD_DIR, file), 'utf8');
    const bodies = {};
    for (const part of src.split(/^(?=func )/m)) {
      const h = part.match(/^func ([A-Za-z_0-9]+)/);
      if (h) bodies[h[1]] = part;
    }
    const gc = bodies['get_commands'] || '';
    for (const m of gc.matchAll(/"([a-z0-9_]+)"\s*:\s*([A-Za-z_0-9]+)/g)) {
      const [, cmd, handler] = m;
      const body = bodies[handler] || '';
      const names = new Set(EXTRA_PARAMS[cmd] || []);
      for (const x of body.matchAll(/require_string\(params,\s*"([a-z0-9_]+)"/g)) names.add(x[1]);
      for (const x of body.matchAll(/optional_(?:string|bool|int)\(params,\s*"([a-z0-9_]+)"/g)) names.add(x[1]);
      for (const x of body.matchAll(/params\.get\(\s*"([a-z0-9_]+)"/g)) names.add(x[1]);
      for (const x of body.matchAll(/params\.has\(\s*"([a-z0-9_]+)"/g)) names.add(x[1]);
      spec[cmd] = { file, params: [...names] };
    }
  }
  return spec;
}

const addon = parseAddon();
const real = new Set(Object.keys(addon));
const known = knownMethods();
const problems = [];

for (const m of known) if (!real.has(m)) problems.push(`método inexistente no addon: ${m}`);
for (const m of real) if (!known.has(m)) problems.push(`método do addon não mapeado: ${m}`);

for (const [toolName, tool] of Object.entries(ROUTES)) {
  for (const [actionName, action] of Object.entries(tool.actions)) {
    if (!action.method) continue;
    const realParams = addon[action.method]?.params ?? [];
    for (const p of Object.keys(action.params || {})) {
      if (!realParams.includes(p)) {
        problems.push(`${toolName}.${actionName} -> ${action.method}: param '${p}' não existe (reais: ${realParams.join(', ') || '—'})`);
      }
    }
  }
}

console.log(`comandos no addon: ${real.size}`);
console.log(`métodos conhecidos pelo bridge: ${known.size} (${routedMethods().size} na árvore de 9 ferramentas, ${known.size - routedMethods().size} só via godot_raw)`);
for (const [name, tool] of Object.entries(ROUTES)) {
  console.log(`  ${name.padEnd(15)} ${String(Object.keys(tool.actions).length).padStart(2)} ações`);
}

if (problems.length) {
  console.log(`\n${problems.length} problema(s):`);
  for (const p of problems) console.log(`  - ${p}`);
  process.exit(1);
}
console.log('\nrouting.js consistente com o addon vendorizado.');
