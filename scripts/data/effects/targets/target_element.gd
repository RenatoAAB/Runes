class_name TargetElement
extends EffectTarget

@export var target_element: GameEnums.Element = GameEnums.Element.NEUTRAL
@export var include_self: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets: Array[GridSlot] = []
	
	# Iterate through all slots in the grid
	for slot in context.grid.grid:
		if not slot.is_empty() and slot.rune.data.element == target_element:
			if slot == source_slot and not include_self:
				continue
			targets.append(slot)
			
	return targets

func get_description() -> String:
	var elem_name = GameEnums.Element.keys()[target_element].capitalize()
	var desc = "All %s Runes" % elem_name
	if include_self:
		desc += " (incl. Self)"
	else:
		desc += " (excl. Self)"
	return desc

func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_TARGET, Keywords.ALL]
