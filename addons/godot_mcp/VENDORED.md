# Vendored: godot_mcp addon

Este diretório foi vendorizado (copiado) do repositório de código aberto abaixo.
Apenas o addon Godot (`addons/godot_mcp/`) foi trazido para este projeto — o
servidor Node.js pago que acompanha o repositório original **não** foi baixado
nem é usado aqui.

## Origem

- Repositório: https://github.com/youichi-uda/godot-mcp-pro
- Branch: `master`
- Commit vendorizado: `c17a182d92f23ae22045598f6105a06a6737707b`
  (Youichi Uda, "v1.15.1: fix 15 bugs from external full-toolset audit", 2026-07-19)
- Data da vendorização: 2026-07-26

## Licença

O conteúdo deste diretório (`addons/godot_mcp/`) é licenciado sob **MIT**
(ver `LICENSE` neste mesmo diretório, copiado da raiz do repositório de origem).

## Servidor MCP

O servidor MCP (ponte WebSocket <-> MCP client) usado com este addon é uma
**implementação própria**, escrita do zero, localizada em `tools/mcp-bridge/`.
Ela **não** deriva do servidor Node.js proprietário/pago do repositório
`godot-mcp-pro` — apenas consome o mesmo protocolo WebSocket exposto por este
addon (`websocket_server.gd` / `command_router.gd`).

## Atualização

Para atualizar este vendor no futuro, repita o processo de download dos
arquivos em `addons/godot_mcp/` a partir do commit desejado da branch `master`
do repositório de origem, e atualize o SHA e a data acima.
