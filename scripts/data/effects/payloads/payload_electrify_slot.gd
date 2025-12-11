class_name PayloadDoubleActivateSlot
extends EffectPayload

## Makes the slot "electrified" - runes are activated twice.

@export var state_id: String = "electrified"
@export var duration: int = 3

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, 0, 1) # +1 activation bonus
		context.grid.slot_changed.emit(slot.grid_position)
		print("Electrified slot at %s for %d turns" % [str(slot.grid_position), duration])

func get_description() -> String:
	return "Electrifies slot (runes activate twice, %d turns)" % duration
