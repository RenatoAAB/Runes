class_name ConditionNotActivatedThisRound
extends EffectCondition

## Returns true if this rune has NOT been activated this round.
## Used for: Sonho (+50 if not activated).

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	# Quick check: if we spent any activations, it's considered activated.
	if source_rune.current_activations > 0:
		return false

	if context:
		# Use the tracked unique activations to cover slots that preserve charges
		var rune_id = source_rune.data.id if source_rune and source_rune.data else ""
		if not rune_id.is_empty() and context.unique_runes_activated.get(rune_id, 0) > 0:
			return false
		# Fallback: scan activation history for this instance (safety for edge cases)
		for entry in context.activation_history:
			if entry.get("rune_instance", null) == source_rune:
				return false

	return true


func get_description() -> String:
	return "this rune was not activated this round"


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
