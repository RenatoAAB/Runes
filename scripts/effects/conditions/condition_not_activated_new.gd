class_name ConditionNotActivatedThisRoundNew
extends NewEffectCondition

## True if the source rune has NOT been activated this round.

func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_rune:
		return false

	if ctx.source_rune.current_activations > 0:
		EffectLogger.log_condition(ctx, self, false)
		return false

	if ctx.battle:
		var rune_id = ctx.source_rune.data.id if ctx.source_rune.data else ""
		if not rune_id.is_empty() and ctx.battle.unique_runes_activated.get(rune_id, 0) > 0:
			EffectLogger.log_condition(ctx, self, false)
			return false
		for entry in ctx.battle.activation_history:
			if entry.get("rune_instance", null) == ctx.source_rune:
				EffectLogger.log_condition(ctx, self, false)
				return false

	EffectLogger.log_condition(ctx, self, true)
	return true


func get_description() -> String:
	return "this rune was not activated this round"


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
