class_name RuneUI
extends TextureRect

## Visual representation of a Rune.
## Handles the start of the Drag & Drop operation.

var rune_instance: RuneInstance
var disabled_material: ShaderMaterial

# Keep the node in its source slot so drop/sale handlers retain their origin.
# Top-level drawing lifts the actual rune out of container layout and clipping.
var _dragging := false
var _drag_offset := Vector2.ZERO
var _pointer_position := Vector2.ZERO
var _drag_origin := Vector2.ZERO
var _drag_rotation := 0.0
var _drag_scale := Vector2.ONE
var _drag_mouse_filter: int
var _drag_z_index: int
var _drag_top_level: bool

func setup(rune: RuneInstance) -> void:
	rune_instance = rune
	# In a real scene, we would set the texture from the data
	if rune.data.textures.size() > 0:
		texture = rune.data.textures[0]
	
	# Setup tooltip (Task 6)
	# We will use custom signals for hover to drive the Highlighter and TooltipManager
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Setup disabled shader
	disabled_material = ShaderMaterial.new()
	disabled_material.shader = load("res://resources/shaders/disabled_rune.gdshader")

func _process(_delta: float) -> void:
	if rune_instance:
		if rune_instance.can_activate():
			material = null
		else:
			material = disabled_material

func _on_mouse_entered() -> void:
	if get_viewport().gui_is_dragging():
		return
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	var highlighter = get_tree().get_first_node_in_group("grid_highlighter")
	
	var parent = get_parent()
	var is_in_inventory = false
	if parent and "inventory_index" in parent and parent.inventory_index != -1:
		is_in_inventory = true
	
	var shop_price_text = ""
	if parent and parent.has_method("get_shop_price_text"):
		shop_price_text = parent.get_shop_price_text()
	
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var context: BattleContext = null
		var slot: GridSlot = null
		var can_evaluate = not is_in_inventory
		
		if can_evaluate and highlighter and highlighter.grid_manager:
			context = BattleContext.new(highlighter.grid_manager)
			if parent and "grid_coord" in parent:
				slot = highlighter.grid_manager.get_slot(parent.grid_coord)
		
		var ctx = EffectContext.new(rune_instance, slot, context)
		ctx.can_evaluate = can_evaluate
		var info = TooltipBuilder.build_rune_tooltip(rune_instance, ctx, can_evaluate, shop_price_text)
		tooltip_manager.set_rune_tooltip(info, is_in_inventory)
		
		# Secondary tooltip: previous round stats
		var stats_text = TooltipBuilder.build_rune_stats_tooltip(rune_instance)
		if tooltip_manager.has_method("set_stats_tooltip"):
			tooltip_manager.set_stats_tooltip(stats_text)
	
	if highlighter and highlighter.has_method("highlight_rune_effects"):
		if not is_in_inventory:
			var slot_ui = get_parent()
			if slot_ui and "grid_coord" in slot_ui and slot_ui.grid_coord != Vector2i(-1, -1):
				var slot = highlighter.grid_manager.get_slot(slot_ui.grid_coord)
				highlighter.highlight_rune_effects(rune_instance, slot)

func _on_mouse_exited() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.clear_rune_tooltip()
		
	var highlighter = get_tree().get_first_node_in_group("grid_highlighter")
	if highlighter and not _dragging and not get_viewport().gui_is_dragging():
		highlighter.clear_highlights()

func _get_drag_data(at_position: Vector2) -> Variant:
	# Check if interaction is allowed (not in Battle or Resolution phase)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.current_phase == GameEnums.GamePhase.BATTLE or game_manager.current_phase == GameEnums.GamePhase.RESOLUTION:
			return null
	
	# Check if rune is in a petrified slot (cannot be moved)
	var parent = get_parent()
	if parent and parent is SlotUI and parent.current_slot_data:
		if parent.current_slot_data.has_state("petrified"):
			return null

	_dragging = true
	_drag_origin = position
	_drag_rotation = rotation
	_drag_scale = scale
	_drag_mouse_filter = mouse_filter
	_drag_z_index = z_index
	_drag_top_level = is_set_as_top_level()
	var origin := get_global_transform()
	_drag_offset = origin.basis_xform(at_position)
	set_as_top_level(true)
	rotation = origin.get_rotation()
	scale = origin.get_scale()
	global_position = _pointer_position - _drag_offset
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_on_mouse_exited()
	
	# Return data dictionary
	return {
		"source_ui": self,
		"rune_instance": rune_instance
	}


func is_dragging_rune() -> bool:
	return _dragging


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Input coordinates work for both real pointers and viewport-injected input.
		_pointer_position = get_canvas_transform().affine_inverse() * event.position
		if _dragging:
			global_position = _pointer_position - _drag_offset


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		set_as_top_level(_drag_top_level)
		position = _drag_origin
		rotation = _drag_rotation
		scale = _drag_scale
		z_index = _drag_z_index
		mouse_filter = _drag_mouse_filter
