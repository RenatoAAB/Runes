class_name ConditionScore
extends EffectCondition

enum Comparison {
	GREATER_THAN,
	LESS_THAN,
	EQUALS
}

@export var comparison: Comparison = Comparison.GREATER_THAN
@export var threshold: int = 0

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var current = context.current_score
	
	match comparison:
		Comparison.GREATER_THAN:
			return current > threshold
		Comparison.LESS_THAN:
			return current < threshold
		Comparison.EQUALS:
			return current == threshold
	return false

func get_description() -> String:
	var comp_str = ">"
	match comparison:
		Comparison.LESS_THAN: comp_str = "<"
		Comparison.EQUALS: comp_str = "="
	
	return "Score %s %d" % [comp_str, threshold]
