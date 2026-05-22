class_name ConditionNotFirstActivation
extends NewEffectCondition

## True if the source rune has been activated at least once earlier this round.
## Used by Sopro: grants extra reader rewind only on repeated activations.

@export var min_previous_activations: int = 1


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle or not ctx.source_rune:
		return false
	var count := 0
	for entry in ctx.battle.activation_history:
		if entry.get("rune_instance") == ctx.source_rune:
			count += 1
			if count >= min_previous_activations:
				EffectLogger.log_condition(ctx, self, true)
				return true
	EffectLogger.log_condition(ctx, self, false)
	return false


func get_description() -> String:
	if min_previous_activations <= 1:
		return "not first activation this round"
	return "after %d previous activations this round" % min_previous_activations


func get_keywords() -> Array[StringName]:
	return []
