# Debugging e ajuste de efeitos de runas

## Contexto atual
Este guia reflete o sistema atual baseado em GameEffect, com pipeline:
Trigger -> Condition -> Selector -> Action.

Os caminhos antigos em resources/effects/conditions, resources/effects/targets e resources/effects/payloads nao sao mais a referencia principal para novos ajustes.

## Arquivos-chave
- resources/effects/rune_effects/*.tres
  - Efeitos ativos por runa (exemplo: ge_s3_labareda_bonus_fire.tres).
  - Cada GameEffect referencia selector, condition e action.
- resources/effects/shared/conditions/*.tres
  - Condicoes compartilhadas (exemplo: condition_last_fire.tres).
- resources/effects/shared/selectors/*.tres
  - Seletores compartilhados (exemplo: selector_self.tres, selector_sequence_next.tres).
- scripts/effects/conditions/condition_last_activated_element_new.gd
  - evaluate(ctx): usa ctx.battle.get_last_activated_elements() para validar required_element.
  - get_highlight_slots(ctx): destaca o slot da ultima ativacao via activation_history.
- scripts/logic/battle_context.gd
  - activation_history: lista de dicts {elements, rune_id, slot_position, rune_instance, simultaneous_batch_id}.
  - record_activation(rune, slot): registra ativacao e atualiza tracking de rodada.
  - get_last_activated_elements(): base para condicoes de sequencia por elemento.
- scripts/logic/reader.gd
  - Em _activate_rune(), apos executar efeitos:
    - _emit_slot_read_event(...)
    - battle_context.record_activation(rune, slot)

## Fluxo para condicoes de sequencia ("ultima runa era ...")
1. Reader ativa a runa e executa os efeitos configurados.
2. Reader registra a ativacao em battle_context.record_activation.
3. ConditionLastActivatedElementNew consulta o ultimo registro de activation_history.
4. Se required_element estiver em last_elements, a condicao passa.

## Pontos de atencao ao criar ou ajustar efeitos
- Garanta que o efeito usa resources/effects/rune_effects/*.tres e nao caminhos legados.
- Em condicoes por elemento, valide required_element com GameEnums.Element correto.
- Se o efeito depende de historico, confirme que record_activation esta sendo chamado no fluxo.
- Para depuracao visual, confira get_highlight_slots nas conditions e get_preview nos selectors.
- Em score, considere multiplicadores de slot aplicados por BattleContext.add_score.

## Checklist rapido de debug
- O .tres em resources/effects/rune_effects aponta para condition/selector/action corretos?
- O condition .tres usa o script certo em scripts/effects/conditions?
- activation_history esta sendo populado durante a rodada?
- O slot lido nao esta vazio, void ou com runa desabilitada?
- O action realmente altera estado/score esperado no EffectContext?

## Onde editar
- Lógica de conditions: scripts/effects/conditions/*.gd
- Lógica de selectors: scripts/effects/selectors/*.gd
- Lógica de actions: scripts/effects/actions/*.gd
- Recursos de efeito ativos: resources/effects/rune_effects/*.tres
- Recursos compartilhados: resources/effects/shared/conditions/*.tres, resources/effects/shared/selectors/*.tres e resources/effects/shared/filters/*.tres
- Encadeamento de execucao: scripts/logic/reader.gd e scripts/logic/battle_context.gd
