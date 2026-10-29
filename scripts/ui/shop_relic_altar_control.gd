extends Button
## ShopManager owns the seal; the circle follows the same authored crystal frames.
const ROOT := "res://sprites/scenes/shop/relic-altar/"
const OUTLINE := preload("res://resources/shaders/outline_hover.gdshader")
const CIRCLE_DIM := Color("#0eaf9b")
const CIRCLE_BRIGHT := Color("#8ff8e2")
var shop: ShopUI
var crystals: Array[Sprite2D] = []
var outlines: Array[ShaderMaterial] = []
var hit_images: Array[Image] = []
var hit_origins: Array[Vector2] = []
var red_circle: Sprite2D
var sealed_circle: Sprite2D
var circle_mask: Image
var altar_hit_image: Image
var info_panel: PanelContainer
var info_label: Label
var hovered := false
var circle_hovered := false
var initialized := false
var shown_sealed := false
var phase := "open"
var phase_time := 0.0
var current_frame := 0
var pointer_position := Vector2(-100,-100)

func _ready() -> void:
	shop = get_parent() as ShopUI
	text = ""
	position = Vector2(473,46)
	size = Vector2(108,90)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(func(): hovered = true; _update_tooltip())
	mouse_exited.connect(func(): hovered = false; _update_tooltip())
	shop.visibility_changed.connect(_visibility_changed)
	get_window().mouse_exited.connect(_pointer_left_window)
	call_deferred("_setup_art")

func _sprite(name_text: String, file: String, point: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name_text
	sprite.texture = load(ROOT + file)
	sprite.centered = false
	sprite.position = point
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop.get_node("FountainArt").add_child(sprite)
	return sprite

func _setup_art() -> void:
	var altar_sprite := _sprite("RelicAltar","altar.png",Vector2(473,132))
	altar_hit_image = altar_sprite.texture.get_image()
	for part in [
		["RelicPedestalLeft","pedestal-left.png",Vector2(473,65)],
		["RelicPedestalRight","pedestal-right.png",Vector2(536,95)]]:
		var sprite := _sprite(part[0],part[1],part[2])
		var source := sprite.texture.get_image()
		source.convert(Image.FORMAT_RGBA8)
		hit_images.append(source)
		hit_origins.append(sprite.position-position)
		var padded := Image.create(source.get_width()+4,source.get_height()+4,false,Image.FORMAT_RGBA8)
		padded.fill(Color.TRANSPARENT)
		padded.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(2,2))
		sprite.texture = ImageTexture.create_from_image(padded)
		sprite.position -= Vector2(2,2)
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE
		outline.set_shader_parameter("outline_width",1.0)
		outline.set_shader_parameter("outline_color",Color("#b6fff5"))
		outline.set_shader_parameter("show_outline",false)
		sprite.material = outline
		outlines.append(outline)
	var sheet: Texture2D = load(ROOT + "crystal-binding-sheet.png")
	for point in [Vector2(483,46),Vector2(546,76)]:
		var crystal := _sprite("RelicCrystalLeft" if crystals.is_empty() else "RelicCrystalRight","crystal-binding-sheet.png",point)
		crystal.hframes = 8
		crystals.append(crystal)
		var hit := sheet.get_image().get_region(Rect2i(0,0,25,33))
		hit.convert(Image.FORMAT_RGBA8)
		hit_images.append(hit)
		hit_origins.append(point-position)
	sealed_circle = _sprite("RelicSealedCircle","altar-circle-mask.png",Vector2(473,132))
	sealed_circle.visible = false
	red_circle = _sprite("RelicSealedEmptyCircle","altar-circle-red.png",Vector2(473,132))
	red_circle.visible = false
	circle_mask = load(ROOT + "altar-circle-mask.png").get_image()
	info_panel = PanelContainer.new()
	info_panel.name = "RelicSealTooltip"
	info_panel.position = Vector2(371,231)
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.z_index = 50
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#241d2d")
	background.content_margin_left = 5
	background.content_margin_right = 5
	background.content_margin_top = 4
	background.content_margin_bottom = 4
	info_panel.add_theme_stylebox_override("panel",background)
	info_label = Label.new()
	info_label.custom_minimum_size.x = 246
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size",9)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_label)
	shop.add_child(info_panel)
	info_panel.visible = false
	sync_state()

func _opaque(image: Image, point: Vector2) -> bool:
	var pixel := Vector2i(point.floor())
	return Rect2i(Vector2i.ZERO,image.get_size()).has_point(pixel) and image.get_pixelv(pixel).a > 0.08

func _has_point(point: Vector2) -> bool:
	for i in hit_images.size():
		if _opaque(hit_images[i],point-hit_origins[i]):
			return true
	return false

func sync_state() -> void:
	if not shop or not shop.shop_manager or not red_circle:
		return
	var sealed: bool = shop.shop_manager.relic_sealed
	if not initialized:
		phase = "sealed" if sealed else "open"
		initialized = true
	elif sealed != shown_sealed:
		phase = "capture" if sealed else "release"
		phase_time = 0.0
	shown_sealed = sealed
	red_circle.visible = sealed and shop.shop_manager.available_relics.is_empty()
	_update_frame()
	_update_tooltip()

func _update_frame() -> void:
	if phase == "capture":
		if phase_time >= 0.5:
			phase = "sealed"
			phase_time -= 0.5
		else:
			current_frame = 1 + mini(int(phase_time / 0.1),4)
	elif phase == "release":
		if phase_time >= 0.5:
			phase = "open"
		else:
			current_frame = 5 - mini(int(phase_time / 0.1),4)
	if phase == "open": current_frame = 0
	if phase == "sealed": current_frame = 6 + (int(phase_time / 0.4) % 2)
	for crystal in crystals: crystal.frame = current_frame
	_update_circle_pulse()

func _update_circle_pulse() -> void:
	if not sealed_circle or not red_circle or not shop.shop_manager:
		return
	# Frames6/7 are the original400ms held phases; no independent pulse clock.
	var bright := current_frame == 7
	sealed_circle.visible = shown_sealed and not shop.shop_manager.available_relics.is_empty()
	sealed_circle.modulate = CIRCLE_BRIGHT if bright else CIRCLE_DIM
	# The empty-altar warning remains the original fixed red, regardless of phase.

func _visibility_changed() -> void:
	if not shop.is_visible_in_tree():
		_pointer_left_window()

func _pointer_left_window() -> void:
	pointer_position = Vector2(-100,-100)
	hovered = false
	circle_hovered = false
	for outline in outlines: outline.set_shader_parameter("show_outline",false)
	if info_panel: info_panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer_position = event.position

func _update_tooltip() -> void:
	if not info_label or not shop.shop_manager:
		return
	var manager := shop.shop_manager
	var cost := manager.get_relic_seal_cost()
	var message := ""
	if manager.relic_sealed:
		if manager.available_relics.is_empty():
			message = "Selo ativo sem relíquia.\nNão haverá nova oferta na próxima rodada.\nLiberar selo: %d Mana." % cost
		else:
			message = "Selo ativo: esta relíquia fica para as próximas rodadas.\nLiberar selo: %d Mana." % cost
	elif manager.available_relics.is_empty():
		message = "Altar livre e vazio.\nAguarde a próxima rodada para uma nova oferta."
	else:
		message = "Selar relíquia: %d Mana.\nMantém a oferta entre rodadas, até liberar o selo.\nLiberar também custa %d Mana, mesmo após comprar." % [cost,ShopConfig.RELIC_UNSEAL_COST]
	if (manager.relic_sealed or not manager.available_relics.is_empty()) and not manager.can_toggle_relic_seal():
		message += "\nMana insuficiente."
	info_label.text = message
	info_label.modulate = Color("#ff9b91") if red_circle.visible else Color.WHITE
	info_panel.visible = shop.is_visible_in_tree() and (hovered or circle_hovered)

func _process(delta: float) -> void:
	if not red_circle: return
	phase_time += delta
	_update_frame()
	# The circle offers passive hover information; it never intercepts purchase clicks.
	var local_pointer := shop.get_global_transform_with_canvas().affine_inverse() * pointer_position
	circle_hovered = shop.is_visible_in_tree() and shop.shop_manager != null and shop.shop_manager.available_relics.is_empty() and _opaque(altar_hit_image,local_pointer-Vector2(473,132))
	for outline in outlines:
		outline.set_shader_parameter("show_outline",hovered and shop.is_visible_in_tree() and not disabled)
	if hovered or circle_hovered:
		_update_tooltip()
	elif info_panel:
		info_panel.visible = false
