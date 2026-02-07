class_name SlotPayloadTransmuterSet
extends SlotEffectPayload

## Permanently adds one element from the previously activated rune.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	var previous = context.get_last_activated_elements()
	if previous.is_empty():
		return
	var current = slot.rune.get_base_elements()
	var candidates: Array[GameEnums.Element] = []
	for elem in previous:
		if elem not in current:
			candidates.append(elem)
	if candidates.is_empty():
		return
	var picked = candidates[randi_range(0, candidates.size() - 1)]
	slot.rune.add_permanent_element(picked)

func get_description() -> String:
	return "Permanently gains one element from the previously activated rune"
