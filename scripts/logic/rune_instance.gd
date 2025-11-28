class_name RuneInstance
extends RefCounted

## Runtime instance of a Rune. 
## Created based on RuneData, but holds mutable state like current activations and buffs.

var data: RuneData

# State
var current_activations: int = 0
var temporary_buffs: Dictionary = {} 

func _init(p_data: RuneData):
	data = p_data
	reset_state()

## Resets the rune state for a new round (activations, temp buffs).
func reset_state() -> void:
	current_activations = 0
	temporary_buffs.clear()

## Checks if the rune has activations remaining.
func can_activate() -> bool:
	return current_activations < get_max_activations()

## Returns the max activations, accounting for any buffs.
func get_max_activations() -> int:
	var bonus = temporary_buffs.get("max_activations_bonus", 0)
	return data.base_max_activations + bonus

## Called when the rune is triggered by the Reader.
func on_activate(context: BattleContext, my_slot: GridSlot) -> void:
	if can_activate():
		current_activations += 1
		
		for effect in data.effects:
			effect.execute(self, context, my_slot)
