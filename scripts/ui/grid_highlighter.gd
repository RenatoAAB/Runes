class_name GridHighlighter
extends Node

## Manages the visual highlighting of the grid based on Rune effects.

@export var grid_manager: GridManager
# Colors
const COLOR_CONDITION = Color(0, 1, 0, 0.3) # Green
const COLOR_CLEAR = Color(0, 0, 0, 0)

# Effect target colors (cycling)
const EFFECT_COLORS = [
	Color(1, 0, 0, 0.3),    # Red
	Color(0, 0, 1, 0.3),    # Blue
	Color(1, 1, 0, 0.3)     # Yellow
]

# We need a context to run the queries.
var _preview_context: BattleContext

func _ready() -> void:
	if grid_manager:
		_preview_context = BattleContext.new(grid_manager)

func highlight_rune_effects(rune: RuneInstance, origin_slot: GridSlot) -> void:
	clear_highlights()
	
	if not rune or not origin_slot:
		return
		
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		
		# 1. Highlight Condition Sources (Green)
		if effect.condition:
			var condition_slots = effect.condition.get_relevant_slots(rune, _preview_context, origin_slot)
			for slot in condition_slots:
				_set_slot_color(slot, COLOR_CONDITION)
		
		# 2. Highlight Targets (Cycling Colors)
		if effect.target:
			var target_slots = effect.target.get_targets(rune, _preview_context, origin_slot)
			var color = EFFECT_COLORS[i % EFFECT_COLORS.size()]
			for slot in target_slots:
				_set_slot_color(slot, color)

func clear_highlights() -> void:
	# Or just iterate all valid coords
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			request_highlight.emit(Vector2i(x, y), COLOR_CLEAR)

signal request_highlight(coord: Vector2i, color: Color)

func _set_slot_color(slot: GridSlot, color: Color) -> void:
	request_highlight.emit(slot.grid_position, color)
