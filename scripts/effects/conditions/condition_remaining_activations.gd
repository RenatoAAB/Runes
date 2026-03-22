class_name ConditionRemainingActivations
extends NewEffectCondition

## True when the source rune's remaining activations meet a threshold.

enum Comparison {
	GREATER_THAN_OR_EQUAL,
	LESS_THAN_OR_EQUAL,
	EQUAL,
	GREATER_THAN,
	LESS_THAN
}

@export var threshold: int = 1
@export var comparison: Comparison = Comparison.GREATER_THAN_OR_EQUAL


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_rune:
		return false

	var remaining = ctx.source_rune.get_max_activations() - ctx.source_rune.current_activations
	var result = false

	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			result = remaining >= threshold
		Comparison.LESS_THAN_OR_EQUAL:
			result = remaining <= threshold
		Comparison.EQUAL:
			result = remaining == threshold
		Comparison.GREATER_THAN:
			result = remaining > threshold
		Comparison.LESS_THAN:
			result = remaining < threshold

	EffectLogger.log_condition(ctx, self, result)
	return result


func get_description() -> String:
	var comp_str = ""
	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			comp_str = ">="
		Comparison.LESS_THAN_OR_EQUAL:
			comp_str = "<="
		Comparison.EQUAL:
			comp_str = "="
		Comparison.GREATER_THAN:
			comp_str = ">"
		Comparison.LESS_THAN:
			comp_str = "<"
	return "remaining activations %s %d" % [comp_str, threshold]


func get_keywords() -> Array[StringName]:
	return [Keywords.CHARGED]
