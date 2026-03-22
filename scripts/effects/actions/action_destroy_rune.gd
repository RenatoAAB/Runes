class_name ActionDestroyRune
extends EffectAction

## Destroys runes in target slots.

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		var rune = slot.rune
		if ctx.battle.event_bus:
			ctx.battle.event_bus.notify_rune_destroyed(slot, rune)
		else:
			ctx.battle.on_rune_destroyed(slot, rune)
		slot.remove_rune()
		ctx.battle.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	return "Destroys target runes"


func get_keywords() -> Array[StringName]:
	return [Keywords.DESTROY]
