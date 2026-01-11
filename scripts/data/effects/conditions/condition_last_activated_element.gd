class_name ConditionLastActivatedElement
extends EffectCondition

## Returns true if the last activated rune had a specific element.
## Used for: Fogo (+20 if last was fire).

@export var required_element: GameEnums.Element = GameEnums.Element.FIRE
@export var check_base_elements: bool = true  ## If true, checks element composition

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var last_element = context.get_last_activated_element()
	if last_element == -1:
		return false
	
	if check_base_elements:
		return GameEnums.has_base_element(last_element, required_element)
	
	return last_element == required_element


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
	var elem_name = GameEnums.Element.keys()[required_element].capitalize()
	return "last activated rune was %s" % elem_name


func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
