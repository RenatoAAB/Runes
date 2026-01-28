class_name SlotPayloadCharger
extends SlotEffectPayload

## Grants +1 activation to the rune above this slot.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not context.grid or not slot:
		return
	var above_coord = slot.grid_position + Vector2i.UP
	var above_slot = context.grid.get_slot(above_coord)
	if not above_slot or above_slot.is_empty():
		return
	var target_rune = above_slot.rune
	var current = target_rune.stat_modifiers.get("activation_bonus", 0)
	target_rune.stat_modifiers["activation_bonus"] = current + 1

func get_description() -> String:
	return "Rune above gains +1 activation"
