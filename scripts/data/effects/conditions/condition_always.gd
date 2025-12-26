class_name ConditionAlways
extends EffectCondition

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return true

func get_description() -> String:
	return "Always"

func get_keywords() -> Array[StringName]:
	return []
