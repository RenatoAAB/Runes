extends Node2D
## Visual composition only. SlotUI and the existing altar keep all input/state.
const HOVER_OUTLINE := preload("res://resources/shaders/outline_hover.gdshader")
@export var presentation_enabled := true
@export var base_visual_offset := Vector2(0, -4)
@export_group("Flutuação")
@export_range(0.0, 8.0, 0.25) var float_amplitude := 2.0
@export_range(0.2, 10.0, 0.1) var float_period := 2.0
@export var snap_to_pixel := true
@export_group("Brilho")
@export var glow_enabled := true
@export var glow_color := Color("#ffffff")
@export_range(0.0, 1.0, 0.05) var glow_strength := 0.6
@export_range(16.0, 64.0, 1.0) var glow_diameter := 46.0
@export_range(0.05, 0.95, 0.05) var glow_plateau := 0.7
@export_range(0.0, 1.0, 0.05) var sealed_glow_scale := 0.5
@export var hover_color := Color("#b6fff5")
@export_group("Vínculos")
@export var bindings_enabled := true
@export var binding_color := Color("#4d9be6")
@export var link_color := Color("#8ff8e2")
@export_range(4.0, 12.0, 1.0) var link_spacing := 6.0

var shop: ShopUI
var states: Dictionary = {}
var elapsed := 0.0
var _manager: ShopManager
var _circle_points := PackedVector2Array()
var binding_intensity := 1.0

func _ready() -> void:
	shop = get_parent() as ShopUI
	shop.visibility_changed.connect(_sync)
	call_deferred("_sync")

func _exit_tree() -> void:
	_clear_all()
	if is_instance_valid(_manager) and _manager.shop_updated.is_connected(_sync):
		_manager.shop_updated.disconnect(_sync)

func _clear(index: int) -> void:
	if not states.has(index): return
	var state: Dictionary = states[index]
	if is_instance_valid(state.icon) and not state.icon.is_queued_for_deletion():
		state.icon.self_modulate = state.original_modulate
	if is_instance_valid(state.backdrop):
		state.backdrop.visible = state.original_backdrop_visible
	state.visual.hide()
	state.visual.queue_free()
	states.erase(index)
	queue_redraw()

func _clear_all() -> void:
	for index in states.keys(): _clear(index)

func _sync() -> void:
	if not is_instance_valid(shop): return
	if _manager != shop.shop_manager:
		if is_instance_valid(_manager) and _manager.shop_updated.is_connected(_sync):
			_manager.shop_updated.disconnect(_sync)
		_manager = shop.shop_manager
		if _manager: _manager.shop_updated.connect(_sync)
	if not presentation_enabled or not shop.is_visible_in_tree() or not _manager:
		_clear_all()
		return
	var slots := shop.purchasable_relics_container.get_children()
	for index in states.keys():
		if index >= slots.size(): _clear(index)
	for index in slots.size():
		var slot := slots[index] as SlotUI
		var icon := slot._display_icon
		if not slot.is_visible_in_tree() or not is_instance_valid(icon) or icon.is_queued_for_deletion() or not icon.texture or index >= _manager.available_relics.size():
			_clear(index)
			continue
		if states.has(index) and (states[index].icon != icon or states[index].texture != icon.texture):
			_clear(index)
		if not states.has(index): _create(index, slot, icon)
		var state: Dictionary = states[index]
		icon.self_modulate = Color(1, 1, 1, 0)
		state.backdrop.hide()
		_configure_glow(state)
		var offset := 0.0 if _manager.relic_sealed else sin(elapsed * TAU / maxf(float_period, 0.01)) * float_amplitude
		if snap_to_pixel: offset = roundf(offset)
		state.visual.position = to_local(icon.get_global_rect().get_center()) + base_visual_offset + Vector2(0, offset)
		state.glow.visible = glow_enabled
		state.glow.modulate.a = sealed_glow_scale if _manager.relic_sealed else 1.0
		state.hovered = get_viewport().gui_get_hovered_control() == slot
		state.outline.set_shader_parameter("show_outline", state.hovered)
		state.outline.set_shader_parameter("outline_color", hover_color)
	queue_redraw()

func _create(index: int, slot: SlotUI, icon: TextureRect) -> void:
	var visual := Node2D.new()
	visual.name = "RelicVisual%d" % index
	add_child(visual)
	var glow := Sprite2D.new()
	glow.name = "Glow"
	visual.add_child(glow)
	var draw := TextureRect.new()
	draw.name = "RelicVisual"
	draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	draw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	draw.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	draw.texture = icon.texture
	draw.size = icon.texture.get_size()
	draw.position = -draw.size * 0.5
	var outline := ShaderMaterial.new()
	outline.shader = HOVER_OUTLINE
	outline.set_shader_parameter("outline_width", 1.0)
	draw.material = outline
	visual.add_child(draw)
	var backdrop := slot.get_node("Sprite2D") as Sprite2D
	states[index] = {"slot":slot, "icon":icon, "texture":icon.texture, "backdrop":backdrop,
		"original_modulate":icon.self_modulate, "original_backdrop_visible":backdrop.visible,
		"visual":visual, "glow":glow, "draw":draw, "outline":outline, "hovered":false, "glow_signature":"",
		"attachments":_silhouette_points(icon.texture)}

func _configure_glow(state: Dictionary) -> void:
	var signature := str([glow_color, glow_strength, glow_diameter, glow_plateau])
	if signature == state.glow_signature: return
	state.glow_signature = signature
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, clampf(glow_plateau, 0.05, 0.95), 1.0])
	gradient.colors = PackedColorArray([Color(glow_color, glow_strength), Color(glow_color, glow_strength), Color(glow_color, 0)])
	var texture := GradientTexture2D.new()
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	state.glow.texture = texture
	state.glow.scale = Vector2.ONE * glow_diameter / 64.0

func _nearest_opaque(image: Image, target: Vector2) -> Vector2:
	var nearest := target
	var distance := INF
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.1: continue
			var point := Vector2(x, y)
			var candidate := point.distance_squared_to(target)
			if candidate < distance:
				distance = candidate
				nearest = point
	return nearest

func _silhouette_points(texture: Texture2D) -> PackedVector2Array:
	var source: Texture2D = texture.get_frame_texture(0) if texture is AnimatedTexture else texture
	var image: Image = source.get_image()
	var bounds := Rect2(image.get_used_rect())
	var center := bounds.get_center()
	var points := PackedVector2Array()
	for target in [Vector2(bounds.position.x, center.y), Vector2(bounds.end.x - 1, center.y), Vector2(center.x, bounds.end.y - 1)]:
		points.append(_nearest_opaque(image, target) - texture.get_size() * 0.5)
	return points

func circle_anchors() -> PackedVector2Array:
	var circle := shop.relic_seal_button.get("sealed_circle") as Sprite2D
	if not is_instance_valid(circle): return PackedVector2Array()
	if _circle_points.is_empty():
		var image := circle.texture.get_image()
		var bounds := Rect2(image.get_used_rect())
		var center := bounds.get_center()
		for target in [Vector2(bounds.position.x, center.y), Vector2(bounds.end.x - 1, center.y), Vector2(center.x, bounds.end.y - 1)]:
			_circle_points.append(_nearest_opaque(image, target))
	var points := PackedVector2Array()
	for point in _circle_points:
		points.append(to_local(circle.to_global(point)))
	return points

func _draw() -> void:
	if not bindings_enabled or states.is_empty() or not _manager or not _manager.relic_sealed: return
	var anchors := circle_anchors()
	if anchors.size() != 3: return
	# Read the live rendered circle, after its process update; no second pulse clock.
	var circle := shop.relic_seal_button.get("sealed_circle") as Sprite2D
	binding_intensity = clampf(circle.modulate.get_luminance() * circle.modulate.a, 0.0, 1.0)
	var shadow := Color("#244b79")
	shadow.a *= binding_intensity
	var line := binding_color
	line.a *= binding_intensity
	var link := link_color
	link.a *= binding_intensity
	for state: Dictionary in states.values():
		for i in 3:
			var start: Vector2 = state.visual.position + state.attachments[i]
			var finish := anchors[i]
			draw_line(start, finish, shadow, 3.0, false)
			draw_line(start, finish, line, 1.0, false)
			var direction := (finish - start).normalized()
			var side := Vector2(-direction.y, direction.x)
			var length := start.distance_to(finish)
			for step in range(1, int(length / maxf(link_spacing, 4.0))):
				var midpoint := start + direction * step * link_spacing
				var loop := PackedVector2Array([midpoint - direction * 2, midpoint + side, midpoint + direction * 2, midpoint - side, midpoint - direction * 2])
				draw_polyline(loop, link, 1.0, false)
			draw_circle(finish, 2.0, line)

func _process(delta: float) -> void:
	elapsed += delta
	_sync()
