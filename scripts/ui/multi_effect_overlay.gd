class_name MultiEffectOverlay
extends Control

## Visual overlay that displays multiple effect colors on a slot.
## When multiple effects target the same slot, divides the slot vertically
## into equal sections, each colored by the corresponding effect.
## Also renders dashed borders for VALUE_SOURCE highlights.

# Current effect indices being displayed
var _effect_indices: Array = []

# Whether this slot has a condition highlight
var _has_condition: bool = false

# Value source effect indices (dashed border)
var _value_source_indices: Array = []

# Dash rendering constants
const DASH_LENGTH := 6.0
const GAP_LENGTH := 4.0
const VALUE_SOURCE_BORDER_WIDTH := 2.5

func _ready() -> void:
	# Ensure we don't block mouse events
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Force redraw when resized
	resized.connect(_on_resized)

func _on_resized() -> void:
	queue_redraw()

## Sets the effect indices to display. Pass empty array to clear.
func set_effect_indices(indices: Array) -> void:
	_effect_indices = indices.duplicate()
	queue_redraw()

## Sets whether to show condition highlight (border/glow).
func set_condition_highlight(has_condition: bool) -> void:
	_has_condition = has_condition
	queue_redraw()

## Sets the value source effect indices for dashed border display.
func set_value_source_indices(indices: Array) -> void:
	_value_source_indices = indices.duplicate()
	queue_redraw()

## Clears all highlights.
func clear() -> void:
	_effect_indices.clear()
	_has_condition = false
	_value_source_indices.clear()
	queue_redraw()

func _draw() -> void:
	var rect_size = size
	
	# Draw effect overlays (TARGET fills)
	if not _effect_indices.is_empty():
		var num_effects = _effect_indices.size()
		
		if num_effects == 1:
			# Single effect: fill entire slot
			var color = EffectColors.get_effect_grid_color(_effect_indices[0])
			draw_rect(Rect2(Vector2.ZERO, rect_size), color, true)
		else:
			# Multiple effects: divide vertically
			var section_width = rect_size.x / num_effects
			
			for i in range(num_effects):
				var effect_index = _effect_indices[i]
				var color = EffectColors.get_effect_grid_color(effect_index)
				var section_rect = Rect2(
					Vector2(i * section_width, 0),
					Vector2(section_width, rect_size.y)
				)
				draw_rect(section_rect, color, true)
			
			# Draw thin separator lines between sections
			var separator_color = Color(1, 1, 1, 0.3)
			for i in range(1, num_effects):
				var x = i * section_width
				draw_line(Vector2(x, 0), Vector2(x, rect_size.y), separator_color, 1.0)
	
	# Draw condition border if active (solid green)
	if _has_condition:
		var border_color = EffectColors.CONDITION_GRID
		var border_width = 3.0
		draw_rect(Rect2(Vector2.ZERO, rect_size), border_color, false, border_width)
	
	# Draw value source dashed borders
	if not _value_source_indices.is_empty():
		# Use the first value source effect's color for the dashed border
		# If multiple, blend by using the first one (most common case is single)
		var vs_color = EffectColors.get_value_source_color(_value_source_indices[0])
		_draw_dashed_rect(Rect2(Vector2(2, 2), rect_size - Vector2(4, 4)), vs_color)


## Draws a dashed rectangle border.
func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	
	for i in range(4):
		var start = corners[i]
		var end = corners[(i + 1) % 4]
		_draw_dashed_line_segment(start, end, color)


## Draws a single dashed line between two points.
func _draw_dashed_line_segment(from: Vector2, to: Vector2, color: Color) -> void:
	var direction = (to - from).normalized()
	var total_length = from.distance_to(to)
	var drawn = 0.0
	
	while drawn < total_length:
		var seg_start = from + direction * drawn
		var seg_end_dist = minf(drawn + DASH_LENGTH, total_length)
		var seg_end = from + direction * seg_end_dist
		draw_line(seg_start, seg_end, color, VALUE_SOURCE_BORDER_WIDTH)
		drawn = seg_end_dist + GAP_LENGTH


## Returns the current effect indices.
func get_effect_indices() -> Array:
	return _effect_indices.duplicate()

## Returns whether any effects are being displayed.
func has_effects() -> bool:
	return not _effect_indices.is_empty()

## Returns the number of effects being displayed.
func get_effect_count() -> int:
	return _effect_indices.size()

## Returns whether any value sources are being displayed.
func has_value_sources() -> bool:
	return not _value_source_indices.is_empty()
