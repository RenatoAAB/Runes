extends Node2D
## Scene-only light: observes the existing successful Overclock state transition.
## Never buys, refreshes, moves hitboxes, or mutates source sprite pixels.

const LIGHT_SHADER := preload("res://resources/shaders/shop_room_light.gdshader")
const FIRE_SHEET := preload("res://sprites/scenes/shop/lighting/fire-sheet.png")
const FIRE_PLAYBACK := preload("res://sprites/scenes/shop/lighting/playback.json")
const FLOOR_SHADOWS := preload("res://scripts/ui/shop_floor_shadows.gd")
const WATER_SHADER := preload("res://resources/shaders/shop_water_receiver.gdshader")
const FOREGROUND_SHADER := preload("res://resources/shaders/shop_foreground_receiver.gdshader")
const TUBES_SCRIPT := preload("res://scripts/ui/shop_furnace_tubes.gd")

@export_group("Fountain — weak blue")
@export var fountain_center := Vector2(317,183)
@export var fountain_radius := Vector2(125,88)
@export var fountain_color := Color("#2e80ff")
@export_range(0.0,0.5,0.005) var fountain_strength := 0.055
@export_group("Furnace — stable yellow")
@export var furnace_center := Vector2(109,101)
@export var idle_radius := Vector2(90,75)
@export var active_radius := Vector2(220,172)
@export var furnace_color := Color("#ffce53")
@export_range(0.0,0.8,0.005) var idle_strength := 0.15
@export_group("Successful Overclock — orange surge and retained heat")
@export var surge_color := Color("#ff6612")
@export_range(0.5,8.0,0.1) var surge_seconds := 2.4
@export_range(0.0,1.0,0.01) var peak_strength := 0.38
@export_range(0.0,0.5,0.01) var peak_room_strength := 0.19
@export_range(0.0,1.0,0.01) var heated_strength := 0.24
@export_range(0.0,0.5,0.005) var heated_room_strength := 0.05
@export_range(0.0,2.0,0.05) var flicker_amount := 1.0
@export_group("Pixel light — authored canvas")
@export_range(1,2,1) var pixel_grid := 1
@export_range(3,5,1) var light_bands := 5
@export_group("Floor shadows — short pixel projections")
@export var shadows_enabled := true
@export_range(0.0,1.0,0.05) var shadow_strength := 0.65
@export_range(0.0,2.0,0.1) var shadow_length_scale := 1.0
@export var water_surface_shadows := true
@export_range(0.0,0.2,0.01) var water_surface_depth := 0.12
@export_group("Elevated foreground")
@export var foreground_enabled := true
@export_range(0.0,0.2,0.01) var foreground_shadow_depth := 0.10
@export_group("Review switches")
@export var effects_enabled := true
@export var fountain_enabled := true
@export var furnace_enabled := true
@export var fire_enabled := true
@export var tubes_enabled := true

var heated := false
var surge_elapsed := -1.0
var activation_count := 0
var light_material: ShaderMaterial
var fire: AnimatedSprite2D
var tubes: Sprite2D
var fire_playback: Dictionary
var receiver_mask: Image
var water_receiver_mask: Image
var water_material: ShaderMaterial
var _water_sprite: AnimatedSprite2D
var foreground_receiver_mask: Image
var foreground_material: ShaderMaterial
var _background_sprite: Sprite2D
var shadows_ready := false
var receiver_build_ms := 0
var _shop: ShopUI
var _manager: ShopManager

func _ready() -> void:
	# Liquid pixels receive the same light as the original glass/metal around them.
	tubes = TUBES_SCRIPT.new()
	add_child(tubes)
	var overlay := ColorRect.new()
	overlay.name = "LightFalloff"
	overlay.size = Vector2(640,360)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light_material = ShaderMaterial.new()
	light_material.shader = LIGHT_SHADER
	overlay.material = light_material
	add_child(overlay)
	_shop = get_parent().get_parent() as ShopUI
	_setup_fire()
	call_deferred("_bind_manager")
	call_deferred("_setup_floor_shadows")
	_update_light()

func _setup_fire() -> void:
	fire = AnimatedSprite2D.new()
	fire.name = "FurnaceFire"
	fire.position = Vector2(14,18)
	fire.centered = false
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	fire_playback = FIRE_PLAYBACK.data
	for animation: String in ["surge","heated"]:
		frames.add_animation(animation)
		frames.set_animation_loop(animation,true)
		frames.set_animation_speed(animation,1000.0)
		for authored: Dictionary in fire_playback.animations[animation].frames:
			var texture := AtlasTexture.new()
			texture.atlas = FIRE_SHEET
			texture.region = Rect2(int(authored.index)*131,0,131,168)
			texture.filter_clip = true
			frames.add_frame(animation,texture,float(authored.duration_ms))
	fire.sprite_frames = frames
	fire.play("heated")
	fire.visible = true
	add_child(fire)
	fire.frame_changed.connect(_update_light)

func _setup_floor_shadows() -> void:
	# Wait for the original deferred altar/furnace setup to finish before masking.
	await get_tree().process_frame
	await get_tree().process_frame
	var started := Time.get_ticks_msec()
	receiver_mask = FLOOR_SHADOWS.build(get_parent())
	water_receiver_mask = FLOOR_SHADOWS.build_water(get_parent())
	foreground_receiver_mask = FLOOR_SHADOWS.build_foreground(get_parent())
	receiver_build_ms = Time.get_ticks_msec()-started
	if not receiver_mask:
		return
	light_material.set_shader_parameter("floor_mask",ImageTexture.create_from_image(receiver_mask))
	if water_receiver_mask:
		var water_texture := ImageTexture.create_from_image(water_receiver_mask)
		light_material.set_shader_parameter("water_mask",water_texture)
		var water := get_parent().get_node_or_null("FountainWater") as AnimatedSprite2D
		# Preserve any pre-existing authored material; warm occlusion still works.
		if water and not water.material:
			_water_sprite = water
			water_material = ShaderMaterial.new()
			water_material.shader = WATER_SHADER
			water_material.set_shader_parameter("water_mask",water_texture)
			water_material.set_shader_parameter("water_origin",water.position)
			water.material = water_material
	light_material.set_shader_parameter("water_receiver_ready",water_receiver_mask != null)
	if foreground_receiver_mask:
		var foreground_texture := ImageTexture.create_from_image(foreground_receiver_mask)
		light_material.set_shader_parameter("foreground_mask",foreground_texture)
		var background := get_parent().get_node_or_null("Background") as Sprite2D
		if background and not background.material:
			_background_sprite = background
			foreground_material = ShaderMaterial.new()
			foreground_material.shader = FOREGROUND_SHADER
			foreground_material.set_shader_parameter("foreground_mask",foreground_texture)
			background.material = foreground_material
	light_material.set_shader_parameter("shadow_footprints",PackedVector4Array(FLOOR_SHADOWS.FOOTPRINTS))
	light_material.set_shader_parameter("shadow_lengths",PackedFloat32Array(FLOOR_SHADOWS.LENGTHS))
	shadows_ready = true
	_update_light()

func _exit_tree() -> void:
	# Restore only our own installation; never replace another owner's material.
	if is_instance_valid(_water_sprite) and _water_sprite.material == water_material:
		_water_sprite.material = null
	if is_instance_valid(_background_sprite) and _background_sprite.material == foreground_material:
		_background_sprite.material = null

func _bind_manager() -> void:
	if not is_instance_valid(_shop) or not is_instance_valid(_shop.shop_manager):
		return
	_manager = _shop.shop_manager
	_manager.shop_updated.connect(_sync_purchase_state)
	# Entering a scene with an existing purchase restores heat without replaying fire.
	heated = _manager.overclock_purchased_this_round
	if heated:
		fire.play("heated")
	_update_light()
	_update_tubes(0.0)

func _sync_purchase_state() -> void:
	var purchased := _manager.overclock_purchased_this_round
	if purchased and not heated:
		heated = true
		surge_elapsed = 0.0
		activation_count += 1
		if fire:
			fire.play("surge")
	elif not purchased:
		var was_heated := heated
		heated = false
		surge_elapsed = -1.0
		if fire and was_heated:
			fire.play("heated")
			fire.set_frame_and_progress(0,0.0)
	_update_light()
	_update_tubes(0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(_manager):
		_bind_manager()
	if surge_elapsed >= 0.0:
		surge_elapsed += delta
		if surge_elapsed >= surge_seconds:
			surge_elapsed = -1.0
			if fire:
				fire.play("heated")
	_update_light()
	_update_tubes(delta)

func _update_tubes(delta: float) -> void:
	if tubes:
		tubes.visible = tubes_enabled
		tubes.update_playback(delta,heated,surge_elapsed)

func _update_light() -> void:
	if not light_material:
		return
	var source := heated_strength if heated else idle_strength
	var room := heated_room_strength if heated else 0.0
	var warmth := 0.38 if heated else 0.0
	var radius := active_radius if heated else idle_radius
	var water_depth := water_surface_depth*0.4 if heated else 0.0
	if surge_elapsed >= 0.0:
		var phase := surge_elapsed / surge_seconds
		radius = idle_radius.lerp(active_radius,smoothstep(0.0,0.12,phase))
		var envelope := smoothstep(0.0,0.08,phase) * (1.0-smoothstep(0.55,1.0,phase))
		# Authored ragged poses hold their own brightness; never interpolate a sine.
		# Only the overall surge envelope eases toward the retained baseline.
		var energy: float = fire_playback.animations.surge.frames[fire.frame].energy
		var beat := lerpf(1.0,energy,flicker_amount)
		source = lerpf(heated_strength,peak_strength*beat,envelope)
		room = lerpf(heated_room_strength,peak_room_strength*beat,envelope)
		warmth = lerpf(0.38,1.0,envelope)
		water_depth = lerpf(water_surface_depth*0.4,water_surface_depth,envelope)
	for key in ["fountain_center","fountain_radius","fountain_color","furnace_center","furnace_color","surge_color"]:
		light_material.set_shader_parameter(key,get(key))
	light_material.set_shader_parameter("furnace_radius",radius)
	light_material.set_shader_parameter("pixel_grid",float(pixel_grid))
	light_material.set_shader_parameter("light_bands",float(light_bands))
	light_material.set_shader_parameter("fountain_strength",fountain_strength if fountain_enabled else 0.0)
	light_material.set_shader_parameter("furnace_strength",source if furnace_enabled else 0.0)
	light_material.set_shader_parameter("room_strength",room if furnace_enabled else 0.0)
	light_material.set_shader_parameter("warmth",warmth)
	light_material.set_shader_parameter("enabled",1.0 if effects_enabled else 0.0)
	light_material.set_shader_parameter("shadows_enabled",shadows_enabled and shadows_ready)
	light_material.set_shader_parameter("shadow_strength",shadow_strength)
	light_material.set_shader_parameter("shadow_length_scale",shadow_length_scale)
	var shade_foreground := effects_enabled and foreground_enabled and foreground_receiver_mask != null
	light_material.set_shader_parameter("foreground_enabled",shade_foreground)
	if foreground_material:
		foreground_material.set_shader_parameter("shadow_depth",foreground_shadow_depth if shade_foreground else 0.0)
	if water_material:
		water_material.set_shader_parameter("furnace_center",furnace_center)
		water_material.set_shader_parameter("shadow_length_scale",shadow_length_scale)
		water_material.set_shader_parameter("surface_depth",water_depth if effects_enabled and furnace_enabled and shadows_enabled and shadows_ready and water_surface_shadows else 0.0)
	if fire:
		fire.visible = fire_enabled
