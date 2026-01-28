class_name SlotEffectCondition
extends Resource

## Base class for slot effect conditions.

func evaluate(_context: BattleContext, _slot: GridSlot) -> bool:
	return true

func get_description() -> String:
	return "Always"

func get_keywords() -> Array[StringName]:
	return []
