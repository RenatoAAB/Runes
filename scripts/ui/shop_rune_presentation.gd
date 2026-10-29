extends Node2D
## Visual-only offer presentation. Original RuneUI owns input, tooltip and drag.
@export_group("FlutuaÃ§Ã£o")
@export_range(0.0,8.0,0.25) var float_amplitude := 2.0
@export_range(0.2,10.0,0.1) var float_period := 2.0
@export_range(0.0,360.0,1.0) var phase_step_degrees := 120.0
@export var snap_to_pixel := true
@export_group("Sparks")
@export var particle_counts: Array[int] = [4,6,8,10,14]
@export_range(0.1,5.0,0.1) var particle_lifetime := 1.6
@export var particle_speed_min := 4.0
@export var particle_speed_max := 8.0
@export var particle_spread := 35.0
@export var particle_gravity := Vector2(0,-2)
@export var particle_emission_extents := Vector2(17,15)
@export_group("Brilho e raridades")
@export var rarity_colors: Array[Color] = [Color("#9babb2"),Color("#1ebc73"),Color("#4d9be6"),Color("#905ea9"),Color("#f79617")]
@export var glow_strengths: Array[float] = [0.45,0.50,0.55,0.60,0.65]
@export_range(8.0,48.0,1.0) var glow_diameter := 42.0
@export_range(0.0,0.95,0.05) var glow_plateau := 0.7

var shop: ShopUI
var states: Dictionary = {}
var elapsed := 0.0
var _particle_texture: ImageTexture
var _hidden_disabled_material: ShaderMaterial

func _ready() -> void:
	shop = get_parent() as ShopUI
	var hidden_shader := Shader.new()
	hidden_shader.code = "shader_type canvas_item; void fragment(){ COLOR=vec4(0.0); }"
	_hidden_disabled_material = ShaderMaterial.new()
	_hidden_disabled_material.shader = hidden_shader
	var pixel := Image.create(1,1,false,Image.FORMAT_RGBA8)
	pixel.fill(Color.WHITE)
	_particle_texture = ImageTexture.create_from_image(pixel)
	shop.visibility_changed.connect(_visibility_changed)
	call_deferred("_bind_manager")

func _bind_manager() -> void:
	if shop.shop_manager and not shop.shop_manager.shop_updated.is_connected(_sync):
		shop.shop_manager.shop_updated.connect(_sync)
	_sync()

func _visibility_changed() -> void:
	if not shop.is_visible_in_tree(): _clear_all()
	else: _sync()

func _clear(index: int) -> void:
	if not states.has(index): return
	var state: Dictionary = states[index]
	if is_instance_valid(state.ui):
		state.ui.self_modulate = state.original_modulate
		state.ui.disabled_material = state.original_disabled_material
	state.visual.visible = false
	state.particles.emitting = false
	state.particles.restart()
	state.visual.queue_free()
	states.erase(index)

func _clear_all() -> void:
	for index in states.keys(): _clear(index)

func _exit_tree() -> void:
	_clear_all()

func _sync() -> void:
	# ShopUI receives its manager after this child becomes ready.
	if is_instance_valid(shop) and shop.shop_manager and not shop.shop_manager.shop_updated.is_connected(_sync):
		shop.shop_manager.shop_updated.connect(_sync)
	if not is_instance_valid(shop) or not shop.is_visible_in_tree():
		_clear_all()
		return
	var slots := shop.purchasable_runes_container.get_children()
	for i in slots.size():
		var slot: SlotUI = slots[i]
		slot.get_node("Sprite2D").visible = false
		var ui: RuneUI = slot.rune_ui
		if not is_instance_valid(ui) or not ui.rune_instance:
			_clear(i)
			continue
		if states.has(i) and states[i].ui != ui: _clear(i)
		if not states.has(i): _create(i,slot,ui)
		var state: Dictionary = states[i]
		ui.self_modulate = Color(1,1,1,0)
		state.rune.texture = ui.texture
		# Suppress only this input control; its legacy disabled shader ignores alpha.
		ui.disabled_material = _hidden_disabled_material
		state.rune.material = null if ui.rune_instance.can_activate() else state.original_disabled_material
		state.rune.size = ui.texture.get_size()
		state.rune.position = -state.rune.size*0.5
		_configure(state,int(ui.rune_instance.data.rarity))

func _create(index: int, slot: SlotUI, ui: RuneUI) -> void:
	var visual := Node2D.new()
	visual.name = "OfferVisual%d" % index
	add_child(visual)
	var glow := Sprite2D.new()
	glow.name = "Glow"
	visual.add_child(glow)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	glow.material = additive
	var particles := CPUParticles2D.new()
	particles.name = "Sparks"
	particles.texture = _particle_texture
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.material = additive
	particles.direction = Vector2(0,-1)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	visual.add_child(particles)
	var draw := TextureRect.new()
	draw.name = "RuneVisual"
	draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw.expand_mode = ui.expand_mode
	draw.stretch_mode = ui.stretch_mode
	draw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.add_child(draw)
	states[index] = {"slot":slot,"ui":ui,"original_modulate":ui.self_modulate,"original_disabled_material":ui.disabled_material,"visual":visual,"glow":glow,"particles":particles,"rune":draw,"signature":""}

func _configure(state: Dictionary, rarity: int) -> void:
	var r := clampi(rarity,0,4)
	var signature := str([r,particle_counts,particle_lifetime,particle_speed_min,particle_speed_max,particle_spread,particle_gravity,particle_emission_extents,rarity_colors,glow_strengths,glow_diameter,glow_plateau])
	if state.signature == signature: return
	state.signature = signature
	var color: Color = rarity_colors[mini(r,rarity_colors.size()-1)] if not rarity_colors.is_empty() else Color("#c7dcd0")
	var strength: float = glow_strengths[mini(r,glow_strengths.size()-1)] if not glow_strengths.is_empty() else 0.0
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,clampf(glow_plateau,0.01,0.95),1])
	gradient.colors = PackedColorArray([Color(color,clampf(strength,0.0,1.0)),Color(color,clampf(strength,0.0,1.0)),Color(color,0)])
	var texture := GradientTexture2D.new()
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	texture.gradient = gradient
	state.glow.texture = texture
	state.glow.scale = Vector2.ONE * glow_diameter/64.0
	var particles: CPUParticles2D = state.particles
	var count: int = particle_counts[mini(r,particle_counts.size()-1)] if not particle_counts.is_empty() else 0
	particles.amount = maxi(1,count)
	particles.lifetime = maxf(0.1,particle_lifetime)
	particles.initial_velocity_min = particle_speed_min
	particles.initial_velocity_max = maxf(particle_speed_min,particle_speed_max)
	particles.spread = particle_spread
	particles.gravity = particle_gravity
	# Emit along the perimeter instead of underneath opaque rune pixels.
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU*i/24.0
		points.append(Vector2(cos(angle),sin(angle))*particle_emission_extents)
	particles.emission_points = points
	particles.color = color
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0,0.15,0.7,1])
	fade.colors = PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)])
	particles.color_ramp = fade
	particles.restart()
	particles.emitting = count > 0

func _process(delta: float) -> void:
	_sync()
	if states.is_empty(): return
	elapsed += delta
	var drag: Variant = get_viewport().gui_get_drag_data() if get_viewport().gui_is_dragging() else null
	for index in states:
		var state: Dictionary = states[index]
		var offset := sin(elapsed*TAU/maxf(float_period,0.01)+deg_to_rad(phase_step_degrees)*index)*float_amplitude
		if snap_to_pixel: offset = roundf(offset)
		state.visual.position = to_local(state.ui.get_global_rect().get_center()) + Vector2(0,offset)
		# The existing offer (including glow/sparks) travels with its input rune.
		var moving: bool = state.ui.is_dragging_rune()
		state.visual.z_index = RenderingServer.CANVAS_ITEM_Z_MAX if moving else 0
		state.visual.visible = moving or not (drag is Dictionary and drag.get("source_ui") == state.ui)
