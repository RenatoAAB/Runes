class_name PayloadCreatePureElementIfEmpty
extends EffectPayload

const RuneLibrary = preload("res://scripts/data/rune_library.gd")
const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Creates a pure rune of the configured element in empty target slots.
## Optionally grants a permanent activation bonus to the created rune.
@export var element: GameEnums.Element = GameEnums.Element.WATER
@export var activation_bonus: int = 0

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if not context:
		return
	var candidates = RuneLibrary.get_pure_runes_for_element(element)
	for slot in targets:
		if slot.is_void() or not slot.is_empty():
			continue
		var rune_data: RuneData = _pick_candidate(candidates)
		if not rune_data:
			continue
		var instance = RuneInstance.new(rune_data)
		if activation_bonus != 0:
			var mult = _get_enhancer_multiplier(slot)
			var final_bonus = activation_bonus * mult
			instance.permanent_buffs["activation_bonus"] = instance.permanent_buffs.get("activation_bonus", 0) + final_bonus
		slot.set_rune(instance)
		if context.grid:
			context.grid.slot_changed.emit(slot.grid_position)
		if context.event_bus:
			context.event_bus.notify_rune_created(slot, instance)
		else:
			context.on_rune_created(slot, instance)
		print("Created %s rune at %s" % [GameEnums.Element.keys()[element], str(slot.grid_position)])


func _pick_candidate(candidates: Array[RuneData]) -> RuneData:
	if candidates.is_empty():
		return null
	return candidates[randi_range(0, candidates.size() - 1)]


func get_description() -> String:
	var icon = ElementIcons.get_bbcode(element)
	var desc = "If target slot is empty, create a pure %s rune there" % icon
	if activation_bonus != 0:
		desc += " with +%d permanent activation" % activation_bonus
	return desc


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.CREATE, Keywords.ELEMENT_TARGET]
	if activation_bonus != 0:
		kw.append(Keywords.BUFF)
	return kw
