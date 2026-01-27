class_name GridHighlighter
extends Node

## Manages the visual highlighting of the grid based on Rune effects.
## Supports multiple effects affecting the same slot with split visualization.

@export var grid_manager: GridManager

# We need a context to run the queries.
var _preview_context: BattleContext

# Tracks which effect indices affect each slot position
# Dictionary[Vector2i, Array[int]]
var _slot_effect_indices: Dictionary = {}

# Tracks condition slots separately
# Dictionary[Vector2i, bool]
var _slot_has_condition: Dictionary = {}

func _ready() -> void:
	if grid_manager:
		_preview_context = BattleContext.new(grid_manager)


func set_grid_manager(new_grid_manager: GridManager) -> void:
	if new_grid_manager == grid_manager:
		return
	grid_manager = new_grid_manager
	if grid_manager:
		_preview_context = BattleContext.new(grid_manager)
	else:
		_preview_context = null
	clear_highlights()

## Main entry point: highlights all effects of a rune from a given slot.
func highlight_rune_effects(rune: RuneInstance, origin_slot: GridSlot) -> void:
	clear_highlights()
	
	if not rune or not origin_slot:
		return
	
	# First pass: collect all effect indices for each slot
	# Only show targets for effects whose conditions are met
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		
		# Check if condition is met (or if there's no condition)
		var condition_met = true
		if effect.condition:
			condition_met = effect.condition.evaluate(rune, _preview_context, origin_slot)
			
			# 1. Track Condition Sources (always show condition slots for feedback)
			var condition_slots = effect.condition.get_relevant_slots(rune, _preview_context, origin_slot)
			for slot in condition_slots:
				_slot_has_condition[slot.grid_position] = true
		
		# 2. Track Target slots with their effect index (only if condition is met)
		if effect.target and condition_met:
			var target_slots = effect.target.get_targets(rune, _preview_context, origin_slot)
			if effect.target.has_method("get_preview_targets"):
				target_slots = effect.target.get_preview_targets(rune, _preview_context, origin_slot)
			for slot in target_slots:
				var pos = slot.grid_position
				if not _slot_effect_indices.has(pos):
					_slot_effect_indices[pos] = []
				if not _slot_effect_indices[pos].has(i):
					_slot_effect_indices[pos].append(i)
	
	# Second pass: emit signals with all effect data
	# Emit condition highlights
	for pos in _slot_has_condition:
		request_condition_highlight.emit(pos, true)
	
	# Emit effect highlights with all indices
	for pos in _slot_effect_indices:
		var effect_indices: Array = _slot_effect_indices[pos]
		request_multi_effect_highlight.emit(pos, effect_indices)

## Clears all highlights from the grid.
func clear_highlights() -> void:
	_slot_effect_indices.clear()
	_slot_has_condition.clear()
	
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var pos = Vector2i(x, y)
			request_multi_effect_highlight.emit(pos, [])
			request_condition_highlight.emit(pos, false)

## Returns the effect indices affecting a specific position.
## Useful for UI queries.
func get_effects_at_position(pos: Vector2i) -> Array:
	return _slot_effect_indices.get(pos, [])

## Returns whether a position has a condition highlight.
func has_condition_at_position(pos: Vector2i) -> bool:
	return _slot_has_condition.get(pos, false)

# Signals for UI updates
# New signal that passes all effect indices for multi-color support
signal request_multi_effect_highlight(coord: Vector2i, effect_indices: Array)
signal request_condition_highlight(coord: Vector2i, has_condition: bool)

# Legacy signal for backwards compatibility (deprecated)
signal request_highlight(coord: Vector2i, color: Color)
