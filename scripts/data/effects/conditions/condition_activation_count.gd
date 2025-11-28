class_name ConditionActivationCount
extends EffectCondition

enum Comparison {
	GREATER_THAN,
	LESS_THAN,
	EQUALS
}

@export var comparison: Comparison = Comparison.EQUALS
@export var threshold: int = 1

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	# Note: current_activations is incremented BEFORE effects run in RuneInstance.on_activate
	# So if this is the first activation, current_activations is 1.
	var current = source_rune.current_activations
	
	match comparison:
		Comparison.GREATER_THAN:
			return current > threshold
		Comparison.LESS_THAN:
			return current < threshold
		Comparison.EQUALS:
			return current == threshold
	return false

func get_description() -> String:
	var comp_str = "="
	match comparison:
		Comparison.GREATER_THAN: comp_str = ">"
		Comparison.LESS_THAN: comp_str = "<"
	
	return "Activations %s %d" % [comp_str, threshold]
