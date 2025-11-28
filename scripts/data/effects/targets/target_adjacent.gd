class_name TargetAdjacent
extends EffectTarget

@export var include_diagonals: bool = false
@export var include_self: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	if include_self:
		targets.append(source_slot)
	return targets

func get_description() -> String:
	var desc = "Adjacent"
	if include_diagonals:
		desc += " (incl. diag)"
	if include_self:
		desc += " + Self"
	return desc
