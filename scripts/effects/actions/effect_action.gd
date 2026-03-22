class_name EffectAction
extends Resource

## Base class for the action performed by a GameEffect.
## Actions use ValueResolver for dynamic values and report value source slots for highlights.

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	pass


func get_description() -> String:
	return ""


## Returns description with resolved runtime values when context is available.
## Override in actions that display dynamic numerical values.
func get_description_with_context(ctx: EffectContext) -> String:
	return get_description()


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	return []


func get_keywords() -> Array[StringName]:
	return []


## Returns buff multiplier for runes in an Enhancer slot.
func _get_enhancer_multiplier(target_slot: GridSlot) -> int:
	if not target_slot or not target_slot.slot or not target_slot.slot.data:
		return 1
	return 2 if target_slot.slot.data.id == "slot_enhancer" else 1
