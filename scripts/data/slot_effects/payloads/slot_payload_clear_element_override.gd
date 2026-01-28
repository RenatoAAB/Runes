class_name SlotPayloadClearElementOverride
extends SlotEffectPayload

## Clears any element override on the current rune.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not slot or not slot.rune:
		return
	slot.rune.clear_element_override()

func get_description() -> String:
	return "Restores rune elements"
