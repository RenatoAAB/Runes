class_name ConditionPreviousEffectNew
extends NewEffectCondition

## True if the previous effect on this rune succeeded.

func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_rune:
		return false
	var result = ctx.source_rune.last_effect_success
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_description() -> String:
	return "the previous effect succeeded"


func get_keywords() -> Array[StringName]:
	return [Keywords.CHAIN]
