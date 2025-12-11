class_name ConditionActivationMultiple
extends EffectCondition

## Returns true if the total number of previous activations is a multiple of N.

@export var multiple_of: int = 5

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var total_activations = context.get_meta("total_activations", 0)
	if total_activations == 0:
		return false
	return total_activations % multiple_of == 0

func get_description() -> String:
	return "total activations is multiple of %d" % multiple_of
