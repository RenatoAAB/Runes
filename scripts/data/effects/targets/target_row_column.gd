class_name TargetRowColumn
extends EffectTarget

enum Axis {
	ROW,
	COLUMN,
	BOTH
}

@export var axis: Axis = Axis.ROW
@export var include_self: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets: Array[GridSlot] = []
	var pos = source_slot.grid_position
	
	if axis == Axis.ROW or axis == Axis.BOTH:
		var row = context.grid.get_row(pos.y)
		targets.append_array(row)
		
	if axis == Axis.COLUMN or axis == Axis.BOTH:
		var col = context.grid.get_column(pos.x)
		# Avoid duplicates if BOTH is selected (center slot is in both)
		for slot in col:
			if not targets.has(slot):
				targets.append(slot)
	
	if not include_self:
		targets.erase(source_slot)
	elif not targets.has(source_slot):
		# Should be there if row/col includes it, but safety check
		targets.append(source_slot)
	
	return targets

func get_description() -> String:
	var desc = ""
	match axis:
		Axis.ROW: desc = "Row"
		Axis.COLUMN: desc = "Column"
		Axis.BOTH: desc = "Row & Column"
	
	if include_self:
		desc += " (incl. Self)"
	else:
		desc += " (excl. Self)"
	return desc
