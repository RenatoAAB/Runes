class_name PayloadPetrifySlot
extends EffectPayload

## Permanently petrifies a slot - the rune cannot be moved and the state never expires.

@export var state_id: String = "petrified"

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if slot.slot and slot.slot.data and slot.slot.data.id == "slot_distiller":
			continue
		# Add state with very long duration (effectively permanent)
		slot.add_state(state_id, 999999, 0, 0)
		if not slot.is_empty():
			slot.rune.is_disabled = false # Still activates, just can't be moved
		context.grid.slot_changed.emit(slot.grid_position)
		print("Petrified slot at %s" % str(slot.grid_position))

func get_description() -> String:
	return "Petrifies slot permanently (rune cannot be moved)"

func get_keywords() -> Array[StringName]:
	return [Keywords.PETRIFIED]
