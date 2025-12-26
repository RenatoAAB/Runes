class_name PayloadBlockConditions
extends EffectPayload

## Applies a slot state that blocks conditional effects from runes.

@export var state_id: String = "lead_residue"
@export var duration: int = 999999

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		slot.add_state(state_id, duration, 0, 0)
		context.grid.slot_changed.emit(slot.grid_position)
		print("Fool's Gold: Applied lead residue to slot at %s" % str(slot.grid_position))

func get_description() -> String:
	return "Leaves lead residue (blocks conditional effects)"

func get_keywords() -> Array[StringName]:
	return [Keywords.DEBUFF, Keywords.CURSED]
