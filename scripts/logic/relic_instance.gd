class_name RelicInstance
extends RefCounted

## Runtime instance of a Relic.
## Tracks state like trigger counts and attached panel.
## Uses the calculator system: input = BattleRoundStatistics → output = float multiplier.

signal relic_multiplier_calculated(relic: RelicInstance, multiplier: float)

var data: RelicData

## Which panel is this relic attached to?
var attached_panel_index: int = -1

## Has this relic been triggered this battle?
var triggered_this_battle: bool = false

## How many times has this triggered? (for stats)
var total_trigger_count: int = 0

## Is this relic currently active/enabled?
var is_active: bool = true

## Last multiplier value calculated (for UI display)
var last_calculated_multiplier: float = 1.0


func _init(p_data: RelicData):
	data = p_data


## Whether this relic has a calculator assigned
func has_calculator() -> bool:
	return data and data.has_calculator()


## Calculate the score multiplier from round statistics.
## Returns 1.0 if no calculator is set (neutral multiplier).
func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	if not is_active or not has_calculator():
		return 1.0

	var mult := data.calculator.calculate_multiplier(stats)
	last_calculated_multiplier = mult
	total_trigger_count += 1
	triggered_this_battle = true
	relic_multiplier_calculated.emit(self, mult)
	return mult


## Reset for new battle
func reset_for_battle() -> void:
	triggered_this_battle = false
	last_calculated_multiplier = 1.0


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
		"is_attached": is_attached(),
		"panel_index": attached_panel_index,
		"trigger_count": total_trigger_count,
		"is_active": is_active,
		"last_multiplier": last_calculated_multiplier
	}


## Get keywords for tooltip display
func get_keywords() -> Array[StringName]:
	return data.get_keywords()
