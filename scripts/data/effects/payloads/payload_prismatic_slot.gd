class_name PayloadPrismaticSlot
extends EffectPayload

## Makes the slot prismatic - activates any slot condition for runes placed there.

@export var state_id: String = "prismatic"
@export var duration: int = 999999

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, 0, 0)
		context.grid.slot_changed.emit(slot.grid_position)
		print("Crystal: Made slot prismatic at %s" % str(slot.grid_position))

func get_description() -> String:
	return "Makes slot prismatic (activates any condition)"
