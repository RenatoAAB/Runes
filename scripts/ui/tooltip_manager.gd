class_name TooltipManager
extends Control

## Simple singleton-like manager for tooltips.
## In a real project, this would be an Autoload or part of the main UI canvas.

@export var label_settings: LabelSettings

@onready var label: RichTextLabel = RichTextLabel.new()
@onready var panel: PanelContainer = PanelContainer.new()

@onready var stats_label: RichTextLabel = RichTextLabel.new()
@onready var stats_panel: PanelContainer = PanelContainer.new()

var _force_left: bool = false
var _rune_text: String = ""
var _slot_text: String = ""
var _item_text: String = ""  # For relics, modifiers, pieces
var _stats_text: String = ""  # Secondary tooltip: previous round stats

func _ready() -> void:
	# Setup simple tooltip UI
	add_child(panel)
	panel.add_child(label)
	
	# Configure RichTextLabel
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.bbcode_enabled = true
	
	if label_settings:
		_apply_label_settings()
	
	panel.hide()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style
	panel.z_index = 100 # On top
	
	# Setup secondary stats tooltip
	add_child(stats_panel)
	stats_panel.add_child(stats_label)
	stats_label.fit_content = true
	stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_label.bbcode_enabled = true
	if label_settings:
		_apply_label_settings_to(stats_label)
	stats_panel.hide()
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.z_index = 100

func _process(_delta: float) -> void:
	if panel.visible:
		var mouse_pos = get_global_mouse_position()
		var offset = Vector2(15, 15)
		var target_pos: Vector2
		
		if _force_left:
			target_pos = mouse_pos - Vector2(panel.size.x + 15, -15)
		else:
			target_pos = mouse_pos + offset
		
		# Viewport clamping
		var viewport_size = get_viewport_rect().size
		target_pos.x = clampf(target_pos.x, 0, viewport_size.x - panel.size.x)
		target_pos.y = clampf(target_pos.y, 0, viewport_size.y - panel.size.y)
		
		panel.global_position = target_pos
		
		# Position stats panel beside the main panel
		if stats_panel.visible:
			var stats_pos = Vector2(target_pos.x + panel.size.x + 4, target_pos.y)
			# If it overflows right, place it to the left instead
			if stats_pos.x + stats_panel.size.x > viewport_size.x:
				stats_pos.x = target_pos.x - stats_panel.size.x - 4
			stats_pos.y = clampf(stats_pos.y, 0, viewport_size.y - stats_panel.size.y)
			stats_panel.global_position = stats_pos

func show_tooltip(text: String, force_left: bool = false) -> void:
	set_rune_tooltip(text, force_left)

func set_rune_tooltip(text: String, force_left: bool = false) -> void:
	_rune_text = text
	_force_left = force_left
	_update_display()

func set_slot_tooltip(text: String) -> void:
	_slot_text = text
	_update_display()

func hide_tooltip() -> void:
	clear_rune_tooltip()

func clear_rune_tooltip() -> void:
	_rune_text = ""
	_stats_text = ""
	_update_display()

func clear_slot_tooltip() -> void:
	_slot_text = ""
	_update_display()


func set_stats_tooltip(text: String) -> void:
	_stats_text = text
	_update_stats_display()


func clear_stats_tooltip() -> void:
	_stats_text = ""
	_update_stats_display()


## Show tooltip for an ItemUI (relic, modifier, piece)
func show_item_tooltip(item_ui: ItemUI) -> void:
	if not item_ui or not item_ui.item_data:
		return
	
	var text = ""
	
	match item_ui.item_type:
		ItemUI.ItemType.RELIC:
			var relic_data = item_ui.item_data as RelicData
			var relic_instance = item_ui.item_instance as RelicInstance
			text = TooltipBuilder.build_relic_tooltip(relic_data, relic_instance)
		
		ItemUI.ItemType.MODIFIER:
			var modifier_data = item_ui.item_data as SlotModifierData
			text = TooltipBuilder.build_modifier_tooltip(modifier_data)
		
		ItemUI.ItemType.PIECE:
			var piece_data = item_ui.item_data as SlotPieceData
			text = TooltipBuilder.build_piece_tooltip(piece_data)
	
	_item_text = text
	_update_display()


func hide_item_tooltip() -> void:
	_item_text = ""
	_update_display()


func _update_display() -> void:
	var final_text = ""
	if _rune_text != "":
		final_text = _rune_text
	
	if _item_text != "":
		if final_text != "":
			final_text += "\n" + TooltipTexts.SEPARATOR + "\n"
		final_text += _item_text
		
	if _slot_text != "":
		if final_text != "":
			final_text += "\n" + TooltipTexts.SEPARATOR + "\n"
		final_text += _slot_text
		
	if final_text == "":
		panel.hide()
	else:
		label.text = _wrap_text(final_text, 90)
		panel.show()
		panel.size = Vector2.ZERO # Reset size to fit content

## Wrap long tooltip lines so individual rune descriptions don't need manual breaks.
func _wrap_text(text: String, max_chars: int = 90) -> String:
	if text.is_empty() or max_chars <= 10:
		return text

	# Normalize spacing around [img] tags so wrapping doesn't split them
	text = _normalize_img_spacing(text)
	var result: Array[String] = []
	for raw_line in text.split("\n"):
		var line = raw_line.strip_edges(false, false)
		if _visible_length(line) <= max_chars:
			result.append(line)
			continue
		var words = line.split(" ")
		var current = ""
		for word in words:
			if current.is_empty():
				current = word
				continue
			var candidate = current + " " + word
			if _visible_length(candidate) > max_chars:
				result.append(current)
				current = word
			else:
				current = candidate
		if not current.is_empty():
			result.append(current)
		# Preserve blank line if original ended with newline
	if text.ends_with("\n"):
		result.append("")
	return "\n".join(result)


func _normalize_img_spacing(text: String) -> String:
	if text.is_empty():
		return text
	var s := text
	var start := 0
	while true:
		var open_idx := s.find("[img", start)
		if open_idx == -1:
			break
		# Ensure there's a space before the opening tag
		if open_idx > 0:
			var prev_ch := s.substr(open_idx - 1, 1)
			if prev_ch != " " and prev_ch != "\n" and prev_ch != "\t":
				s = s.substr(0, open_idx) + " " + s.substr(open_idx, s.length() - open_idx)
				open_idx += 1
		# Find end of opening tag
		var open_end := s.find("]", open_idx)
		if open_end == -1:
			start = open_idx + 4
			continue
		# Find closing tag
		var close_idx := s.find("[/img]", open_end)
		var close_end := 0
		if close_idx == -1:
			close_end = open_end + 1
		else:
			close_end = close_idx + 6
		# Ensure there's a space after the closing tag (or after the opening tag if no close)
		if close_end < s.length():
			var next_ch := s.substr(close_end, 1)
			if next_ch != " " and next_ch != "\n" and next_ch != "\t":
				s = s.substr(0, close_end) + " " + s.substr(close_end, s.length() - close_end)
		start = close_end + 1
	return s


func _visible_length(text: String) -> int:
	var length = 0
	var i = 0
	while i < text.length():
		if text.find("[img", i) == i:
			var close_idx = text.find("[/img]", i)
			length += 2
			if close_idx == -1:
				i += 4
			else:
				i = close_idx + 6
			continue
		length += 1
		i += 1
	return length

func _apply_label_settings() -> void:
	_apply_label_settings_to(label)


func _apply_label_settings_to(target_label: RichTextLabel) -> void:
	if not label_settings or not target_label:
		return
		
	if label_settings.font:
		target_label.add_theme_font_override("normal_font", label_settings.font)
	
	if label_settings.font_size > 0:
		target_label.add_theme_font_size_override("normal_font_size", label_settings.font_size)
		
	if label_settings.font_color != Color(1, 1, 1, 1):
		target_label.add_theme_color_override("default_color", label_settings.font_color)
	
	if label_settings.outline_size > 0:
		target_label.add_theme_constant_override("outline_size", label_settings.outline_size)
		target_label.add_theme_color_override("outline_color", label_settings.outline_color)


func _update_stats_display() -> void:
	if _stats_text.is_empty():
		stats_panel.hide()
	else:
		stats_label.text = _stats_text
		stats_panel.show()
		stats_panel.size = Vector2.ZERO
