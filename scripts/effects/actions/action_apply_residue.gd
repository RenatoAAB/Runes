class_name ActionApplyResidue
extends EffectAction

## Applies a runic residue to target slots.

@export var residue_id: String = ""
@export var duration: int = -1  ## -1 = permanent
@export var score_bonus: int = 0


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or residue_id.is_empty():
		return

	for slot in targets:
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_method("apply_residue"):
			slot.slot.apply_residue(residue_id, duration, score_bonus)


func get_description() -> String:
	var desc = "Apply %s" % residue_id
	if duration > 0:
		desc += " for %d round(s)" % duration
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.DEBUFF]
