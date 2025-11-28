class_name PayloadBuffSlot
extends EffectPayload

@export var state_id: String = "buffed"
@export var duration: int = 3
@export var score_bonus: int = 0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, score_bonus)
		# We need to notify UI. GridManager handles slot_changed signal usually for rune changes.
		# We might need a specific signal for state changes or just reuse slot_changed.
		context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	var desc = "Applies '%s' to slot for %d turns" % [state_id, duration]
	if score_bonus != 0:
		desc += " (Bonus: +%d Score)" % score_bonus
	return desc
