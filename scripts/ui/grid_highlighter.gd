class_name GridHighlighter
extends Node

## Manages the visual highlighting of the grid based on Rune effects.
## Supports multiple effects affecting the same slot with split visualization.
## 3-pass system: Condition (green) → Target (effect color) → Value Source (dashed border).

@export var grid_manager: GridManager

# We need a context to run the queries.
var _preview_context: BattleContext

# Tracks which effect indices affect each slot position
# Dictionary[Vector2i, Array[int]]
var _slot_effect_indices: Dictionary = {}

# Tracks condition slots separately
# Dictionary[Vector2i, bool]
var _slot_has_condition: Dictionary = {}

# Tracks value source slots per effect index
# Dictionary[Vector2i, Array[int]]
var _slot_value_source_indices: Dictionary = {}

# Directional movement preview links.
# Array[Dictionary] with keys: source(Vector2i), destination(Vector2i), effect_index(int)
var _movement_links: Array[Dictionary] = []

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
	
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		_highlight_game_effect(effect, rune, origin_slot, i)
	
	# Emit all signals
	_emit_highlights()


## Highlights a new GameEffect using 3-pass system.
func _highlight_game_effect(effect: GameEffect, rune: RuneInstance, origin_slot: GridSlot, index: int) -> void:
	var ctx = EffectContext.new(rune, origin_slot, _preview_context)
	ctx.effect_index = index
	
	var highlights = effect.get_all_highlights(ctx)
	
	# Pass 1: Condition slots (always shown for feedback)
	for slot in highlights["condition"]:
		_slot_has_condition[slot.grid_position] = true
	
	# Evaluate condition for gating target/value_source
	var condition_met = true
	if effect.condition:
		condition_met = effect.condition.evaluate(ctx)
	
	if condition_met:
		# Pass 2: Target slots
		for slot in highlights["target"]:
			_add_effect_highlight(slot.grid_position, index)
		
		# Pass 3: Value Source slots
		for slot in highlights["value_source"]:
			var pos = slot.grid_position
			if not _slot_value_source_indices.has(pos):
				_slot_value_source_indices[pos] = []
			if not _slot_value_source_indices[pos].has(index):
				_slot_value_source_indices[pos].append(index)

		# Pass 4: Directional movement links (origin -> destination)
		if effect.action and effect.action.has_method("get_preview_links"):
			var links: Array = effect.action.get_preview_links(ctx, highlights["target"])
			for link in links:
				var source_pos = link.get("source")
				var destination_pos = link.get("destination")
				if not (source_pos is Vector2i) or not (destination_pos is Vector2i):
					continue

				# Ensure both endpoints are highlighted.
				_add_effect_highlight(source_pos, index)
				_add_effect_highlight(destination_pos, index)

				_movement_links.append({
					"source": source_pos,
					"destination": destination_pos,
					"effect_index": index,
				})


func _add_effect_highlight(pos: Vector2i, effect_index: int) -> void:
	if not _slot_effect_indices.has(pos):
		_slot_effect_indices[pos] = []
	if not _slot_effect_indices[pos].has(effect_index):
		_slot_effect_indices[pos].append(effect_index)


## Emits all highlight signals after collecting data.
func _emit_highlights() -> void:
	# Emit condition highlights
	for pos in _slot_has_condition:
		request_condition_highlight.emit(pos, true)
	
	# Emit effect highlights with all indices
	for pos in _slot_effect_indices:
		request_multi_effect_highlight.emit(pos, _slot_effect_indices[pos])
	
	# Emit value source highlights
	for pos in _slot_value_source_indices:
		request_value_source_highlight.emit(pos, _slot_value_source_indices[pos])

	# Emit directional movement links
	request_movement_links.emit(_movement_links)

## Clears all highlights from the grid.
func clear_highlights() -> void:
	_slot_effect_indices.clear()
	_slot_has_condition.clear()
	_slot_value_source_indices.clear()
	_movement_links.clear()
	
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var pos = Vector2i(x, y)
			request_multi_effect_highlight.emit(pos, [])
			request_condition_highlight.emit(pos, false)
			request_value_source_highlight.emit(pos, [])

	request_movement_links.emit([])

## Returns the effect indices affecting a specific position.
## Useful for UI queries.
func get_effects_at_position(pos: Vector2i) -> Array:
	return _slot_effect_indices.get(pos, [])

## Returns whether a position has a condition highlight.
func has_condition_at_position(pos: Vector2i) -> bool:
	return _slot_has_condition.get(pos, false)

## Returns the value source effect indices at a specific position.
func get_value_sources_at_position(pos: Vector2i) -> Array:
	return _slot_value_source_indices.get(pos, [])

# Signals for UI updates
signal request_multi_effect_highlight(coord: Vector2i, effect_indices: Array)
signal request_condition_highlight(coord: Vector2i, has_condition: bool)
signal request_value_source_highlight(coord: Vector2i, effect_indices: Array)
signal request_movement_links(links: Array)

# Legacy signal for backwards compatibility (deprecated)
signal request_highlight(coord: Vector2i, color: Color)
