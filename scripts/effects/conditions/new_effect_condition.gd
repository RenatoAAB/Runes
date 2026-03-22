class_name NewEffectCondition
extends Resource

## Base class for conditions in the new effect system.
## Uses EffectContext instead of loose (source_rune, context, source_slot) params.
## Named NewEffectCondition to coexist with existing EffectCondition during migration.

func evaluate(ctx: EffectContext) -> bool:
	return true


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
