extends Node

## Spawns a floating "+N" over the slot that just scored.
## Added as a child of JuiceManager.
##
## Driven by EventBus.slot_read (a SlotReadEvent), which is the only place that
## knows both how many points a single slot produced and which coordinate produced
## them — the reader's score_updated signal only carries the running total.

## Loaded by path rather than by class_name: this module is itself loaded
## dynamically by JuiceManager, and a freshly added class_name is not in the
## global class cache until the editor rescans the project.
const SCORE_POPUP := preload("res://scripts/ui/juice/score_popup.gd")

var _config: JuiceConfig
var _grid_ui_slots: Dictionary = {}  # Vector2i -> SlotUI
var _fx_layer: Control = null
var _font: Font = null


func setup(config: JuiceConfig) -> void:
	_config = config


func set_grid_ui_slots(slots: Dictionary) -> void:
	_grid_ui_slots = slots


func set_fx_layer(layer: Control) -> void:
	_fx_layer = layer


## Borrow the score label's font so the popups match the rest of the HUD.
func set_reference_label(label: Label) -> void:
	if label:
		_font = label.get_theme_font("font")


func on_slot_read(event) -> void:
	if not _config or not _config.popup_enabled or not _fx_layer or not event:
		return

	var delta: int = event.score_after - event.score_before
	if delta <= 0:
		return

	var slot_ui: Control = _grid_ui_slots.get(event.slot_coord)
	if not slot_ui:
		return

	var is_large: bool = delta >= _config.score_large_threshold
	var popup: Label = SCORE_POPUP.new()
	popup.setup(
		delta,
		_config.popup_color_large if is_large else _config.popup_color_small,
		_config.popup_font_size_large if is_large else _config.popup_font_size_small,
		_font
	)

	_fx_layer.add_child(popup)
	popup.size = slot_ui.size
	popup.global_position = slot_ui.global_position \
		- Vector2(0.0, slot_ui.size.y * _config.popup_start_offset)
	popup.play(_config.popup_rise, _config.popup_duration)
