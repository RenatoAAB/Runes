class_name ConditionSlotState
extends NewEffectCondition

## True based on the state of the source slot (has residue, is petrified, etc.).

enum StateCheck {
	HAS_RESIDUE,
	IS_PETRIFIED,
	IS_EMPTY,
	IS_OCCUPIED,
	IS_BROKEN,
}

@export var state_check: StateCheck = StateCheck.HAS_RESIDUE
@export var negate: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot:
		return false

	var is_match = false
	match state_check:
		StateCheck.HAS_RESIDUE:
			is_match = ctx.source_slot.slot != null and ctx.source_slot.slot.has_method("has_residue") and ctx.source_slot.slot.has_residue()
		StateCheck.IS_PETRIFIED:
			is_match = ctx.source_slot.slot != null and ctx.source_slot.slot.has_method("is_petrified") and ctx.source_slot.slot.is_petrified()
		StateCheck.IS_EMPTY:
			is_match = ctx.source_slot.is_empty()
		StateCheck.IS_OCCUPIED:
			is_match = not ctx.source_slot.is_empty()
		StateCheck.IS_BROKEN:
			is_match = ctx.source_slot.slot != null and ctx.source_slot.slot.has_method("is_broken") and ctx.source_slot.slot.is_broken()

	var result = not is_match if negate else is_match
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_description() -> String:
	var state_str = StateCheck.keys()[state_check].replace("_", " ").to_lower()
	if negate:
		return "slot is NOT %s" % state_str
	return "slot is %s" % state_str


func get_keywords() -> Array[StringName]:
	return [Keywords.DEBUFF]
