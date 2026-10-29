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

## Condições de jogo e O Alquimista (2026-10-21)

Uma condição é um requisito explícito de uma regra de jogo: um predicado sobre
o estado da fonte, do alvo ou do painel que autoriza um efeito ou uma alternativa
da ação. Deve ser um `NewEffectCondition`, inclusive quando avaliada por alvo.
Um `if` de validação técnica, um gatilho, um filtro de alvos e uma fórmula
"por cada" não se tornam condições automaticamente.

- `evaluate(ctx)` consulta o requisito sem alterar a contagem (tooltip, hover e previews).
- `evaluate_for_execution(ctx)` avalia e registra uma satisfação natural durante a execução.
- Cada execução de GameEffect contribui no máximo uma vez, mesmo com vários requisitos satisfeitos ou vários alvos elegíveis.
- Uma regra composta AND/OR conta uma vez; seus termos não registram separadamente.
- Regras por alvo usam o contexto do efeito para compartilhar essa contagem. Efeitos copiados/aninhados têm execuções próprias; novas execuções do mesmo efeito podem contar novamente.
- `Always`, condição ausente e composições sem requisitos não contam.
- O Refrator pode liberar um efeito sem satisfazer naturalmente o requisito; esse bypass não conta.
- A satisfação é registrada antes da seleção/ação: não exige alvo disponível nem resultado da ação.
- Novas execuções podem contar novamente. O total reinicia com a rodada/painel.

Golem declara os requisitos de resíduo e anomalia nos dois GameEffects. Cada
regra conta uma vez, mesmo consumindo vários resíduos. Geada declara
`buff_condition` e a avalia no contexto de cada alvo antes de conceder carga,
mas contribui apenas uma vez por execução, mesmo beneficiando vários alvos;
uma runa desabilitada que ainda tem cargas não satisfaz "sem cargas".
Fênix continua usando um gatilho de destruição, que não conta por si só.

Regressão: `godot --headless --path . --script tools/test_gameplay_conditions.gd`.
