class_name TargetSelf
extends EffectTarget

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return [source_slot]

func get_description() -> String:
	return "Self"

func get_keywords() -> Array[StringName]:
	return [Keywords.SELF]
