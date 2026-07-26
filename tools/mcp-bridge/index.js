#!/usr/bin/env node
/**
 * MCP stdio server bridging Claude <-> the vendored `addons/godot_mcp` editor plugin.
 *
 *   Claude  --stdio-->  este bridge  --WebSocket(server :6505)-->  editor Godot
 *
 * Tudo local (127.0.0.1). Porta via GODOT_MCP_PORT (default 6505).
 * Logs SEMPRE em stderr — stdout é o canal MCP.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

import { GodotBridge, log } from './bridge.js';
import { listTools, makeToolHandler, SHOT_DIR } from './tools.js';

const ENV_PORT = process.env.GODOT_MCP_PORT;
const PORT = Number(ENV_PORT || 6505);

async function main() {
  const bridge = new GodotBridge({ port: PORT, fixedPort: Boolean(ENV_PORT) });
  await bridge.start();

  const callTool = makeToolHandler(bridge);

  const server = new Server(
    { name: 'godot-runes-bridge', version: '1.0.0' },
    { capabilities: { tools: {} } },
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: listTools() }));

  server.setRequestHandler(CallToolRequestSchema, async (req) => {
    const { name, arguments: args } = req.params;
    try {
      const result = await callTool(name, args ?? {});
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    } catch (err) {
      log(`erro em ${name}: ${err.message}`);
      return {
        isError: true,
        content: [{ type: 'text', text: err.message }],
      };
    }
  });

  const shutdown = async () => {
    log('encerrando...');
    await bridge.stop().catch(() => {});
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  await server.connect(new StdioServerTransport());
  log(`pronto — ${listTools().length} ferramentas; screenshots em ${SHOT_DIR}`);
}

main().catch((err) => {
  log(`falha fatal: ${err.stack || err.message}`);
  process.exit(1);
});
