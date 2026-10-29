extends Button
## Alpha-aware furnace activation; the existing ShopUI signal owns the purchase.
const OUTLINE := preload("res://resources/shaders/outline_hover.gdshader")
@export_group("Overclock presentation")
@export var dim_color := Color("#a14a3f")
@export var bright_color := Color("#ffcf6b")
@export_range(0.2,5.0,0.1) var pulse_period := 1.6
var furnace: Sprite2D
var source_image: Image
var outline: ShaderMaterial
var markers: Array[Sprite2D] = []
var hovered := false
var elapsed := 0.0
var shop: ShopUI
var info_panel: PanelContainer
var info_label: Label
var active_tooltip := ""

func _ready() -> void:
	shop = get_parent() as ShopUI
	info_panel = PanelContainer.new()
	info_panel.position = Vector2(14,244)
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.z_index = 50
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#241d2d")
	background.content_margin_left = 4
	background.content_margin_right = 4
	background.content_margin_top = 2
	background.content_margin_bottom = 2
	info_panel.add_theme_stylebox_override("panel",background)
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size",9)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_label)
	info_panel.visible = false
	shop.add_child.call_deferred(info_panel)
	mouse_entered.connect(_entered)
	mouse_exited.connect(_exited)
	shop.visibility_changed.connect(_visibility_changed)
	call_deferred("_setup_art")

func _setup_art() -> void:
	furnace = shop.get_node("FountainArt/Furnace")
	source_image = furnace.texture.get_image()
	source_image.convert(Image.FORMAT_RGBA8)
	position = furnace.position
	size = source_image.get_size()
	text = ""
	for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var padded := Image.create(source_image.get_width()+4, source_image.get_height()+4, false, Image.FORMAT_RGBA8)
	padded.fill(Color.TRANSPARENT)
	padded.blit_rect(source_image, Rect2i(Vector2i.ZERO,source_image.get_size()),Vector2i(2,2))
	furnace.texture = ImageTexture.create_from_image(padded)
	furnace.position -= Vector2(2,2)
	outline = ShaderMaterial.new()
	outline.shader = OUTLINE
	outline.set_shader_parameter("outline_width",1.0)
	outline.set_shader_parameter("outline_color",bright_color)
	outline.set_shader_parameter("show_outline",false)
	furnace.material = outline
	for point in [Vector2(128,157),Vector2(128,200)]:
		var marker := Sprite2D.new()
		marker.texture = load("res://sprites/scenes/shop/furnace-benches/overclock-sigil.png")
		marker.centered = false
		marker.position = point
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.visible = false
		shop.add_child(marker)
		markers.append(marker)

func _has_point(point: Vector2) -> bool:
	if not source_image:
		return false
	var pixel := Vector2i(point.floor())
	return Rect2i(Vector2i.ZERO,source_image.get_size()).has_point(pixel) and source_image.get_pixelv(pixel).a > 0.08

func _entered() -> void:
	hovered = true
	elapsed = 0.0
	_update_tooltip()

func _exited() -> void:
	hovered = false
	_clear_tooltip()

func _visibility_changed() -> void:
	if not shop.is_visible_in_tree():
		hovered = false
		_clear_tooltip()

func _update_tooltip() -> void:
	if not info_label or not shop.shop_manager:
		return
	var message := "Overclock - 1 mana / uma vez por rodada\n+ Pe\u00e7a defeituosa e modificador an\u00f4malo"
	if shop.shop_manager.overclock_purchased_this_round:
		message += "\nJ\u00e1 utilizado nesta rodada."
	elif disabled:
		message += "\nMana insuficiente."
	info_label.text = message
	info_panel.visible = true

func _clear_tooltip() -> void:
	if info_panel:
		info_panel.visible = false

func _process(delta: float) -> void:
	if not outline:
		return
	elapsed += delta
	var active := hovered and shop.is_visible_in_tree() and not disabled
	outline.set_shader_parameter("show_outline",active)
	var color := dim_color.lerp(bright_color,0.5-0.5*cos(TAU*elapsed/pulse_period))
	for marker in markers:
		marker.visible = active
		marker.modulate = color
	if hovered:
		_update_tooltip()
