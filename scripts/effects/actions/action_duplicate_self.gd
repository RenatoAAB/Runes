class_name ActionDuplicateSelf
extends EffectAction

## Duplicates source rune into an empty target slot.
## Picks the first empty target (priority: order of targets array).

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.source_rune or not ctx.battle:
		return

	for slot in targets:
		if slot.is_void() or not slot.is_empty():
			continue
		var clone = RuneInstance.new(ctx.source_rune.data)
		# Copy permanent buffs
		for key in ctx.source_rune.permanent_buffs:
			clone.permanent_buffs[key] = ctx.source_rune.permanent_buffs[key]
		clone.permanent_elements = ctx.source_rune.permanent_elements.duplicate()
		slot.set_rune(clone)
		if ctx.battle.grid:
			ctx.battle.grid.slot_changed.emit(slot.grid_position)
		if ctx.battle.event_bus:
			ctx.battle.event_bus.notify_rune_created(slot, clone)
		else:
			ctx.battle.on_rune_created(slot, clone)
		break  # Only duplicate to first empty target


func get_description() -> String:
	return "Duplicate self to an empty adjacent slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE]
