class_name TargetDirectionalSlot
extends EffectTarget

## Targets a slot in a specific direction relative to source.
## Used for: Ninfa (below), payloads that affect slot above/below.

enum Direction {
	ABOVE,
	BELOW,
	LEFT,
	RIGHT
}

@export var direction: Direction = Direction.BELOW
@export var include_if_empty: bool = true

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var pos = source_slot.grid_position
	var target_pos: Vector2i
	
	match direction:
		Direction.ABOVE:
			if pos.y <= 0:
				return []
			target_pos = Vector2i(pos.x, pos.y - 1)
		Direction.BELOW:
			if pos.y >= GridManager.GRID_SIZE - 1:
				return []
			target_pos = Vector2i(pos.x, pos.y + 1)
		Direction.LEFT:
			if pos.x <= 0:
				return []
			target_pos = Vector2i(pos.x - 1, pos.y)
		Direction.RIGHT:
			if pos.x >= GridManager.GRID_SIZE - 1:
				return []
			target_pos = Vector2i(pos.x + 1, pos.y)
	
	var target_slot = context.grid.get_slot(target_pos)
	if not target_slot:
		return []
	
	if target_slot.is_empty() and not include_if_empty:
		return []
	
	return [target_slot]


func get_description() -> String:
	match direction:
		Direction.ABOVE:
			return "Slot above"
		Direction.BELOW:
			return "Slot below"
		Direction.LEFT:
			return "Slot to left"
		Direction.RIGHT:
			return "Slot to right"
	return "Directional slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.NEIGHBORS]
