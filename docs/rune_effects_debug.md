# Debugging e ajuste de efeitos de runas

## Arquivos-chave
- resources/effects/effect_score_20_if_last_fire.tres
  - Usa scripts/data/rune_effect.gd
  - Condition: resources/effects/conditions/condition_last_was_fire.tres
  - Target: resources/effects/targets/target_self.tres
  - Payload: resources/effects/payloads/payload_add_score_20.tres
- resources/effects/conditions/condition_last_was_fire.tres
  - Script: scripts/data/effects/conditions/condition_last_activated_element.gd
  - required_element = GameEnums.Element.FIRE (0 no enum)
- scripts/data/effects/conditions/condition_last_activated_element.gd
  - evaluate(): pega context.get_last_activated_elements() e checa required_element in last_elements
  - get_relevant_slots(): retorna o slot da última ativação via context.activation_history[-1]
  - get_description(): monta string com nome do elemento
- scripts/logic/battle_context.gd
  - activation_history: lista de dicts {elements, rune_id, slot_position, rune_instance}
  - record_activation(rune, slot): preenche entry com GameEnums.normalize_elements(rune.data.elements) e posição
  - get_last_activated_elements(): devolve último elements ou [] se vazio
  - get_last_activated_element(): helper que pega o primeiro elemento
- scripts/logic/reader.gd
  - Durante _activate_rune():
    - battle_context.set_current_context(slot, rune)
    - Executa efeitos (rune.on_activate) e efeitos do slot
    - _emit_slot_read_event(...)
    - battle_context.record_activation(rune, slot) **(necessário para condições baseadas na última runa)**

## Fluxo para condições de sequência ("última runa era ...")
1) Reader ativa a runa e chama rune.on_activate.
2) Depois de executar efeitos e eventos, reader.gd registra a ativação com battle_context.record_activation.
3) Condições como ConditionLastActivatedElement usam context.get_last_activated_elements() para checar o elemento anterior.

## Pontos de atenção ao criar/ajustar efeitos
- Sempre garantir que o Reader chame battle_context.record_activation após a ativação; sem isso, activation_history fica vazio e condições falham.
- required_element nas condições de elemento é um enum GameEnums.Element; validar valor na .tres.
- GameEnums.normalize_elements() permite múltiplos elementos por runa; condições checam inclusão (in), não igualdade exata.
- Se o efeito precisa olhar mais de uma ativação, usar battle_context.get_last_n_activations(n) ou last_n_same_element(n).
- Efeitos com multiplicadores ou pontuação devem considerar slot multipliers aplicados em BattleContext.add_score.

## Checklist rápido de debug
- O .tres do efeito aponta para a condição/payload corretas?
- O arquivo de condição (.tres) tem required_element (ou outros exports) configurado corretamente?
- activation_history está sendo populado? (ver se reader.gd chama record_activation)
- O grid/slot não está vazio ou disabled? (reader ignora void/empty slots)
- O payload executa e modifica score? Conferir BattleContext.add_score via eventos de score_updated.

## Onde editar
- Lógica de condição: scripts/data/effects/conditions/*.gd
- Recursos de condição/payload: resources/effects/conditions/*.tres e resources/effects/payloads/*.tres
- Encadeamento/ordem de execução: scripts/logic/reader.gd e scripts/logic/battle_context.gd
