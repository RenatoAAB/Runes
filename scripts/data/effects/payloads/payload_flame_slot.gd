class_name PayloadFlameSlot
extends EffectPayload

## Makes the slot "burning" - runes have their score multiplied.

@export var state_id: String = "burning"
@export var duration: int = 999999
@export var score_multiplier: float = 1.2

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		# We store the multiplier as a score bonus that gets applied
		# Since slot states can give score_bonus, we use a special calculation
		slot.add_state(state_id, duration, 0, 0)
		# The actual multiplier effect needs to be checked during score calculation
		# For now, we'll mark the state and handle it in the rune score calculation
		context.grid.slot_changed.emit(slot.grid_position)
		print("Set slot on fire at %s" % str(slot.grid_position))

func get_description() -> String:
	return "Sets slot on fire (%.1fx score multiplier)" % score_multiplier
