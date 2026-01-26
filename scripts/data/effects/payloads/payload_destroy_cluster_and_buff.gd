class_name PayloadDestroyClusterAndBuff
extends EffectPayload

## Destroys the source rune and its neighbors, then buffs all other runes with permanent activations.
@export var activation_bonus: int = 1
@export var include_diagonals: bool = false

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context or not context.current_slot:
		return
	var slots_to_destroy: Array[GridSlot] = []
	slots_to_destroy.append(context.current_slot)
	slots_to_destroy.append_array(context.grid.get_neighbors(context.current_slot.grid_position, include_diagonals))
	var destroyed: Dictionary = {}
	for slot in slots_to_destroy:
		if slot and not slot.is_empty():
			_destroy_slot(slot, context)
			destroyed[slot] = true
	if activation_bonus == 0:
		return
	for slot in context.grid.grid:
		if slot.is_void() or slot.is_empty():
			continue
		if destroyed.has(slot):
			continue
		var target_rune: RuneInstance = slot.rune
		var current_bonus: int = target_rune.permanent_buffs.get("activation_bonus", 0)
		target_rune.permanent_buffs["activation_bonus"] = current_bonus + activation_bonus
		print("%s gained +%d permanent activation(s) from %s" % [target_rune.data.rune_name, activation_bonus, source_rune.data.rune_name])


func _destroy_slot(slot: GridSlot, context: BattleContext) -> void:
	var rune: RuneInstance = slot.rune
	if context.event_bus:
		context.event_bus.notify_rune_destroyed(slot, rune)
	else:
		context.on_rune_destroyed(slot, rune)
	slot.remove_rune()
	context.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	return "Destroy this and adjacent runes, other runes gain +%d permanent activations" % activation_bonus


func get_keywords() -> Array[StringName]:
	return [Keywords.DESTROY, Keywords.BUFF, Keywords.CHARGED, Keywords.ALL]
