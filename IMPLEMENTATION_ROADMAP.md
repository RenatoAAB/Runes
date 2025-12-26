# ROTEIRO DE IMPLEMENTAÇÃO - RUNES
**Versão:** 1.0  
**Data:** 25/12/2024  
**Objetivo:** Alinhar implementação ao GDD + Sistema de Eventos Unificado + Keywords

---

## Status de Progresso

| Fase | Status | Arquivos Criados/Modificados |
|------|--------|------------------------------|
| 1.1 Estruturas de Evento | ✅ COMPLETO | `events/game_event.gd`, `slot_read_event.gd`, `panel_complete_event.gd`, `planning_event.gd`, `economy_event.gd` |
| 1.2 Event Bus | ✅ COMPLETO | `autoloads/event_bus.gd` |
| 1.3 Keywords | ✅ COMPLETO | `core/keywords.gd` (50+ keywords em 5 categorias) |
| 1.4 Keywords nos Efeitos | ✅ COMPLETO | Todos os payloads, conditions e targets atualizados |
| 2.1 Refatorar Reader | ✅ COMPLETO | `logic/reader.gd` - emite SlotReadEvent e PanelCompleteEvent |
| 2.2 Refatorar BattleContext | ✅ COMPLETO | `logic/battle_context.gd` - tracking de efeitos |
| 2.3 GridManager Eventos | ✅ COMPLETO | `logic/grid_manager.gd` - emite PlanningEvent |
| 2.4 Keywords em Todos Efeitos | ✅ COMPLETO | 35 payloads, 13 conditions, 8 targets com get_keywords() |
| 3.1 StatisticsManager | ✅ COMPLETO | `autoloads/statistics_manager.gd` - 3 níveis de stats |
| 3.2 Persistência JSON | ✅ COMPLETO | `statistics_manager.gd` - save/load em user://statistics.json |
| 3.3 UI de Estatísticas | ✅ COMPLETO | `ui/stats_display.gd`, `ui/battle_result_screen.gd` |
| Configuração Autoloads | ✅ COMPLETO | `project.godot` - EventBus e Stats registrados |
| 4.1 Sistema de Economia | ✅ COMPLETO | `payload_add_money.gd`, `condition_money.gd`, `game_manager.gd` bônus de vitória |
| 4.2 Slots como Entidades | ✅ COMPLETO | `slot_data.gd`, `slot_instance.gd`, 6 tipos de slot, refatoração de grid_slot.gd |
| 4.3 Controles do Reader | ✅ COMPLETO | `payload_skip_next.gd` (teleport/reset já existiam) |
| 4.4 Sistema de Painéis | ❌ NÃO INICIADO | Multi-grid com multiplicadores globais |

---

## Visão Geral da Refatoração

### Princípios Guia
1. **Eventos como Núcleo:** Todo gameplay flui através de eventos tipados. O mesmo evento serve para processamento E registro.
2. **Keywords Fixas:** Vocabulário fechado que traduz mecânicas para o jogador (glossário do jogo).
3. **Estatísticas Onipresentes:** Toda ação é rastreável em três níveis: Batalha → Run → Histórico.
4. **Data-Driven:** Comportamentos definidos em Resources, não em código.

### Estado Atual (85% implementado)
- ✅ Core Loop (Reader, Grid, Slots, Runas)
- ✅ Sistema de Efeitos (Condition/Target/Payload)
- ✅ UI básica (Drag-drop, Tooltips, Highlights)
- ✅ Sistema de eventos unificado (EventBus + 5 tipos de evento)
- ✅ Keywords (50+ keywords em 5 categorias, integradas a todos efeitos)
- ✅ Persistência (StatisticsManager com JSON)
- ✅ UI de estatísticas (StatsDisplay, BattleResultScreen, keywords em tooltips)
- ✅ Slots como entidades (SlotData/SlotInstance, 6 tipos, multiplicadores, triggers)
- ✅ Economia básica (dinheiro, bônus de vitória, payloads de economia)
- ✅ Controles do Reader (skip, teleport, reset)
- ❌ Faltando: Painéis (multi-grid)
- ❌ Faltando: Loja (shop phase)

---

## FASE 1: Fundação - Sistema de Eventos e Keywords ✅ COMPLETO
**Prioridade:** CRÍTICA  
**Status:** ✅ IMPLEMENTADO

### 1.1 Definir Estruturas de Evento ✅
> Criar classes base para eventos que serão usados em TODO o jogo.

**Arquivos criados:**
- [x] `scripts/core/events/game_event.gd` - Classe base abstrata
- [x] `scripts/core/events/slot_read_event.gd` - Evento de leitura de slot
- [x] `scripts/core/events/panel_complete_event.gd` - Evento de finalização de painel
- [x] `scripts/core/events/planning_event.gd` - Evento de ação na fase de planejamento
- [x] `scripts/core/events/economy_event.gd` - Evento de transação monetária

**Estrutura `SlotReadEvent`:** ✅ Implementado

**Estrutura `PlanningEvent`:** ✅ Implementado

### 1.2 Criar Event Bus (Autoload) ✅
> Singleton central que processa e distribui eventos.

**Arquivo criado:**
- [x] `scripts/autoloads/event_bus.gd`

**Responsabilidades:** ✅ Todas implementadas
- Receber eventos via `emit(event: GameEvent)`
- Processar lógica de gameplay baseada no evento
- Notificar listeners (UI, estatísticas)
- Manter histórico da batalha atual

**Sinais:** ✅ Implementados

### 1.3 Definir Vocabulário de Keywords ✅
> Dicionário estático com todas as keywords do jogo.

**Arquivo criado:**
- [x] `scripts/core/keywords.gd`

**Categorias de Keywords:** ✅ 50+ keywords implementadas

| Categoria | Keywords | Descrição |
|-----------|----------|-----------|
| **Condição** | `COMBO`, `THRESHOLD`, `ADJACENT`, `POSITION`, `ELEMENT_SYNC`, `SEQUENCE`, `RESOURCE` | Quando o efeito ativa |
| **Ação** | `SCORE`, `SCALING`, `MULTIPLY`, `CHAIN`, `TRIGGER`, `ABSORB`, `DESTROY`, `CREATE`, `MOVE`, `BUFF`, `DEBUFF`, `INCOME`, `COST` | O que o efeito faz |
| **Alvo** | `SELF`, `NEIGHBORS`, `ROW`, `COLUMN`, `ELEMENT_TARGET`, `RANDOM`, `ALL` | Quem é afetado |
| **Estado** | `FRAGILE`, `PETRIFIED`, `BURNING`, `WET`, `ILLUMINATED`, `PRISMATIC`, `CURSED`, `DISABLED`, `CHARGED`, `DECAYING` | Status aplicados |
| **Especial** | `VOLATILE`, `ECHO`, `MIMIC`, `INVERSE`, `META` | Mecânicas especiais |

### 1.4 Integrar Keywords aos Efeitos Existentes ✅
> Cada Condition, Target e Payload declara suas keywords.

**Arquivos modificados:**
- [x] `scripts/data/rune_effect.gd` - Adicionado `get_keywords()` e `get_keywords_display()`
- [x] `scripts/data/effects/conditions/*.gd` - 13 arquivos com keywords
- [x] `scripts/data/effects/targets/*.gd` - 8 arquivos com keywords
- [x] `scripts/data/effects/payloads/*.gd` - 35 arquivos com keywords

---

## FASE 2: Refatorar Core Loop para Usar Eventos ✅ COMPLETO
**Prioridade:** CRÍTICA  
**Status:** ✅ IMPLEMENTADO

### 2.1 Refatorar Reader ✅
> Reader emite `SlotReadEvent` ao invés de chamar métodos diretamente.

**Arquivo modificado:**
- [x] `scripts/logic/reader.gd`

**Mudanças:** ✅ Implementadas
1. Ao processar slot, criar `SlotReadEvent` com todos os dados
2. Emitir evento via `EventBus.emit(event)`
3. Aguardar processamento antes de continuar
4. Remover lógica de score do Reader (fica no EventBus)

### 2.2 Refatorar BattleContext ✅
> BattleContext se torna consumidor de eventos, não produtor.

**Arquivo modificado:**
- [x] `scripts/logic/battle_context.gd`

**Mudanças:** ✅ Implementadas
1. Adicionado `set_current_context()` para tracking de efeitos
2. Adicionado `record_effect_result()` para registrar resultados
3. Adicionado `get_effects_results()` para consultar resultados
4. Mantém estado agregado (score atual, ativações totais)

### 2.3 Refatorar GridManager para Ações de Planejamento ✅
> Toda modificação no grid emite `PlanningEvent`.

**Arquivo modificado:**
- [x] `scripts/logic/grid_manager.gd`

**Mudanças:** ✅ Implementadas
1. `place_rune()` → emite `PlanningEvent(PLACE_RUNE, ...)`
2. `move_rune()` → emite `PlanningEvent(MOVE_RUNE, ...)`
3. `rotate_runes()` → emite `PlanningEvent(SWAP_RUNES, ...)`
4. Helper methods `_emit_planning_event()` e `_emit_swap_event()`

### 2.4 Atualizar Payloads para Contribuir ao Evento ✅
> Payloads declaram keywords e contribuem para rastreamento de eventos.

**Arquivos modificados:**
- [x] Todos os 35 `scripts/data/effects/payloads/*.gd` - Implementado `get_keywords()`

**Nota:** A refatoração completa para retorno estruturado foi adiada. O sistema atual funciona com:
- Keywords declaradas em cada payload
- BattleContext rastreia resultados via `record_effect_result()`
- SlotReadEvent agrega keywords no evento final

---

## FASE 3: Sistema de Estatísticas ✅ COMPLETO
**Prioridade:** ALTA  
**Status:** ✅ IMPLEMENTADO

### 3.1 Criar StatisticsManager (Autoload) ✅
> Escuta eventos e agrega estatísticas.

**Arquivo criado:**
- [x] `scripts/autoloads/statistics_manager.gd`

**Estruturas de dados:** ✅ Implementadas com 3 níveis (battle/run/history)
```gdscript
# Estatísticas da batalha atual
var battle_stats: Dictionary = {
    "events": [],  # Array de SlotReadEvent
    "score_by_rune": {},  # rune_id -> int
    "activations_by_element": {},  # Element -> int
    "keywords_triggered": {},  # keyword_id -> count
    "highest_single_activation": 0,
}

# Estatísticas da run atual
var run_stats: Dictionary = {
    "rounds_played": 0,
    "rounds_won": 0,
    "total_score": 0,
    "money": 0,
    "runes_acquired": [],
    "runes_destroyed": [],
    "planning_actions": 0,
}

# Estatísticas históricas (persistidas)
var history_stats: Dictionary = {
    "runs_completed": 0,
    "runs_won": 0,
    "best_score": 0,
    "total_playtime_seconds": 0,
    "lifetime_runes_activated": 0,
    "lifetime_score": 0,
    "keyword_usage": {},  # keyword_id -> total count
}
```

### 3.2 Implementar Persistência JSON ✅
> Salvar/carregar estatísticas históricas.

**Arquivo modificado:**
- [x] `scripts/autoloads/statistics_manager.gd`

**Funções implementadas:**
- `save_history()` - Salva em `user://statistics.json`
- `load_history()` - Carrega do arquivo JSON
- Auto-save ao final de cada run

### 3.3 Conectar UI às Estatísticas ✅
> Mostrar estatísticas em tempo real e no fim da run.

**Arquivos criados:**
- [x] `scripts/ui/stats_display.gd` - Painel de estatísticas em tempo real durante batalha
- [x] `scripts/ui/battle_result_screen.gd` - Tela de resultado pós-batalha com stats

**Arquivos modificados:**
- [x] `scripts/ui/rune_ui.gd` - Keywords exibidas no tooltip
- [x] `scripts/logic/game_manager.gd` - Integração com BattleResultScreen
- [x] `scripts/main_controller.gd` - Cria/destrói StatsDisplay por fase
- [x] `scripts/logic/reader.gd` - Agrega keywords_triggered no SlotReadEvent
- [x] `scenes/main.tscn` - Grupo "ui_layer" adicionado

**Funcionalidades implementadas:**
- StatsDisplay mostra score, ativações e keywords em tempo real
- BattleResultScreen exibe resumo completo ao fim da batalha
- Keywords aparecem nos tooltips das runas
- Clique em qualquer lugar fecha a tela de resultado

---

## FASE 4: Implementar Features Faltantes do GDD
**Prioridade:** ALTA  
**Status:** ⚠️ EM PROGRESSO (4.1-4.3 completos)  
**Estimativa:** 3-4 sessões de trabalho

### 4.1 Sistema de Economia ✅ COMPLETO
> Dinheiro, custos e recompensas.

**Arquivos criados:**
- [x] `scripts/core/events/economy_event.gd` - Evento de transação
- [x] `scripts/data/effects/payloads/payload_add_money.gd` - Adiciona dinheiro
- [x] `scripts/data/effects/payloads/payload_score_for_money.gd` - Converte score↔dinheiro
- [x] `scripts/data/effects/conditions/condition_money.gd` - Condição baseada em saldo

**Arquivos modificados:**
- [x] `scripts/autoloads/statistics_manager.gd` - Gerencia `run_stats.money` via EconomyEvent
- [x] `scripts/logic/battle_context.gd` - API de economia: `add_money()`, `remove_money()`, `get_money()`
- [x] `scripts/logic/game_manager.gd` - Bônus de vitória em `_handle_win()`
- [x] `scripts/logic/slot_instance.gd` - Slots podem gerar dinheiro via `money_on_activation`

### 4.2 Sistema de Slots como Entidades ✅ COMPLETO
> Slots tratados como entidades de primeira classe, similar às runas.

**Arquivos criados:**
- [x] `scripts/data/slot_data.gd` - Resource definindo tipo de slot
- [x] `scripts/logic/slot_instance.gd` - Instância runtime com estados e upgrades
- [x] `resources/slots/slot_default.tres` - Slot padrão (1x)
- [x] `resources/slots/slot_amplifier.tres` - Multiplicador 2x
- [x] `resources/slots/slot_repeater.tres` - Dispara runa 2 vezes
- [x] `resources/slots/slot_eternal.tres` - Preserva cargas
- [x] `resources/slots/slot_merchant.tres` - Gera dinheiro por ativação
- [x] `resources/slots/slot_broken.tres` - Multiplicador 0.5x

**Arquivos modificados:**
- [x] `scripts/logic/grid_slot.gd` - Refatorado para usar SlotInstance
- [x] `scripts/ui/slot_ui.gd` - Drag & drop de slots, tooltips melhoradas
- [x] `scripts/logic/reader.gd` - Usa slot.preserves_charges(), slot.get_trigger_count()

### 4.3 Controles Avançados do Reader ✅ COMPLETO
> Skip, teleport (reverse não necessário).

**Arquivos criados:**
- [x] `scripts/data/effects/payloads/payload_skip_next.gd` - Pula X slots à frente

**Nota:** Teleport já existe via `payload_teleport_reader.gd` e reset via `payload_reset_reader.gd`.
Reverse não é necessário pois o sistema de teleport cobre esse caso.

### 4.4 Sistema de Painéis (Multi-Grid) ❌ NÃO INICIADO
> Múltiplos grids com multiplicadores globais.

**Arquivos a criar:**
- [ ] `scripts/data/panel_data.gd` - Resource para definir painel
- [ ] `scripts/logic/panel_manager.gd` - Gerencia múltiplos GridManagers

**Nota:** `panel_complete_event.gd` já foi criado na Fase 1

---

## FASE 5: Fase de Loja
**Prioridade:** MÉDIA  
**Status:** ❌ NÃO INICIADO  
**Estimativa:** 2 sessões de trabalho

### 5.1 Criar ShopManager
**Arquivos a criar:**
- [ ] `scripts/logic/shop_manager.gd`
- [ ] `scripts/ui/shop_ui.gd`
- [ ] `scenes/Shop.tscn`

**Funcionalidades:**
- Gerar ofertas baseadas em raridade (usando `RuneDropRates`)
- Comprar runas (deduz dinheiro, adiciona ao inventário)
- Comprar modificadores de slot
- Refresh de loja (custo aumenta)

### 5.2 Integrar ao Game Loop
**Arquivo a modificar:**
- [ ] `scripts/logic/game_manager.gd`

**Nova fase:** `SHOP` entre `REWARD` e `PLANNING`

---

## FASE 6: Polish e Juice
**Prioridade:** BAIXA  
**Status:** ❌ NÃO INICIADO  
**Estimativa:** 2-3 sessões de trabalho

### 6.1 Feedback Visual
- [ ] Camera shake em ativações grandes
- [ ] Partículas por elemento
- [ ] Animação de "laser" no score final
- [ ] Transições entre fases

### 6.2 Feedback Sonoro
- [ ] Som de ativação (pitch ascendente em combo)
- [ ] Som de erro (condição não atendida)
- [ ] Música por fase

### 6.3 Tooltip Avançado
- [ ] Mostrar equação completa: `Σ(Base + Buff) × Slot × Painel`
- [ ] Badges de keywords clicáveis
- [ ] Preview de score estimado

---

## Ordem de Implementação Recomendada

```
FASE 1.1 → 1.2 → 1.3 → 1.4  (Fundação)           ✅ COMPLETO
    ↓
FASE 2.1 → 2.2 → 2.3 → 2.4  (Refatoração Core)   ✅ COMPLETO
    ↓
FASE 3.1 → 3.2 → 3.3        (Estatísticas)       ✅ COMPLETO
    ↓
FASE 4.2 → 4.3 → 4.1 → 4.4  (Features GDD)       ❌ PENDENTE  ← PRÓXIMO
    ↓
FASE 5.1 → 5.2              (Loja)               ❌ PENDENTE
    ↓
FASE 6.x                    (Polish)             ❌ PENDENTE
```

---

## Checklist de Validação

Após cada fase, verificar:
- [x] Jogo ainda roda sem erros
- [x] Eventos estão sendo emitidos corretamente (debug)
- [x] Estatísticas estão sendo agregadas
- [x] Keywords aparecem nos tooltips
- [x] Persistência funciona (fechar e reabrir)
- [x] Tela de resultado aparece após batalha
- [x] StatsDisplay aparece durante batalha

---

## Notas de Migração

### Breaking Changes Esperados
1. `BattleContext.add_score()` → Obsoleto, usar `EventBus.emit(SlotReadEvent)`
2. `Reader.score_updated` signal → Obsoleto, usar `EventBus.slot_read`
3. Payloads retornam `Dictionary` ao invés de `void`

### Compatibilidade
- Manter métodos antigos como wrappers durante transição
- Marcar com `@deprecated` no GDScript 4.x
- Remover após validação completa

---

## Arquivos Criados/Modificados (Fases 1-2)

### Core Events (`scripts/core/events/`)
| Arquivo | Descrição | Status |
|---------|-----------|--------|
| `game_event.gd` | Classe base para todos os eventos | ✅ |
| `slot_read_event.gd` | Evento de leitura de slot (ativação de runa) | ✅ |
| `panel_complete_event.gd` | Evento de finalização de painel | ✅ |
| `planning_event.gd` | Evento de ação na fase de planejamento | ✅ |
| `economy_event.gd` | Evento de transação monetária | ✅ |

### Autoloads (`scripts/autoloads/`)
| Arquivo | Nome no Godot | Descrição | Status |
|---------|---------------|-----------|--------|
| `event_bus.gd` | `EventBus` | Barramento central de eventos | ✅ |
| `statistics_manager.gd` | `Stats` | Gerenciador de estatísticas (3 níveis) | ✅ |

### Core (`scripts/core/`)
| Arquivo | Descrição | Status |
|---------|-----------|--------|
| `keywords.gd` | Vocabulário fixo de keywords (50+ keywords) | ✅ |

### Modificados na Fase 1-2
| Arquivo | Mudança | Status |
|---------|---------|--------|
| `game_enums.gd` | Adicionado `GamePhase` enum | ✅ |
| `game_manager.gd` | Migrado para usar `GameEnums.GamePhase` | ✅ |
| `reader.gd` | Refatorado para emitir eventos via `EventBus` | ✅ |
| `battle_context.gd` | Adicionado tracking de efeitos | ✅ |
| `grid_manager.gd` | Emite PlanningEvent em ações | ✅ |
| `rune_effect.gd` | Adicionado `get_keywords()` e `get_keywords_display()` | ✅ |
| `effect_condition.gd` | Adicionado `get_keywords()` base | ✅ |
| `effect_target.gd` | Adicionado `get_keywords()` base | ✅ |
| `effect_payload.gd` | Adicionado `get_keywords()` base | ✅ |
| `project.godot` | Adicionados autoloads `EventBus` e `Stats` | ✅ |

### Criados na Fase 3
| Arquivo | Descrição | Status |
|---------|-----------|--------|
| `ui/stats_display.gd` | Painel de stats em tempo real durante batalha | ✅ |
| `ui/battle_result_screen.gd` | Tela de resultado pós-batalha | ✅ |

### Modificados na Fase 3
| Arquivo | Mudança | Status |
|---------|---------|--------|
| `ui/rune_ui.gd` | Keywords exibidas no tooltip | ✅ |
| `logic/game_manager.gd` | Integração com BattleResultScreen | ✅ |
| `main_controller.gd` | Cria/destrói StatsDisplay por fase | ✅ |
| `logic/reader.gd` | Agrega keywords_triggered no evento | ✅ |
| `scenes/main.tscn` | Grupo "ui_layer" adicionado | ✅ |
| `autoloads/statistics_manager.gd` | Métodos get_battle/run/history_stats() | ✅ |

### Payloads com Keywords (35 arquivos)
| Arquivo | Keywords |
|---------|----------|
| `payload_add_score.gd` | `SCORE` |
| `payload_multiply_self.gd` | `MULTIPLY, SELF` |
| `payload_multiply_global_score.gd` | `MULTIPLY` |
| `payload_multiply_target_score.gd` | `MULTIPLY, BUFF` |
| `payload_multiply_score_permanent.gd` | `SCALING, MULTIPLY` |
| `payload_destroy_rune.gd` | `DESTROY` |
| `payload_destroy_and_absorb.gd` | `DESTROY, ABSORB, SCALING` |
| `payload_trigger_rune.gd` | `TRIGGER, CHAIN` |
| `payload_activate_region.gd` | `TRIGGER, CHAIN` |
| `payload_activate_double_trigger.gd` | `TRIGGER, CHAIN` |
| `payload_absorb.gd` | `ABSORB, BUFF` |
| `payload_create_rune.gd` | `CREATE, SELF` |
| `payload_copy_effect.gd` | `MIMIC, MULTIPLY` |
| `payload_copy_previous.gd` | `MIMIC, ECHO` |
| `payload_decay.gd` | `DECAYING, MULTIPLY, NEIGHBORS` |
| `payload_buff_slot.gd` | `BUFF` |
| `payload_buff_activation.gd` | `BUFF, CHARGED` |
| `payload_buff_row_column.gd` | `BUFF, ROW/COLUMN` |
| `payload_buff_element_permanent.gd` | `BUFF, SCALING, ELEMENT_TARGET` |
| `payload_meta_buff.gd` | `BUFF, SCALING` |
| `payload_consume_activation.gd` | `ABSORB, SCORE` |
| `payload_block_conditions.gd` | `DEBUFF, CURSED` |
| `payload_modify_rune.gd` | `BUFF/DEBUFF/DISABLED` |
| `payload_move_reader.gd` | `MOVE` |
| `payload_random_move_reader.gd` | `MOVE, RANDOM` |
| `payload_reset_reader.gd` | `MOVE, ECHO` |
| `payload_rotate_runes.gd` | `MOVE` |
| `payload_swap_runes.gd` | `MOVE` |
| `payload_flame_slot.gd` | `BURNING, MULTIPLY` |
| `payload_wet_slot.gd` | `WET, BUFF` |
| `payload_electrify_slot.gd` | `CHARGED, BUFF` |
| `payload_illuminate.gd` | `ILLUMINATED, BUFF` |
| `payload_illuminate_crystal_adjacent.gd` | `ILLUMINATED, NEIGHBORS, BUFF` |
| `payload_prismatic_slot.gd` | `PRISMATIC, BUFF` |
| `payload_petrify_slot.gd` | `PETRIFIED` |
| `payload_crystal_corner.gd` | `SCALING, POSITION` |
| `payload_divide_score.gd` | `META, MULTIPLY` |
| `payload_rhythm_buff.gd` | `SCALING, ELEMENT_TARGET, BUFF` |
| `payload_rhythm_chain_buff.gd` | `SCALING, COMBO, ELEMENT_TARGET` |
| `payload_score_per_activation.gd` | `SCORE, COMBO` |
| `payload_score_per_empty.gd` | `SCORE, NEIGHBORS` |

### Conditions com Keywords (13 arquivos)
| Arquivo | Keywords |
|---------|----------|
| `condition_activation_count.gd` | `COMBO` |
| `condition_activation_multiple.gd` | `COMBO` |
| `condition_activation_order.gd` | `SEQUENCE` |
| `condition_always.gd` | (nenhuma) |
| `condition_element_adjacent.gd` | `ADJACENT, ELEMENT_SYNC` |
| `condition_element_behind.gd` | `SEQUENCE, ELEMENT_SYNC` |
| `condition_element_nearby.gd` | `ADJACENT, ELEMENT_SYNC` |
| `condition_grid_position.gd` | `POSITION` |
| `condition_multiple_elements.gd` | `ADJACENT, ELEMENT_SYNC` |
| `condition_neighbor_count.gd` | `ADJACENT` |
| `condition_not_blocked.gd` | `ADJACENT, ELEMENT_SYNC` |
| `condition_not_on_border.gd` | `POSITION` |
| `condition_previous_effect_succeeded.gd` | `CHAIN` |
| `condition_rhythm_chain.gd` | `CHAIN, ELEMENT_SYNC` |
| `condition_score.gd` | `THRESHOLD` |
| `condition_slot_state.gd` | (state-based) |

### Targets com Keywords (8 arquivos)
| Arquivo | Keywords |
|---------|----------|
| `target_self.gd` | `SELF` |
| `target_adjacent.gd` | `NEIGHBORS` |
| `target_row_column.gd` | `ROW/COLUMN` |
| `target_sequence.gd` | `SEQUENCE` |
| `target_previous.gd` | `SEQUENCE` |
| `target_front_empty.gd` | `SEQUENCE` |
| `target_empty_adjacent.gd` | `NEIGHBORS` |
| `target_element.gd` | `ELEMENT_TARGET, ALL` |
| `target_below.gd` | `COLUMN` |
| `target_arbitrary.gd` | (nenhuma) |
| `target_relative.gd` | (nenhuma) |
