class_name TargetSequence
extends EffectTarget

enum Direction {
	PREVIOUS,
	NEXT,
	BOTH
}

@export var direction: Direction = Direction.NEXT
@export var include_self: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var targets: Array[GridSlot] = []
	var current_idx = source_slot.grid_position.y * GridManager.GRID_SIZE + source_slot.grid_position.x
	
	var indices_to_check = []
	if direction == Direction.PREVIOUS or direction == Direction.BOTH:
		indices_to_check.append(current_idx - 1)
	if direction == Direction.NEXT or direction == Direction.BOTH:
		indices_to_check.append(current_idx + 1)
		
	for idx in indices_to_check:
		if idx >= 0 and idx < GridManager.GRID_SIZE * GridManager.GRID_SIZE:
			var y = idx / GridManager.GRID_SIZE
			var x = idx % GridManager.GRID_SIZE
			var slot = context.grid.get_slot(Vector2i(x, y))
			if slot:
				targets.append(slot)
				
	if include_self:
		targets.append(source_slot)
		
	return targets

func get_description() -> String:
	var desc = ""
	match direction:
		Direction.PREVIOUS: desc = "Previous Slot"
		Direction.NEXT: desc = "Next Slot"
		Direction.BOTH: desc = "Prev & Next Slots"
	
	if include_self:
		desc += " + Self"
	return desc

func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
