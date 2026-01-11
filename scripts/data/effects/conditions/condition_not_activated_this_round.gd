class_name ConditionNotActivatedThisRound
extends EffectCondition

## Returns true if this rune has NOT been activated this round.
## Used for: Sonho (+50 if not activated).

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return source_rune.current_activations == 0


func get_description() -> String:
	return "this rune was not activated this round"


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
