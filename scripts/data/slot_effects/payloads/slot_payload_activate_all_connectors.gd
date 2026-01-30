class_name SlotPayloadActivateAllConnectors
extends SlotEffectPayload

## Activates all other connector slots once (no recursion).

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not context.grid or not slot:
		return
	if not context.grid.slot_processor:
		return
	if context.grid.slot_processor.get_global_data("connector_chain_active", false):
		return
	context.grid.slot_processor.set_global_data("connector_chain_active", true)
	for other_slot in context.grid.grid:
		if not other_slot or other_slot == slot:
			continue
		if not other_slot.slot or not other_slot.slot.data:
			continue
		if other_slot.slot.data.id != "slot_conector":
			continue
		if other_slot.is_empty():
			continue
		var other_rune = other_slot.rune
		if not other_rune.can_activate():
			continue
		var activations_before = other_rune.current_activations
		var should_preserve = other_slot.preserves_charges()
		other_rune.on_activate(context, other_slot)
		other_slot.on_rune_activation(context)
		if should_preserve:
			other_rune.current_activations = activations_before
	context.grid.slot_processor.set_global_data("connector_chain_active", false)

func get_description() -> String:
	return "Activates all other connector runes"
