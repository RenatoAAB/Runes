class_name ActivatorSprite
extends Node2D

## Handles click and hover effects for the ativador (battle activator) sprite.
## Replaces the deprecated invisible BattleButton node.
## Battle starts when the player clicks directly on the sprite.

var _sprite: Sprite2D = null
var _shader_material: ShaderMaterial = null
var _is_hovering: bool = false
var _sprite_image: Image = null
var _alpha_threshold: float = 0.08


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D")
	_cache_sprite_image()
	_setup_shader()


func _cache_sprite_image() -> void:
	if not _sprite or not _sprite.texture:
		_sprite_image = null
		return
	_sprite_image = _sprite.texture.get_image()
	if _sprite_image:
		_sprite_image.convert(Image.FORMAT_RGBA8)


func _setup_shader() -> void:
	if not _sprite:
		return
	var shader = load("res://resources/shaders/outline_hover.gdshader") as Shader
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_sprite.material = _shader_material


func _process(_delta: float) -> void:
	if not _sprite or not visible:
		if _is_hovering:
			_is_hovering = false
			_update_hover_shader()
		return

	var local_pos = _sprite.to_local(get_global_mouse_position())
	var hovering = _is_opaque_pixel(local_pos)
	if hovering != _is_hovering:
		_is_hovering = hovering
		_update_hover_shader()


func _input(event: InputEvent) -> void:
	if not _sprite or not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = _sprite.to_local(get_global_mouse_position())
		if _is_opaque_pixel(local_pos):
			_on_activator_clicked()
			get_viewport().set_input_as_handled()


func _is_opaque_pixel(local_pos: Vector2) -> bool:
	if not _sprite:
		return false
	var rect := _sprite.get_rect()
	if not rect.has_point(local_pos):
		return false
	if _sprite_image == null:
		return true

	var uv := (local_pos - rect.position) / rect.size
	uv.x = clampf(uv.x, 0.0, 1.0)
	uv.y = clampf(uv.y, 0.0, 1.0)

	var tex_x := int(floor(uv.x * float(_sprite_image.get_width() - 1)))
	var tex_y := int(floor(uv.y * float(_sprite_image.get_height() - 1)))

	if _sprite.flip_h:
		tex_x = (_sprite_image.get_width() - 1) - tex_x
	if _sprite.flip_v:
		tex_y = (_sprite_image.get_height() - 1) - tex_y

	var alpha := _sprite_image.get_pixel(tex_x, tex_y).a
	return alpha >= _alpha_threshold


func _update_hover_shader() -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("show_outline", _is_hovering)


func _on_activator_clicked() -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("start_battle"):
		game_manager.start_battle()
