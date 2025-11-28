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
	tooltip_text = "%s\n%s" % [rune.data.rune_name, GameEnums.Element.keys()[rune.data.element]]

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
