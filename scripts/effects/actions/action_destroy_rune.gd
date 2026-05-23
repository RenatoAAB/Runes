class_name ActionDestroyRune
extends EffectAction

## Destroys runes in target slots.
## When max_targets > 0, a random subset of that size is picked from targets.

@export var max_targets: int = 0  ## 0 = destroy all targets, >0 = random pick N


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	var actual_targets := targets
	if max_targets > 0 and actual_targets.size() > max_targets:
		var shuffled := actual_targets.duplicate()
		shuffled.shuffle()
		actual_targets = shuffled.slice(0, max_targets)

	for slot in actual_targets:
		if slot.is_empty():
			continue
		var rune = slot.rune
		if ctx.battle.event_bus:
			ctx.battle.event_bus.notify_rune_destroyed(slot, rune)
		else:
			ctx.battle.on_rune_destroyed(slot, rune)
		slot.remove_rune(true)
		ctx.battle.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	return "Destroys target runes"


func get_keywords() -> Array[StringName]:
	return [Keywords.DESTROY]
