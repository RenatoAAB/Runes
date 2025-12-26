class_name PayloadPreserveSlot
extends EffectPayload

## Makes target slots preserve rune charges (don't consume activations).
## This is the "Infinite use" effect from GDD 3.3.

@export var preserve_charges: bool = true
@export var protect_fragile: bool = false  ## Also protects Glass runes from breaking

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for grid_slot in targets:
		# Access the SlotInstance inside GridSlot and set temp flags
		grid_slot.slot.temp_preserves_charges = preserve_charges
		grid_slot.slot.temp_protects_fragile = protect_fragile
		
		# Notify UI of slot change
		context.grid.slot_changed.emit(grid_slot.grid_position)

func get_description() -> String:
	var desc = ""
	if preserve_charges:
		desc = "Runes in this slot don't consume activations"
	if protect_fragile:
		if desc.length() > 0:
			desc += " and "
		desc += "Fragile runes don't break here"
	return desc

func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF]
