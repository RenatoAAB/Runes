class_name GridSlot
extends RefCounted

## Represents a single cell in the 5x5 grid.
## Holds a RuneInstance and manages temporary slot states (e.g., Scorched Earth).

var grid_position: Vector2i
var rune: RuneInstance = null

# Dictionary to hold active slot states. 
# Key: State ID (String), Value: Dictionary { "duration": int, "score_bonus": int }
var active_states: Dictionary = {}

func _init(pos: Vector2i):
	grid_position = pos

func is_empty() -> bool:
	return rune == null

func set_rune(new_rune: RuneInstance) -> void:
	rune = new_rune
	if rune:
		apply_buffs(rune)

func remove_rune() -> RuneInstance:
	var removed = rune
	if removed:
		remove_buffs(removed)
	rune = null
	return removed

# --- Slot State Logic ---

func add_state(state_id: String, duration: int, score_bonus: int = 0) -> void:
	active_states[state_id] = {
		"duration": duration,
		"score_bonus": score_bonus
	}
	# If there is a rune here, update its stats immediately
	if rune:
		# We remove all buffs and re-apply to ensure no duplication/stale data
		# Or simpler: just add the new bonus. But since we don't track which bonus came from where in the rune easily,
		# it's safer to rely on the 'stat_modifiers' being transient or managed.
		# Actually, RuneInstance.stat_modifiers are reset every round.
		# But if we add a state mid-round, we should apply it.
		# For simplicity, let's just re-apply all buffs.
		# But wait, 'apply_buffs' adds to the current modifiers.
		# We need to be careful not to double add.
		# Since this is a prototype, let's just add the new bonus directly.
		rune.stat_modifiers["score_bonus"] += score_bonus

func has_state(state_id: String) -> bool:
	return active_states.has(state_id)

func process_states() -> void:
	var states_to_remove: Array[String] = []
	
	for state_id in active_states:
		active_states[state_id]["duration"] -= 1
		if active_states[state_id]["duration"] <= 0:
			states_to_remove.append(state_id)
	
	for state_id in states_to_remove:
		# If we remove a state, we should remove its effect from the rune if present.
		# This is tricky because modifiers are usually reset at start of round.
		# If process_states happens at end of round, the rune will reset itself anyway.
		active_states.erase(state_id)

func apply_buffs(target_rune: RuneInstance) -> void:
	for state_id in active_states:
		var data = active_states[state_id]
		target_rune.stat_modifiers["score_bonus"] += data["score_bonus"]

func remove_buffs(target_rune: RuneInstance) -> void:
	for state_id in active_states:
		var data = active_states[state_id]
		target_rune.stat_modifiers["score_bonus"] -= data["score_bonus"]

func clear_states() -> void:
	active_states.clear()

