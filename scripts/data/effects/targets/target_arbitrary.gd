class_name TargetArbitrary
extends EffectTarget

## Targets specific relative coordinates defined by a list of Vector2i offsets.
## Example: (0, -1) is Up, (-1, 0) is Left.

@export var offsets: Array[Vector2i]
@export var include_self: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets: Array[GridSlot] = []
	var origin = source_slot.grid_position
	
	for offset in offsets:
		var target_pos = origin + offset
		# Note: In Godot Y is down. -1 Y is up.
		if context.grid.is_valid_coord(target_pos):
			targets.append(context.grid.get_slot(target_pos))
			
	if include_self:
		if not targets.has(source_slot):
			targets.append(source_slot)
			
	return targets

func get_description() -> String:
	return "Custom Area (%d offsets)" % offsets.size()
