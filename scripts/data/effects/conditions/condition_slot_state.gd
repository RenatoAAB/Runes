class_name ConditionSlotState
extends EffectCondition

## Returns true if the source slot has a specific state.

@export var required_state: String = "electrified"
@export var negate: bool = false

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var has_state = source_slot.has_state(required_state)
	if negate:
		return not has_state
	return has_state

func get_description() -> String:
	if negate:
		return "slot is NOT %s" % required_state
	return "slot is %s" % required_state
