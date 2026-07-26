class_name RuneInstance
extends RefCounted

## Runtime instance of a Rune. 
## Created based on RuneData, but holds mutable state like current activations and buffs.

var data: RuneData

# State
var current_activations: int = 0
var temporary_buffs: Dictionary = {} 
var permanent_buffs: Dictionary = {} # Persists across rounds
var permanent_elements: Array[GameEnums.Element] = [] # Persists across rounds

# Modifiers for the current round/activation
var stat_modifiers: Dictionary = {
	"score_bonus": 0,
	"score_multiplier": 1.0,
	"activation_bonus": 0,
	"reader_return_bonus": 0
}
var is_disabled: bool = false
var last_effect_success: bool = false

## Element override (used by residues like Obscurecido)
var _element_override: Array[GameEnums.Element] = []
var _has_element_override: bool = false

## Optional override for max activations (used by residues like Descarregado)
var _max_activations_override: int = -1

## If true, the next activation will not consume an activation charge
var next_activation_free: bool = false

## The simultaneous batch ID this rune was last activated in (-1 if not simultaneous)
var last_simultaneous_batch_id: int = -1

func _init(p_data: RuneData):
	data = p_data
	reset_state()

## Resets the rune state for a new round (activations, temp buffs).
func reset_state() -> void:
	current_activations = 0
	temporary_buffs.clear()
	is_disabled = false
	last_effect_success = false
	_has_element_override = false
	_element_override = []
	_max_activations_override = -1
	next_activation_free = false
	last_simultaneous_batch_id = -1
	
	# Reset modifiers to default
	stat_modifiers = {
		"score_bonus": 0,
		"score_multiplier": 1.0,
		"activation_bonus": 0,
		"reader_return_bonus": 0
	}
	
	# Re-apply permanent buffs if any logic requires it here
	# (For now permanent buffs might just be direct value modifications, 
	# but if we want to track them separately, we do it here)
	# Permanent elements persist across rounds

## Checks if the rune has activations remaining.
func can_activate() -> bool:
	if is_disabled:
		return false
	return current_activations < get_max_activations()

## Returns the max activations, accounting for any buffs.
func get_max_activations() -> int:
	if _max_activations_override >= 0:
		return _max_activations_override
	var bonus = stat_modifiers.get("activation_bonus", 0)
	var perm_bonus = permanent_buffs.get("activation_bonus", 0)
	return data.base_max_activations + bonus + perm_bonus


func get_reader_return_bonus() -> int:
	var bonus = stat_modifiers.get("reader_return_bonus", 0)
	var perm_bonus = permanent_buffs.get("reader_return_bonus", 0)
	return bonus + perm_bonus


## Returns effective elements for this rune (with residue overrides)
func get_elements() -> Array[GameEnums.Element]:
	if _has_element_override:
		return _element_override
	return get_base_elements()


## Returns elements without residue override (base + permanent elements)
func get_base_elements() -> Array[GameEnums.Element]:
	var elems: Array[GameEnums.Element] = data.elements.duplicate()
	for elem in permanent_elements:
		if elem not in elems:
			elems.append(elem)
	return elems


## Adds a permanent element if it isn't already present
func add_permanent_element(element: GameEnums.Element) -> bool:
	var elems = get_base_elements()
	if element in elems:
		return false
	permanent_elements.append(element)
	return true


func set_element_override(elements: Array[GameEnums.Element]) -> void:
	_element_override = elements
	_has_element_override = true


func clear_element_override() -> void:
	_has_element_override = false
	_element_override = []


func set_max_activations_override(value: int) -> void:
	_max_activations_override = max(value, 0)


func clear_max_activations_override() -> void:
	_max_activations_override = -1

## Helper to get modified score
func get_modified_score(base_score: int) -> int:
	var bonus = stat_modifiers.get("score_bonus", 0)
	var mult = stat_modifiers.get("score_multiplier", 1.0)
	var perm_bonus = permanent_buffs.get("score_bonus", 0)
	var perm_mult = permanent_buffs.get("score_multiplier", 1.0)
	
	return int((base_score + bonus + perm_bonus) * mult * perm_mult)

## Called when the rune is triggered by the Reader.
func on_activate(context: BattleContext, my_slot: GridSlot) -> void:
	last_effect_success = false
	if can_activate():
		# Free activation: don't consume a charge
		if next_activation_free:
			next_activation_free = false
		else:
			current_activations += 1
		
		# Track simultaneous batch
		if context.is_simultaneous_active():
			last_simultaneous_batch_id = context.get_simultaneous_batch_id()

		# Single source of truth for "this rune is activating now" — every activation
		# path (reader, triggered, simultaneous, connector) funnels through here.
		if context:
			context.rune_activation_started.emit(my_slot, self, context.get_simultaneous_batch_id())

		# Track total activations for Memory rune and Rhythm conditions
		var total = context.get_meta("total_activations", 0)
		context.set_meta("total_activations", total + 1)
		
		for effect in data.effects:
			# ON_READ executes during the rune's own activation; other triggers are handled by EventBus
			if effect.trigger != GameEnums.EffectTrigger.ON_READ:
				continue
			var ctx = EffectContext.new(self, my_slot, context)
			effect.execute(ctx)
