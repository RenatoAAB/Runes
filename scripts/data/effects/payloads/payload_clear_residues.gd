class_name PayloadClearResidues
extends EffectPayload

## Clears residue states from target slots.
## If state_ids is empty, clears all states.

@export var state_ids: Array[String] = []

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if state_ids.is_empty():
			slot.clear_states()
		else:
			for state_id in state_ids:
				slot.remove_state(state_id)
		context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	return "Clears residues from target slots"
