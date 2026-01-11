class_name TargetEmptyInPanel
extends EffectTarget

## Targets empty slots in the panel.
## Used for: Poeira (swap to random empty), Golem (create in corner empty).

enum SelectionMode {
	ALL,        ## All empty slots
	FIRST,      ## First empty slot found
	RANDOM,     ## Random empty slot
	CORNERS,    ## Only corner empty slots
	EDGES,      ## Only edge empty slots
	ADJACENT    ## Only adjacent empty slots
}

@export var selection_mode: SelectionMode = SelectionMode.ALL

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var empty_slots: Array[GridSlot] = []
	var grid_size = GridManager.GRID_SIZE
	
	match selection_mode:
		SelectionMode.ALL:
			for slot in context.grid.grid:
				if slot.is_empty():
					empty_slots.append(slot)
		
		SelectionMode.FIRST:
			for slot in context.grid.grid:
				if slot.is_empty():
					return [slot]
		
		SelectionMode.RANDOM:
			var all_empty: Array[GridSlot] = []
			for slot in context.grid.grid:
				if slot.is_empty():
					all_empty.append(slot)
			if all_empty.size() > 0:
				return [all_empty[randi() % all_empty.size()]]
		
		SelectionMode.CORNERS:
			var corners = [
				Vector2i(0, 0),
				Vector2i(grid_size - 1, 0),
				Vector2i(0, grid_size - 1),
				Vector2i(grid_size - 1, grid_size - 1)
			]
			for pos in corners:
				var slot = context.grid.get_slot(pos)
				if slot and slot.is_empty():
					empty_slots.append(slot)
		
		SelectionMode.EDGES:
			for slot in context.grid.grid:
				var pos = slot.grid_position
				if pos.x == 0 or pos.x == grid_size - 1 or pos.y == 0 or pos.y == grid_size - 1:
					if slot.is_empty():
						empty_slots.append(slot)
		
		SelectionMode.ADJACENT:
			var neighbors = context.grid.get_neighbors(source_slot.grid_position, false)
			for slot in neighbors:
				if slot.is_empty():
					empty_slots.append(slot)
	
	return empty_slots


func get_description() -> String:
	match selection_mode:
		SelectionMode.ALL:
			return "All empty slots"
		SelectionMode.FIRST:
			return "First empty slot"
		SelectionMode.RANDOM:
			return "Random empty slot"
		SelectionMode.CORNERS:
			return "Empty corner slot"
		SelectionMode.EDGES:
			return "Empty edge slot"
		SelectionMode.ADJACENT:
			return "Empty adjacent slot"
	return "Empty slots"


func get_keywords() -> Array[StringName]:
	return [Keywords.NEIGHBORS]
