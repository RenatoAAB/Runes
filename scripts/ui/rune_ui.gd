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
	
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var type_str = GameEnums.Element.keys()[rune_instance.data.element]
		var activations = rune_instance.get_max_activations()
		var info = "[b]%s[/b]\n%s | Activations: %d\nTier: %d" % [rune_instance.data.rune_name, type_str, activations, rune_instance.data.tier]
		
		# Context for evaluation
		var context = null
		var slot = null
		if not is_in_inventory and highlighter and highlighter.grid_manager:
			context = BattleContext.new(highlighter.grid_manager)
			if parent and "grid_coord" in parent:
				slot = highlighter.grid_manager.get_slot(parent.grid_coord)
		
		# Add effects description
		for i in range(rune_instance.data.effects.size()):
			var effect = rune_instance.data.effects[i]
			
			# Get color for this effect
			var color = Color.WHITE
			if highlighter and "EFFECT_COLORS" in highlighter:
				var colors = highlighter.EFFECT_COLORS
				if colors.size() > 0:
					color = colors[i % colors.size()]
			var hex_color = color.to_html()
			
			# Build description
			var payload_desc = ""
			if effect.payload:
				payload_desc = effect.payload.get_description()
			
			# Color keywords in payload
			# We also want to color the target description if it appears.
			# The target description is now part of payload_desc (via RuneEffect.get_description)
			
			var keywords = ["target", "runes", "line", "column", "row", "adjacent", "self"]
			
			# Add element names to keywords
			for elem in GameEnums.Element.keys():
				keywords.append(elem.capitalize())
				
			for kw in keywords:
				var regex = RegEx.new()
				# Match whole words, case insensitive
				regex.compile("(?i)\\b" + kw + "\\b")
				payload_desc = regex.sub(payload_desc, "[color=#%s]%s[/color]" % [hex_color, "$0"], true)
			
			var final_desc = payload_desc
			
			# Handle Condition
			if effect.condition:
				var cond_desc = effect.condition.get_description()
				if cond_desc != "Always":
					var cond_text = " if " + cond_desc
					var is_met = true
					if context and slot:
						is_met = effect.condition.evaluate(rune_instance, context, slot)
					
					var cond_color = "green" if is_met else "red"
					if is_in_inventory:
						cond_color = "white"
					
					final_desc += "[color=%s]%s[/color]" % [cond_color, cond_text]
			
			info += "\n- " + final_desc
			
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
		if game_manager.current_phase == GameManager.GamePhase.BATTLE or game_manager.current_phase == GameManager.GamePhase.RESOLUTION:
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
