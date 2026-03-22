class_name RuneUI
extends TextureRect

## Visual representation of a Rune.
## Handles the start of the Drag & Drop operation.

var rune_instance: RuneInstance
var disabled_material: ShaderMaterial

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
	if highlighter:
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

	# Create a visual preview for the drag
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = expand_mode
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.7)
	
	# Center the preview on the mouse
	var control = Control.new()
	control.add_child(preview)
	preview.position = -0.5 * size
	set_drag_preview(control)
	
	# Start breathing animation on the preview
	var juice = get_node_or_null("/root/JuiceManager")
	if juice:
		juice.start_breathing_on_preview(preview)
	
	# Return data dictionary
	return {
		"source_ui": self,
		"rune_instance": rune_instance
	}
