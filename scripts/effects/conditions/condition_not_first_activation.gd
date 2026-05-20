class_name ConditionNotFirstActivation
extends NewEffectCondition

## True if the source rune has been activated at least once earlier this round.
## Used by Sopro: grants extra reader rewind only on repeated activations.


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle or not ctx.source_rune:
		return false
	for entry in ctx.battle.activation_history:
		if entry.get("rune_instance") == ctx.source_rune:
			EffectLogger.log_condition(ctx, self, true)
			return true
	EffectLogger.log_condition(ctx, self, false)
	return false


func get_description() -> String:
	return "not first activation this round"


func get_keywords() -> Array[StringName]:
	return []
