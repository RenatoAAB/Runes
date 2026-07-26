/**
 * Self-test: sobe um FAKE addon Godot (WebSocket client falando o protocolo real
 * de addons/godot_mcp/websocket_server.gd) + o bridge real via cliente MCP stdio,
 * e valida a superfície de ferramentas ponta a ponta.
 *
 *   node selftest.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import WebSocket from 'ws';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

import { GodotBridge } from './bridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.SELFTEST_PORT || 6599);

// PNG 1x1 válido (transparente).
const PNG_1X1 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

let passed = 0;
const failures = [];

function ok(label, cond, detail = '') {
  if (cond) {
    passed++;
    console.log(`  PASS  ${label}`);
  } else {
    failures.push(`${label}${detail ? ` — ${detail}` : ''}`);
    console.log(`  FAIL  ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── FAKE addon Godot ────────────────────────────────────────────────────────
// Fala exatamente o que websocket_server.gd fala: conecta como CLIENTE,
// manda ping a cada 5s, responde {"jsonrpc":"2.0","id":N,"result"|"error"}.
class FakeGodot {
  constructor(port) {
    this.port = port;
    this.ws = null;
    this.gotPong = false;
    this.receivedMethods = [];
  }

  connect() {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${this.port}`, {
        maxPayload: 16 * 1024 * 1024,
      });
      this.ws = ws;
      ws.on('open', () => {
        // heartbeat idêntico ao do addon
        this.pingTimer = setInterval(() => this.send({ jsonrpc: '2.0', method: 'ping', params: {} }), 5000);
        resolve();
      });
      ws.on('error', reject);
      ws.on('message', (data) => this.onMessage(data));
    });
  }

  send(obj) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) this.ws.send(JSON.stringify(obj));
  }

  close() {
    if (this.pingTimer) clearInterval(this.pingTimer);
    if (this.ws) this.ws.close();
  }

  onMessage(data) {
    const msg = JSON.parse(data.toString('utf8'));

    if (msg.method === 'ping') {
      // O addon responde pong a um ping recebido.
      this.send({ jsonrpc: '2.0', method: 'pong', params: {} });
      return;
    }
    if (msg.method === 'pong') {
      this.gotPong = true;
      return;
    }

    this.receivedMethods.push(msg.method);
    const reply = this.handle(msg.method, msg.params || {});
    if (reply.error) this.send({ jsonrpc: '2.0', id: msg.id, error: reply.error });
    else this.send({ jsonrpc: '2.0', id: msg.id, result: reply.result });
  }

  handle(method, params) {
    switch (method) {
      case 'get_scene_tree':
        return {
          result: {
            scene_path: 'res://scenes/main.tscn',
            tree: {
              name: 'Main',
              type: 'Node2D',
              children: [
                { name: 'GridManager', type: 'Node2D', children: [] },
                { name: 'Reader', type: 'Node', children: [] },
              ],
            },
          },
        };
      case 'get_project_info':
        return {
          result: {
            project_name: 'Runes',
            godot_version: { major: 4, minor: 4, string: '4.4.stable' },
            main_scene: 'res://scenes/main.tscn',
            autoloads: { EventBus: '*res://scripts/autoloads/event_bus.gd' },
          },
        };
      case 'get_editor_screenshot':
        return { result: { image_base64: PNG_1X1, width: 1, height: 1, format: 'png' } };
      case 'capture_frames':
        return {
          result: {
            frames: [PNG_1X1, PNG_1X1, PNG_1X1],
            count: 3,
            width: 1,
            height: 1,
            half_resolution: params.half_resolution ?? true,
          },
        };
      case 'get_performance_monitors':
        // Estado real quando nada está rodando.
        return {
          error: {
            code: -32000,
            message: 'No scene is currently playing',
            data: { suggestion: 'Use play_scene first.' },
          },
        };
      case 'get_editor_performance':
        return { result: { fps: 60, node_count: 1234 } };
      case 'setup_collision':
        return { result: { node_path: params.node_path, shape: params.shape, created: true } };
      default:
        return { error: { code: -32601, message: `Method not found: ${method}` } };
    }
  }
}

// ── helpers de asserção ─────────────────────────────────────────────────────
function payload(res) {
  const text = res.content?.[0]?.text ?? '';
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function isValidPng(file) {
  if (!fs.existsSync(file)) return false;
  const buf = fs.readFileSync(file);
  return buf.length > 8 && buf.subarray(0, 8).equals(PNG_MAGIC);
}

// ── execução ────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n=== selftest do godot mcp bridge (porta ${PORT}) ===\n`);

  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [path.join(__dirname, 'index.js')],
    env: { ...process.env, GODOT_MCP_PORT: String(PORT) },
    stderr: 'pipe',
    cwd: __dirname,
  });

  const client = new Client({ name: 'selftest', version: '1.0.0' }, { capabilities: {} });
  await client.connect(transport);
  if (transport.stderr) transport.stderr.on('data', (d) => process.stderr.write(`    [bridge] ${d}`));

  const fake = new FakeGodot(PORT);

  try {
    // 1 ── tools/list
    console.log('[1] tools/list');
    const { tools } = await client.listTools();
    const names = tools.map((t) => t.name).sort();
    const expected = [
      'godot_anim', 'godot_fx', 'godot_node', 'godot_project', 'godot_raw',
      'godot_runtime', 'godot_scene', 'godot_script', 'godot_view',
    ];
    ok('9 ferramentas expostas', tools.length === 9, `recebido ${tools.length}: ${names.join(', ')}`);
    ok('nomes das ferramentas corretos', JSON.stringify(names) === JSON.stringify(expected), names.join(', '));
    ok(
      'descrições listam as ações',
      tools.every((t) => /Ações:|Categorias acessíveis/.test(t.description)),
    );
    ok(
      'schemas exigem action (ou method no raw)',
      tools.every((t) => t.inputSchema.required?.length >= 1),
    );

    // 2 ── erro claro com Godot desconectado
    console.log('\n[2] Godot desconectado');
    const disc = await client.callTool({ name: 'godot_scene', arguments: { action: 'tree' } });
    ok('chamada falha quando o editor não está conectado', disc.isError === true);
    ok(
      'mensagem de erro é clara e em pt-BR',
      String(payload(disc)).includes('Editor Godot não conectado'),
      String(payload(disc)).slice(0, 120),
    );

    const statusOffline = payload(
      await client.callTool({ name: 'godot_view', arguments: { action: 'status' } }),
    );
    ok('status funciona mesmo desconectado', statusOffline.editor_connected === false);
    ok('status informa a porta', statusOffline.port === PORT);

    // 3 ── conecta o fake addon
    console.log('\n[3] conectando o addon Godot falso');
    await fake.connect();
    await sleep(300);
    ok('addon conectou ao bridge', fake.ws.readyState === WebSocket.OPEN);

    // 4 ── status conectado
    console.log('\n[4] godot_view status');
    const status = payload(await client.callTool({ name: 'godot_view', arguments: { action: 'status' } }));
    ok('editor_connected = true', status.editor_connected === true);
    ok('detecta que o jogo NÃO está rodando', status.game_running === false, JSON.stringify(status.game_running));
    ok('traz metadados do projeto', status.project_name === 'Runes', JSON.stringify(status.project_name));
    ok('informa o diretório de screenshots', typeof status.screenshot_dir === 'string');

    // 5 ── godot_scene tree
    console.log('\n[5] godot_scene tree');
    const tree = payload(await client.callTool({ name: 'godot_scene', arguments: { action: 'tree' } }));
    ok('retorna scene_path', tree.scene_path === 'res://scenes/main.tscn');
    ok('retorna a árvore', tree.tree?.name === 'Main' && tree.tree?.children?.length === 2);

    // 6 ── screenshot vira arquivo PNG
    console.log('\n[6] screenshot -> arquivo PNG');
    const shot = payload(await client.callTool({ name: 'godot_view', arguments: { action: 'editor_shot' } }));
    ok('não retorna base64 inline', !JSON.stringify(shot).includes(PNG_1X1.slice(0, 40)));
    ok('retorna image_png_path', typeof shot.image_png_path === 'string', JSON.stringify(shot));
    ok('arquivo existe e é um PNG válido', isValidPng(shot.image_png_path), shot.image_png_path);
    ok('mantém os metadados', shot.width === 1 && shot.height === 1 && shot.format === 'png');

    // 7 ── capture multi-frame
    console.log('\n[7] godot_runtime capture (multi-frame)');
    const cap = payload(
      await client.callTool({ name: 'godot_runtime', arguments: { action: 'capture', params: { count: 3 } } }),
    );
    ok('frames viram lista de caminhos', Array.isArray(cap.frames) && cap.frames.length === 3, JSON.stringify(cap.frames));
    ok('todos os frames são PNGs válidos', Array.isArray(cap.frames) && cap.frames.every(isValidPng));

    // 8 ── describe
    console.log('\n[8] describe');
    const desc = payload(
      await client.callTool({ name: 'godot_node', arguments: { action: 'describe', params: { action: 'add' } } }),
    );
    ok('describe mapeia para o método real', desc.godot_method === 'add_node', JSON.stringify(desc.godot_method));
    ok('describe lista params com required', desc.params?.type?.required === true);
    ok('describe traz exemplo', desc.example?.action === 'add');

    const descAll = payload(await client.callTool({ name: 'godot_fx', arguments: { action: 'describe' } }));
    ok('describe sem alvo lista todas as ações', Object.keys(descAll.actions || {}).length === 11);

    // 9 ── validação de params
    console.log('\n[9] validação de params');
    const bad = await client.callTool({ name: 'godot_node', arguments: { action: 'add', params: {} } });
    ok('param obrigatório ausente é rejeitado', bad.isError === true);
    ok('erro nomeia o param faltante', String(payload(bad)).includes('type'), String(payload(bad)).slice(0, 140));

    const badAction = await client.callTool({ name: 'godot_scene', arguments: { action: 'nope' } });
    ok('ação inexistente é rejeitada', badAction.isError === true);
    ok('erro lista as ações válidas', String(payload(badAction)).includes('tree'));

    // 10 ── godot_raw
    console.log('\n[10] godot_raw');
    const raw = payload(
      await client.callTool({
        name: 'godot_raw',
        arguments: { method: 'setup_collision', params: { node_path: 'Player', shape: 'rect' } },
      }),
    );
    ok('raw repassa o método', raw.created === true && raw.node_path === 'Player', JSON.stringify(raw));

    const methods = payload(await client.callTool({ name: 'godot_raw', arguments: { method: 'list_methods' } }));
    ok('list_methods devolve os 174 métodos do addon', methods.count === 174, `count=${methods.count}`);

    // 11 ── heartbeat
    console.log('\n[11] heartbeat');
    fake.send({ jsonrpc: '2.0', method: 'ping', params: {} });
    await sleep(300);
    ok('bridge responde pong ao ping do addon', fake.gotPong === true);

    // 12 ── erro vindo do Godot é propagado
    console.log('\n[12] propagação de erro do Godot');
    const gameErr = await client.callTool({ name: 'godot_runtime', arguments: { action: 'exec', params: { code: 'pass' } } });
    ok('erro do addon vira isError', gameErr.isError === true);
    ok(
      'mensagem inclui método e código',
      String(payload(gameErr)).includes('execute_game_script') && String(payload(gameErr)).includes('-32601'),
      String(payload(gameErr)).slice(0, 140),
    );
    // 13 ── fallback de porta (o addon varre 6505..6514; várias sessões coexistem)
    console.log('\n[13] fallback de porta');
    const a = new GodotBridge({ port: 6505 });
    const b = new GodotBridge({ port: 6505 });
    try {
      await a.start();
      await b.start();
      ok('duas instâncias pegam portas diferentes', a.port !== b.port, `a=${a.port} b=${b.port}`);
      ok('ambas dentro de 6505..6514', a.port >= 6505 && b.port <= 6514, `a=${a.port} b=${b.port}`);
    } finally {
      await a.stop().catch(() => {});
      await b.stop().catch(() => {});
    }
  } finally {
    fake.close();
    await client.close().catch(() => {});
  }

  console.log(`\n=== ${passed} passaram, ${failures.length} falharam ===`);
  if (failures.length) {
    for (const f of failures) console.log(`  - ${f}`);
    process.exit(1);
  }
  console.log('selftest OK\n');
  process.exit(0);
}

main().catch((err) => {
  console.error('selftest quebrou:', err);
  process.exit(1);
});
