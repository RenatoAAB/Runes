class_name ChoiceArea
extends Control

## Manages the UI for selecting a new rune reward.
## Displays 3 options. The player selects one by dragging it to their inventory.

@export var container: Container # HBoxContainer to hold the slots
@export var slot_scene: PackedScene # To instantiate slots for choices

var active_options: Array[RuneData] = []
var generated_slots: Array[SlotUI] = []

func _ready() -> void:
	hide()

func show_choices(options: Array[RuneData]) -> void:
	print("Showing choices: %s" % [options])
	active_options = options
	_clear_slots()
	
	for data in options:
		var slot = _create_slot_for_choice(data)
		container.add_child(slot)
		generated_slots.append(slot)
	
	show()

func hide_choices() -> void:
	hide()
	_clear_slots()

func _clear_slots() -> void:
	for slot in generated_slots:
		slot.queue_free()
	generated_slots.clear()

func _create_slot_for_choice(data: RuneData) -> SlotUI:
	var slot: SlotUI
	if slot_scene:
		slot = slot_scene.instantiate()
	else:
		slot = SlotUI.new()
		slot.custom_minimum_size = Vector2(64, 64)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.3) # Distinct color for choice
		slot.add_theme_stylebox_override("panel", style)
	
	# Create a temporary instance for display
	var instance = RuneInstance.new(data)
	slot.set_rune(instance)
	
	# Mark this slot as a choice source (we can check this in MainController)
	slot.set_meta("is_choice_slot", true)
	
	return slot

func is_choice_slot(slot: SlotUI) -> bool:
	return slot.has_meta("is_choice_slot") and slot.get_meta("is_choice_slot")
