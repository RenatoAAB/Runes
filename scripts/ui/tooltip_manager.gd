class_name TooltipManager
extends Control

## Simple singleton-like manager for tooltips.
## In a real project, this would be an Autoload or part of the main UI canvas.

@export var label_settings: LabelSettings

@onready var label: RichTextLabel = RichTextLabel.new()
@onready var panel: PanelContainer = PanelContainer.new()

var _force_left: bool = false
var _rune_text: String = ""
var _slot_text: String = ""
var _item_text: String = ""  # For relics, modifiers, pieces

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

func _process(_delta: float) -> void:
	if panel.visible:
		var mouse_pos = get_global_mouse_position()
		var offset = Vector2(15, 15)
		
		if _force_left:
			# Position to the left of the mouse
			panel.global_position = mouse_pos - Vector2(panel.size.x + 15, -15)
		else:
			# Default to right
			panel.global_position = mouse_pos + offset

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
	_update_display()

func clear_slot_tooltip() -> void:
	_slot_text = ""
	_update_display()


## Show tooltip for an ItemUI (relic, modifier, piece)
func show_item_tooltip(item_ui: ItemUI) -> void:
	if not item_ui or not item_ui.item_data:
		return
	
	var text = ""
	
	match item_ui.item_type:
		ItemUI.ItemType.RELIC:
			var relic_data = item_ui.item_data as RelicData
			var relic_instance = item_ui.item_instance as RelicInstance
			text = _build_relic_tooltip(relic_data, relic_instance)
		
		ItemUI.ItemType.MODIFIER:
			var modifier_data = item_ui.item_data as SlotModifierData
			text = _build_modifier_tooltip(modifier_data)
		
		ItemUI.ItemType.PIECE:
			var piece_data = item_ui.item_data as SlotPieceData
			text = _build_piece_tooltip(piece_data)
	
	_item_text = text
	_update_display()


func hide_item_tooltip() -> void:
	_item_text = ""
	_update_display()


func _build_relic_tooltip(data: RelicData, relic_instance: RelicInstance = null) -> String:
	if not data:
		return ""
	
	var text = "[b]%s[/b]" % data.display_name
	
	# Rarity
	var rarity_color = _get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, _get_rarity_name(data.rarity)]
	
	# Description (full)
	var full_desc = data.get_full_description()
	if full_desc and not full_desc.is_empty():
		text += "[color=silver]%s[/color]" % full_desc

	# Last calculated multiplier (if instance exists)
	if relic_instance and relic_instance.last_calculated_multiplier != 1.0:
		text += "\n[color=yellow]Último: ×%.2f[/color]" % relic_instance.last_calculated_multiplier
	
	return text


func _build_modifier_tooltip(data: SlotModifierData) -> String:
	if not data:
		return ""
	
	var text = "[b]%s[/b]" % data.display_name
	
	# Rarity
	var rarity_color = _get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, _get_rarity_name(data.rarity)]
	
	# Type
	var type_name = _get_modifier_type_name(data.modifier_type)
	text += "[color=cyan]%s[/color]\n" % type_name

	# Slot type override
	if data.slot_data_override:
		text += "[color=orange]Tipo de Slot:[/color] %s\n" % data.slot_data_override.slot_name
		var slot_desc = data.slot_data_override.get_full_description()
		if slot_desc and not slot_desc.is_empty():
			text += "[color=gray]%s[/color]\n" % slot_desc
	
	# Description
	if data.description and not data.description.is_empty():
		text += "[color=silver]%s[/color]" % data.description
	else:
		# Generate description from type
		text += "[color=silver]%s[/color]" % _get_modifier_auto_description(data)
	
	return text


func _build_piece_tooltip(data: SlotPieceData) -> String:
	if not data:
		return ""
	
	var text = "[b]%s[/b]" % data.display_name
	
	# Rarity
	var rarity_color = _get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, _get_rarity_name(data.rarity)]
	
	# Size
	text += "[color=yellow]%d slots[/color]\n" % data.get_slot_count()
	
	# Description
	if data.description and not data.description.is_empty():
		text += "[color=silver]%s[/color]" % data.description
	
	return text


func _get_rarity_name(rarity: GameEnums.Rarity) -> String:
	match rarity:
		GameEnums.Rarity.COMMON: return "Common"
		GameEnums.Rarity.UNCOMMON: return "Uncommon"
		GameEnums.Rarity.RARE: return "Rare"
		GameEnums.Rarity.EPIC: return "Epic"
		GameEnums.Rarity.LEGENDARY: return "Legendary"
		_: return "Unknown"


func _get_rarity_color_name(rarity: GameEnums.Rarity) -> String:
	match rarity:
		GameEnums.Rarity.COMMON: return "gray"
		GameEnums.Rarity.UNCOMMON: return "green"
		GameEnums.Rarity.RARE: return "blue"
		GameEnums.Rarity.EPIC: return "purple"
		GameEnums.Rarity.LEGENDARY: return "orange"
		_: return "white"


func _get_modifier_type_name(type: SlotModifierData.ModifierType) -> String:
	match type:
		SlotModifierData.ModifierType.MULTIPLIER: return "Multiplier"
		SlotModifierData.ModifierType.TRIGGER: return "Trigger"
		SlotModifierData.ModifierType.ECONOMY: return "Economy"
		SlotModifierData.ModifierType.PRESERVATION: return "Preservation"
		SlotModifierData.ModifierType.PROTECTION: return "Protection"
		SlotModifierData.ModifierType.STATE: return "State"
		_: return "Unknown"


func _get_modifier_auto_description(data: SlotModifierData) -> String:
	match data.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			return "Adds +%.1fx multiplier to this slot." % data.value
		SlotModifierData.ModifierType.TRIGGER:
			return "Slot triggers %d extra time(s)." % int(data.value)
		SlotModifierData.ModifierType.ECONOMY:
			return "Generates $%d per activation." % int(data.value)
		SlotModifierData.ModifierType.PRESERVATION:
			return "Runes in this slot don't consume charges."
		SlotModifierData.ModifierType.PROTECTION:
			return "Protects fragile runes from breaking."
		SlotModifierData.ModifierType.STATE:
			return "Applies a special state to the slot."
		_:
			return ""

func _update_display() -> void:
	var final_text = ""
	if _rune_text != "":
		final_text = _rune_text
	
	if _item_text != "":
		if final_text != "":
			final_text += "\n[color=gray]----------------[/color]\n"
		final_text += _item_text
		
	if _slot_text != "":
		if final_text != "":
			final_text += "\n[color=gray]----------------[/color]\n" # Separator
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
	if not label_settings or not label:
		return
		
	if label_settings.font:
		label.add_theme_font_override("normal_font", label_settings.font)
	
	if label_settings.font_size > 0:
		label.add_theme_font_size_override("normal_font_size", label_settings.font_size)
		
	if label_settings.font_color != Color(1, 1, 1, 1):
		label.add_theme_color_override("default_color", label_settings.font_color)
	
	if label_settings.outline_size > 0:
		label.add_theme_constant_override("outline_size", label_settings.outline_size)
		label.add_theme_color_override("outline_color", label_settings.outline_color)
