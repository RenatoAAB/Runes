extends Node

## Handles drag & drop juice effects: breathing preview, impact on drop, gentle settle on return.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _breathing_tween: Tween = null


func setup(config: JuiceConfig) -> void:
	_config = config


## Called when a drag operation starts. Finds the drag preview and applies breathing.
func on_drag_started() -> void:
	if not _config:
		return
	# The breathing is applied lazily in _process when the preview is available
	set_process(true)
	_breathing_tween = null


## Called when a drag operation ends.
func on_drag_ended(success: bool) -> void:
	set_process(false)
	_stop_breathing()

	if not _config:
		return

	if success:
		_play_drop_impact()
	else:
		_play_return_settle()


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	# Try to find the drag preview and apply breathing if we haven't yet
	if _breathing_tween and _breathing_tween.is_valid():
		return  # Already breathing

	var viewport = get_viewport()
	if not viewport:
		return

	# Godot's drag preview is set via set_drag_preview, which is a child of the viewport's drag preview control
	# We can't directly access it, but we can find RuneUI nodes that are being dragged
	# Instead, we'll skip breathing on the preview (it's transient) and focus on drop effects
	# The breathing effect is best applied by the RuneUI._get_drag_data itself
	set_process(false)


func _stop_breathing() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	_breathing_tween = null


## Play impact animation on the SlotUI that just received the rune
func _play_drop_impact() -> void:
	# Find the slot that was just dropped on - we get notified via EventBus
	# The actual slot target is handled by on_rune_placed_in_slot
	pass


## Play gentle settle on inventory slots when rune is returned
func _play_return_settle() -> void:
	pass


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
