class_name PayloadApplyResidue
extends EffectPayload

## Applies a residue state to target slots.

@export var state_id: String = "petrified"
@export var duration: int = -1  # -1 = permanent
@export var score_bonus: int = 0
@export var activation_bonus: int = 0
@export var multiplier_bonus: float = 0.0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if slot.slot and slot.slot.data and slot.slot.data.id == "slot_distiller":
			continue
		var final_duration = 999999 if duration < 0 else duration
		slot.add_state(state_id, final_duration, score_bonus, activation_bonus, multiplier_bonus)
		context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	return "Applies residue: %s" % state_id
