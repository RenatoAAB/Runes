class_name SlotPayloadPurifierNext
extends SlotEffectPayload

## Clears residues on the next slot in reader order.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not context.grid:
		return
	var next_index = context.current_step_index + 1
	var coord = context.get_reader_coord(next_index)
	if coord == Vector2i(-1, -1):
		return
	var target = context.grid.get_slot(coord)
	if not target:
		return
	target.clear_states()
	context.grid.slot_changed.emit(target.grid_position)

func get_description() -> String:
	return "Clears residues from the next slot"
