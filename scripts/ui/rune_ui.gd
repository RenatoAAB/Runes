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
	# Find TooltipManager and GridHighlighter in the tree.
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	var highlighter = get_tree().get_first_node_in_group("grid_highlighter")
	
	var parent = get_parent()
	var is_in_inventory = false
	if parent and "inventory_index" in parent and parent.inventory_index != -1:
		is_in_inventory = true
	
	# Check if parent has shop price info
	var shop_price_text = ""
	if parent and parent.has_method("get_shop_price_text"):
		shop_price_text = parent.get_shop_price_text()
	
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var type_str = GameEnums.Element.keys()[rune_instance.data.element]
		var activations = rune_instance.get_max_activations()
		
		# Build header with price in top-right if in shop mode
		var header = "[b]%s[/b]" % rune_instance.data.rune_name
		if shop_price_text != "":
			header = "[b]%s[/b]  [color=gold][b]%s[/b][/color]" % [rune_instance.data.rune_name, shop_price_text]
		
		var info = "%s\n%s | Activations: %d\nTier: %d" % [header, type_str, activations, rune_instance.data.tier]
		
		# Collect all keywords from all effects
		var all_keywords: Array[StringName] = []
		for effect in rune_instance.data.effects:
			for kw in effect.get_keywords():
				if kw not in all_keywords:
					all_keywords.append(kw)
		
		# Add keyword badges line
		if all_keywords.size() > 0:
			info += "\n" + Keywords.format_keyword_line(all_keywords)
		
		# Context for evaluation
		var context: BattleContext = null
		var slot: GridSlot = null
		var can_evaluate = not is_in_inventory
		
		if can_evaluate and highlighter and highlighter.grid_manager:
			context = BattleContext.new(highlighter.grid_manager)
			if parent and "grid_coord" in parent:
				slot = highlighter.grid_manager.get_slot(parent.grid_coord)
		
		# Add effects description using the new colored description system
		for i in range(rune_instance.data.effects.size()):
			var effect = rune_instance.data.effects[i]
			
			# Get color marker for this effect (●)
			var color_marker = EffectColors.get_color_marker(i)
			
			# Evaluate condition if possible
			var is_condition_met = true
			if can_evaluate and context and slot and effect.condition:
				is_condition_met = effect.condition.evaluate(rune_instance, context, slot)
			
			# Get the colored description
			var effect_desc = effect.get_description_colored(i, is_condition_met, can_evaluate)
			
			info += "\n%s %s" % [color_marker, effect_desc]
			
		# Add Permanent Buffs
		if rune_instance.permanent_buffs.size() > 0:
			var has_buffs = false
			var buff_text = ""
			var buffs = rune_instance.permanent_buffs
			
			if buffs.has("score_multiplier") and buffs["score_multiplier"] != 1.0:
				buff_text += "\n Score x%.1f" % buffs["score_multiplier"]
				has_buffs = true
			if buffs.has("score_bonus") and buffs["score_bonus"] != 0:
				buff_text += "\n Score +%d" % buffs["score_bonus"]
				has_buffs = true
			if buffs.has("activation_bonus") and buffs["activation_bonus"] != 0:
				buff_text += "\n Activations +%d" % buffs["activation_bonus"]
				has_buffs = true
				
			if has_buffs:
				info += "\n[color=yellow]Permanent Buffs:[/color]" + buff_text
			
		tooltip_manager.set_rune_tooltip(info, is_in_inventory)
	
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
	
	# Return data dictionary
	return {
		"source_ui": self,
		"rune_instance": rune_instance
	}
