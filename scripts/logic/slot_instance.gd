class_name SlotInstance
extends RefCounted

## Runtime instance of a Slot.
## Created based on SlotData, holds mutable state like upgrade level and temporary buffs.
## Similar lifecycle to RuneInstance.

var data: SlotData

## Current upgrade level (0 = base, max = data.max_upgrade_level)
var upgrade_level: int = 0

## Temporary multiplier bonus (resets each round)
var temp_multiplier_bonus: float = 0.0

## Temporary extra triggers (resets each round)
var temp_trigger_bonus: int = 0

## Temporary state flags
var temp_preserves_charges: bool = false
var temp_protects_fragile: bool = false

## Active states (similar to old GridSlot.active_states)
## Key: State ID, Value: { duration: int, score_bonus: int, activation_bonus: int, multiplier_bonus: float }
var active_states: Dictionary = {}

## Economy tracking for this round
var money_generated_this_round: int = 0


func _init(p_data: SlotData = null):
	if p_data:
		data = p_data
	else:
		# Create default empty slot
		data = _create_default_slot_data()


## Create a default "empty" slot data
static func _create_default_slot_data() -> SlotData:
	var default = SlotData.new()
	default.id = "default"
	default.slot_name = "Empty Slot"
	default.base_multiplier = 1.0
	default.trigger_count = 1
	return default


## Get the total multiplier for score calculation
func get_multiplier() -> float:
	var base = data.base_multiplier
	var upgrade_bonus = upgrade_level * data.multiplier_per_upgrade
	var state_bonus = _get_state_multiplier_bonus()
	var total = base + upgrade_bonus + temp_multiplier_bonus + state_bonus
	
	if data.is_broken:
		total *= 0.5
	
	return maxf(total, 0.0)


## Get the number of times a rune should trigger
func get_trigger_count() -> int:
	return maxi(data.trigger_count + temp_trigger_bonus, 1)


## Check if this slot preserves rune charges
func preserves_charges() -> bool:
	return data.preserves_charges or temp_preserves_charges


## Check if this slot protects fragile runes
func protects_fragile() -> bool:
	return data.protects_fragile or temp_protects_fragile


## Get money generated on activation
func get_money_on_activation() -> int:
	return data.money_on_activation


## Check if this is a void/gap (no physical slot)
func is_void() -> bool:
	return data.is_void


## Upgrade the slot (increase multiplier)
func upgrade() -> bool:
	if upgrade_level < data.max_upgrade_level and data.can_upgrade_multiplier:
		upgrade_level += 1
		return true
	return false


## Check if can be upgraded further
func can_upgrade() -> bool:
	return data.can_upgrade_multiplier and upgrade_level < data.max_upgrade_level


## Reset temporary effects at round end
func reset_temp_effects() -> void:
	temp_multiplier_bonus = 0.0
	temp_trigger_bonus = 0
	temp_preserves_charges = false
	temp_protects_fragile = false
	money_generated_this_round = 0


## Add a temporary multiplier bonus (lasts one round)
func add_temp_multiplier(amount: float) -> void:
	temp_multiplier_bonus += amount


## Add temporary extra triggers
func add_temp_triggers(amount: int) -> void:
	temp_trigger_bonus += amount


# --- State Management (from old GridSlot) ---

func add_state(state_id: String, duration: int, score_bonus: int = 0, 
				activation_bonus: int = 0, multiplier_bonus: float = 0.0) -> void:
	active_states[state_id] = {
		"duration": duration,
		"score_bonus": score_bonus,
		"activation_bonus": activation_bonus,
		"multiplier_bonus": multiplier_bonus
	}


func has_state(state_id: String) -> bool:
	return active_states.has(state_id)


func remove_state(state_id: String) -> void:
	active_states.erase(state_id)


func process_states() -> void:
	var states_to_remove: Array[String] = []
	
	for state_id in active_states:
		active_states[state_id]["duration"] -= 1
		if active_states[state_id]["duration"] <= 0:
			states_to_remove.append(state_id)
	
	for state_id in states_to_remove:
		active_states.erase(state_id)
	
	# Reset temporary effects
	reset_temp_effects()


func _get_state_multiplier_bonus() -> float:
	var bonus = 0.0
	for state_id in active_states:
		bonus += active_states[state_id].get("multiplier_bonus", 0.0)
	return bonus


func get_state_score_bonus() -> int:
	var bonus = 0
	for state_id in active_states:
		bonus += active_states[state_id].get("score_bonus", 0)
	return bonus


func get_state_activation_bonus() -> int:
	var bonus = 0
	for state_id in active_states:
		bonus += active_states[state_id].get("activation_bonus", 0)
	return bonus


func clear_states() -> void:
	active_states.clear()


# --- Effect Execution ---

## Execute on-activation effects (including money generation)
func execute_on_activation(rune: RuneInstance, context: BattleContext, grid_slot) -> void:
	# Generate money if slot has money_on_activation
	if data.money_on_activation > 0:
		context.add_money(data.money_on_activation, rune)
		money_generated_this_round += data.money_on_activation
	
	# Execute custom effects
	for effect in data.on_activation_effects:
		effect.execute(rune, context, grid_slot)


## Execute round-start effects
func execute_on_round_start(context: BattleContext, grid_slot) -> void:
	for effect in data.on_round_start_effects:
		# For slot effects without a rune, we pass null
		var rune = grid_slot.rune if grid_slot else null
		effect.execute(rune, context, grid_slot)


## Execute round-end effects (including money generation)
func execute_on_round_end(context: BattleContext, grid_slot) -> void:
	# Generate money if slot has money_on_round_end and has a rune
	if data.money_on_round_end > 0 and grid_slot and grid_slot.rune:
		context.add_money(data.money_on_round_end, grid_slot.rune)
		money_generated_this_round += data.money_on_round_end
	
	# Execute custom effects
	for effect in data.on_round_end_effects:
		var rune = grid_slot.rune if grid_slot else null
		effect.execute(rune, context, grid_slot)


## Get display info for UI
func get_display_info() -> Dictionary:
	return {
		"name": data.slot_name,
		"multiplier": get_multiplier(),
		"trigger_count": get_trigger_count(),
		"upgrade_level": upgrade_level,
		"max_upgrade": data.max_upgrade_level,
		"preserves_charges": preserves_charges(),
		"protects_fragile": protects_fragile(),
		"is_broken": data.is_broken,
		"is_void": data.is_void,
		"states": active_states.keys()
	}
