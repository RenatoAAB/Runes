class_name PayloadWetSlot
extends EffectPayload

## Makes the slot "wet" - runes placed gain extra activations.

@export var state_id: String = "wet"
@export var duration: int = 3
@export var activation_bonus: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, 0, activation_bonus)
		context.grid.slot_changed.emit(slot.grid_position)
		print("Made slot wet at %s for %d turns (+%d activation)" % [str(slot.grid_position), duration, activation_bonus])

func get_description() -> String:
	return "Wets slot (+%d activation, %d turns)" % [activation_bonus, duration]
