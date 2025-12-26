class_name ConditionActivationOrder
extends EffectCondition

enum Comparison {
	EARLIER_THAN, # < Index
	LATER_THAN,   # > Index
	EXACTLY_AT    # = Index
}

@export var comparison: Comparison = Comparison.EXACTLY_AT
@export var step_index: int = 0

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var current = context.current_step_index
	
	match comparison:
		Comparison.EARLIER_THAN:
			return current < step_index
		Comparison.LATER_THAN:
			return current > step_index
		Comparison.EXACTLY_AT:
			return current == step_index
	return false

func get_description() -> String:
	match comparison:
		Comparison.EARLIER_THAN:
			return "Before step %d" % step_index
		Comparison.LATER_THAN:
			return "After step %d" % step_index
		Comparison.EXACTLY_AT:
			return "At step %d" % step_index
	return ""

func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
