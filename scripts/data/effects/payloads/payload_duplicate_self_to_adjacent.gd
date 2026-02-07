class_name PayloadDuplicateSelfToAdjacent
extends EffectPayload

## Duplicates the source rune into an adjacent empty slot.
## Priority order: Right, Down, Left, Up.

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context or not source_rune or not context.grid or not context.current_slot:
		return
	var origin: GridSlot = context.current_slot
	var origin_pos = origin.grid_position
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for dir in directions:
		var pos = origin_pos + dir
		if not context.grid.is_valid_coord(pos):
			continue
		var slot = context.grid.get_slot(pos)
		if slot.is_void() or not slot.is_empty():
			continue
		var clone = RuneInstance.new(source_rune.data)
		for key in source_rune.permanent_buffs.keys():
			clone.permanent_buffs[key] = source_rune.permanent_buffs[key]
		clone.permanent_elements = source_rune.permanent_elements.duplicate()
		slot.set_rune(clone)
		if context.grid:
			context.grid.slot_changed.emit(slot.grid_position)
		if context.event_bus:
			context.event_bus.notify_rune_created(slot, clone)
		else:
			context.on_rune_created(slot, clone)
		print("Duplicated %s to %s" % [source_rune.data.rune_name, str(pos)])
		return


func get_description() -> String:
	return "If there is an empty adjacent slot, duplicate this rune there (priority: right, down, left, up)"


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.NEIGHBORS, Keywords.ELEMENT_SYNC]
