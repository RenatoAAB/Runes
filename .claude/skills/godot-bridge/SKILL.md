---
name: godot-bridge
description: Use ao iterar efeitos visuais, partículas, shaders, animações ou cenas do Godot com visão do jogo rodando; manual das ferramentas godot_* (bridge MCP) e da bancada de efeitos (effect_bench).
---

# godot-bridge — co-desenvolvimento visual no Godot

Manual para atuar como co-desenvolvedor visual: ver o jogo/editor rodando, editar cenas, nós,
scripts, partículas, shaders e animações através do bridge MCP (`tools/mcp-bridge/`), e iterar
efeitos isolados via bancada headless (`scripts/dev/effect_bench.gd`) quando não há editor aberto.

## 1. Pré-requisitos

- O bridge (`godot_*`) só funciona com o **editor Godot aberto** e o plugin **Godot MCP**
  habilitado (`Project → Project Settings → Plugins`).
- Antes de qualquer outra chamada, confira a conexão:
  ```
  godot_view {action: "status"}
  ```
  Resposta esperada: `editor_connected: true`. Esse action não exige conexão prévia — é o único
  que responde mesmo com o editor fechado (retornando `false`).
- Se `editor_connected` vier `false`, **peça ao usuário para abrir o editor Godot** neste projeto
  (`C:\Users\55119\Documents\runes`) com o plugin habilitado. Não há como o Claude abrir o editor
  sozinho.
- Se precisar de algo do **jogo rodando** (`godot_runtime`, `godot_view.game_shot`) e o jogo não
  estiver em play, use `godot_scene {action:"play"}` ou peça ao usuário para dar play.

## 2. Mapa das 9 ferramentas

Cada ferramenta tem `action` + `params`. Para o schema detalhado de qualquer ação, use
`action: "describe"` (opcionalmente com `params: {action: "<nome>"}` para uma ação específica).

### `godot_view` — visão do editor e do jogo
- `status` — estado da ponte (editor conectado? jogo rodando?)
- `editor_shot` — screenshot da janela do editor
- `game_shot` — screenshot do jogo em execução (exige play ativo)
- `diff` — diff visual entre duas imagens (% de pixels alterados + PNG do diff)
- `preview` — preview PNG de uma textura/imagem do projeto
- `camera_get` / `camera_set` — posição/rotação/FOV da câmera do viewport 3D do editor
- `auto_dismiss` — liga/desliga fechamento automático de diálogos modais

### `godot_scene` — cenas
- `tree` — árvore de nós da cena aberta
- `content` — conteúdo textual bruto de um `.tscn`
- `create` / `open` / `delete` / `save` — ciclo de vida do arquivo de cena
- `instance` — instancia uma cena como filha de outro nó
- `play` / `stop` — roda/para o jogo (`play` aceita `mode: "main"|"current"|res://...`)
- `exports` — lista `@export` dos scripts usados pela cena
- `deps` — dependências (cenas/scripts/recursos) de uma cena

### `godot_node` — nós da cena editada
- `add` / `delete` / `duplicate` / `move` / `rename` — ciclo de vida do nó
- `set_prop` / `get_props` — escreve/lê propriedades (com undo/redo do editor)
- `add_resource` — cria e atribui um Resource a uma propriedade (ex: shape, material)
- `anchor_preset` — aplica preset de âncora a um Control
- `connect` / `disconnect` — conecta/desconecta sinal entre dois nós
- `signals` — lista sinais e conexões de um nó
- `groups_get` / `groups_set` / `in_group` — grupos de nós
- `selection_get` / `select` / `selection_clear` — seleção do editor

### `godot_script` — scripts, erros e log
- `list` / `read` / `create` / `edit` / `attach` — ciclo de vida do script GDScript
- `open_list` — scripts abertos no editor de código
- `validate` — valida sintaxe sem executar
- `errors` — erros recentes do editor/debugger
- `log` / `clear_log` — painel de saída (print/push_error)
- `exec` — executa GDScript arbitrário dentro do editor (EditorScript)
- `refs` — onde um símbolo/arquivo é referenciado
- `circular` — detecta dependências circulares

### `godot_fx` — partículas e shaders
- `particles_create` — cria GPUParticles2D/3D
- `particles_material` — configura ParticleProcessMaterial (direção, velocidade, gravidade, forma...)
- `particles_gradient` — gradiente de cor ao longo da vida da partícula
- `particles_preset` — aplica preset pronto (ex: "fire", "smoke", "sparks")
- `particles_info` — configuração atual de um nó de partículas
- `shader_create` / `shader_read` / `shader_edit` — ciclo de vida do `.gdshader`
- `shader_assign` — cria ShaderMaterial com o shader e atribui ao nó
- `shader_set_param` / `shader_params` — escreve/lê uniforms do ShaderMaterial

### `godot_anim` — animações e AnimationTree
- `list` / `create` / `remove` / `info` — ciclo de vida de animações num AnimationPlayer
- `track_add` — adiciona track a uma animação
- `keyframe` — insere/atualiza keyframe numa track
- `tree_create` / `tree_info` — cria/inspeciona um AnimationTree
- `state_add` / `state_remove` — estados da state machine
- `transition_add` / `transition_remove` — transições entre estados
- `blend_node` — cria/configura nó dentro de um blend tree
- `tree_param` — define parâmetro do AnimationTree (ex: `parameters/blend_position`)

### `godot_runtime` — jogo em execução (exige play ativo)
- `tree` — árvore de nós do jogo rodando
- `get_props` / `set_prop` / `batch_props` — lê/escreve propriedades de nós vivos
- `capture` — captura N frames em PNG
- `monitor` — observa propriedades ao longo de vários frames
- `exec` — executa GDScript dentro do processo do jogo (acesso a autoloads, cena viva)
- `record_start` / `record_stop` / `replay` — grava e reproduz inputs do jogador
- `by_script` — encontra nós vivos por script anexado
- `autoload` — lê estado de um singleton (ex: "EventBus", "GameManager")
- `ui_find` / `click_text` — localiza/clica elementos de UI
- `wait_node` — espera um nó aparecer na árvore
- `nearby` — nós próximos de uma posição no mundo
- `navigate` / `move_to` — teleporta/move o player até um alvo
- `watch_signals` — escuta emissões de sinais por um período

### `godot_project` — projeto, arquivos e recursos
- `info` — nome, versão do Godot, cena principal, renderer, autoloads
- `fs` — árvore de arquivos do projeto
- `search_files` / `search_text` — busca por nome de arquivo / texto dentro dos arquivos
- `settings_get` / `settings_set` — lê/escreve project settings (nunca edite `project.godot` direto)
- `uid_to_path` / `path_to_uid` — conversão uid:// ↔ res://
- `autoload_add` / `autoload_remove` — registra/remove autoload
- `res_read` / `res_edit` / `res_create` — ciclo de vida de `.tres` (ex: uma RuneData)
- `batch_set` / `batch_add` / `batch_find_type` / `batch_find_signals` / `batch_find_refs` — operações em lote na cena aberta
- `batch_cross_scene` — define propriedade em nós de um tipo através de várias cenas (`dry_run` por padrão)
- `input_actions` / `input_action_set` — InputMap
- `unused` — recursos não referenciados
- `signal_flow` — mapa de emissões/conexões de sinais do projeto
- `complexity` — complexidade de uma cena
- `stats` — estatísticas gerais do projeto
- `reload_plugin` / `reload_project` — recarrega o plugin/projeto no editor

### `godot_raw` — métodos fora da árvore
`{method, params}` chama qualquer um dos 174 comandos do addon, incluindo os 54 que não têm
atalho nas 8 ferramentas acima: **android, navigation, 3D (mesh/lighting/materiais/câmera),
tilemap, export, theme (UI), audio (buses/efeitos), physics (colisão/layers), profiling, testing
(cenários automatizados) e input (simulação de teclado/mouse)**. Use
`godot_raw {method:"list_methods"}` para listar todos os métodos conhecidos pelo addon.

## 3. Regras de ouro

1. **Screenshots e imagens nunca voltam em base64 inline** — toda resposta com campo
   `*_base64`/`frames` já vem decodificada e salva como PNG em disco; a ferramenta devolve o
   **caminho** (`<campo>_png_path`). **Sempre abra esse PNG com `Read`** para efetivamente ver o
   resultado — não assuma o conteúdo pelo texto da resposta.
2. Depois de qualquer mudança visual (shader, partícula, animação, layout), **capture um novo
   screenshot** e compare com o anterior (visualmente, ou com `godot_view.diff` quando útil).
3. Mutações feitas por `godot_node`/`godot_script`/`godot_fx`/`godot_anim` passam pelo **UndoRedo**
   do editor — o usuário pode desfazer com Ctrl+Z a qualquer momento. Isso não vale para
   `godot_project.res_edit`/`res_create` em arquivos fechados, nem para o processo do jogo em
   runtime (`godot_runtime`).
4. Para diagnosticar erro de script ou comportamento estranho, **sempre** confira
   `godot_script {action:"errors"}` e `godot_script {action:"log"}` antes de concluir hipóteses.
5. Nunca envie imagem em base64 manualmente numa chamada — os parâmetros de imagem aceitam
   **caminho de arquivo** (ex: `godot_view.diff` com `image_a`/`image_b` apontando para PNGs já
   salvos).

## 4. Receitas

### Iterar shader ao vivo
1. Jogo já rodando (`godot_scene {action:"play"}` se necessário).
2. `godot_runtime {action:"tree"}` ou `by_script` para achar o nó com o ShaderMaterial.
3. `godot_fx {action:"shader_set_param", params:{node_path, param, value}}` para ajustar um uniform
   (o shader precisa já estar atribuído via `shader_assign`, feito em edição normal, não em runtime).
4. `godot_view {action:"game_shot"}` → `Read` no PNG retornado.
5. Repita 3-4 comparando com o frame anterior até o efeito bater com o esperado.

### Criar partículas
1. `godot_fx {action:"particles_create", params:{parent_path, name, ...}}`.
2. `godot_fx {action:"particles_preset", params:{node_path, preset:"fire"}}` para um ponto de
   partida, ou `particles_material`/`particles_gradient` para configurar do zero.
3. `godot_view {action:"editor_shot"}` (fora de jogo) ou `game_shot` (com play ativo) → `Read`.
4. Ajuste incremental de um parâmetro por vez (`particles_material`) e novo screenshot.

### Diagnosticar cena
1. `godot_scene {action:"tree"}` para ver a hierarquia.
2. `godot_node {action:"get_props", params:{node_path}}` no(s) nó(s) suspeito(s).
3. `godot_script {action:"errors"}` + `godot_script {action:"log"}` se houver comportamento errado.
4. `godot_view {action:"editor_shot"}` → `Read` para confirmar visualmente.

### Bancada de efeitos (iteração autônoma, sem editor)
Quando não há editor Godot disponível/aberto, use a bancada headless para iterar um efeito
isolado (`.tscn` de efeito, `.gdshader` ou `.tres` de `ParticleProcessMaterial`):

```powershell
& "C:\Users\55119\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" `
  --path "C:\Users\55119\Documents\runes" res://scenes/dev/effect_bench.tscn -- `
  --effect=res://caminho/do/efeito --frames=8 --interval=0.1 --bg=dark --out=<dir absoluto>
```

- `--effect` aceita `.tscn` (instanciado direto), `.gdshader` (aplicado num sprite de runa
  placeholder) ou `.tres` de `ParticleProcessMaterial` (envolvido num `GPUParticles2D`).
- Saída em `--out`: `frame_000.png`...`frame_NNN.png`, `contact_sheet.png` (grade 4 colunas) e
  `manifest.json`. **Leia o `contact_sheet.png` com `Read`** para ver a sequência inteira de uma vez.
- Sucesso imprime `EFFECT_BENCH_OUT=<dir>` (exit 0); erro imprime `EFFECT_BENCH_ERROR=<msg>`
  (exit 1) — confira o stdout do comando para saber qual dos dois aconteceu.
- Loop de iteração: editar o `.gdshader`/`.tres`/`.tscn` do efeito → rodar o comando → `Read` no
  contact sheet → ajustar → repetir. Cada rodada é um processo Godot novo e isolado, então não há
  estado residual entre execuções.
- Parâmetros opcionais: `--delay` (segundos antes de começar a capturar, default 0.2) e `--bg`
  (`dark`|`neutral`|`checker`, hoje `checker` cai para um cinza neutro).

### Bancada de leitura (juice de ativação + score, sem editor)
Para o juice que só existe com o jogo inteiro rodando — o flash/pulse do slot quando a runa ativa
e o punch/contagem do score — use `scenes/dev/juice_bench.tscn`. Ela boota `main.tscn` de verdade,
enche o grid de runas, dispara `start_battle()` e grava o viewport frame a frame:

```powershell
& "C:\Users\55119\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" `
  --path "C:\Users\55119\Documents\runes" res://scenes/dev/juice_bench.tscn -- `
  --frames=36 --interval=0 --runes=6 --crop=grid --out=<dir absoluto>
```

- `--interval=0` captura **todo frame renderizado** — obrigatório para ver o começo de um tween
  curto; qualquer `--interval` por timer perde os primeiros ~100 ms.
- `--crop` recorta pelo rect vivo do nó: `grid` (GridContainer), `score` (ScoreLabel) ou `none`.
- `--runes=N` preenche as N primeiras coordenadas com elementos alternados (o flash é tingido por
  elemento, então misturar torna a diferença visível).
- O `manifest.json` traz `events[]` (com `rune_activation_started`, `rune_destroyed`,
  `score_updated`, `step_started/completed`) e `frame_list[]`, ambos com timestamp em segundos
  desde `start_battle` — **é assim que se atribui um frame ao evento que o causou**. Leia com
  PowerShell (`ConvertFrom-Json`); não há Python nesta máquina.
- Sucesso imprime `JUICE_BENCH_OUT=<dir>` (exit 0); erro, `JUICE_BENCH_ERROR=<msg>` (exit 1).

## 5. Solução de problemas

- **`status` retorna `editor_connected: false`**: peça ao usuário para abrir o editor Godot neste
  projeto com o plugin **Godot MCP** habilitado em `Project → Project Settings → Plugins`.
- **Porta ocupada / bridge não conecta**: o bridge varre `6505`–`6514` procurando porta livre; se
  precisar fixar uma porta específica, use a variável de ambiente `GODOT_MCP_PORT`.
- **Timeout**: toda chamada ao addon tem limite de 60s; se estourar, a operação provavelmente
  travou o editor (ex: diálogo modal aberto) — tente `godot_view {action:"auto_dismiss"}` ou peça
  ao usuário para verificar a janela do Godot.
- **"No scene is currently playing" / erro equivalente em `godot_runtime`/`game_shot`**: o jogo não
  está em execução. Rode `godot_scene {action:"play"}` (ou peça ao usuário para dar play) antes de
  chamar qualquer ação de runtime.
- **Método não encontrado nas 9 ferramentas**: verifique se ele está nas categorias raw-only
  (android, navigation, 3D, tilemap, export, theme, audio, physics, profiling, testing, input) e
  chame via `godot_raw {method, params}`.
