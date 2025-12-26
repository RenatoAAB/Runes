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
| 1.3 Keywords | ✅ COMPLETO | `core/keywords.gd` |
| 1.4 Keywords nos Efeitos | ✅ COMPLETO | Vários payloads, conditions, targets atualizados |
| 2.1 Refatorar Reader | ✅ COMPLETO | `logic/reader.gd` |
| 3.1 StatisticsManager | ✅ COMPLETO | `autoloads/statistics_manager.gd` |
| Configuração Autoloads | ✅ COMPLETO | `project.godot` atualizado |

---

## Visão Geral da Refatoração

### Princípios Guia
1. **Eventos como Núcleo:** Todo gameplay flui através de eventos tipados. O mesmo evento serve para processamento E registro.
2. **Keywords Fixas:** Vocabulário fechado que traduz mecânicas para o jogador (glossário do jogo).
3. **Estatísticas Onipresentes:** Toda ação é rastreável em três níveis: Batalha → Run → Histórico.
4. **Data-Driven:** Comportamentos definidos em Resources, não em código.

### Estado Atual (66% implementado)
- ✅ Core Loop (Reader, Grid, Slots, Runas)
- ✅ Sistema de Efeitos (Condition/Target/Payload)
- ✅ UI básica (Drag-drop, Tooltips, Highlights)
- ⚠️ Parcial: Slots (faltam multiplicadores locais)
- ⚠️ Parcial: Reader (falta skip, reverse, teleport)
- ❌ Faltando: Painéis (multi-grid)
- ❌ Faltando: Economia (dinheiro, loja)
- ❌ Faltando: Sistema de eventos unificado
- ❌ Faltando: Keywords
- ❌ Faltando: Persistência

---

## FASE 1: Fundação - Sistema de Eventos e Keywords
**Prioridade:** CRÍTICA  
**Estimativa:** 2-3 sessões de trabalho

### 1.1 Definir Estruturas de Evento
> Criar classes base para eventos que serão usados em TODO o jogo.

**Arquivos a criar:**
- [ ] `scripts/core/events/game_event.gd` - Classe base abstrata
- [ ] `scripts/core/events/slot_read_event.gd` - Evento de leitura de slot
- [ ] `scripts/core/events/panel_complete_event.gd` - Evento de finalização de painel
- [ ] `scripts/core/events/planning_event.gd` - Evento de ação na fase de planejamento
- [ ] `scripts/core/events/economy_event.gd` - Evento de transação monetária

**Estrutura `SlotReadEvent`:**
```gdscript
class_name SlotReadEvent extends GameEvent

var slot_coord: Vector2i
var rune_id: StringName
var rune_element: GameEnums.Element
var conditions_evaluated: Array[Dictionary]  # {condition_id, met: bool}
var targets_selected: Array[Vector2i]
var payloads_executed: Array[Dictionary]  # {payload_id, keywords: [], result: Variant}
var score_before: int
var score_after: int
var activations_used: int
var slot_multiplier: float
```

**Estrutura `PlanningEvent`:**
```gdscript
class_name PlanningEvent extends GameEvent

enum ActionType { PLACE_RUNE, MOVE_RUNE, SWAP_RUNES, REMOVE_RUNE, UPGRADE_RUNE }
var action_type: ActionType
var rune_id: StringName
var source_location: Variant  # Vector2i or "inventory"
var destination_location: Variant
```

### 1.2 Criar Event Bus (Autoload)
> Singleton central que processa e distribui eventos.

**Arquivo a criar:**
- [ ] `scripts/autoloads/event_bus.gd`

**Responsabilidades:**
- Receber eventos via `emit(event: GameEvent)`
- Processar lógica de gameplay baseada no evento
- Notificar listeners (UI, estatísticas)
- Manter histórico da batalha atual

**Sinais:**
```gdscript
signal event_emitted(event: GameEvent)
signal slot_read(event: SlotReadEvent)
signal panel_completed(event: PanelCompleteEvent)
signal planning_action(event: PlanningEvent)
```

### 1.3 Definir Vocabulário de Keywords
> Dicionário estático com todas as keywords do jogo.

**Arquivo a criar:**
- [ ] `scripts/core/keywords.gd`

**Categorias de Keywords:**

| Categoria | Keywords | Descrição |
|-----------|----------|-----------|
| **Condição** | `COMBO`, `THRESHOLD`, `ADJACENT`, `POSITION`, `ELEMENT_SYNC`, `RESOURCE` | Quando o efeito ativa |
| **Ação** | `SCORE`, `SCALING`, `MULTIPLY`, `CHAIN`, `TRIGGER`, `ABSORB`, `DESTROY`, `CREATE`, `MOVE` | O que o efeito faz |
| **Alvo** | `SELF`, `NEIGHBORS`, `ROW`, `COLUMN`, `ELEMENT`, `RANDOM` | Quem é afetado |
| **Estado** | `FRAGILE`, `PETRIFIED`, `BURNING`, `WET`, `ILLUMINATED`, `PRISMATIC`, `CURSED` | Status aplicados |
| **Econômico** | `INCOME`, `COST`, `TRADE` | Relacionado a dinheiro |

**Estrutura:**
```gdscript
const KEYWORDS: Dictionary = {
    # Condições
    &"COMBO": {
        "name": "Combo",
        "description": "Efeito escala com número de ativações.",
        "color": Color.GOLD,
        "category": "condition"
    },
    &"ADJACENT": {
        "name": "Adjacente", 
        "description": "Requer vizinhos específicos.",
        "color": Color.CYAN,
        "category": "condition"
    },
    # ... etc
}
```

### 1.4 Integrar Keywords aos Efeitos Existentes
> Cada Condition, Target e Payload declara suas keywords.

**Arquivos a modificar:**
- [ ] `scripts/data/rune_effect.gd` - Adicionar `func get_keywords() -> Array[StringName]`
- [ ] `scripts/data/effects/conditions/*.gd` - Cada um retorna suas keywords
- [ ] `scripts/data/effects/targets/*.gd` - Cada um retorna suas keywords  
- [ ] `scripts/data/effects/payloads/*.gd` - Cada um retorna suas keywords

**Exemplo:**
```gdscript
# Em payload_multiply_self_permanent.gd
func get_keywords() -> Array[StringName]:
    return [&"SCALING", &"MULTIPLY", &"SELF"]
```

---

## FASE 2: Refatorar Core Loop para Usar Eventos
**Prioridade:** CRÍTICA  
**Estimativa:** 2-3 sessões de trabalho

### 2.1 Refatorar Reader
> Reader emite `SlotReadEvent` ao invés de chamar métodos diretamente.

**Arquivo a modificar:**
- [ ] `scripts/logic/reader.gd`

**Mudanças:**
1. Ao processar slot, criar `SlotReadEvent` com todos os dados
2. Emitir evento via `EventBus.emit(event)`
3. Aguardar processamento antes de continuar
4. Remover lógica de score do Reader (fica no EventBus)

### 2.2 Refatorar BattleContext
> BattleContext se torna consumidor de eventos, não produtor.

**Arquivo a modificar:**
- [ ] `scripts/logic/battle_context.gd`

**Mudanças:**
1. Escutar `EventBus.slot_read` para atualizar score
2. Escutar `EventBus.slot_read` para processar payloads em cadeia
3. Manter apenas estado agregado (score atual, ativações totais)
4. Remover métodos de ação direta (agora via eventos)

### 2.3 Refatorar GridManager para Ações de Planejamento
> Toda modificação no grid emite `PlanningEvent`.

**Arquivo a modificar:**
- [ ] `scripts/logic/grid_manager.gd`

**Mudanças:**
1. `place_rune()` → emite `PlanningEvent(PLACE_RUNE, ...)`
2. `move_rune()` → emite `PlanningEvent(MOVE_RUNE, ...)`
3. `swap_runes()` → emite `PlanningEvent(SWAP_RUNES, ...)`
4. EventBus processa e aplica a mudança real

### 2.4 Atualizar Payloads para Contribuir ao Evento
> Payloads retornam resultado estruturado ao invés de modificar estado diretamente.

**Arquivos a modificar:**
- [ ] Todos os `scripts/data/effects/payloads/*.gd`

**Padrão novo:**
```gdscript
func execute(context: BattleContext, source: GridSlot, targets: Array[GridSlot]) -> Dictionary:
    # Retorna resultado ao invés de modificar diretamente
    return {
        "keywords": get_keywords(),
        "score_delta": calculated_score,
        "targets_affected": targets.map(func(t): return t.coord),
        "side_effects": []  # buffs, destruições, etc
    }
```

---

## FASE 3: Sistema de Estatísticas
**Prioridade:** ALTA  
**Estimativa:** 1-2 sessões de trabalho

### 3.1 Criar StatisticsManager (Autoload)
> Escuta eventos e agrega estatísticas.

**Arquivo a criar:**
- [ ] `scripts/autoloads/statistics_manager.gd`

**Estruturas de dados:**
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

### 3.2 Implementar Persistência JSON
> Salvar/carregar estatísticas históricas.

**Arquivo a modificar:**
- [ ] `scripts/autoloads/statistics_manager.gd`

**Funções:**
```gdscript
const SAVE_PATH = "user://statistics.json"

func save_history() -> void:
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(history_stats))
    file.close()

func load_history() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
        history_stats = JSON.parse_string(file.get_as_text())
        file.close()
```

### 3.3 Conectar UI às Estatísticas
> Mostrar estatísticas em tempo real e no fim da run.

**Arquivos a modificar:**
- [ ] `scripts/ui/tooltip_manager.gd` - Mostrar keywords no tooltip
- [ ] Criar `scripts/ui/stats_display.gd` - Painel de estatísticas

---

## FASE 4: Implementar Features Faltantes do GDD
**Prioridade:** ALTA  
**Estimativa:** 3-4 sessões de trabalho

### 4.1 Sistema de Economia
> Dinheiro, custos e recompensas.

**Arquivos a criar:**
- [ ] `scripts/core/events/economy_event.gd`
- [ ] `scripts/data/effects/payloads/payload_add_money.gd`
- [ ] `scripts/data/effects/payloads/payload_remove_money.gd`
- [ ] `scripts/data/effects/conditions/condition_money.gd`

**Arquivos a modificar:**
- [ ] `scripts/autoloads/statistics_manager.gd` - Gerenciar `run_stats.money`
- [ ] `scripts/logic/game_manager.gd` - Integrar economia às fases

### 4.2 Multiplicadores de Slot
> Slots aplicam multiplicadores ao score da runa.

**Arquivo a modificar:**
- [ ] `scripts/logic/grid_slot.gd`

**Adicionar:**
```gdscript
@export var base_multiplier: float = 1.0
var temporary_multiplier: float = 1.0  # Reset por rodada
var permanent_multiplier: float = 1.0  # Persiste na run

func get_total_multiplier() -> float:
    return base_multiplier * temporary_multiplier * permanent_multiplier
```

### 4.3 Controles Avançados do Reader
> Skip, reverse, teleport.

**Arquivos a criar:**
- [ ] `scripts/data/effects/payloads/payload_skip_slot.gd`
- [ ] `scripts/data/effects/payloads/payload_reverse_reader.gd`
- [ ] `scripts/data/effects/payloads/payload_teleport_reader.gd`

**Arquivo a modificar:**
- [ ] `scripts/logic/reader.gd` - Adicionar suporte a direção e skip

### 4.4 Sistema de Painéis (Multi-Grid)
> Múltiplos grids com multiplicadores globais.

**Arquivos a criar:**
- [ ] `scripts/data/panel_data.gd` - Resource para definir painel
- [ ] `scripts/logic/panel_manager.gd` - Gerencia múltiplos GridManagers
- [ ] `scripts/core/events/panel_complete_event.gd`

**Mudanças arquiteturais:**
1. `GridManager` vira componente de `PanelManager`
2. Reader processa painéis em sequência
3. Score de um painel alimenta o próximo

---

## FASE 5: Fase de Loja
**Prioridade:** MÉDIA  
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
FASE 1.1 → 1.2 → 1.3 → 1.4  (Fundação)
    ↓
FASE 2.1 → 2.2 → 2.3 → 2.4  (Refatoração Core)
    ↓
FASE 3.1 → 3.2 → 3.3        (Estatísticas)
    ↓
FASE 4.2 → 4.3 → 4.1 → 4.4  (Features GDD - slots primeiro, painéis por último)
    ↓
FASE 5.1 → 5.2              (Loja)
    ↓
FASE 6.x                    (Polish)
```

---

## Checklist de Validação

Após cada fase, verificar:
- [ ] Jogo ainda roda sem erros
- [ ] Eventos estão sendo emitidos corretamente (debug)
- [ ] Estatísticas estão sendo agregadas
- [ ] Keywords aparecem nos tooltips
- [ ] Persistência funciona (fechar e reabrir)

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

## Arquivos Criados Nesta Sessão (Fase 1)

### Core Events (`scripts/core/events/`)
| Arquivo | Descrição |
|---------|-----------|
| `game_event.gd` | Classe base para todos os eventos |
| `slot_read_event.gd` | Evento de leitura de slot (ativação de runa) |
| `panel_complete_event.gd` | Evento de finalização de painel |
| `planning_event.gd` | Evento de ação na fase de planejamento |
| `economy_event.gd` | Evento de transação monetária |

### Autoloads (`scripts/autoloads/`)
| Arquivo | Nome no Godot | Descrição |
|---------|---------------|-----------|
| `event_bus.gd` | `EventBus` | Barramento central de eventos |
| `statistics_manager.gd` | `Stats` | Gerenciador de estatísticas (3 níveis) |

### Core (`scripts/core/`)
| Arquivo | Descrição |
|---------|-----------|
| `keywords.gd` | Vocabulário fixo de keywords do jogo |

### Modificados
| Arquivo | Mudança |
|---------|---------|
| `game_enums.gd` | Adicionado `GamePhase` enum |
| `game_manager.gd` | Migrado para usar `GameEnums.GamePhase` |
| `reader.gd` | Refatorado para emitir eventos via `EventBus` |
| `rune_effect.gd` | Adicionado `get_keywords()` e `get_keywords_display()` |
| `effect_condition.gd` | Adicionado `get_keywords()` base |
| `effect_target.gd` | Adicionado `get_keywords()` base |
| `effect_payload.gd` | Adicionado `get_keywords()` base |
| Vários payloads | Implementado `get_keywords()` específico |
| Vários conditions | Implementado `get_keywords()` específico |
| Vários targets | Implementado `get_keywords()` específico |
| `project.godot` | Adicionados autoloads `EventBus` e `Stats` |
