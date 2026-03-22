class_name ActionClearResidue
extends EffectAction

## Clears residues from target slots.

@export var specific_residue_ids: Array[String] = []  ## Empty = clear all


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx:
		return

	for slot in targets:
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_method("clear_residues"):
			if specific_residue_ids.is_empty():
				slot.slot.clear_residues()
			else:
				for rid in specific_residue_ids:
					if slot.slot.has_method("clear_residue"):
						slot.slot.clear_residue(rid)


func get_description() -> String:
	if specific_residue_ids.is_empty():
		return "Clear all residues from targets"
	return "Clear %s from targets" % ", ".join(specific_residue_ids)


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF]
