class_name EffectCondition
extends Resource

## Base class for conditions that determine if an effect can execute.

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return true

## Returns the slots that this condition checks/cares about.
## Used for visual highlighting (Green overlay).
func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return []
