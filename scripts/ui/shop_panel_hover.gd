extends Node
## Instantaneous silhouette hover from the existing battle activator.
## Padding is render-only; source PNG, geometry and pressed handlers stay intact.
const OUTLINE_SHADER := preload("res://resources/shaders/outline_hover.gdshader")
const PADDING := 2
const ELEMENT_LABELS := {"fire":"Fogo", "water":"Água", "earth":"Terra", "air":"Ar", "soul":"Espírito"}
var tooltip_text: String
var panel_id: String
var button: Button
var sprite: Sprite2D
var source_image: Image
var shader_material: ShaderMaterial
var hovered := false
var tooltip: TooltipManager

func setup(target_sprite: Sprite2D, target_button: Button, id: String = "fire") -> void:
	panel_id = id
	if id == "neutral":
		tooltip_text = "[b]Pedestal Neutro[/b]\nCusto: 1 mana\nRenova as 3 ofertas de runas\nsem alterar as chances dos elementos."
	else:
		assert(ELEMENT_LABELS.has(id), "Unknown elemental panel")
		var label: String = ELEMENT_LABELS[id]
		tooltip_text = "[b]Pedestal de %s[/b]\nCusto: 1 mana\nRenova as 3 ofertas de runas e aumenta\na chance de runas de %s." % [label,label]
	sprite = target_sprite
	button = target_button
	source_image = sprite.texture.get_image()
	source_image.convert(Image.FORMAT_RGBA8)
	var padded := Image.create(source_image.get_width()+PADDING*2, source_image.get_height()+PADDING*2, false, Image.FORMAT_RGBA8)
	padded.fill(Color.TRANSPARENT)
	padded.blit_rect(source_image, Rect2i(Vector2i.ZERO, source_image.get_size()), Vector2i(PADDING,PADDING))
	sprite.texture = ImageTexture.create_from_image(padded)
	sprite.position -= Vector2(PADDING,PADDING)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shader_material = ShaderMaterial.new()
	shader_material.shader = OUTLINE_SHADER
	shader_material.set_shader_parameter("show_outline",false)
	sprite.material = shader_material
	sprite.z_index = 1 # Keep the interactive silhouette above the old recycling backdrop.
	tooltip = get_tree().get_first_node_in_group("tooltip_manager")
	button.tooltip_text = "" # Avoid a second native tooltip over TooltipManager.
	button.mouse_entered.connect(_entered)
	button.mouse_exited.connect(_set_hover.bind(false))
	button.gui_input.connect(_gui_input)
	button.visibility_changed.connect(_visibility_changed)

func _entered() -> void:
	_update_from_local(button.get_local_mouse_position())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_from_local(event.position)

func _update_from_local(local: Vector2) -> void:
	var pixel := Vector2i(floori(local.x),floori(local.y))
	var inside := Rect2i(Vector2i.ZERO,source_image.get_size()).has_point(pixel)
	_set_hover(inside and source_image.get_pixelv(pixel).a >= 0.08)

func _set_hover(value: bool) -> void:
	hovered = value and button.is_visible_in_tree()
	shader_material.set_shader_parameter("show_outline",hovered)
	if tooltip:
		if hovered:
			tooltip.set_rune_tooltip(tooltip_text,true)
		elif tooltip._rune_text == tooltip_text:
			tooltip.clear_rune_tooltip()

func _visibility_changed() -> void:
	if not button.is_visible_in_tree():
		_set_hover(false)
