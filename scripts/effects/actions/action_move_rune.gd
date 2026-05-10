class_name ActionMoveRune
extends EffectAction

## Moves runes from selected source slots to destination slots resolved by a selector.

enum TargetMode {
	FIRST,
	RANDOM,
}

@export var destination_selector: EffectSelector
@export var target_mode: TargetMode = TargetMode.FIRST
@export var allow_swap: bool = false


func get_preview_links(ctx: EffectContext, source_slots: Array[GridSlot]) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	if not ctx or not destination_selector:
		return links

	for source_slot in source_slots:
		if not source_slot or source_slot.is_void() or source_slot.is_empty():
			continue

		# For preview, bypass allow_swap so the intended destination is always shown.
		# Destination is relative to the activating rune (ctx), not the rune being moved.
		var candidates := destination_selector.select(ctx)
		for slot in candidates:
			if not slot or slot.is_void() or slot == source_slot:
				continue
			links.append({
				"source": source_slot.grid_position,
				"destination": slot.grid_position,
			})
			break

	return links


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle or not ctx.battle.grid or not destination_selector:
		return

	for source_slot in targets:
		if not source_slot or source_slot.is_void() or source_slot.is_empty():
			continue

		var destination_slot := _pick_destination(ctx, source_slot)
		if not destination_slot:
			continue

		var moved_rune := source_slot.rune
		if _move_between_slots(ctx.battle.grid, source_slot, destination_slot) and moved_rune:
			ctx.battle.record_rune_moved(moved_rune)


func _pick_destination(ctx: EffectContext, source_slot: GridSlot) -> GridSlot:
	# Destination is relative to the activating rune (ctx), not the rune being moved.
	var candidates := destination_selector.select(ctx)
	var valid_slots: Array[GridSlot] = []

	for slot in candidates:
		if not slot or slot.is_void() or slot == source_slot:
			continue
		if not allow_swap and not slot.is_empty():
			continue
		valid_slots.append(slot)

	if valid_slots.is_empty():
		return null

	match target_mode:
		TargetMode.RANDOM:
			return valid_slots[randi() % valid_slots.size()]
		_:
			return valid_slots[0]


func _move_between_slots(grid: GridManager, source_slot: GridSlot, destination_slot: GridSlot) -> bool:
	if source_slot.has_state("petrified") or (source_slot.slot and source_slot.slot.is_petrified()):
		return false

	if (destination_slot.has_state("petrified") or (destination_slot.slot and destination_slot.slot.is_petrified())) and not destination_slot.is_empty():
		return false

	var source_rune := source_slot.remove_rune()
	var destination_rune := destination_slot.remove_rune()

	source_slot.set_rune(destination_rune)
	destination_slot.set_rune(source_rune)

	grid.slot_changed.emit(source_slot.grid_position)
	grid.slot_changed.emit(destination_slot.grid_position)
	return true


func get_description() -> String:
	var destination_desc := "target slot"
	if destination_selector:
		destination_desc = destination_selector.get_description().to_lower().strip_edges()

	var occupancy_desc := "can swap" if allow_swap else "empty only"
	if target_mode == TargetMode.RANDOM:
		return "Move rune in target to a random %s (%s)" % [destination_desc, occupancy_desc]

	return "Move rune in target to %s (%s)" % [destination_desc, occupancy_desc]


func get_description_colored(effect_index: int) -> String:
	var destination_desc := "target slot"
	if destination_selector:
		var raw := destination_selector.get_description().to_lower().strip_edges()
		destination_desc = EffectColors.colorize_text(raw, effect_index)

	var occupancy_desc := "can swap" if allow_swap else "empty only"
	if target_mode == TargetMode.RANDOM:
		return "Move rune in target to a random %s (%s)" % [destination_desc, occupancy_desc]

	return "Move rune in target to %s (%s)" % [destination_desc, occupancy_desc]


func get_description_with_context(ctx: EffectContext) -> String:
	return get_description_colored(ctx.effect_index)


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]