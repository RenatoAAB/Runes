extends "res://scripts/ui/sell_area.gd"
## The fountain mask owns hover/drop; original SellArea owns all transactions.
const WATER_MASK := preload("res://sprites/scenes/shop/water.png")
const DEFAULT_HINT := "[b]Reciclagem[/b]\nArraste runas ou itens para a água\npara reciclá-los em mana."
var _mask: Image
var _tooltip: TooltipManager
var _hovered := false
var _owned_hint := ""

func _ready() -> void:
	_mask = WATER_MASK.get_image()
	super._ready()
	if label: label.hide()
	if has_node("Panel"): get_node("Panel").hide()
	mouse_entered.connect(_entered)
	mouse_exited.connect(_left)
	visibility_changed.connect(_visibility_changed)
	call_deferred("_bind_tooltip")

func _bind_tooltip() -> void:
	_tooltip = get_tree().get_first_node_in_group("tooltip_manager")

func _has_point(point: Vector2) -> bool:
	if not _mask: return false
	var pixel := Vector2i(floori(point.x),floori(point.y))
	return Rect2i(Vector2i.ZERO,_mask.get_size()).has_point(pixel) and _mask.get_pixelv(pixel).a > 0.5

func _entered() -> void:
	_hovered = true
	_show_hint(DEFAULT_HINT)

func _left() -> void:
	_hovered = false
	if _tooltip and _tooltip._rune_text == _owned_hint: _tooltip.clear_rune_tooltip()
	_owned_hint = ""

func _visibility_changed() -> void:
	if not is_visible_in_tree(): _left()

func _show_hint(text: String) -> void:
	if not _hovered or not _tooltip or not is_visible_in_tree(): return
	_owned_hint = text
	_tooltip.set_rune_tooltip(text)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not _has_point(at_position): return false
	var accepted := super._can_drop_data(at_position,data)
	if accepted:
		_hovered = true
		_show_hint("[b]Reciclagem[/b]\n" + label.text)
	return accepted

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _has_point(at_position): super._drop_data(at_position,data)

func _update_display_default() -> void:
	super._update_display_default()
	_show_hint(DEFAULT_HINT)
