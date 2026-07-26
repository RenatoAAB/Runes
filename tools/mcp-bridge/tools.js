/**
 * MCP tool surface: 9 domain tools, each `{ action, params }`.
 * Handles light param validation, dispatch through GodotBridge and the
 * base64 -> PNG-on-disk conversion (image payloads are never returned inline).
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { ROUTES, RAW_ONLY_CATEGORIES, knownMethods, TOOL_NAMES } from './routing.js';
import { GodotDisconnectedError, DISCONNECTED_MESSAGE, log } from './bridge.js';

export const SHOT_DIR = path.join(os.tmpdir(), 'godot-mcp-shots');

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function timestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').replace('Z', '');
}

function ensureShotDir() {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  return SHOT_DIR;
}

/** Decode a base64 string and write it as a PNG. Returns metadata or null if not a PNG. */
export function saveBase64Png(b64, label) {
  let buf;
  try {
    buf = Buffer.from(b64, 'base64');
  } catch {
    return null;
  }
  if (buf.length < 8 || !buf.subarray(0, 8).equals(PNG_MAGIC)) return null;

  ensureShotDir();
  const file = path.join(SHOT_DIR, `${label}-${timestamp()}-${Math.random().toString(36).slice(2, 7)}.png`);
  fs.writeFileSync(file, buf);
  return { path: file, bytes: buf.length };
}

/**
 * Walk a result payload and replace every base64 image with a saved-file reference.
 * Handles `*_base64` string fields and `frames: [base64, ...]` (capture_frames).
 */
export function extractImages(value, label, key = null) {
  if (Array.isArray(value)) {
    // capture_frames returns `frames: [base64, ...]`
    if (key === 'frames' && value.every((v) => typeof v === 'string')) {
      const saved = [];
      value.forEach((b64, i) => {
        const r = saveBase64Png(b64, `${label}-frame${String(i).padStart(3, '0')}`);
        if (r) saved.push(r.path);
      });
      if (saved.length === value.length && saved.length > 0) return saved;
    }
    return value.map((v) => extractImages(v, label));
  }

  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      if (typeof v === 'string' && k.endsWith('_base64')) {
        const saved = saveBase64Png(v, `${label}-${k.replace(/_base64$/, '')}`);
        if (saved) {
          const base = k.replace(/_base64$/, '');
          out[`${base}_png_path`] = saved.path;
          out[`${base}_bytes`] = saved.bytes;
          continue;
        }
      }
      out[k] = extractImages(v, label, k);
    }
    return out;
  }

  return value;
}

/** JSON Schema shared by the 8 tree tools. */
function treeInputSchema(tool) {
  return {
    type: 'object',
    properties: {
      action: {
        type: 'string',
        enum: [...Object.keys(tool.actions), 'describe'],
        description: 'Ação a executar. Use "describe" com params.action para ver o schema detalhado.',
      },
      params: {
        type: 'object',
        description: 'Parâmetros da ação. Use action="describe" para descobrir os campos.',
        additionalProperties: true,
      },
    },
    required: ['action'],
    additionalProperties: false,
  };
}

function actionLine(name, a) {
  const req = Object.entries(a.params || {})
    .filter(([, p]) => p.required)
    .map(([n]) => n);
  const opt = Object.entries(a.params || {})
    .filter(([, p]) => !p.required)
    .map(([n]) => n);
  const sig = [...req.map((n) => n), ...opt.map((n) => `${n}?`)].join(', ');
  return `- ${name}(${sig}) — ${a.desc}`;
}

function toolDescription(name, tool) {
  const lines = Object.entries(tool.actions).map(([n, a]) => actionLine(n, a));
  return [
    `${tool.title}. ${tool.description}`,
    '',
    'Ações:',
    ...lines,
    '- describe(action) — schema detalhado de uma ação',
  ].join('\n');
}

export function listTools() {
  const tools = Object.entries(ROUTES).map(([name, tool]) => ({
    name,
    description: toolDescription(name, tool),
    inputSchema: treeInputSchema(tool),
  }));

  const rawCats = Object.entries(RAW_ONLY_CATEGORIES)
    .map(([cat, ms]) => `- ${cat}: ${ms.join(', ')}`)
    .join('\n');

  tools.push({
    name: 'godot_raw',
    description: [
      'Escape hatch: chama qualquer método do command_router do addon diretamente.',
      'Use quando a ação desejada não existe nas outras 8 ferramentas.',
      '',
      'Categorias acessíveis SOMENTE por aqui:',
      rawCats,
      '',
      'Use method="list_methods" para listar todos os métodos conhecidos.',
    ].join('\n'),
    inputSchema: {
      type: 'object',
      properties: {
        method: { type: 'string', description: 'Nome exato do método do addon (ex: "setup_collision")' },
        params: { type: 'object', description: 'Parâmetros do método', additionalProperties: true },
      },
      required: ['method'],
      additionalProperties: false,
    },
  });

  return tools;
}

function describeAction(toolName, tool, actionName) {
  if (!actionName) {
    return {
      tool: toolName,
      hint: 'Passe params.action com o nome da ação para ver o schema detalhado.',
      actions: Object.fromEntries(Object.entries(tool.actions).map(([n, a]) => [n, a.desc])),
    };
  }
  const a = tool.actions[actionName];
  if (!a) {
    return {
      error: `Ação desconhecida '${actionName}' em ${toolName}.`,
      available: Object.keys(tool.actions),
    };
  }
  return {
    tool: toolName,
    action: actionName,
    godot_method: a.method ?? '(interno da ponte)',
    description: a.desc,
    params: Object.fromEntries(
      Object.entries(a.params || {}).map(([n, p]) => [
        n,
        { type: p.type, required: !!p.required, description: p.desc },
      ]),
    ),
    example: {
      action: actionName,
      params: Object.fromEntries(
        Object.entries(a.params || {})
          .filter(([, p]) => p.required)
          .map(([n, p]) => [n, `<${p.type}>`]),
      ),
    },
  };
}

/** Light validation: required params present, no unknown params. */
function validateParams(toolName, actionName, action, params) {
  const spec = action.params || {};
  const missing = Object.entries(spec)
    .filter(([n, p]) => p.required && (params[n] === undefined || params[n] === null || params[n] === ''))
    .map(([n]) => n);
  if (missing.length) {
    throw new Error(
      `${toolName}.${actionName}: parâmetro(s) obrigatório(s) ausente(s): ${missing.join(', ')}. ` +
        `Use action="describe" com params.action="${actionName}" para o schema completo.`,
    );
  }
  const unknown = Object.keys(params).filter((n) => !(n in spec));
  if (unknown.length) {
    log(`aviso: ${toolName}.${actionName} recebeu param(s) não documentado(s): ${unknown.join(', ')} (repassados assim mesmo)`);
  }
}

/** Drop undefined/null so the addon sees its own defaults. */
function cleanParams(params) {
  const out = {};
  for (const [k, v] of Object.entries(params || {})) if (v !== undefined && v !== null) out[k] = v;
  return out;
}

async function probeGameRunning(bridge) {
  try {
    await bridge.request('get_performance_monitors', {}, 8000);
    return { game_running: true };
  } catch (err) {
    // The addon answers -32000 "No scene is currently playing" when nothing runs.
    if (/No scene is currently playing/i.test(err.message)) return { game_running: false };
    return { game_running: 'desconhecido', probe_error: err.message };
  }
}

async function handleStatus(bridge, params) {
  const status = bridge.status();
  const result = {
    ...status,
    screenshot_dir: SHOT_DIR,
    message: status.editor_connected
      ? 'Editor Godot conectado.'
      : DISCONNECTED_MESSAGE,
  };
  if (status.editor_connected && params.probe_game !== false) {
    Object.assign(result, await probeGameRunning(bridge));
    try {
      const info = await bridge.request('get_project_info', {}, 10000);
      result.project_name = info.project_name;
      result.godot_version = info.godot_version;
      result.main_scene = info.main_scene;
    } catch { /* non-fatal */ }
  }
  return result;
}

export function makeToolHandler(bridge) {
  return async function callTool(name, args = {}) {
    // ── godot_raw ─────────────────────────────────────────────────────────
    if (name === 'godot_raw') {
      const method = args.method;
      if (!method) throw new Error('godot_raw exige "method".');
      if (method === 'list_methods') {
        return { methods: [...knownMethods()].sort(), count: knownMethods().size };
      }
      if (!knownMethods().has(method)) {
        log(`aviso: método '${method}' não consta na tabela do addon vendorizado — enviando assim mesmo`);
      }
      if (!bridge.connected) throw new GodotDisconnectedError();
      const raw = await bridge.request(method, cleanParams(args.params));
      return extractImages(raw, method);
    }

    // ── the 8 tree tools ──────────────────────────────────────────────────
    const tool = ROUTES[name];
    if (!tool) throw new Error(`Ferramenta desconhecida: ${name}. Disponíveis: ${TOOL_NAMES.join(', ')}`);

    const actionName = args.action;
    const params = cleanParams(args.params);

    if (!actionName) {
      throw new Error(
        `${name} exige "action". Ações: ${Object.keys(tool.actions).join(', ')}, describe.`,
      );
    }

    if (actionName === 'describe') return describeAction(name, tool, params.action);

    const action = tool.actions[actionName];
    if (!action) {
      throw new Error(
        `Ação desconhecida '${actionName}' em ${name}. Ações: ${Object.keys(tool.actions).join(', ')}, describe.`,
      );
    }

    validateParams(name, actionName, action, params);

    // Bridge-internal action (does not need the editor connected).
    if (action.special === 'status') return handleStatus(bridge, params);

    if (!bridge.connected) throw new GodotDisconnectedError();

    const raw = await bridge.request(action.method, params);
    return extractImages(raw, `${name}-${actionName}`);
  };
}
