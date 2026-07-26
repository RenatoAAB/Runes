/**
 * GodotBridge — WebSocket SERVER that the vendored `addons/godot_mcp` plugin
 * connects to as a CLIENT.
 *
 * Protocol (confirmed in addons/godot_mcp/websocket_server.gd):
 *   - The addon connects to ws://127.0.0.1:PORT (it sweeps 6505..6514).
 *   - We send   {"jsonrpc":"2.0","id":N,"method":"...","params":{...}}
 *   - It replies {"jsonrpc":"2.0","id":N,"result":{...}}
 *            or  {"jsonrpc":"2.0","id":N,"error":{code,message,data?}}
 *   - It sends   {"jsonrpc":"2.0","method":"ping","params":{}} every 5s.
 *     On receiving method "ping" it answers {"...","method":"pong"}; it ignores "pong".
 *     It force-reconnects after 30s without receiving ANY message, so we ping every 10s.
 *   - Buffers are 16MB on its side (screenshots travel as base64).
 */

import { WebSocketServer } from 'ws';

export const DISCONNECTED_MESSAGE =
  'Editor Godot não conectado — abra o projeto no editor Godot (plugin habilitado).';

const PING_INTERVAL_MS = 10_000;
const DEFAULT_TIMEOUT_MS = 60_000;
const MAX_PAYLOAD = 16 * 1024 * 1024;

// The addon sweeps these ports (websocket_server.gd: BASE_PORT..MAX_PORT).
export const BASE_PORT = 6505;
export const MAX_PORT = 6514;

function portSweep(start) {
  const ports = [];
  for (let p = start; p <= MAX_PORT; p++) ports.push(p);
  return ports.length ? ports : [start];
}

function listen(host, port) {
  return new Promise((resolve, reject) => {
    const wss = new WebSocketServer({ host, port, maxPayload: MAX_PAYLOAD });
    const onError = (err) => {
      wss.removeListener('listening', onListening);
      reject(err);
    };
    const onListening = () => {
      wss.removeListener('error', onError);
      resolve(wss);
    };
    wss.once('error', onError);
    wss.once('listening', onListening);
  });
}

export function log(...args) {
  // stdout is the MCP stdio channel — logs MUST go to stderr.
  process.stderr.write(`[godot-mcp] ${args.join(' ')}\n`);
}

export class GodotDisconnectedError extends Error {
  constructor() {
    super(DISCONNECTED_MESSAGE);
    this.name = 'GodotDisconnectedError';
  }
}

export class GodotCommandError extends Error {
  constructor(rpcError, method) {
    const code = rpcError?.code ?? -32603;
    super(`Godot [${method}] erro ${code}: ${rpcError?.message ?? 'erro desconhecido'}`);
    this.name = 'GodotCommandError';
    this.code = code;
    this.data = rpcError?.data;
  }
}

export class GodotBridge {
  constructor({ port = BASE_PORT, host = '127.0.0.1', timeoutMs = DEFAULT_TIMEOUT_MS, fixedPort = false } = {}) {
    this.port = port;
    this.host = host;
    this.timeoutMs = timeoutMs;
    // When the port was pinned explicitly (GODOT_MCP_PORT), never wander off it.
    this.fixedPort = fixedPort;

    this.wss = null;
    this.socket = null;
    this.connectedAt = null;
    this.lastMessageAt = null;
    this._nextId = 1;
    this._pending = new Map(); // id -> {resolve, reject, timer, method}
    this._pingTimer = null;
  }

  get connected() {
    return this.socket != null && this.socket.readyState === 1; // OPEN
  }

  /**
   * Bind the WebSocket server. The addon dials every port in 6505..6514, so when
   * another bridge instance already holds our port we simply take the next free
   * one instead of dying (multiple Claude sessions share one editor).
   */
  async start() {
    const candidates = this.fixedPort ? [this.port] : portSweep(this.port);
    let lastErr = null;

    for (const port of candidates) {
      try {
        this.wss = await listen(this.host, port);
        this.port = port;
        log(`WebSocket server ouvindo em ws://${this.host}:${port} (aguardando o addon do editor)`);
        this.wss.on('connection', (ws) => this._onConnection(ws));
        this.wss.on('error', (err) => log(`erro no WebSocket server: ${err.message}`));

        this._pingTimer = setInterval(() => this._ping(), PING_INTERVAL_MS);
        if (this._pingTimer.unref) this._pingTimer.unref();
        return;
      } catch (err) {
        lastErr = err;
        if (err.code === 'EADDRINUSE') {
          log(`porta ${port} ocupada — tentando a próxima`);
          continue;
        }
        throw err;
      }
    }
    throw new Error(
      `Não foi possível abrir nenhuma porta em ${candidates[0]}..${candidates[candidates.length - 1]}: ${lastErr?.message}`,
    );
  }

  async stop() {
    if (this._pingTimer) clearInterval(this._pingTimer);
    for (const [id, p] of this._pending) {
      clearTimeout(p.timer);
      p.reject(new Error('Bridge encerrado'));
      this._pending.delete(id);
    }
    if (this.socket) {
      try { this.socket.close(); } catch { /* ignore */ }
    }
    if (this.wss) await new Promise((r) => this.wss.close(r));
  }

  _onConnection(ws) {
    if (this.socket && this.socket.readyState === 1) {
      // Godot only ever holds one connection per port; a new one means the old
      // socket is stale (editor restarted). Drop the old one.
      log('nova conexão recebida — substituindo a anterior');
      try { this.socket.close(1000, 'Replaced'); } catch { /* ignore */ }
    }
    this.socket = ws;
    this.connectedAt = Date.now();
    this.lastMessageAt = Date.now();
    log('editor Godot conectado');

    ws.on('message', (data) => this._onMessage(data));
    ws.on('close', () => {
      if (this.socket === ws) {
        this.socket = null;
        this.connectedAt = null;
      }
      log('editor Godot desconectado');
      // Fail fast on anything still in flight.
      for (const [id, p] of this._pending) {
        clearTimeout(p.timer);
        p.reject(new GodotDisconnectedError());
        this._pending.delete(id);
      }
    });
    ws.on('error', (err) => log(`erro de socket: ${err.message}`));
  }

  _onMessage(data) {
    this.lastMessageAt = Date.now();
    let msg;
    try {
      msg = JSON.parse(data.toString('utf8'));
    } catch {
      log('mensagem inválida (JSON malformado) descartada');
      return;
    }
    if (!msg || typeof msg !== 'object') return;

    // Heartbeat from the addon: answer so its inactivity timer resets.
    if (msg.method === 'ping') {
      this._send({ jsonrpc: '2.0', method: 'pong', params: {} });
      return;
    }
    if (msg.method === 'pong') return;

    if (msg.id == null) return;
    const pending = this._pending.get(msg.id);
    if (!pending) return;
    this._pending.delete(msg.id);
    clearTimeout(pending.timer);

    if (msg.error) pending.reject(new GodotCommandError(msg.error, pending.method));
    else pending.resolve(msg.result ?? {});
  }

  _send(obj) {
    if (!this.connected) return false;
    this.socket.send(JSON.stringify(obj));
    return true;
  }

  _ping() {
    if (this.connected) this._send({ jsonrpc: '2.0', method: 'ping', params: {} });
  }

  /**
   * Send a command to the editor addon and await its JSON-RPC response.
   * @returns {Promise<object>} the `result` payload (already unwrapped by the addon).
   */
  request(method, params = {}, timeoutMs = this.timeoutMs) {
    if (!this.connected) return Promise.reject(new GodotDisconnectedError());

    const id = this._nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this._pending.delete(id);
        reject(new Error(`Timeout de ${Math.round(timeoutMs / 1000)}s aguardando '${method}' do editor Godot.`));
      }, timeoutMs);
      if (timer.unref) timer.unref();

      this._pending.set(id, { resolve, reject, timer, method });
      const ok = this._send({ jsonrpc: '2.0', id, method, params });
      if (!ok) {
        clearTimeout(timer);
        this._pending.delete(id);
        reject(new GodotDisconnectedError());
      }
    });
  }

  status() {
    return {
      listening: this.wss != null,
      host: this.host,
      port: this.port,
      editor_connected: this.connected,
      connected_for_seconds: this.connectedAt ? Math.round((Date.now() - this.connectedAt) / 1000) : null,
      seconds_since_last_message: this.lastMessageAt
        ? Math.round((Date.now() - this.lastMessageAt) / 1000)
        : null,
      pending_requests: this._pending.size,
    };
  }
}
