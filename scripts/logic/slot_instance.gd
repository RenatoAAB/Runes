class_name SlotInstance
extends RefCounted

## Runtime instance of a Slot.
## Created based on SlotData, holds mutable state like upgrade level and temporary buffs.
## Similar lifecycle to RuneInstance.
## Extended to also support holding relics (when used as a relic slot).

const SlotEffect = preload("res://scripts/data/slot_effects/slot_effect.gd")
const SlotEffectFactory = preload("res://scripts/data/slot_effects/slot_effect_factory.gd")

enum SlotContentType {
	RUNE,   ## Normal slot that holds runes
	RELIC,  ## Slot that holds a relic
	PIECE,  ## Slot that holds a slot piece
	EMPTY   ## Empty slot (no content)
}

var data: SlotData

## Current slot modifier (slot type) applied to this slot
var slot_modifier_id: String = ""
## Current slot type id (for save/load)
var slot_type_id: String = ""

## Cached modifier data reference
var _cached_modifier_data: SlotModifierData = null

## What type of content this slot holds
var content_type: SlotContentType = SlotContentType.RUNE

## Relic reference (if content_type == RELIC)
var held_relic: RefCounted = null  # RelicInstance

## Slot piece reference (if content_type == PIECE)  
var held_piece: RefCounted = null  # SlotPieceInstance

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

## Residue helpers (per round)
var skipped_first_read_this_round: bool = false


func _init(p_data: SlotData = null):
	if p_data:
		data = p_data
	else:
		# Create default empty slot
		data = _create_default_slot_data()
	if data and data.slot_effects.is_empty() and data.id.begins_with("slot_"):
		data.slot_effects = SlotEffectFactory.build(data.id)
	slot_type_id = data.id if data else ""


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
	var permanent_bonus = get_meta("permanent_multiplier_bonus", 0.0)
	var total = base + upgrade_bonus + temp_multiplier_bonus + state_bonus + permanent_bonus
	
	if data.is_broken:
		total *= 0.5
	
	return maxf(total, 0.0)


## Get the number of times a rune should trigger
func get_trigger_count() -> int:
	var permanent_bonus = get_meta("permanent_trigger_bonus", 0)
	return maxi(data.trigger_count + temp_trigger_bonus + permanent_bonus, 1)


## Check if this slot preserves rune charges
func preserves_charges() -> bool:
	var permanent = get_meta("permanent_preserves_charges", false)
	return data.preserves_charges or temp_preserves_charges or permanent


## Check if this slot protects fragile runes
func protects_fragile() -> bool:
	var permanent = get_meta("permanent_protects_fragile", false)
	return data.protects_fragile or temp_protects_fragile or permanent


## Get money generated on activation (including modifier bonus)
func get_money_on_activation() -> int:
	var bonus = get_meta("bonus_money_on_activation", 0)
	return data.money_on_activation + bonus


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
	skipped_first_read_this_round = false


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

## Execute slot effects for a given trigger
func execute_slot_effects(trigger: SlotEffect.SlotEffectTrigger, context: BattleContext, grid_slot) -> void:
	if not data or data.slot_effects.is_empty():
		return
	for effect in data.slot_effects:
		if effect and effect.trigger == trigger:
			effect.execute(context, grid_slot)


## Execute before-rune-read effects
func execute_before_rune_read(context: BattleContext, grid_slot) -> void:
	execute_slot_effects(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, context, grid_slot)


## Execute after-rune-read effects (including money generation)
func execute_after_rune_read(rune: RuneInstance, context: BattleContext, grid_slot) -> void:
	# Generate money if slot has money_on_activation
	if data.money_on_activation > 0:
		context.add_money(data.money_on_activation, rune)
		money_generated_this_round += data.money_on_activation

	execute_slot_effects(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, context, grid_slot)


## Execute round-start effects
func execute_on_round_start(context: BattleContext, grid_slot) -> void:
	execute_slot_effects(SlotEffect.SlotEffectTrigger.ROUND_START, context, grid_slot)


## Execute round-end effects (including money generation)
func execute_on_round_end(context: BattleContext, grid_slot) -> void:
	# Generate money if slot has money_on_round_end and has a rune
	if data.money_on_round_end > 0 and grid_slot and grid_slot.rune:
		context.add_money(data.money_on_round_end, grid_slot.rune)
		money_generated_this_round += data.money_on_round_end

	execute_slot_effects(SlotEffect.SlotEffectTrigger.ROUND_END, context, grid_slot)


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
		"states": active_states.keys(),
		"applied_modifiers": get_meta("applied_modifiers", {})
	}


# --- Modifier Support ---

## Check if this slot has a specific modifier applied
func has_modifier(modifier_id: String) -> bool:
	var applied = get_meta("applied_modifiers", {})
	return applied.has(modifier_id) and applied[modifier_id] > 0


## Get the stack count of a specific modifier
func get_modifier_stack_count(modifier_id: String) -> int:
	var applied = get_meta("applied_modifiers", {})
	return applied.get(modifier_id, 0)


## Apply a modifier to this slot permanently
## Returns true if successfully applied, false if incompatible or at max stacks
func apply_modifier(modifier: SlotModifierData) -> bool:
	if not modifier:
		return false
	if not modifier.can_apply_to_slot(self):
		return false
	
	# Slot type override replaces current slot data and modifier
	if modifier.slot_data_override:
		data = modifier.slot_data_override
		if data and data.slot_effects.is_empty() and data.id.begins_with("slot_"):
			data.slot_effects = SlotEffectFactory.build(data.id)
		slot_modifier_id = modifier.id
		_cached_modifier_data = modifier
		slot_type_id = data.id if data else ""
		upgrade_level = clamp(upgrade_level, 0, data.max_upgrade_level if data else 0)
		set_meta("applied_modifiers", { modifier.id: 1 })
		return true
	
	# Check if already at max stacks
	var current_stacks = get_modifier_stack_count(modifier.id)
	if not modifier.stacks and current_stacks > 0:
		print("Modifier '%s' doesn't stack and is already applied" % modifier.id)
		return false
	if modifier.stacks and current_stacks >= modifier.max_stacks:
		print("Modifier '%s' already at max stacks (%d)" % [modifier.id, modifier.max_stacks])
		return false
	
	# Check incompatibilities
	var applied = get_meta("applied_modifiers", {})
	for incompatible_id in modifier.incompatible_modifier_ids:
		if applied.has(incompatible_id) and applied[incompatible_id] > 0:
			print("Modifier '%s' incompatible with '%s'" % [modifier.id, incompatible_id])
			return false
	
	# Apply modifier based on type
	match modifier.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			var current = get_meta("permanent_multiplier_bonus", 0.0)
			set_meta("permanent_multiplier_bonus", current + modifier.value)
		
		SlotModifierData.ModifierType.TRIGGER:
			var current = get_meta("permanent_trigger_bonus", 0)
			set_meta("permanent_trigger_bonus", current + int(modifier.value))
		
		SlotModifierData.ModifierType.ECONOMY:
			var current = get_meta("bonus_money_on_activation", 0)
			set_meta("bonus_money_on_activation", current + int(modifier.value))
		
		SlotModifierData.ModifierType.PRESERVATION:
			set_meta("permanent_preserves_charges", true)
		
		SlotModifierData.ModifierType.PROTECTION:
			set_meta("permanent_protects_fragile", true)
		
		SlotModifierData.ModifierType.STATE:
			# Apply a permanent state
			apply_state(modifier.id, -1, 0, 0, 0.0)
	
	# Track applied modifier
	applied[modifier.id] = current_stacks + 1
	set_meta("applied_modifiers", applied)
	
	print("Applied modifier '%s' (stack %d)" % [modifier.display_name, current_stacks + 1])
	return true


## Get the applied slot modifier data (if any)
func get_applied_modifier_data() -> SlotModifierData:
	if _cached_modifier_data:
		return _cached_modifier_data
	if slot_modifier_id.is_empty():
		return null
	var path = "res://resources/slot_modifiers/%s.tres" % slot_modifier_id
	if ResourceLoader.exists(path):
		var data_resource = load(path) as SlotModifierData
		_cached_modifier_data = data_resource
		return data_resource
	return null


## Apply a state permanently (for state-type modifiers)
func apply_state(state_id: String, duration: int, score_bonus: int = 0, 
				activation_bonus: int = 0, multiplier_bonus: float = 0.0) -> void:
	if duration < 0:
		# Permanent state - use a very large duration
		add_state(state_id, 999999, score_bonus, activation_bonus, multiplier_bonus)
	else:
		add_state(state_id, duration, score_bonus, activation_bonus, multiplier_bonus)


# --- Residue Management ---
# Residues are special states tagged with the "residue:" prefix for identification.
# Known residue types: petrified, mana_residue, mana_anomaly, faminto

const RESIDUE_PREFIX := "residue:"

## Apply a runic residue to this slot
func apply_residue(residue_id: String, duration: int = -1, score_bonus: int = 0) -> void:
	var state_id = RESIDUE_PREFIX + residue_id
	var dur = 999999 if duration < 0 else duration
	add_state(state_id, dur, score_bonus)

## Check if this slot has any residue
func has_residue() -> bool:
	for state_id in active_states:
		if (state_id as String).begins_with(RESIDUE_PREFIX):
			return true
	return false

## Check if this slot has a specific residue
func has_specific_residue(residue_id: String) -> bool:
	return has_state(RESIDUE_PREFIX + residue_id)

## Get all active residue IDs (without prefix)
func get_residue_ids() -> Array[String]:
	var ids: Array[String] = []
	for state_id in active_states:
		var sid := state_id as String
		if sid.begins_with(RESIDUE_PREFIX):
			ids.append(sid.substr(RESIDUE_PREFIX.length()))
	return ids

## Remove a specific residue
func clear_residue(residue_id: String) -> bool:
	var state_id = RESIDUE_PREFIX + residue_id
	if has_state(state_id):
		remove_state(state_id)
		return true
	return false

## Remove all residues
func clear_residues() -> void:
	var to_remove: Array[String] = []
	for state_id in active_states:
		if (state_id as String).begins_with(RESIDUE_PREFIX):
			to_remove.append(state_id)
	for state_id in to_remove:
		active_states.erase(state_id)

## Petrify this slot (rune cannot be moved)
func petrify() -> void:
	apply_residue("petrified")

## Check if this slot is petrified
func is_petrified() -> bool:
	return has_specific_residue("petrified") or has_state("petrified")


# --- Relic Slot Support ---

## Set this slot to hold a relic
func set_as_relic_slot() -> void:
	content_type = SlotContentType.RELIC
	held_relic = null


## Set this slot to hold a piece
func set_as_piece_slot() -> void:
	content_type = SlotContentType.PIECE
	held_piece = null


## Place a relic in this slot
func place_relic(relic: RefCounted) -> bool:
	if content_type != SlotContentType.RELIC:
		return false
	if held_relic != null:
		return false
	held_relic = relic
	return true


## Remove relic from this slot
func remove_relic() -> RefCounted:
	var relic = held_relic
	held_relic = null
	return relic


## Check if slot has a relic
func has_relic() -> bool:
	return content_type == SlotContentType.RELIC and held_relic != null


## Get the held relic
func get_relic() -> RefCounted:
	return held_relic


## Place a slot piece in this slot
func place_piece(piece: RefCounted) -> bool:
	if content_type != SlotContentType.PIECE:
		return false
	if held_piece != null:
		return false
	held_piece = piece
	return true


## Remove piece from this slot
func remove_piece() -> RefCounted:
	var piece = held_piece
	held_piece = null
	return piece


## Check if slot has a piece
func has_piece() -> bool:
	return content_type == SlotContentType.PIECE and held_piece != null


## Get the held piece
func get_piece() -> RefCounted:
	return held_piece


## Check if this slot is empty (no content regardless of type)
func is_slot_empty() -> bool:
	match content_type:
		SlotContentType.RELIC:
			return held_relic == null
		SlotContentType.PIECE:
			return held_piece == null
		SlotContentType.RUNE:
			return true  # Rune check is handled by GridSlot
		_:
			return true
