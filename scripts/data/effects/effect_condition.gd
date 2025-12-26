class_name EffectCondition
extends Resource

## Base class for conditions that determine if an effect can execute.

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return true

## Returns the slots that this condition checks/cares about.
## Used for visual highlighting (Green overlay).
func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return []

## Returns a plain text description of this condition.
func get_description() -> String:
	return ""

## Returns a BBCode-formatted description with condition color based on evaluation.
func get_description_colored(is_met: bool, can_evaluate: bool = true) -> String:
	var desc = get_description()
	if desc.is_empty() or desc == "Always":
		return ""
	return EffectColors.colorize_condition(desc, is_met, can_evaluate)

## Returns the keywords associated with this condition.
## Override in subclasses to return specific keywords.
func get_keywords() -> Array[StringName]:
	return []
