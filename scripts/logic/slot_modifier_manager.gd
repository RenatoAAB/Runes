class_name SlotModifierManager
extends RefCounted

## Manages the application of modifiers to slots.
## Handles stacking, compatibility checks, and effect application.

signal modifier_applied(slot: GridSlot, modifier: SlotModifierData)
signal modifier_removed(slot: GridSlot, modifier_id: String)
signal application_failed(slot: GridSlot, modifier: SlotModifierData, reason: String)


## Apply a modifier to a slot
func apply_modifier(slot: GridSlot, modifier: SlotModifierData) -> bool:
	if not slot or not modifier:
		application_failed.emit(slot, modifier, "Invalid slot or modifier")
		return false
	
	var slot_instance = slot.slot
	
	# Check compatibility
	if not modifier.can_apply_to_slot(slot_instance):
		application_failed.emit(slot, modifier, "Modifier incompatible with slot")
		return false
	
	# Apply the modifier effect
	_apply_modifier_effect(slot_instance, modifier)
	
	# Track the modifier on the slot
	_track_modifier(slot_instance, modifier)
	
	modifier_applied.emit(slot, modifier)
	return true


## Apply the actual effect based on modifier type
func _apply_modifier_effect(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	match modifier.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			_apply_multiplier_modifier(slot_instance, modifier)
		SlotModifierData.ModifierType.TRIGGER:
			_apply_trigger_modifier(slot_instance, modifier)
		SlotModifierData.ModifierType.ECONOMY:
			_apply_economy_modifier(slot_instance, modifier)
		SlotModifierData.ModifierType.PRESERVATION:
			_apply_preservation_modifier(slot_instance)
		SlotModifierData.ModifierType.PROTECTION:
			_apply_protection_modifier(slot_instance)
		SlotModifierData.ModifierType.STATE:
			_apply_state_modifier(slot_instance, modifier)


## Apply multiplier bonus
func _apply_multiplier_modifier(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	# Store as permanent bonus (different from temp bonus)
	if not slot_instance.get("permanent_multiplier_bonus"):
		slot_instance.set_meta("permanent_multiplier_bonus", 0.0)
	
	var current = slot_instance.get_meta("permanent_multiplier_bonus", 0.0)
	slot_instance.set_meta("permanent_multiplier_bonus", current + modifier.value)


## Apply trigger bonus
func _apply_trigger_modifier(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	if not slot_instance.get("permanent_trigger_bonus"):
		slot_instance.set_meta("permanent_trigger_bonus", 0)
	
	var current = slot_instance.get_meta("permanent_trigger_bonus", 0)
	slot_instance.set_meta("permanent_trigger_bonus", current + int(modifier.value))


## Apply economy modifier
func _apply_economy_modifier(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	if not slot_instance.get("bonus_money_on_activation"):
		slot_instance.set_meta("bonus_money_on_activation", 0)
	
	var current = slot_instance.get_meta("bonus_money_on_activation", 0)
	slot_instance.set_meta("bonus_money_on_activation", current + int(modifier.value))


## Apply preservation modifier
func _apply_preservation_modifier(slot_instance: SlotInstance) -> void:
	slot_instance.set_meta("permanent_preserves_charges", true)


## Apply protection modifier
func _apply_protection_modifier(slot_instance: SlotInstance) -> void:
	slot_instance.set_meta("permanent_protects_fragile", true)


## Apply state modifier
func _apply_state_modifier(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	# This would apply a permanent state to the slot
	# Implementation depends on what states are available
	var state_id = modifier.id + "_state"
	var duration = int(modifier.value) if modifier.value > 0 else -1  # -1 = permanent
	
	slot_instance.apply_state(state_id, duration, 0, 0, modifier.value)


## Track the modifier on the slot for stacking and removal
func _track_modifier(slot_instance: SlotInstance, modifier: SlotModifierData) -> void:
	var applied_modifiers = slot_instance.get_meta("applied_modifiers", {})
	
	if modifier.stacks:
		var current_count = applied_modifiers.get(modifier.id, 0)
		applied_modifiers[modifier.id] = current_count + 1
	else:
		applied_modifiers[modifier.id] = 1
	
	slot_instance.set_meta("applied_modifiers", applied_modifiers)


## Check if a slot has a specific modifier
func has_modifier(slot_instance: SlotInstance, modifier_id: String) -> bool:
	var applied_modifiers = slot_instance.get_meta("applied_modifiers", {})
	return applied_modifiers.has(modifier_id) and applied_modifiers[modifier_id] > 0


## Get the stack count of a modifier on a slot
func get_modifier_stack_count(slot_instance: SlotInstance, modifier_id: String) -> int:
	var applied_modifiers = slot_instance.get_meta("applied_modifiers", {})
	return applied_modifiers.get(modifier_id, 0)


## Get all modifiers applied to a slot
func get_applied_modifiers(slot_instance: SlotInstance) -> Dictionary:
	return slot_instance.get_meta("applied_modifiers", {})


## Remove a modifier from a slot (if removable)
func remove_modifier(slot: GridSlot, modifier_id: String, remove_all_stacks: bool = false) -> bool:
	var slot_instance = slot.slot
	var applied_modifiers = slot_instance.get_meta("applied_modifiers", {})
	
	if not applied_modifiers.has(modifier_id):
		return false
	
	if remove_all_stacks:
		applied_modifiers.erase(modifier_id)
	else:
		applied_modifiers[modifier_id] = maxi(applied_modifiers[modifier_id] - 1, 0)
		if applied_modifiers[modifier_id] == 0:
			applied_modifiers.erase(modifier_id)
	
	slot_instance.set_meta("applied_modifiers", applied_modifiers)
	
	# Note: Actually reversing the effect would require more tracking
	# For now, removed modifiers just prevent further stacking
	
	modifier_removed.emit(slot, modifier_id)
	return true


## Calculate the total modifier bonus for display
func get_modifier_summary(slot_instance: SlotInstance) -> Dictionary:
	var summary = {
		"multiplier_bonus": slot_instance.get_meta("permanent_multiplier_bonus", 0.0),
		"trigger_bonus": slot_instance.get_meta("permanent_trigger_bonus", 0),
		"money_bonus": slot_instance.get_meta("bonus_money_on_activation", 0),
		"preserves_charges": slot_instance.get_meta("permanent_preserves_charges", false),
		"protects_fragile": slot_instance.get_meta("permanent_protects_fragile", false),
		"applied_modifiers": get_applied_modifiers(slot_instance)
	}
	return summary
