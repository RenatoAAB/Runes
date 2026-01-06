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
			text = _build_relic_tooltip(relic_data)
		
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


func _build_relic_tooltip(data: RelicData) -> String:
	if not data:
		return ""
	
	var text = "[b]%s[/b]" % data.display_name
	
	# Rarity
	var rarity_color = _get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, _get_rarity_name(data.rarity)]
	
	# Description
	if data.description and not data.description.is_empty():
		text += "[color=silver]%s[/color]" % data.description
	
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
		label.text = final_text
		panel.show()
		panel.size = Vector2.ZERO # Reset size to fit content

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
