extends Node

## Handles drag & drop juice effects: breathing preview, impact on drop, gentle settle on return.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _breathing_tween: Tween = null
var _breathing_target: Control = null


func setup(config: JuiceConfig) -> void:
	_config = config


## Start breathing animation on a drag preview node.
func start_breathing(preview: Control) -> void:
	if not _config or not preview:
		return
	_stop_breathing()
	_breathing_target = preview
	preview.pivot_offset = preview.size / 2.0
	_breathing_tween = preview.create_tween()
	_breathing_tween.set_loops()
	var s = _config.drag_breathing_scale
	var half_dur = _config.drag_breathing_duration * 0.5
	_breathing_tween.tween_property(
		preview, "scale",
		Vector2(s, s),
		half_dur
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathing_tween.tween_property(
		preview, "scale",
		Vector2.ONE,
		half_dur
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Called when a drag operation ends.
func on_drag_ended(success: bool) -> void:
	_stop_breathing()


func _ready() -> void:
	pass


func _stop_breathing() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	_breathing_tween = null
	_breathing_target = null


## Called by JuiceManager when a rune is placed in a grid slot (drop impact)
func play_slot_impact(slot_ui: Control) -> void:
	if not _config or not slot_ui:
		return

	slot_ui.pivot_offset = slot_ui.size / 2.0
	var original_pos = slot_ui.position

	# Impact scale: overshoot → undershoot → settle
	var tween = slot_ui.create_tween()
	tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.drop_impact_scale, _config.drop_impact_scale),
		_config.drop_impact_duration * 0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.drop_impact_undershoot, _config.drop_impact_undershoot),
		_config.drop_impact_duration * 0.3
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(
		slot_ui, "scale",
		Vector2.ONE,
		_config.drop_impact_duration * 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Micro-shake after the scale animation
	tween.tween_callback(_play_micro_shake.bind(slot_ui, original_pos))


func _play_micro_shake(slot_ui: Control, original_pos: Vector2) -> void:
	if not slot_ui or not is_instance_valid(slot_ui):
		return

	var shake_tween = slot_ui.create_tween()
	var amp = _config.drop_shake_amplitude
	var step_time = _config.drop_shake_duration / 4.0

	shake_tween.tween_property(slot_ui, "position", original_pos + Vector2(amp, 0), step_time)
	shake_tween.tween_property(slot_ui, "position", original_pos + Vector2(-amp, 0), step_time)
	shake_tween.tween_property(slot_ui, "position", original_pos + Vector2(0, amp), step_time)
	shake_tween.tween_property(slot_ui, "position", original_pos, step_time)


## Called when a rune is returned to inventory (gentle settle)
func play_inventory_settle(slot_ui: Control) -> void:
	if not _config or not slot_ui:
		return

	slot_ui.pivot_offset = slot_ui.size / 2.0

	var tween = slot_ui.create_tween()
	tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.drop_return_scale, _config.drop_return_scale),
		_config.drop_return_duration * 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		slot_ui, "scale",
		Vector2.ONE,
		_config.drop_return_duration * 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Subtle fade-in
	slot_ui.modulate.a = 0.8
	var fade_tween = slot_ui.create_tween()
	fade_tween.tween_property(slot_ui, "modulate:a", 1.0, _config.drop_return_duration)
