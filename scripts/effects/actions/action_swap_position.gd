class_name ActionSwapPosition
extends EffectAction

## Swaps source rune to an empty target slot.

enum SwapMode {
	FIRST,   ## First empty target
	RANDOM,  ## Random empty target
}

@export var swap_mode: SwapMode = SwapMode.FIRST


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.source_slot or not ctx.source_rune or not ctx.battle:
		return

	var empty_targets: Array[GridSlot] = []
	for slot in targets:
		if slot.is_empty() and not slot.is_void():
			empty_targets.append(slot)

	if empty_targets.is_empty():
		return

	var target_slot: GridSlot
	match swap_mode:
		SwapMode.FIRST:
			target_slot = empty_targets[0]
		SwapMode.RANDOM:
			target_slot = empty_targets[randi() % empty_targets.size()]

	# Move rune from source to target
	var rune = ctx.source_rune
	ctx.source_slot.remove_rune()
	target_slot.set_rune(rune)
	if ctx.battle.grid:
		ctx.battle.grid.slot_changed.emit(ctx.source_slot.grid_position)
		ctx.battle.grid.slot_changed.emit(target_slot.grid_position)


func get_description() -> String:
	match swap_mode:
		SwapMode.FIRST:
			return "Move to first empty target slot"
		SwapMode.RANDOM:
			return "Move to random empty target slot"
	return "Move to empty slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
