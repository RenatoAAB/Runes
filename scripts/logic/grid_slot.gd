class_name GridSlot
extends RefCounted

## Represents a single cell in the 5x5 grid.
## Holds a RuneInstance and manages temporary slot states (e.g., Scorched Earth).

var grid_position: Vector2i
var rune: RuneInstance = null

# Dictionary to hold active slot states. 
# Key: State ID (String), Value: Duration remaining (int)
var active_states: Dictionary = {}

func _init(pos: Vector2i):
	grid_position = pos

func is_empty() -> bool:
	return rune == null

func set_rune(new_rune: RuneInstance) -> void:
	rune = new_rune

func remove_rune() -> RuneInstance:
	var removed = rune
	rune = null
	return removed

# --- Slot State Logic ---

func add_state(state_id: String, duration: int) -> void:
	active_states[state_id] = duration

func has_state(state_id: String) -> bool:
	return active_states.has(state_id)

func process_states() -> void:
	var states_to_remove: Array[String] = []
	
	for state_id in active_states:
		active_states[state_id] -= 1
		if active_states[state_id] <= 0:
			states_to_remove.append(state_id)
	
	for state_id in states_to_remove:
		active_states.erase(state_id)
