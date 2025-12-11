class_name PayloadIlluminate
extends EffectPayload

## Illuminates target slots (adds activation bonus to runes placed there).

@export var state_id: String = "illuminated"
@export var duration: int = 5
@export var activation_bonus: int = 2

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, 0, activation_bonus)
		context.grid.slot_changed.emit(slot.grid_position)
		print("Illuminated slot at %s for %d turns" % [str(slot.grid_position), duration])

func get_description() -> String:
	return "Illuminates slots (+%d activations, %d turns)" % [activation_bonus, duration]
