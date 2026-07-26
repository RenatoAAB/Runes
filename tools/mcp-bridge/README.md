# godot mcp bridge

Servidor MCP (stdio) que conecta o Claude ao editor Godot através do addon vendorizado em `addons/godot_mcp/` (MIT).

```
Claude  --stdio-->  tools/mcp-bridge  --WebSocket server 127.0.0.1:6505-->  editor Godot (addon)
```

Tudo local. O **addon é o cliente** WebSocket e varre as portas 6505–6514; o bridge é o **servidor** e pega a primeira porta livre nessa faixa (fixe com `GODOT_MCP_PORT`).

## Uso

Já registrado em `.mcp.json` como servidor `godot`. Basta abrir o projeto no editor Godot com o plugin **Godot MCP** habilitado (`Project → Project Settings → Plugins`).

Verifique com `godot_view {action:"status"}` — deve responder `editor_connected: true`.

## Ferramentas

9 ferramentas por domínio, cada uma com `action` + `params`. Use `action:"describe"` (opcionalmente com `params.action`) para o schema detalhado.

| Ferramenta | Ações | Domínio |
|---|---:|---|
| `godot_view` | 8 | status da conexão, screenshots, diff visual, câmera do editor |
| `godot_scene` | 11 | árvore/abrir/salvar/criar cenas, instanciar, play/stop |
| `godot_node` | 18 | nós, propriedades, sinais, grupos, seleção |
| `godot_script` | 13 | scripts GDScript, erros e log do editor |
| `godot_fx` | 11 | partículas e shaders |
| `godot_anim` | 14 | animações e AnimationTree |
| `godot_runtime` | 19 | jogo rodando: árvore viva, props, exec, captura, UI |
| `godot_project` | 27 | settings, filesystem, busca, `.tres`, batch, análises |
| `godot_raw` | — | `{method, params}` para qualquer um dos 174 comandos do addon |

120 métodos ficam na árvore; os outros 54 (android, navigation, 3D, tilemap, export, theme, audio, physics, profiling, testing, input) são acessíveis via `godot_raw`. `godot_raw {method:"list_methods"}` lista todos.

### Imagens

Nenhum base64 volta inline. Todo campo `*_base64` (e o array `frames` de `capture_frames`) é decodificado, validado como PNG e salvo em `%TEMP%/godot-mcp-shots/`. A resposta traz `<campo>_png_path` + metadados.

## Manutenção

```bash
npm install
npm run validate   # confere routing.js contra addons/godot_mcp/commands/*.gd
npm run selftest   # sobe um addon Godot falso + cliente MCP e valida ponta a ponta
```

Rode `npm run validate` sempre que o addon vendorizado for atualizado: ele falha se algum método ou nome de parâmetro do `routing.js` deixar de existir, ou se um comando novo do addon não estiver mapeado.

## Arquivos

- `index.js` — entrada MCP (stdio), registro das ferramentas
- `bridge.js` — servidor WebSocket, JSON-RPC, heartbeat, timeout de 60s
- `routing.js` — tabela estática `(tool, action) → {método, params, descrição}`
- `tools.js` — schemas MCP, validação, dispatch, base64 → PNG em disco
- `validate-routes.mjs` / `selftest.mjs` — verificação
