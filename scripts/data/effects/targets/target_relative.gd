class_name TargetRelative
extends EffectTarget

@export var relative_position: Vector2i

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets: Array[GridSlot] = []
	var target_position = source_slot.grid_position + relative_position
	var target_slot = context.grid.get_slot(target_position)
	if target_slot and not target_slot.is_empty():
		targets.append(target_slot)
	return targets

func get_description() -> String:
	return "Relative (%d, %d)" % [relative_position.x, relative_position.y]
