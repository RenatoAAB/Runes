class_name PanelNavigatorUI
extends HBoxContainer

## UI component for navigating between multiple panels.
## Shows current panel, navigation buttons, and panel indicators.

signal panel_selected(panel_index: int)
signal previous_pressed
signal next_pressed

@export var button_min_size: Vector2 = Vector2(40, 40)
@export var indicator_size: Vector2 = Vector2(20, 20)
@export var spacing: int = 10

var previous_button: Button
var next_button: Button
var panel_label: Label
var indicator_container: HBoxContainer

var _panel_indicators: Array[ColorRect] = []
var _current_panel_index: int = 0
var _total_panels: int = 1
var _unlocked_panels: Array[int] = [0]


func _ready() -> void:
	add_theme_constant_override("separation", spacing)
	_setup_ui()


func _setup_ui() -> void:
	# Previous button
	previous_button = Button.new()
	previous_button.text = "◀"
	previous_button.custom_minimum_size = button_min_size
	previous_button.pressed.connect(_on_previous_pressed)
	add_child(previous_button)
	
	# Panel info container (vertical)
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(info_container)
	
	# Panel label
	panel_label = Label.new()
	panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_label.text = "Panel 1"
	info_container.add_child(panel_label)
	
	# Indicator container
	indicator_container = HBoxContainer.new()
	indicator_container.alignment = BoxContainer.ALIGNMENT_CENTER
	indicator_container.add_theme_constant_override("separation", 5)
	info_container.add_child(indicator_container)
	
	# Next button
	next_button = Button.new()
	next_button.text = "▶"
	next_button.custom_minimum_size = button_min_size
	next_button.pressed.connect(_on_next_pressed)
	add_child(next_button)


## Update the navigator with panel information
func update_panels(total: int, unlocked: Array[int], current: int) -> void:
	_total_panels = total
	_unlocked_panels = unlocked
	_current_panel_index = current
	
	_update_label()
	_update_indicators()
	_update_buttons()


## Set the current panel index
func set_current_panel(index: int) -> void:
	_current_panel_index = index
	_update_label()
	_update_indicators()
	_update_buttons()


func _update_label() -> void:
	if panel_label:
		panel_label.text = "Panel %d of %d" % [_current_panel_index + 1, _total_panels]


func _update_indicators() -> void:
	# Clear existing indicators
	for indicator in _panel_indicators:
		indicator.queue_free()
	_panel_indicators.clear()
	
	# Create new indicators
	for i in range(_total_panels):
		var indicator = ColorRect.new()
		indicator.custom_minimum_size = indicator_size
		
		if i == _current_panel_index:
			indicator.color = Color(1.0, 0.8, 0.2)  # Gold for current
		elif i in _unlocked_panels:
			indicator.color = Color(0.3, 0.7, 0.3)  # Green for unlocked
		else:
			indicator.color = Color(0.3, 0.3, 0.3)  # Gray for locked
		
		# Make clickable
		indicator.mouse_filter = Control.MOUSE_FILTER_STOP
		indicator.gui_input.connect(_on_indicator_input.bind(i))
		
		indicator_container.add_child(indicator)
		_panel_indicators.append(indicator)


func _update_buttons() -> void:
	if previous_button:
		# Can go to previous if current > 0 and previous is unlocked
		var can_prev = _current_panel_index > 0 and (_current_panel_index - 1) in _unlocked_panels
		previous_button.disabled = not can_prev
	
	if next_button:
		# Can go to next if not at end and next is unlocked
		var can_next = _current_panel_index < _total_panels - 1 and (_current_panel_index + 1) in _unlocked_panels
		next_button.disabled = not can_next


func _on_previous_pressed() -> void:
	if _current_panel_index > 0 and (_current_panel_index - 1) in _unlocked_panels:
		_current_panel_index -= 1
		_update_label()
		_update_indicators()
		_update_buttons()
		previous_pressed.emit()
		panel_selected.emit(_current_panel_index)


func _on_next_pressed() -> void:
	if _current_panel_index < _total_panels - 1 and (_current_panel_index + 1) in _unlocked_panels:
		_current_panel_index += 1
		_update_label()
		_update_indicators()
		_update_buttons()
		next_pressed.emit()
		panel_selected.emit(_current_panel_index)


func _on_indicator_input(event: InputEvent, panel_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if panel_index in _unlocked_panels:
			_current_panel_index = panel_index
			_update_label()
			_update_indicators()
			_update_buttons()
			panel_selected.emit(panel_index)
