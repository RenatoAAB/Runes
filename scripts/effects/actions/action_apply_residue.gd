class_name ActionApplyResidue
extends EffectAction

## Applies a runic residue to target slots.

@export var residue_id: String = ""
@export var duration: int = -1  ## -1 = permanent
@export var score_bonus: int = 0
@export var max_targets: int = 0  ## 0 = no limit, >0 = random pick up to N


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or residue_id.is_empty():
		return

	var actual_targets := targets
	if max_targets > 0 and actual_targets.size() > max_targets:
		var shuffled := actual_targets.duplicate()
		shuffled.shuffle()
		actual_targets = shuffled.slice(0, max_targets)

	for slot in actual_targets:
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_method("apply_residue"):
			var had_residue := slot.slot.has_specific_residue(residue_id)
			slot.slot.apply_residue(residue_id, duration, score_bonus)
			if residue_id == "mana_anomaly" and not had_residue and ctx.battle:
				ctx.battle.record_residue_created("mana_anomaly")
			if ctx.battle and ctx.battle.grid:
				ctx.battle.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	var residue_name = _format_residue_name(residue_id, false)
	var desc = "Apply %s" % residue_name
	if duration > 0:
		desc += " for %d round(s)" % duration
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.DEBUFF]
