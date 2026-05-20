class_name ActionDestroyClusterAndBuff
extends EffectAction

## Destroys the source rune and its neighbors, then grants permanent
## activation bonus to all remaining runes on the panel. Used by Energy.

@export var activation_bonus: int = 1
@export var include_diagonals: bool = false


func execute(ctx: EffectContext, _targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, _targets)
	if not ctx or not ctx.battle or not ctx.source_slot or not ctx.battle.grid:
		return

	var slots_to_destroy: Array[GridSlot] = []
	slots_to_destroy.append(ctx.source_slot)
	slots_to_destroy.append_array(ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals))

	var destroyed: Dictionary = {}
	for slot in slots_to_destroy:
		if slot and not slot.is_empty():
			_destroy_slot(slot, ctx)
			destroyed[slot] = true

	if activation_bonus == 0:
		return

	for slot in ctx.battle.grid.grid:
		if slot.is_void() or slot.is_empty():
			continue
		if destroyed.has(slot):
			continue
		var mult = _get_enhancer_multiplier(slot)
		var final_bonus = activation_bonus * mult
		var current: int = slot.rune.permanent_buffs.get("activation_bonus", 0)
		slot.rune.permanent_buffs["activation_bonus"] = current + final_bonus
		EventBus.notify_buff_received(slot, slot.rune)


func _destroy_slot(slot: GridSlot, ctx: EffectContext) -> void:
	var rune: RuneInstance = slot.rune
	if ctx.battle.event_bus:
		ctx.battle.event_bus.notify_rune_destroyed(slot, rune)
	else:
		ctx.battle.on_rune_destroyed(slot, rune)
	slot.remove_rune()
	ctx.battle.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	return "Destroy this and adjacent runes, other runes gain +%d permanent activations" % activation_bonus


func get_keywords() -> Array[StringName]:
	return [Keywords.DESTROY, Keywords.BUFF, Keywords.CHARGED, Keywords.ALL]
