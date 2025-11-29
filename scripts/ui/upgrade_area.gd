class_name UpgradeArea
extends Control

## Manages the UI for upgrading runes.
## Has an Input Slot, an Output Slot (preview), and a Confirm Button.

signal upgrade_confirmed(rune_instance: RuneInstance)

@export var input_slot_container: Control
@export var output_slot_container: Control
@export var confirm_button: Button
@export var slot_scene: PackedScene

var input_slot: SlotUI
var output_slot: SlotUI
var current_rune_in_input: RuneInstance
var valid_upgrade_runes: Array[RuneInstance] = []

func _ready() -> void:
	hide()
	_setup_slots()
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
		confirm_button.disabled = true

func show_upgrade_ui(upgradeable_runes: Array[RuneInstance]) -> void:
	valid_upgrade_runes = upgradeable_runes
	_clear_input()
	show()

func hide_upgrade_ui() -> void:
	hide()
	_clear_input()

func _setup_slots() -> void:
	# Create Input Slot
	if slot_scene:
		input_slot = slot_scene.instantiate()
	else:
		input_slot = SlotUI.new()
	
	input_slot.set_meta("is_upgrade_input", true)
	input_slot_container.add_child(input_slot)
	
	# Create Output Slot
	if slot_scene:
		output_slot = slot_scene.instantiate()
	else:
		output_slot = SlotUI.new()
	
	# Output slot should not accept drops
	output_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	output_slot_container.add_child(output_slot)

func try_place_rune(rune: RuneInstance) -> bool:
	# Check if this rune is allowed to be upgraded
	if rune in valid_upgrade_runes:
		current_rune_in_input = rune
		input_slot.set_rune(rune)
		_update_preview()
		confirm_button.disabled = false
		return true
	return false

func _update_preview() -> void:
	if current_rune_in_input and current_rune_in_input.data.upgrades_to:
		var next_data = current_rune_in_input.data.upgrades_to
		var preview_instance = RuneInstance.new(next_data)
		output_slot.set_rune(preview_instance)
	else:
		output_slot.set_rune(null)

func _clear_input() -> void:
	current_rune_in_input = null
	input_slot.set_rune(null)
	output_slot.set_rune(null)
	confirm_button.disabled = true

func _on_confirm_pressed() -> void:
	if current_rune_in_input:
		upgrade_confirmed.emit(current_rune_in_input)
		hide_upgrade_ui()

func is_upgrade_input_slot(slot: SlotUI) -> bool:
	return slot == input_slot
