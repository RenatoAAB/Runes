class_name SlotEffectPayload
extends Resource

## Base class for slot effect payloads.

func execute(_context: BattleContext, _slot: GridSlot) -> void:
	pass

func get_description() -> String:
	return ""

func get_keywords() -> Array[StringName]:
	return []
