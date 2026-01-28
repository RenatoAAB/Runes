class_name SlotPayloadTransmuterSet
extends SlotEffectPayload

## Sets the current rune's elements to the previous activated rune's elements.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	var previous = context.get_last_activated_elements()
	if previous.is_empty():
		return
	slot.rune.set_element_override(previous)

func get_description() -> String:
	return "Adopts the elements of the previously activated rune"
