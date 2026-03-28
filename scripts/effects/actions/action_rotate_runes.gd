class_name ActionRotateRunes
extends EffectAction

## Rotates runes (and residues) in target slots.
## Used by Praia: "Rotacione as runas e residuos adjacentes no sentido anti-horário".

@export var clockwise: bool = false
@export var include_residues: bool = true


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return

	if targets.size() < 2:
		return

	# Collect runes and optionally residues from targets
	var runes: Array = []
	var residues: Array = []
	for slot in targets:
		runes.append(slot.remove_rune() if not slot.is_empty() else null)
		if include_residues and slot.slot:
			residues.append(slot.slot.get_residue_ids())
			slot.slot.clear_residues()
		else:
			residues.append([])

	# Rotate the arrays
	if clockwise:
		var last_rune = runes.pop_back()
		runes.push_front(last_rune)
		var last_res = residues.pop_back()
		residues.push_front(last_res)
	else:
		var first_rune = runes.pop_front()
		runes.push_back(first_rune)
		var first_res = residues.pop_front()
		residues.push_back(first_res)

	# Reassign
	for i in range(targets.size()):
		var slot = targets[i]
		if runes[i] != null:
			slot.set_rune(runes[i])
		if include_residues:
			for rid in residues[i]:
				slot.slot.apply_residue(rid)
		ctx.battle.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	var dir = "clockwise" if clockwise else "counter-clockwise"
	var res_str = " (including residues)" if include_residues else ""
	return "Rotate target runes %s%s" % [dir, res_str]


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
