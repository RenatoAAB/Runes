class_name ActionCreateRandomRune
extends EffectAction

## Creates a random rune of specified element(s) in empty target slots.
## Unlike ActionCreateRune which picks from pure element runes,
## this picks from ALL runes containing the specified element.
## Used by Caos (spirit rune), Djinn (air rune), Entropia (random).

@export var allowed_elements: Array[GameEnums.Element] = []
@export var random_any: bool = false  ## Ignore element filter, pick any rune
@export var min_rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	var candidates: Array[RuneData] = []
	if random_any:
		for rd in RuneLibrary.get_all_runes():
			if rd and rd.rarity >= min_rarity:
				candidates.append(rd)
	else:
		for elem in allowed_elements:
			var elem_runes = RuneLibrary.get_runes_for_element(elem)
			for rd in elem_runes:
				if rd and rd.rarity >= min_rarity and rd not in candidates:
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
	var rarity_suffix := ""
	if min_rarity > GameEnums.Rarity.COMMON:
		rarity_suffix = " (%s+)" % TooltipTexts.get_rarity_name(min_rarity)

	if random_any:
		return "Create a random rune%s in empty target" % rarity_suffix
	if allowed_elements.size() == 1:
		return "Create a random %s rune%s in empty target" % [ElementIcons.get_bbcode(allowed_elements[0]), rarity_suffix]
	return "Create a random rune%s in empty target" % rarity_suffix


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.RANDOM]
