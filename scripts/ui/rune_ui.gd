class_name RuneUI
extends TextureRect

## Visual representation of a Rune.
## Handles the start of the Drag & Drop operation.

var rune_instance: RuneInstance

func setup(rune: RuneInstance) -> void:
	rune_instance = rune
	# In a real scene, we would set the texture from the data
	if rune.data.textures.size() > 0:
		texture = rune.data.textures[0]
	
	# Setup tooltip (Task 6)
	# We will use custom signals for hover to drive the Highlighter and TooltipManager
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	# Find TooltipManager and GridHighlighter in the tree.
	# This is a bit loose, but standard for decoupled UI components in Godot without a DI framework.
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var info = "%s\n%s\nTier: %d" % [rune_instance.data.rune_name, GameEnums.Element.keys()[rune_instance.data.element], rune_instance.data.tier]
		tooltip_manager.show_tooltip(info)
	
	var highlighter = get_tree().get_first_node_in_group("grid_highlighter")
	if highlighter and highlighter.has_method("highlight_rune_effects"):
		# We need to know which slot we are in.
		# RuneUI is a child of SlotUI.
		var slot_ui = get_parent()
		if slot_ui and "grid_coord" in slot_ui and slot_ui.grid_coord != Vector2i(-1, -1):
			# We need the GridSlot object.
			# We can get it from the GridManager if we can find it, or if SlotUI holds it.
			# Let's assume highlighter has access to GridManager (it does).
			var slot = highlighter.grid_manager.get_slot(slot_ui.grid_coord)
			highlighter.highlight_rune_effects(rune_instance, slot)

func _on_mouse_exited() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.hide_tooltip()
		
	var highlighter = get_tree().get_first_node_in_group("grid_highlighter")
	if highlighter:
		highlighter.clear_highlights()

func _get_drag_data(at_position: Vector2) -> Variant:
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
