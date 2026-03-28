class_name ActionTransformResidue
extends EffectAction

## Transforms one type of residue into another in target slots.
## Used by Mudança: "Transforme anomalias mânicas adjacentes em resíduos mânicos".

@export var from_residue_id: String = "mana_anomaly"
@export var to_residue_id: String = "mana_residue"


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or from_residue_id.is_empty() or to_residue_id.is_empty():
		return

	var transformed_count = 0
	for slot in targets:
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_specific_residue(from_residue_id):
			slot.slot.clear_residue(from_residue_id)
			slot.slot.apply_residue(to_residue_id)
			transformed_count += 1
			if ctx.battle and ctx.battle.grid:
				ctx.battle.grid.slot_changed.emit(slot.grid_position)

	if ctx.source_rune:
		ctx.source_rune.last_effect_success = transformed_count > 0


func get_description() -> String:
	return "Transform %s into %s" % [from_residue_id, to_residue_id]


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.DEBUFF]
