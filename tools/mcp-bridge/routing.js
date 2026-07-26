/**
 * Static routing table: (tool, action) -> { method, params, desc }.
 *
 * Every `method` below is a REAL command exposed by `get_commands()` in
 * addons/godot_mcp/commands/*.gd, and every param name matches what the
 * handler actually reads (require_string / optional_* / params.get).
 *
 * Param spec: { type, required?, default?, desc }
 *   type is informational (`any` = the handler accepts several shapes).
 */

const S = (desc, extra = {}) => ({ type: 'string', desc, ...extra });
const REQ = (desc, extra = {}) => ({ type: 'string', required: true, desc, ...extra });
const N = (desc, extra = {}) => ({ type: 'number', desc, ...extra });
const B = (desc, extra = {}) => ({ type: 'boolean', desc, ...extra });
const A = (desc, extra = {}) => ({ type: 'array', desc, ...extra });
const O = (desc, extra = {}) => ({ type: 'object', desc, ...extra });
const ANY = (desc, extra = {}) => ({ type: 'any', desc, ...extra });

const NODE_PATH = REQ('Caminho do nó na cena editada (ex: "Player/Sprite2D" ou "." para a raiz)');

export const ROUTES = {
  // ─────────────────────────────────────────────────────────────────────────
  godot_view: {
    title: 'Visão do editor e do jogo',
    description: 'Estado da conexão, screenshots do editor/jogo, diff visual e câmera do editor. Imagens são salvas em disco e a resposta traz o CAMINHO do PNG.',
    actions: {
      status: {
        special: 'status',
        desc: 'Estado da ponte: editor conectado? jogo rodando? (não requer editor conectado)',
        params: {
          probe_game: B('Consulta o processo do jogo para saber se está rodando (default true)'),
        },
      },
      editor_shot: {
        method: 'get_editor_screenshot',
        desc: 'Screenshot da janela do editor Godot',
        params: { save_path: S('Opcional: salvar do lado do Godot (res:// ou user://) em vez de retornar a imagem') },
      },
      game_shot: {
        method: 'get_game_screenshot',
        desc: 'Screenshot do jogo em execução (exige play ativo)',
        params: { save_path: S('Opcional: salvar do lado do Godot (res:// ou user://) em vez de retornar a imagem') },
      },
      diff: {
        method: 'compare_screenshots',
        desc: 'Diff visual entre duas imagens (caminho de arquivo ou base64); retorna % de pixels alterados + PNG do diff',
        params: {
          image_a: REQ('Caminho da imagem A (ou base64)'),
          image_b: REQ('Caminho da imagem B (ou base64)'),
          threshold: N('Tolerância por canal 0-255 (default 10)'),
        },
      },
      preview: {
        method: 'get_resource_preview',
        desc: 'Preview PNG de uma textura/imagem do projeto',
        params: {
          path: REQ('Caminho res:// da imagem ou recurso Texture2D'),
          max_size: N('Lado máximo em pixels (default 256)'),
        },
      },
      camera_get: { method: 'get_editor_camera', desc: 'Posição/rotação/FOV da câmera do viewport 3D do editor', params: {} },
      camera_set: {
        method: 'set_editor_camera',
        desc: 'Move a câmera do viewport 3D do editor',
        params: {
          position: A('[x, y, z]'),
          rotation_degrees: A('[x, y, z]'),
          look_at: A('[x, y, z] — alvo para onde olhar'),
          fov: N('Campo de visão em graus'),
        },
      },
      auto_dismiss: {
        method: 'set_auto_dismiss',
        desc: 'Liga/desliga o fechamento automático de diálogos modais do editor',
        params: { enabled: B('Default true') },
      },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_scene: {
    title: 'Cenas',
    description: 'Árvore da cena aberta, criar/abrir/salvar/apagar cenas, instanciar cenas filhas e controlar play/stop do jogo.',
    actions: {
      tree: {
        method: 'get_scene_tree',
        desc: 'Árvore de nós da cena atualmente aberta no editor',
        params: { max_depth: N('Profundidade máxima (-1 = ilimitado)') },
      },
      content: {
        method: 'get_scene_file_content',
        desc: 'Conteúdo textual bruto de um arquivo .tscn',
        params: { path: REQ('Caminho res:// da cena') },
      },
      create: {
        method: 'create_scene',
        desc: 'Cria um novo arquivo de cena em disco',
        params: {
          path: REQ('Caminho res:// destino (.tscn)'),
          root_type: S('Classe do nó raiz (default "Node2D")'),
          root_name: S('Nome do nó raiz (default = nome do arquivo)'),
        },
      },
      open: { method: 'open_scene', desc: 'Abre uma cena no editor', params: { path: REQ('Caminho res:// da cena') } },
      delete: { method: 'delete_scene', desc: 'Apaga um arquivo de cena do disco', params: { path: REQ('Caminho res:// da cena') } },
      save: { method: 'save_scene', desc: 'Salva a cena aberta (opcionalmente em outro caminho)', params: { path: S('Salvar-como; vazio = salvar no lugar') } },
      instance: {
        method: 'add_scene_instance',
        desc: 'Instancia uma cena como filha de um nó da cena aberta',
        params: {
          scene_path: REQ('Caminho res:// da cena a instanciar'),
          parent_path: S('Nó pai (default ".")'),
          name: S('Nome da instância'),
        },
      },
      play: {
        method: 'play_scene',
        desc: 'Roda o jogo: "main" (cena principal), "current" (cena aberta) ou um caminho res://',
        params: { mode: S('"main" | "current" | res://caminho.tscn (default "main")') },
      },
      stop: { method: 'stop_scene', desc: 'Para o jogo em execução', params: {} },
      exports: {
        method: 'get_scene_exports',
        desc: 'Lista as variáveis @export dos scripts usados por uma cena',
        params: { path: REQ('Caminho res:// da cena') },
      },
      deps: {
        method: 'get_scene_dependencies',
        desc: 'Dependências (cenas/scripts/recursos) de uma cena',
        params: { path: REQ('Caminho res:// da cena') },
      },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_node: {
    title: 'Nós da cena editada',
    description: 'Adicionar/remover/renomear/mover/duplicar nós, ler e escrever propriedades, sinais, grupos, seleção do editor e recursos anexados a propriedades.',
    actions: {
      add: {
        method: 'add_node',
        desc: 'Adiciona um nó novo à cena aberta',
        params: {
          type: REQ('Classe do nó (ex: "Sprite2D", "Control")'),
          parent_path: S('Nó pai (default ".")'),
          name: S('Nome do nó'),
          properties: O('Propriedades iniciais { nome: valor }'),
        },
      },
      delete: { method: 'delete_node', desc: 'Remove um nó da cena aberta', params: { node_path: NODE_PATH } },
      duplicate: {
        method: 'duplicate_node',
        desc: 'Duplica um nó (mesmo pai)',
        params: { node_path: NODE_PATH, name: S('Nome da cópia') },
      },
      move: {
        method: 'move_node',
        desc: 'Reparenta um nó',
        params: { node_path: NODE_PATH, new_parent_path: REQ('Novo nó pai') },
      },
      rename: {
        method: 'rename_node',
        desc: 'Renomeia um nó',
        params: { node_path: NODE_PATH, new_name: REQ('Novo nome') },
      },
      set_prop: {
        method: 'update_property',
        desc: 'Escreve uma propriedade de um nó (com undo/redo do editor)',
        params: { node_path: NODE_PATH, property: REQ('Nome da propriedade'), value: ANY('Novo valor (aceita arrays para Vector2/3, Color etc.)') },
      },
      get_props: {
        method: 'get_node_properties',
        desc: 'Lê as propriedades de um nó',
        params: { node_path: NODE_PATH, category: S('Filtra por categoria/prefixo') },
      },
      add_resource: {
        method: 'add_resource',
        desc: 'Cria e atribui um Resource a uma propriedade do nó (ex: material, shape)',
        params: {
          node_path: NODE_PATH,
          property: REQ('Propriedade que receberá o recurso'),
          resource_type: REQ('Classe do recurso (ex: "CircleShape2D")'),
          resource_properties: O('Propriedades iniciais do recurso'),
        },
      },
      anchor_preset: {
        method: 'set_anchor_preset',
        desc: 'Aplica um preset de âncora a um Control',
        params: { node_path: NODE_PATH, preset: REQ('Ex: "full_rect", "center", "top_left"'), keep_offsets: B('Preserva offsets (default false)') },
      },
      connect: {
        method: 'connect_signal',
        desc: 'Conecta um sinal entre dois nós da cena aberta',
        params: {
          source_path: REQ('Nó emissor'),
          signal_name: REQ('Nome do sinal'),
          target_path: REQ('Nó receptor'),
          method_name: REQ('Método a chamar no receptor'),
          deferred: B('Conexão deferred'),
          one_shot: B('Conexão one-shot'),
        },
      },
      disconnect: {
        method: 'disconnect_signal',
        desc: 'Desconecta um sinal',
        params: {
          source_path: REQ('Nó emissor'),
          signal_name: REQ('Nome do sinal'),
          target_path: REQ('Nó receptor'),
          method_name: REQ('Método conectado'),
        },
      },
      signals: { method: 'get_signals', desc: 'Lista sinais (e conexões) de um nó', params: { node_path: NODE_PATH } },
      groups_get: { method: 'get_node_groups', desc: 'Grupos de um nó', params: { node_path: NODE_PATH } },
      groups_set: {
        method: 'set_node_groups',
        desc: 'Define os grupos de um nó',
        params: { node_path: NODE_PATH, groups: A('Lista de nomes de grupo') },
      },
      in_group: { method: 'find_nodes_in_group', desc: 'Lista os nós da cena aberta em um grupo', params: { group: REQ('Nome do grupo') } },
      selection_get: { method: 'get_editor_selection', desc: 'Nós atualmente selecionados no editor', params: { top_only: B('Apenas nós de topo da seleção') } },
      select: {
        method: 'select_nodes',
        desc: 'Seleciona nós no editor (e opcionalmente abre no inspetor)',
        params: {
          node_paths: A('Caminhos dos nós a selecionar (alternativa: node_path para um único nó)'),
          node_path: S('Caminho de um único nó (usado quando node_paths não é informado)'),
          mode: S('"replace" | "add" | "remove" (default "replace")'),
          inspect: B('Abrir no inspetor (default true)'),
          focus: B('Focar no viewport (default = inspect)'),
          inspector_only: B('Só inspecionar, sem alterar seleção da árvore'),
          for_property: S('Destacar uma propriedade específica no inspetor'),
        },
      },
      selection_clear: { method: 'clear_editor_selection', desc: 'Limpa a seleção do editor', params: {} },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_script: {
    title: 'Scripts, erros e log',
    description: 'Listar/ler/criar/editar scripts GDScript, anexar a nós, validar sintaxe, e ler erros/log do editor.',
    actions: {
      list: {
        method: 'list_scripts',
        desc: 'Lista scripts do projeto',
        params: { path: S('Pasta raiz da busca (default "res://")'), recursive: B('Default true') },
      },
      read: { method: 'read_script', desc: 'Lê o conteúdo de um script', params: { path: REQ('Caminho res:// do .gd') } },
      create: {
        method: 'create_script',
        desc: 'Cria um novo script',
        params: {
          path: REQ('Caminho res:// do .gd'),
          content: S('Conteúdo completo; vazio = esqueleto gerado'),
          extends: S('Classe base (default "Node")'),
          class_name: S('class_name opcional'),
          force: B('Sobrescreve mesmo se aberto no editor'),
        },
      },
      edit: {
        method: 'edit_script',
        desc: 'Edita um script: substituições (replacements), reescrita total (content), faixa de linhas (start_line/end_line + text) ou inserção (insert_at_line + text)',
        params: {
          path: REQ('Caminho res:// do .gd'),
          replacements: A('Lista de { old, new } (ou { from, to }) para substituição textual'),
          content: S('Reescreve o arquivo inteiro'),
          start_line: N('Início da faixa a substituir (1-based)'),
          end_line: N('Fim da faixa (default = start_line)'),
          insert_at_line: N('Insere text antes desta linha'),
          text: S('Texto usado por start_line/end_line ou insert_at_line'),
          force: B('Edita mesmo com o arquivo aberto no editor'),
        },
      },
      attach: {
        method: 'attach_script',
        desc: 'Anexa um script existente a um nó da cena aberta',
        params: { node_path: NODE_PATH, script_path: REQ('Caminho res:// do .gd') },
      },
      open_list: { method: 'get_open_scripts', desc: 'Scripts abertos no editor de código', params: {} },
      validate: { method: 'validate_script', desc: 'Valida a sintaxe de um script', params: { path: REQ('Caminho res:// do .gd') } },
      errors: { method: 'get_editor_errors', desc: 'Erros recentes do editor/debugger', params: { max_lines: N('Default 50') } },
      log: {
        method: 'get_output_log',
        desc: 'Painel de saída (print/push_error) do editor e do jogo',
        params: { max_lines: N('Default 100'), filter: S('Substring para filtrar as linhas') },
      },
      clear_log: { method: 'clear_output', desc: 'Limpa o painel de saída do editor', params: {} },
      exec: {
        method: 'execute_editor_script',
        desc: 'Executa GDScript arbitrário DENTRO do editor (EditorScript). Use com cuidado.',
        params: {
          code: REQ('Código GDScript; o corpo roda em _run()'),
          allow_unsafe_editor_io: B('Permite I/O de arquivos no editor (default false)'),
        },
      },
      refs: {
        method: 'find_script_references',
        desc: 'Onde um símbolo/arquivo é referenciado no projeto',
        params: { query: REQ('Símbolo, nome de classe ou caminho'), path: S('Raiz da busca (default "res://")'), include_addons: B('Default false') },
      },
      circular: {
        method: 'detect_circular_dependencies',
        desc: 'Detecta dependências circulares entre scripts/cenas',
        params: { path: S('Raiz da busca (default "res://")'), include_addons: B('Default false') },
      },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_fx: {
    title: 'Partículas e shaders',
    description: 'GPUParticles2D/3D (criação, material de processo, gradientes de cor, presets) e shaders (criar/ler/editar, ShaderMaterial, uniforms).',
    actions: {
      particles_create: {
        method: 'create_particles',
        desc: 'Cria um nó GPUParticles2D/3D',
        params: {
          parent_path: REQ('Nó pai'),
          name: S('Nome (default "Particles")'),
          is_3d: B('GPUParticles3D em vez de 2D (default false)'),
          amount: N('Quantidade de partículas (default 16)'),
          one_shot: B('Default false'),
          emitting: B('Default true'),
          lifetime: N('Segundos (default 1.0)'),
          explosiveness: N('0..1'),
          randomness: N('0..1'),
        },
      },
      particles_material: {
        method: 'set_particle_material',
        desc: 'Configura o ParticleProcessMaterial (direção, velocidade, gravidade, escala, cor, forma de emissão, órbita, damping...)',
        params: {
          node_path: NODE_PATH,
          direction: A('[x, y, z]'),
          spread: N('Graus'),
          initial_velocity_min: N(''),
          initial_velocity_max: N(''),
          gravity: A('[x, y, z]'),
          scale_min: N(''),
          scale_max: N(''),
          color: S('Cor hex "#rrggbbaa" ou [r,g,b,a]'),
          emission_shape: S('"point" | "sphere" | "box" | "ring"'),
          emission_sphere_radius: N(''),
          emission_box_extents: A('[x, y, z]'),
          emission_ring_radius: N(''),
          emission_ring_inner_radius: N(''),
          emission_ring_height: N(''),
          angular_velocity_min: N(''),
          angular_velocity_max: N(''),
          orbit_velocity_min: N(''),
          orbit_velocity_max: N(''),
          damping_min: N(''),
          damping_max: N(''),
          attractor_interaction_enabled: B(''),
        },
      },
      particles_gradient: {
        method: 'set_particle_color_gradient',
        desc: 'Define o gradiente de cor ao longo da vida da partícula',
        params: { node_path: NODE_PATH, stops: A('Lista de { offset, color } (color hex ou [r,g,b,a])') },
      },
      particles_preset: {
        method: 'apply_particle_preset',
        desc: 'Aplica um preset pronto de partículas',
        params: { node_path: NODE_PATH, preset: REQ('Nome do preset (ex: "fire", "smoke", "sparks")') },
      },
      particles_info: { method: 'get_particle_info', desc: 'Configuração atual de um nó de partículas', params: { node_path: NODE_PATH } },
      shader_create: {
        method: 'create_shader',
        desc: 'Cria um arquivo .gdshader',
        params: {
          path: REQ('Caminho res:// do .gdshader'),
          content: S('Código do shader; vazio = template'),
          shader_type: S('"spatial" | "canvas_item" | "particles" (default "spatial")'),
          force: B('Sobrescreve se já aberto/existente'),
        },
      },
      shader_read: { method: 'read_shader', desc: 'Lê um arquivo de shader', params: { path: REQ('Caminho res:// do .gdshader') } },
      shader_edit: {
        method: 'edit_shader',
        desc: 'Edita um shader por conteúdo completo ou por substituições',
        params: {
          path: REQ('Caminho res:// do .gdshader'),
          content: S('Reescreve o arquivo inteiro'),
          replacements: A('Lista de { old, new }'),
          force: B('Edita mesmo com o arquivo aberto no editor'),
        },
      },
      shader_assign: {
        method: 'assign_shader_material',
        desc: 'Cria um ShaderMaterial com o shader dado e atribui ao nó',
        params: { node_path: NODE_PATH, shader_path: REQ('Caminho res:// do .gdshader') },
      },
      shader_set_param: {
        method: 'set_shader_param',
        desc: 'Define um uniform do ShaderMaterial do nó',
        params: { node_path: NODE_PATH, param: REQ('Nome do uniform'), value: ANY('Valor (número, array, cor hex...)') },
      },
      shader_params: { method: 'get_shader_params', desc: 'Lista os uniforms e valores atuais do shader do nó', params: { node_path: NODE_PATH } },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_anim: {
    title: 'Animações e AnimationTree',
    description: 'AnimationPlayer (criar animações, tracks, keyframes) e AnimationTree (state machines, transições, blend trees, parâmetros).',
    actions: {
      list: { method: 'list_animations', desc: 'Lista as animações de um AnimationPlayer', params: { node_path: NODE_PATH } },
      create: {
        method: 'create_animation',
        desc: 'Cria uma animação nova em um AnimationPlayer',
        params: { node_path: NODE_PATH, name: REQ('Nome da animação'), length: N('Duração em segundos (default 1.0)'), loop_mode: N('0=none, 1=linear, 2=pingpong') },
      },
      remove: { method: 'remove_animation', desc: 'Remove uma animação', params: { node_path: NODE_PATH, name: REQ('Nome da animação') } },
      info: {
        method: 'get_animation_info',
        desc: 'Detalhes de uma animação (tracks, keyframes, duração)',
        params: { node_path: NODE_PATH, animation: REQ('Nome da animação') },
      },
      track_add: {
        method: 'add_animation_track',
        desc: 'Adiciona uma track a uma animação',
        params: {
          node_path: NODE_PATH,
          animation: REQ('Nome da animação'),
          track_path: REQ('Alvo da track (ex: "Sprite2D:modulate")'),
          track_type: S('"value" | "method" | "bezier" | "audio" | "animation" (default "value")'),
          update_mode: S('"continuous" | "discrete" | "capture"'),
        },
      },
      keyframe: {
        method: 'set_animation_keyframe',
        desc: 'Insere/atualiza um keyframe em uma track',
        params: {
          node_path: NODE_PATH,
          animation: REQ('Nome da animação'),
          track_index: N('Índice da track (default 0)'),
          time: N('Tempo em segundos'),
          value: ANY('Valor do keyframe'),
          easing: N('Easing (default 1.0)'),
        },
      },
      tree_create: {
        method: 'create_animation_tree',
        desc: 'Cria um AnimationTree ligado a um AnimationPlayer',
        params: { node_path: NODE_PATH, anim_player: S('Caminho do AnimationPlayer'), name: S('Nome do nó (default "AnimationTree")') },
      },
      tree_info: { method: 'get_animation_tree_structure', desc: 'Estrutura do AnimationTree (estados, transições, parâmetros)', params: { node_path: NODE_PATH } },
      state_add: {
        method: 'add_state_machine_state',
        desc: 'Adiciona um estado à state machine',
        params: {
          node_path: NODE_PATH,
          state_name: REQ('Nome do estado'),
          state_machine_path: S('Caminho da sub-state-machine (vazio = raiz)'),
          state_type: S('"animation" | "state_machine" | "blend_tree" (default "animation")'),
          animation: S('Animação associada quando state_type="animation"'),
          position_x: N('Posição no grafo'),
          position_y: N('Posição no grafo'),
        },
      },
      state_remove: {
        method: 'remove_state_machine_state',
        desc: 'Remove um estado da state machine',
        params: { node_path: NODE_PATH, state_name: REQ('Nome do estado'), state_machine_path: S('Sub-state-machine') },
      },
      transition_add: {
        method: 'add_state_machine_transition',
        desc: 'Cria uma transição entre estados',
        params: {
          node_path: NODE_PATH,
          from_state: REQ('Estado de origem'),
          to_state: REQ('Estado de destino'),
          state_machine_path: S('Sub-state-machine'),
          switch_mode: S('"immediate" | "sync" | "at_end" (default "immediate")'),
          advance_mode: S('"disabled" | "enabled" | "auto" (default "enabled")'),
          advance_expression: S('Expressão de avanço'),
          xfade_time: N('Tempo de crossfade em segundos'),
        },
      },
      transition_remove: {
        method: 'remove_state_machine_transition',
        desc: 'Remove uma transição',
        params: { node_path: NODE_PATH, from_state: REQ('Origem'), to_state: REQ('Destino'), state_machine_path: S('Sub-state-machine') },
      },
      blend_node: {
        method: 'set_blend_tree_node',
        desc: 'Cria/configura um nó dentro de um blend tree',
        params: {
          node_path: NODE_PATH,
          blend_tree_state: REQ('Estado blend_tree alvo'),
          bt_node_name: REQ('Nome do nó no blend tree'),
          bt_node_type: REQ('Tipo (ex: "Animation", "Blend2", "OneShot")'),
          state_machine_path: S('Sub-state-machine'),
          animation: S('Animação quando o tipo é Animation'),
          connect_to: S('Nome do nó de destino da conexão'),
          connect_port: N('Porta de entrada do destino (default 0)'),
          position_x: N('Posição no grafo'),
          position_y: N('Posição no grafo'),
        },
      },
      tree_param: {
        method: 'set_tree_parameter',
        desc: 'Define um parâmetro do AnimationTree (ex: "parameters/blend_position")',
        params: { node_path: NODE_PATH, parameter: REQ('Caminho do parâmetro'), value: ANY('Valor') },
      },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_runtime: {
    title: 'Jogo em execução',
    description: 'Inspeção e controle do jogo rodando: árvore viva, propriedades ao vivo, execução de GDScript, captura multi-frame, busca de UI e automação. Exige play ativo.',
    actions: {
      tree: {
        method: 'get_game_scene_tree',
        desc: 'Árvore de nós do jogo em execução',
        params: {
          max_depth: N('Profundidade máxima (-1 = ilimitado)'),
          script_filter: S('Só nós cujo script casa com este filtro'),
          type_filter: S('Só nós desta classe'),
          named_only: B('Ignora nós com nome autogerado'),
        },
      },
      get_props: {
        method: 'get_game_node_properties',
        desc: 'Lê propriedades de um nó vivo',
        params: { node_path: REQ('Caminho absoluto no jogo (ex: "/root/Main/Player")'), properties: A('Lista de propriedades; vazio = todas') },
      },
      set_prop: {
        method: 'set_game_node_property',
        desc: 'Escreve uma propriedade em um nó vivo',
        params: { node_path: REQ('Caminho absoluto no jogo'), property: REQ('Nome da propriedade'), value: ANY('Novo valor') },
      },
      batch_props: {
        method: 'batch_get_properties',
        desc: 'Lê propriedades de vários nós de uma vez',
        params: { nodes: A('Lista de { node_path, properties }') },
      },
      capture: {
        method: 'capture_frames',
        desc: 'Captura N frames do jogo; cada frame vira um PNG salvo em disco (retorna caminhos)',
        params: {
          count: N('Número de frames (1..30, default 5)'),
          frame_interval: N('Frames de espera entre capturas (default 10)'),
          half_resolution: B('Captura em meia resolução (default true)'),
        },
      },
      monitor: {
        method: 'monitor_properties',
        desc: 'Observa propriedades de um nó ao longo de vários frames',
        params: {
          node_path: REQ('Caminho absoluto no jogo'),
          properties: A('Propriedades a observar'),
          frame_count: N('Quantos frames (default 60)'),
          frame_interval: N('Intervalo em frames (default 1)'),
        },
      },
      exec: {
        method: 'execute_game_script',
        desc: 'Executa GDScript dentro do processo do jogo (acesso a autoloads, cena viva...)',
        params: { code: REQ('Código GDScript; use return para devolver um valor') },
      },
      record_start: { method: 'start_recording', desc: 'Começa a gravar os inputs do jogador', params: {} },
      record_stop: { method: 'stop_recording', desc: 'Para a gravação e devolve os eventos', params: {} },
      replay: {
        method: 'replay_recording',
        desc: 'Reproduz uma sequência de inputs gravada',
        params: { events: A('Eventos gravados'), speed: N('Multiplicador de velocidade (default 1.0)') },
      },
      by_script: {
        method: 'find_nodes_by_script',
        desc: 'Encontra nós vivos por script anexado',
        params: { script: REQ('Caminho res:// do script'), properties: A('Propriedades a incluir no resultado') },
      },
      autoload: {
        method: 'get_autoload',
        desc: 'Lê o estado de um singleton/autoload do jogo (ex: "EventBus", "GameManager")',
        params: { name: REQ('Nome do autoload'), properties: A('Propriedades a ler; vazio = todas') },
      },
      ui_find: {
        method: 'find_ui_elements',
        desc: 'Localiza elementos de UI visíveis no jogo (botões, labels...)',
        params: { type_filter: S('Classe de Control a filtrar (ex: "Button")') },
      },
      click_text: {
        method: 'click_button_by_text',
        desc: 'Clica em um botão do jogo pelo texto',
        params: { text: REQ('Texto do botão'), partial: B('Casamento parcial (default true)') },
      },
      wait_node: {
        method: 'wait_for_node',
        desc: 'Espera um nó aparecer na árvore do jogo',
        params: { node_path: REQ('Caminho absoluto no jogo'), poll_frames: N('Frames entre checagens (default 5)'), timeout: N('Segundos (default 5.0)') },
      },
      nearby: {
        method: 'find_nearby_nodes',
        desc: 'Nós próximos de uma posição no mundo',
        params: {
          position: A('[x, y] ou [x, y, z]'),
          radius: N('Raio de busca'),
          type_filter: S('Classe a filtrar'),
          group_filter: S('Grupo a filtrar'),
          max_results: N('Limite de resultados'),
        },
      },
      navigate: {
        method: 'navigate_to',
        desc: 'Teleporta/aponta o player para um alvo',
        params: { target: A('[x, y] ou [x, y, z]'), player_path: S('Caminho do player'), camera_path: S('Caminho da câmera'), move_speed: N('Velocidade') },
      },
      move_to: {
        method: 'move_to',
        desc: 'Move o player até um alvo simulando input, aguardando a chegada',
        params: {
          target: A('[x, y] ou [x, y, z]'),
          player_path: S('Caminho do player'),
          camera_path: S('Caminho da câmera'),
          arrival_radius: N('Distância considerada como chegada'),
          run: B('Correr em vez de andar'),
          look_at_target: B('Olhar para o alvo ao chegar'),
          timeout: N('Segundos (default 15.0)'),
        },
      },
      watch_signals: {
        method: 'watch_signals',
        desc: 'Escuta emissões de sinais no jogo por um período',
        params: { node_paths: A('Nós a observar'), signal_filter: A('Nomes de sinais a filtrar'), duration_ms: N('Duração em ms (default 5000)') },
      },
    },
  },

  // ─────────────────────────────────────────────────────────────────────────
  godot_project: {
    title: 'Projeto, arquivos e recursos',
    description: 'Project settings, autoloads, árvore de arquivos, busca em arquivos, leitura/edição/criação de .tres, operações em lote e análises do projeto.',
    actions: {
      info: { method: 'get_project_info', desc: 'Nome, versão do Godot, cena principal, viewport, renderer e autoloads', params: {} },
      fs: {
        method: 'get_filesystem_tree',
        desc: 'Árvore de arquivos do projeto',
        params: { path: S('Raiz (default "res://")'), filter: S('Filtro de extensão/nome'), max_depth: N('Default 10') },
      },
      search_files: {
        method: 'search_files',
        desc: 'Busca arquivos por nome',
        params: { query: REQ('Trecho do nome'), path: S('Raiz (default "res://")'), file_type: S('Extensão (ex: "tres")'), max_results: N('Default 50') },
      },
      search_text: {
        method: 'search_in_files',
        desc: 'Busca texto dentro dos arquivos do projeto',
        params: {
          query: REQ('Texto ou regex'),
          path: S('Raiz (default "res://")'),
          regex: B('Interpreta query como regex (default false)'),
          file_type: S('Extensão a filtrar'),
          max_results: N('Default 50'),
        },
      },
      settings_get: {
        method: 'get_project_settings',
        desc: 'Lê project settings',
        params: { section: S('Seção (ex: "display")'), key: S('Chave específica') },
      },
      settings_set: { method: 'set_project_setting', desc: 'Escreve um project setting', params: { key: REQ('Chave completa'), value: ANY('Valor') } },
      uid_to_path: { method: 'uid_to_project_path', desc: 'Converte uid:// em caminho res://', params: { uid: REQ('uid://...') } },
      path_to_uid: { method: 'project_path_to_uid', desc: 'Converte caminho res:// em uid://', params: { path: REQ('res://...') } },
      autoload_add: { method: 'add_autoload', desc: 'Registra um autoload', params: { name: REQ('Nome do singleton'), path: REQ('Caminho res:// do script/cena') } },
      autoload_remove: { method: 'remove_autoload', desc: 'Remove um autoload', params: { name: REQ('Nome do singleton') } },
      res_read: { method: 'read_resource', desc: 'Lê um Resource .tres/.res com suas propriedades', params: { path: REQ('Caminho res:// do recurso') } },
      res_edit: {
        method: 'edit_resource',
        desc: 'Edita propriedades de um .tres existente (ex: uma RuneData)',
        params: { path: REQ('Caminho res:// do recurso'), properties: O('{ propriedade: valor }') },
      },
      res_create: {
        method: 'create_resource',
        desc: 'Cria um novo .tres a partir de uma classe de Resource',
        params: {
          path: REQ('Caminho res:// destino (.tres)'),
          type: REQ('Classe do Resource (ex: "RuneData")'),
          properties: O('Propriedades iniciais'),
          overwrite: B('Sobrescreve se já existir (default false)'),
        },
      },
      batch_set: {
        method: 'batch_set_property',
        desc: 'Define uma propriedade em todos os nós de um tipo na cena aberta',
        params: { type: REQ('Classe do nó'), property: REQ('Propriedade'), value: ANY('Valor') },
      },
      batch_add: { method: 'batch_add_nodes', desc: 'Adiciona vários nós de uma vez', params: { nodes: A('Lista de { type, parent_path, name, properties }') } },
      batch_find_type: {
        method: 'find_nodes_by_type',
        desc: 'Encontra nós por classe na cena aberta',
        params: { type: REQ('Classe do nó'), recursive: B('Default true') },
      },
      batch_find_signals: {
        method: 'find_signal_connections',
        desc: 'Encontra conexões de sinal na cena aberta',
        params: { signal_name: S('Nome do sinal'), node_path: S('Restringe a uma subárvore') },
      },
      batch_find_refs: { method: 'find_node_references', desc: 'Busca referências a nós por padrão de nome/caminho', params: { pattern: REQ('Padrão') } },
      batch_cross_scene: {
        method: 'cross_scene_set_property',
        desc: 'Define uma propriedade em nós de um tipo através de VÁRIAS cenas do projeto',
        params: {
          type: REQ('Classe do nó'),
          property: REQ('Propriedade'),
          value: ANY('Valor'),
          path_filter: S('Raiz das cenas (default "res://")'),
          exclude_addons: B('Default true'),
          dry_run: B('Simula sem salvar (default: true a menos que force=true)'),
          force: B('Aplica de verdade'),
        },
      },
      input_actions: { method: 'get_input_actions', desc: 'Lista as ações do InputMap', params: { filter: S('Filtro de nome'), include_builtin: B('Inclui ações internas (default false)') } },
      input_action_set: {
        method: 'set_input_action',
        desc: 'Cria/atualiza uma ação do InputMap',
        params: { action: REQ('Nome da ação'), events: A('Lista de eventos de input'), deadzone: N('Default 0.5') },
      },
      unused: {
        method: 'find_unused_resources',
        desc: 'Recursos não referenciados por nenhuma cena/script',
        params: { path: S('Raiz (default "res://")'), include_addons: B('Default false') },
      },
      signal_flow: { method: 'analyze_signal_flow', desc: 'Mapa de emissões/conexões de sinais do projeto', params: {} },
      complexity: { method: 'analyze_scene_complexity', desc: 'Complexidade de uma cena (nº de nós, profundidade, scripts)', params: { path: S('Cena a analisar; vazio = aberta') } },
      stats: {
        method: 'get_project_statistics',
        desc: 'Estatísticas gerais do projeto (arquivos, linhas, tipos)',
        params: { path: S('Raiz (default "res://")'), include_addons: B('Default false') },
      },
      reload_plugin: { method: 'reload_plugin', desc: 'Recarrega o plugin godot_mcp no editor', params: {} },
      reload_project: { method: 'reload_project', desc: 'Recarrega o projeto inteiro no editor', params: {} },
    },
  },
};

/**
 * Categories intentionally NOT exposed in the 9-tool tree — reachable via godot_raw.
 * (Kept in sync manually with addons/godot_mcp/commands/*.gd.)
 */
export const RAW_ONLY_CATEGORIES = {
  android: ['list_android_devices', 'get_android_preset_info', 'deploy_to_android'],
  navigation: ['setup_navigation_region', 'bake_navigation_mesh', 'setup_navigation_agent', 'set_navigation_layers', 'get_navigation_info'],
  '3d': ['add_mesh_instance', 'setup_lighting', 'set_material_3d', 'setup_environment', 'setup_camera_3d', 'add_gridmap'],
  tilemap: ['tilemap_set_cell', 'tilemap_fill_rect', 'tilemap_get_cell', 'tilemap_clear', 'tilemap_get_info', 'tilemap_get_used_cells'],
  export: ['list_export_presets', 'export_project', 'get_export_info'],
  theme: ['create_theme', 'set_theme_color', 'set_theme_constant', 'set_theme_font_size', 'set_theme_stylebox', 'setup_control', 'get_theme_info'],
  audio: ['get_audio_bus_layout', 'add_audio_bus', 'set_audio_bus', 'add_audio_bus_effect', 'add_audio_player', 'get_audio_info'],
  physics: ['setup_collision', 'set_physics_layers', 'get_physics_layers', 'add_raycast', 'setup_physics_body', 'get_collision_info'],
  profiling: ['get_performance_monitors', 'get_editor_performance'],
  testing: ['run_test_scenario', 'assert_node_state', 'assert_screen_text', 'run_stress_test', 'get_test_report'],
  input: ['simulate_key', 'simulate_mouse_click', 'simulate_mouse_move', 'simulate_action', 'simulate_sequence'],
};

/** All methods reachable through the 9-tool tree. */
export function routedMethods() {
  const out = new Set();
  for (const tool of Object.values(ROUTES)) {
    for (const a of Object.values(tool.actions)) if (a.method) out.add(a.method);
  }
  return out;
}

/** All methods known to the bridge (tree + raw-only). */
export function knownMethods() {
  const out = routedMethods();
  for (const list of Object.values(RAW_ONLY_CATEGORIES)) for (const m of list) out.add(m);
  return out;
}

export const TOOL_NAMES = [...Object.keys(ROUTES), 'godot_raw'];
