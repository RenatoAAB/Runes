class_name SlotPayloadCreateRandomRuneIfEmpty
extends SlotEffectPayload

const RuneLibrary = preload("res://scripts/data/rune_library.gd")

## Creates a random rune in this slot if empty.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_void() or not slot.is_empty():
		return
	var candidates = RuneLibrary.get_all_runes()
	if candidates.is_empty():
		return
	var rune_data: RuneData = candidates[randi_range(0, candidates.size() - 1)]
	if not rune_data:
		return
	var instance = RuneInstance.new(rune_data)
	slot.set_rune(instance)
	if context.grid:
		context.grid.slot_changed.emit(slot.grid_position)
	if context.event_bus:
		context.event_bus.notify_rune_created(slot, instance)
	else:
		context.on_rune_created(slot, instance)

func get_description() -> String:
	return "If empty at round end, create a random rune"
