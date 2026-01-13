class_name RelicInstance
extends RefCounted

## Runtime instance of a Relic.
## Tracks state like trigger counts and attached panel.

signal relic_triggered(relic: RelicInstance, trigger_type: RelicData.RelicTrigger)
signal effect_applied(effect_index: int, success: bool)

var data: RelicData

## Which panel is this relic attached to?
var attached_panel_index: int = -1

## Has this relic been triggered this battle? (for non-repeating relics)
var triggered_this_battle: bool = false

## How many times has this triggered? (for stats)
var total_trigger_count: int = 0

## Is this relic currently active/enabled?
var is_active: bool = true


func _init(p_data: RelicData):
	data = p_data


## Check if relic can trigger based on its type and current state
func can_trigger() -> bool:
	if not is_active:
		return false
	
	if not data.can_repeat and triggered_this_battle:
		return false
	
	return true


## Execute the relic's effects
func trigger(context: BattleContext, trigger_source: RelicData.RelicTrigger) -> bool:
	if not can_trigger():
		return false
	
	# Only trigger if the trigger type matches
	if trigger_source != data.trigger_type and data.trigger_type != RelicData.RelicTrigger.PASSIVE:
		return false
	
	triggered_this_battle = true
	total_trigger_count += 1
	
	# Execute each effect
	for i in range(data.effects.size()):
		var effect = data.effects[i]
		if effect:
			var success = _execute_effect(effect, context)
			effect_applied.emit(i, success)
	
	relic_triggered.emit(self, trigger_source)
	return true


## Execute a single effect
func _execute_effect(effect: RuneEffect, context: BattleContext) -> bool:
	if not effect or not effect.payload:
		return false
	
	# Check condition if present
	if effect.condition:
		# Relics don't have a source rune, so we pass null
		if not effect.condition.evaluate(null, context, null):
			return false
	
	# Get targets if target selector exists
	var targets: Array[GridSlot] = []
	if effect.target:
		targets = effect.target.get_targets(null, context, null)
	
	# Execute payload - signature is (targets, source_rune, context)
	# For relics, we pass empty targets array if none, and null for source_rune
	effect.payload.execute(targets, null, context)
	
	return true


## Get the multiplier bonus from this relic (for passive calculations)
func get_multiplier_bonus() -> float:
	if not is_active:
		return 0.0
	return data.multiplier_bonus


## Get the score bonus from this relic
func get_score_bonus() -> int:
	if not is_active:
		return 0
	return data.score_bonus


## Get element affinity multiplier for a rune's elements
func get_element_multiplier(elements: Array[GameEnums.Element]) -> float:
	if not is_active:
		return 1.0
	
	if data.element_affinity.is_empty():
		return 1.0
	
	for elem in elements:
		if elem in data.element_affinity:
			return data.affinity_multiplier

	return 1.0


## Reset for new battle
func reset_for_battle() -> void:
	triggered_this_battle = false


## Attach to a panel
func attach_to_panel(panel_index: int) -> void:
	attached_panel_index = panel_index


## Detach from panel
func detach_from_panel() -> void:
	attached_panel_index = -1


## Check if attached to a panel
func is_attached() -> bool:
	return attached_panel_index >= 0


## Get display info
func get_display_info() -> Dictionary:
	return {
		"name": data.display_name,
		"description": data.get_full_description(),
		"rarity": data.rarity,
		"trigger_type": data.trigger_type,
		"trigger_text": data.get_trigger_text(),
		"is_attached": is_attached(),
		"panel_index": attached_panel_index,
		"trigger_count": total_trigger_count,
		"is_active": is_active
	}


## Get keywords for tooltip display
func get_keywords() -> Array[StringName]:
	return data.get_keywords()
