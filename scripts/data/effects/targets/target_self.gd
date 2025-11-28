class_name TargetSelf
extends EffectTarget

func get_targets(source_rune: RuneInstance, grid_manager: GridManager, source_slot: GridSlot) -> Array[GridSlot]:
	return [source_slot]
