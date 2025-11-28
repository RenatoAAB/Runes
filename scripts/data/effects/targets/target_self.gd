class_name TargetSelf
extends EffectTarget

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return [source_slot]
