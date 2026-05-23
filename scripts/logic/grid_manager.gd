class_name GridManager
extends Node

## Manages the 5x5 Grid of GridSlots.
## Handles placement, movement, and coordinate queries.
## Emits PlanningEvents through EventBus for tracking and statistics.

const GRID_SIZE = 5

# 1D Array representing 5x5 grid. Index = y * WIDTH + x
var grid: Array[GridSlot] = []

signal slot_changed(coord: Vector2i)

const ResidueProcessor = preload("res://scripts/logic/residue_processor.gd")
const SlotProcessor = preload("res://scripts/logic/slot_processor.gd")

## Centralized residue processing
var residue_processor: ResidueProcessor = ResidueProcessor.new()

## Centralized slot effect processing
var slot_processor: SlotProcessor = SlotProcessor.new()

## Reference to EventBus (set in _ready)
var event_bus: Node = null

func _ready() -> void:
	_init_grid()
	# Try to get EventBus autoload
	if has_node("/root/EventBus"):
		event_bus = get_node("/root/EventBus")

func _init_grid() -> void:
	grid.clear()
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			grid.append(GridSlot.new(Vector2i(x, y)))

# --- Core Accessors ---

func get_slot(coord: Vector2i) -> GridSlot:
	if not is_valid_coord(coord):
		return null
	var index = coord.y * GRID_SIZE + coord.x
	return grid[index]

func is_valid_coord(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < GRID_SIZE and coord.y >= 0 and coord.y < GRID_SIZE

# --- Matrix Operations ---

func get_neighbors(coord: Vector2i, include_diagonals: bool = false) -> Array[GridSlot]:
	var neighbors: Array[GridSlot] = []
	var directions = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
	]
	
	if include_diagonals:
		directions.append_array([
			Vector2i(-1, -1), Vector2i(1, -1), 
			Vector2i(-1, 1), Vector2i(1, 1)
		])
		
	for dir in directions:
		var neighbor_coord = coord + dir
		if is_valid_coord(neighbor_coord):
			neighbors.append(get_slot(neighbor_coord))
			
	return neighbors

## Returns all slots that belong to the same Formação Rochosa as [coord].
## A formation is a group of 2+ orthogonally connected earth runes.
## Returns an empty array if the source slot has no earth rune or if the
## connected cluster is smaller than 2.
func get_earth_formation(coord: Vector2i) -> Array[GridSlot]:
	var source = get_slot(coord)
	if not source or source.is_empty():
		return []
	if not GameEnums.has_element(source.rune.get_elements(), GameEnums.Element.EARTH):
		return []

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [coord]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current in visited:
			continue
		visited[current] = true
		for neighbor in get_neighbors(current, false):
			if neighbor.is_void() or neighbor.is_empty():
				continue
			if neighbor.grid_position in visited:
				continue
			if GameEnums.has_element(neighbor.rune.get_elements(), GameEnums.Element.EARTH):
				queue.append(neighbor.grid_position)

	if visited.size() < 2:
		return []

	var result: Array[GridSlot] = []
	for v in visited.keys():
		result.append(get_slot(v))
	return result


func get_row(y: int) -> Array[GridSlot]:
	var row: Array[GridSlot] = []
	if y < 0 or y >= GRID_SIZE:
		return row
	
	for x in range(GRID_SIZE):
		row.append(get_slot(Vector2i(x, y)))
	return row

func get_column(x: int) -> Array[GridSlot]:
	var col: Array[GridSlot] = []
	if x < 0 or x >= GRID_SIZE:
		return col
		
	for y in range(GRID_SIZE):
		col.append(get_slot(Vector2i(x, y)))
	return col

# --- Manipulation ---

func place_rune(rune_data: RuneData, coord: Vector2i) -> bool:
	var slot = get_slot(coord)
	if slot and slot.is_empty():
		var instance = RuneInstance.new(rune_data)
		slot.set_rune(instance)
		slot_changed.emit(coord)
		
		# Emit planning event
		_emit_planning_event(
			PlanningEvent.ActionType.PLACE_RUNE,
			_get_rune_id(instance),
			"inventory",
			coord
		)
		return true
	return false


## Place an existing RuneInstance (used when moving from inventory)
func place_rune_instance(rune: RuneInstance, coord: Vector2i) -> bool:
	var slot = get_slot(coord)
	if slot and slot.is_empty():
		slot.set_rune(rune)
		slot_changed.emit(coord)
		
		# Emit planning event
		_emit_planning_event(
			PlanningEvent.ActionType.PLACE_RUNE,
			_get_rune_id(rune),
			"inventory",
			coord
		)
		return true
	return false


## Remove a rune from grid (move to inventory)
func remove_rune(coord: Vector2i) -> RuneInstance:
	var slot = get_slot(coord)
	if slot and not slot.is_empty():
		var rune = slot.remove_rune()
		slot_changed.emit(coord)
		
		# Emit planning event
		_emit_planning_event(
			PlanningEvent.ActionType.REMOVE_RUNE,
			_get_rune_id(rune),
			coord,
			"inventory"
		)
		return rune
	return null


func move_rune(from_coord: Vector2i, to_coord: Vector2i) -> bool:
	var from_slot = get_slot(from_coord)
	var to_slot = get_slot(to_coord)
	
	if not from_slot or not to_slot:
		return false
	
	# Check if source slot is petrified (cannot move rune out)
	if from_slot.has_state("petrified") or (from_slot.slot and from_slot.slot.is_petrified()):
		print("Cannot move rune: slot is petrified")
		return false
	
	# Check if target slot is petrified and has a rune (cannot swap)
	if (to_slot.has_state("petrified") or (to_slot.slot and to_slot.slot.is_petrified())) and not to_slot.is_empty():
		print("Cannot swap: target slot is petrified")
		return false
		
	# If moving to same slot, do nothing
	if from_coord == to_coord:
		return true
		
	if from_slot.is_empty():
		return false
	
	# Capture rune IDs before the move
	var rune_a_id = _get_rune_id(from_slot.rune)
	var rune_b_id = _get_rune_id(to_slot.rune) if to_slot.rune else &""
	var is_swap = not to_slot.is_empty()
		
	# Swap logic
	# Use remove_rune() to ensure buffs are stripped from the leaving runes
	var rune_a = from_slot.remove_rune()
	var rune_b = to_slot.remove_rune()
	
	# Use set_rune() to ensure buffs are applied from the entering slots
	from_slot.set_rune(rune_b)
	to_slot.set_rune(rune_a)
	
	slot_changed.emit(from_coord)
	slot_changed.emit(to_coord)
	
	# Emit planning event
	if is_swap:
		_emit_swap_event(rune_a_id, from_coord, rune_b_id, to_coord)
	else:
		_emit_planning_event(
			PlanningEvent.ActionType.MOVE_RUNE,
			rune_a_id,
			from_coord,
			to_coord
		)
	
	return true

func rotate_runes(slots: Array[GridSlot], clockwise: bool) -> void:
	if slots.size() < 2:
		return
	
	# Check if any slot is petrified - cannot rotate
	for slot in slots:
		if slot.has_state("petrified") or (slot.slot and slot.slot.is_petrified()):
			print("Cannot rotate: slot at %s is petrified" % str(slot.grid_position))
			return
	
	# Capture rune IDs before rotation
	var rune_ids: Array[StringName] = []
	for slot in slots:
		if slot.rune:
			rune_ids.append(_get_rune_id(slot.rune))
		
	var runes: Array[RuneInstance] = []
	for slot in slots:
		# Remove rune to strip buffs
		runes.append(slot.remove_rune()) 
		
	# Shift array
	if clockwise:
		var last = runes.pop_back()
		runes.push_front(last)
	else:
		var first = runes.pop_front()
		runes.push_back(first)
		
	# Reassign
	for i in range(slots.size()):
		slots[i].set_rune(runes[i])
		slot_changed.emit(slots[i].grid_position)
	
	# Emit planning event for rotation
	if event_bus:
		var event = PlanningEvent.new()
		event.action_type = PlanningEvent.ActionType.ROTATE_RUNES
		event.rune_ids = rune_ids
		event.source_location = slots[0].grid_position if slots.size() > 0 else Vector2i.ZERO
		event.destination_location = slots[slots.size() - 1].grid_position if slots.size() > 0 else Vector2i.ZERO
		event_bus.emit(event)


func process_round_end() -> void:
	for slot in grid:
		if residue_processor:
			residue_processor.handle_round_end_for_slot(slot, self)
		slot.process_states()
		if slot.rune:
			slot.rune.reset_state()
			# Re-apply slot buffs because reset_state cleared them
			slot.apply_buffs(slot.rune)
		# Notify UI of potential state changes (buff expiration)
		slot_changed.emit(slot.grid_position)


func clear_grid(reset_slot_types: bool = false) -> void:
	for slot in grid:
		if reset_slot_types:
			# Recreate slot runtime data to remove applied modifiers and permanent metas.
			slot.set_slot(SlotInstance.new())
		else:
			slot.clear_states()
		if not slot.is_empty():
			slot.remove_rune()
		slot_changed.emit(slot.grid_position)


# --- Event Emission Helpers ---

func _get_rune_id(rune: RuneInstance) -> StringName:
	if not rune or not rune.data:
		return &""
	if rune.data.id and not rune.data.id.is_empty():
		return StringName(rune.data.id)
	return StringName(rune.data.rune_name)


func _emit_planning_event(action_type: PlanningEvent.ActionType, rune_id: StringName, source: Variant, destination: Variant) -> void:
	if not event_bus:
		return
	
	var event = PlanningEvent.new()
	event.action_type = action_type
	if rune_id:
		event.rune_ids.append(rune_id)
	event.source_location = source
	event.destination_location = destination
	event_bus.emit(event)


func _emit_swap_event(rune_a_id: StringName, loc_a: Vector2i, rune_b_id: StringName, loc_b: Vector2i) -> void:
	if not event_bus:
		return
	
	var event = PlanningEvent.new()
	event.action_type = PlanningEvent.ActionType.SWAP_RUNES
	event.rune_ids.append(rune_a_id)
	event.rune_ids.append(rune_b_id)
	event.source_location = loc_a
	event.destination_location = loc_b
	event.swap_source = loc_b
	event_bus.emit(event)
