class_name ActionCreateRandomRune
extends EffectAction

## Creates a random rune of specified element(s) in empty target slots.
## Unlike ActionCreateRune which picks from pure element runes,
## this picks from ALL runes containing the specified element.
## Used by Caos (spirit rune), Djinn (air rune), Entropia (random).

@export var allowed_elements: Array[GameEnums.Element] = []
@export var random_any: bool = false  ## Ignore element filter, pick any rune


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	var candidates: Array[RuneData] = []
	if random_any:
		candidates = RuneLibrary.get_all_runes()
	else:
		for elem in allowed_elements:
			var elem_runes = RuneLibrary.get_runes_for_element(elem)
			for rd in elem_runes:
				if rd not in candidates:
					candidates.append(rd)

	if candidates.is_empty():
		return

	for slot in targets:
		if slot.is_void() or not slot.is_empty():
			continue
		var rune_data: RuneData = candidates[randi_range(0, candidates.size() - 1)]
		var instance = RuneInstance.new(rune_data)
		slot.set_rune(instance)
		if ctx.battle.grid:
			ctx.battle.grid.slot_changed.emit(slot.grid_position)
		if ctx.battle.event_bus:
			ctx.battle.event_bus.notify_rune_created(slot, instance)
		else:
			ctx.battle.on_rune_created(slot, instance)
		break  # Only create one rune


func get_description() -> String:
	if random_any:
		return "Create a random rune in empty target"
	if allowed_elements.size() == 1:
		return "Create a random %s rune in empty target" % ElementIcons.get_bbcode(allowed_elements[0])
	return "Create a random rune in empty target"


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.RANDOM]
