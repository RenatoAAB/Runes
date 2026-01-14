class_name ConditionLastActivatedElement
extends EffectCondition

const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Returns true if the last activated rune had a specific element.
## Used for: Fogo (+20 if last was fire).

@export var required_element: GameEnums.Element = GameEnums.Element.FIRE

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var last_elements = context.get_last_activated_elements()
	if last_elements.is_empty():
		return false
	return required_element in last_elements


func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	# The relevant slot is the previously activated one
	if context.activation_history.size() > 0:
		var last_entry = context.activation_history[-1]
		var pos = last_entry.get("slot_position", Vector2i(-1, -1))
		if pos.x >= 0:
			var slot = context.grid.get_slot(pos)
			if slot:
				return [slot]
	return []


func get_description() -> String:
	var elem_icon = ElementIcons.get_bbcode(required_element)
	return "last activated rune was %s" % elem_icon


func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
