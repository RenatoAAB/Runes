class_name MovementLinkOverlay
extends Control

## Draws directional arrows linking movement source and destination slots.

@export var line_width: float = 2.5
@export var arrow_size: float = 7.0
@export var endpoint_padding: float = 10.0
@export var fallback_color: Color = Color(1.0, 0.85, 0.25, 0.95)

var _links: Array = []
var _slot_map: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)


func _on_resized() -> void:
	queue_redraw()


func set_slot_map(slot_map: Dictionary) -> void:
	_slot_map = slot_map
	queue_redraw()


func set_links(links: Array) -> void:
	_links = links.duplicate(true)
	queue_redraw()


func clear_links() -> void:
	_links.clear()
	queue_redraw()


func _draw() -> void:
	if _links.is_empty() or _slot_map.is_empty():
		return

	for link in _links:
		var source_coord = link.get("source")
		var destination_coord = link.get("destination")
		if not (source_coord is Vector2i) or not (destination_coord is Vector2i):
			continue

		var source_slot = _slot_map.get(source_coord) as Control
		var destination_slot = _slot_map.get(destination_coord) as Control
		if not source_slot or not destination_slot:
			continue

		var source_center = _canvas_to_local(source_slot.get_global_rect().get_center())
		var destination_center = _canvas_to_local(destination_slot.get_global_rect().get_center())
		var distance = source_center.distance_to(destination_center)
		if distance <= 1.0:
			continue

		var dir = (destination_center - source_center).normalized()
		var start = source_center + dir * endpoint_padding
		var end = destination_center - dir * (endpoint_padding + arrow_size)
		if start.distance_to(end) <= 1.0:
			continue

		var effect_index = int(link.get("effect_index", -1))
		var color = fallback_color
		if effect_index >= 0:
			color = EffectColors.get_effect_ui_color(effect_index)
			color.a = 0.95

		draw_line(start, end, color, line_width, true)
		draw_circle(start, maxf(1.5, line_width * 0.7), color)
		_draw_arrow_head(end, dir, color)


func _canvas_to_local(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point


func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color) -> void:
	if direction.length_squared() <= 0.0001:
		return

	var normal = Vector2(-direction.y, direction.x)
	var back = tip - direction * arrow_size
	var left = back + normal * (arrow_size * 0.55)
	var right = back - normal * (arrow_size * 0.55)

	var points = PackedVector2Array([tip, left, right])
	draw_colored_polygon(points, color)
