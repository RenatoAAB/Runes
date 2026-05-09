# Runes Architecture Map

This document is a fast technical map for agents before any code change.

## Scope / Escopo

PT-BR:
- Mostra os limites entre sistemas.
- Define fluxo principal de execucao e eventos.
- Destaca regras para evitar regressao arquitetural.

EN:
- Shows subsystem boundaries.
- Defines core execution and event flow.
- Highlights rules that prevent architectural regressions.

## Core Runtime Topology / Topologia Principal

| Subsystem | Main File | Responsibility |
|---|---|---|
| EventBus (autoload) | [scripts/autoloads/event_bus.gd](scripts/autoloads/event_bus.gd) | Central hub for typed gameplay events |
| StatisticsManager (autoload) | [scripts/autoloads/statistics_manager.gd](scripts/autoloads/statistics_manager.gd) | Battle/run/history tracking + persistence |
| JuiceManager (autoload) | [scripts/autoloads/juice_manager.gd](scripts/autoloads/juice_manager.gd) | Feedback and feel orchestration |
| Reader | [scripts/logic/reader.gd](scripts/logic/reader.gd) | Traverses slots and drives activation loop |
| BattleContext | [scripts/logic/battle_context.gd](scripts/logic/battle_context.gd) | Runtime state API for effects |
| GridManager | [scripts/logic/grid_manager.gd](scripts/logic/grid_manager.gd) | Grid state, placement, spatial queries |
| GameManager | [scripts/logic/game_manager.gd](scripts/logic/game_manager.gd) | High-level phase and progression control |
| PanelManager | [scripts/logic/panel_manager.gd](scripts/logic/panel_manager.gd) | Multi-panel flow and panel aggregation |
| ShopManager | [scripts/logic/shop_manager.gd](scripts/logic/shop_manager.gd) | Economy/shop lifecycle |

## Battle Flow / Fluxo de Batalha

1. Reader starts sequence via `start_sequence()`.
2. Reader instantiates BattleContext and shares references with EventBus.
3. Reader builds traversal order from valid grid slots.
4. For each step:
   - emits visual step signals
   - processes residue hooks
   - activates rune (if present and valid)
   - emits SlotReadEvent through EventBus
   - records activation into BattleContext history
5. Reader finishes sequence and finalizes panel/battle events.

Key file references:
- [scripts/logic/reader.gd](scripts/logic/reader.gd)
- [scripts/logic/battle_context.gd](scripts/logic/battle_context.gd)
- [scripts/core/events/slot_read_event.gd](scripts/core/events/slot_read_event.gd)

## Effect Pipeline / Pipeline de Efeitos

Pipeline order:
- Trigger -> Condition -> Selector -> Action

Implementation anchors:
- GameEffect container: [scripts/effects/game_effect.gd](scripts/effects/game_effect.gd)
- Conditions: [scripts/effects/conditions](scripts/effects/conditions)
- Selectors: [scripts/effects/selectors](scripts/effects/selectors)
- Actions: [scripts/effects/actions](scripts/effects/actions)
- Runtime context object: [scripts/effects/effect_context.gd](scripts/effects/effect_context.gd)

Resource layout:
- Active effects: [resources/effects/rune_effects](resources/effects/rune_effects)
- Shared selectors/conditions/filters: [resources/effects/shared](resources/effects/shared)

## Data-Driven Contract / Contrato Data-Driven

PT-BR:
- Dados em `.tres` definem comportamento.
- Codigo interpreta e executa comportamento.
- Novos conteudos devem priorizar criacao de novos resources e componentes standalone.

EN:
- `.tres` data defines behavior.
- Code interprets and executes behavior.
- New content should prefer new resources and standalone components.

Primary pattern:
- Data -> Instance -> Manager

Examples:
- RuneData -> RuneInstance -> GridManager
- PanelData -> PanelInstance -> PanelManager
- RelicData -> RelicInstance -> RelicProcessor

## Event Contracts / Contratos de Evento

Current typed event files:
- [scripts/core/events/game_event.gd](scripts/core/events/game_event.gd)
- [scripts/core/events/slot_read_event.gd](scripts/core/events/slot_read_event.gd)
- [scripts/core/events/panel_complete_event.gd](scripts/core/events/panel_complete_event.gd)
- [scripts/core/events/planning_event.gd](scripts/core/events/planning_event.gd)
- [scripts/core/events/economy_event.gd](scripts/core/events/economy_event.gd)
- [scripts/core/events/relic_activated_event.gd](scripts/core/events/relic_activated_event.gd)
- [scripts/core/events/infinite_loop_event.gd](scripts/core/events/infinite_loop_event.gd)

Rule:
- Prefer EventBus and signals for cross-system communication.
- Avoid direct manager-to-manager hard references when an event boundary exists.

## Architecture Guardrails / Guardrails Arquiteturais

Do:
- Keep effect components modular and standalone.
- Keep behavior in resources where possible.
- Preserve EventBus boundaries when integrating systems.

Do not:
- Introduce direct coupling between managers if EventBus/signal can solve it.
- Add new gameplay logic only in UI scripts.
- Reuse legacy migration scripts for normal development workflows.

## Extension Playbook / Playbook de Extensao

For a new effect:
1. Add or reuse condition/selector/action component in [scripts/effects](scripts/effects).
2. Create resource in [resources/effects/rune_effects](resources/effects/rune_effects).
3. Reuse shared resources in [resources/effects/shared](resources/effects/shared) when possible.
4. Validate keyword exposure and tooltip behavior.

For debugging effect execution:
- Start with [docs/rune_effects_debug.md](docs/rune_effects_debug.md).
