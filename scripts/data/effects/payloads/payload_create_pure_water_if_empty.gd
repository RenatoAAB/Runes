class_name PayloadCreatePureWaterIfEmpty
extends EffectPayload

const RuneLibrary = preload("res://scripts/data/rune_library.gd")
const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Creates a random pure Water rune in the target slot if it is empty.
func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if not context:
		return
	var candidates = RuneLibrary.get_pure_runes_for_element(GameEnums.Element.WATER)
	for slot in targets:
		if slot.is_void() or not slot.is_empty():
			continue
		var rune_data: RuneData = _pick_candidate(candidates)
		if not rune_data:
			continue
		var instance = RuneInstance.new(rune_data)
		slot.set_rune(instance)
		if context.grid:
			context.grid.slot_changed.emit(slot.grid_position)
		if context.event_bus:
			context.event_bus.notify_rune_created(slot, instance)
		else:
			context.on_rune_created(slot, instance)
		print("Created Water rune at %s" % str(slot.grid_position))


func _pick_candidate(candidates: Array[RuneData]) -> RuneData:
	if candidates.is_empty():
		return null
	return candidates[randi_range(0, candidates.size() - 1)]


func get_description() -> String:
	var water_icon = ElementIcons.get_bbcode(GameEnums.Element.WATER)
	return "If target slot is empty, create a pure %s rune there" % water_icon


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.ELEMENT_TARGET]
