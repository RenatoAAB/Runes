class_name MultiEffectOverlay
extends Control

## Visual overlay that displays multiple effect colors on a slot.
## When multiple effects target the same slot, divides the slot vertically
## into equal sections, each colored by the corresponding effect.

# Current effect indices being displayed
var _effect_indices: Array = []

# Whether this slot has a condition highlight
var _has_condition: bool = false

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

## Clears all highlights.
func clear() -> void:
	_effect_indices.clear()
	_has_condition = false
	queue_redraw()

func _draw() -> void:
	var rect_size = size
	
	# Draw condition border if active
	if _has_condition:
		var border_color = EffectColors.CONDITION_GRID
		var border_width = 3.0
		# Draw as a border rectangle
		draw_rect(Rect2(Vector2.ZERO, rect_size), border_color, false, border_width)
	
	# Draw effect overlays
	if _effect_indices.is_empty():
		return
	
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

## Returns the current effect indices.
func get_effect_indices() -> Array:
	return _effect_indices.duplicate()

## Returns whether any effects are being displayed.
func has_effects() -> bool:
	return not _effect_indices.is_empty()

## Returns the number of effects being displayed.
func get_effect_count() -> int:
	return _effect_indices.size()
