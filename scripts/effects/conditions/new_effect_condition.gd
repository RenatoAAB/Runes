class_name NewEffectCondition
extends Resource

## Base class for conditions in the new effect system.
## Uses EffectContext instead of loose (source_rune, context, source_slot) params.
## Named NewEffectCondition to coexist with existing EffectCondition during migration.

func evaluate(ctx: EffectContext) -> bool:
	return true


## A gameplay requirement, distinct from triggers, target filters and safety checks.
## Override for unconditional/sentinel conditions. Composite requirements count once.
func is_gameplay_condition() -> bool:
	return true


## Execution-only entry point. Previews must keep using evaluate(), without stats.
## Record the natural result, before any slot bypass or action mutates the board.
## Per-target evaluation supplies the owning effect context to share its count.
func evaluate_for_execution(ctx: EffectContext, execution_ctx: EffectContext = null) -> bool:
	var met: bool = evaluate(ctx)
	var owner := execution_ctx if execution_ctx else ctx
	if met and is_gameplay_condition() and owner:
		owner.record_successful_condition()
	return met


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	return []


func get_description() -> String:
	return ""


func get_description_colored(is_met: bool, can_evaluate: bool = true) -> String:
	var desc = get_description()
	if desc.is_empty() or desc == "Always":
		return ""
	return EffectColors.colorize_condition(desc, is_met, can_evaluate)


func get_keywords() -> Array[StringName]:
	return []
