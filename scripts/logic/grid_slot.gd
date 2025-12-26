class_name GridSlot
extends RefCounted

## Represents a single cell in the grid.
## Acts as a container for a SlotInstance (the slot type) and a RuneInstance (the rune).
## This is the "position" on the board, while SlotInstance defines the slot's properties.

var grid_position: Vector2i

## The slot type/instance at this position (never null - default slot if not set)
var slot: SlotInstance

## The rune placed in this slot (can be null)
var rune: RuneInstance = null


func _init(pos: Vector2i, slot_data: SlotData = null):
	grid_position = pos
	if slot_data:
		slot = SlotInstance.new(slot_data)
	else:
		slot = SlotInstance.new()  # Creates default empty slot


# --- Slot Delegation ---
# These methods delegate to SlotInstance for backwards compatibility

func get_multiplier() -> float:
	return slot.get_multiplier()


func get_trigger_count() -> int:
	return slot.get_trigger_count()


func preserves_charges() -> bool:
	return slot.preserves_charges()


func protects_fragile() -> bool:
	return slot.protects_fragile()


func is_void() -> bool:
	return slot.is_void()


# --- Slot Management ---

## Set a new slot type at this position
func set_slot(new_slot: SlotInstance) -> SlotInstance:
	var old_slot = slot
	slot = new_slot if new_slot else SlotInstance.new()
	return old_slot


## Upgrade the current slot
func upgrade_slot() -> bool:
	return slot.upgrade()


## Check if slot can be upgraded
func can_upgrade_slot() -> bool:
	return slot.can_upgrade()


# --- Rune Management ---

func is_empty() -> bool:
	return rune == null


func set_rune(new_rune: RuneInstance) -> void:
	rune = new_rune
	if rune:
		_apply_slot_buffs_to_rune()


func remove_rune() -> RuneInstance:
	var removed = rune
	rune = null
	return removed


func _apply_slot_buffs_to_rune() -> void:
	if not rune:
		return
	
	# Apply activation bonus from slot states
	var activation_bonus = slot.get_state_activation_bonus()
	if activation_bonus > 0:
		if not rune.stat_modifiers.has("activation_bonus"):
			rune.stat_modifiers["activation_bonus"] = 0
		rune.stat_modifiers["activation_bonus"] += activation_bonus
	
	# Apply score bonus from slot states
	var score_bonus = slot.get_state_score_bonus()
	if score_bonus > 0:
		rune.stat_modifiers["score_bonus"] += score_bonus


## Public method to apply slot buffs to a rune (used after rune reset)
func apply_buffs(target_rune: RuneInstance) -> void:
	if target_rune and target_rune == rune:
		_apply_slot_buffs_to_rune()


# --- State Management (delegated to SlotInstance) ---

func add_state(state_id: String, duration: int, score_bonus: int = 0, 
				activation_bonus: int = 0, multiplier_bonus: float = 0.0) -> void:
	slot.add_state(state_id, duration, score_bonus, activation_bonus, multiplier_bonus)
	
	# If there's a rune, apply the new bonuses immediately
	if rune:
		rune.stat_modifiers["score_bonus"] += score_bonus
		if not rune.stat_modifiers.has("activation_bonus"):
			rune.stat_modifiers["activation_bonus"] = 0
		rune.stat_modifiers["activation_bonus"] += activation_bonus


func has_state(state_id: String) -> bool:
	return slot.has_state(state_id)


func process_states() -> void:
	slot.process_states()


func clear_states() -> void:
	slot.clear_states()


# --- Convenience Getters for UI ---

## Get active states for tooltip display
var active_states: Dictionary:
	get:
		return slot.active_states


## Get slot display info
func get_slot_info() -> Dictionary:
	return slot.get_display_info()


# --- Temporary Effect Helpers (for backwards compatibility) ---

func add_temp_multiplier(amount: float) -> void:
	slot.add_temp_multiplier(amount)


func add_permanent_multiplier(amount: float) -> void:
	# For permanent multiplier, we upgrade the slot or modify base
	# This is a simplification - ideally done via upgrade system
	slot.add_temp_multiplier(amount)  # TODO: Implement proper permanent system


func set_trigger_count(count: int) -> void:
	slot.temp_trigger_bonus = count - slot.data.trigger_count


func reset_temp_effects() -> void:
	slot.reset_temp_effects()


# --- Effect Execution ---

## Called when a rune activates in this slot
func on_rune_activation(context: BattleContext) -> void:
	if rune:
		slot.execute_on_activation(rune, context, self)


## Called at round start
func on_round_start(context: BattleContext) -> void:
	slot.execute_on_round_start(context, self)


## Called at round end
func on_round_end(context: BattleContext) -> void:
	slot.execute_on_round_end(context, self)
	slot.process_states()
