extends Node

## Handles rune activation flash, destruction dissolve, and creation materialization.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _grid_ui_slots: Dictionary = {}  # Vector2i -> SlotUI

## Running activation tweens per slot UI (instance_id -> Array[Tween]).
## Chained/simultaneous activations can hit the same slot within one frame, so the
## previous flash is killed before starting a new one to avoid stuck modulate/scale.
var _activation_tweens: Dictionary = {}


func setup(config: JuiceConfig) -> void:
	_config = config


func set_grid_ui_slots(slots: Dictionary) -> void:
	_grid_ui_slots = slots


# =============================================================================
# ACTIVATION — flash + scale pulse
# =============================================================================

## Plays the activation flash. batch_id >= 0 means the rune is part of a
## simultaneous activation batch (reserved for future batch-specific juice).
func on_rune_activated(slot: GridSlot, rune: RuneInstance, _batch_id: int = -1) -> void:
	if not _config or not rune:
		return

	var slot_ui = _get_slot_ui(slot)
	if not slot_ui:
		return

	var element_color = _get_rune_element_color(rune)

	slot_ui.pivot_offset = slot_ui.size / 2.0

	# A previous flash may still be running (re-activation in the same step)
	_kill_activation_tweens(slot_ui)

	# Color flash
	var flash_tween = slot_ui.create_tween()
	slot_ui.modulate = element_color
	flash_tween.tween_property(
		slot_ui, "modulate",
		Color.WHITE,
		_config.activation_flash_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Scale pulse
	var scale_tween = slot_ui.create_tween()
	scale_tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.activation_pulse_scale, _config.activation_pulse_scale),
		_config.activation_pulse_duration * 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(
		slot_ui, "scale",
		Vector2.ONE,
		_config.activation_pulse_duration * 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	_activation_tweens[slot_ui.get_instance_id()] = [flash_tween, scale_tween]


# =============================================================================
# DESTRUCTION — dissolve in mana + fade out + scale down
# =============================================================================

func on_rune_destroyed(slot: GridSlot, rune: RuneInstance) -> void:
	if not _config or not rune:
		return

	var slot_ui = _get_slot_ui(slot)
	if not slot_ui:
		return

	var element_color = _get_rune_element_color(rune)

	slot_ui.pivot_offset = slot_ui.size / 2.0

	# A rune often activates and dies in the same step — the pending flash would
	# fight the dissolve for modulate/scale.
	_kill_activation_tweens(slot_ui)

	var tween = slot_ui.create_tween()

	# Tint with element/mana color
	tween.tween_property(
		slot_ui, "modulate",
		element_color,
		_config.destruction_fade_duration * 0.3
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Scale down + fade out simultaneously
	tween.parallel().tween_property(
		slot_ui, "scale",
		Vector2(_config.destruction_scale, _config.destruction_scale),
		_config.destruction_fade_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(
		slot_ui, "modulate:a",
		0.0,
		_config.destruction_fade_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Reset after animation
	tween.tween_callback(func() -> void:
		if is_instance_valid(slot_ui):
			slot_ui.scale = Vector2.ONE
			slot_ui.modulate = Color.WHITE
	)


# =============================================================================
# CREATION — mana converges + scale from 0 with overshoot + glow
# =============================================================================

func on_rune_created(slot: GridSlot, rune: RuneInstance) -> void:
	if not _config or not rune:
		return

	var slot_ui = _get_slot_ui(slot)
	if not slot_ui:
		return

	var element_color = _get_rune_element_color(rune)

	slot_ui.pivot_offset = slot_ui.size / 2.0

	# A flash from the previous occupant must not bleed into the materialization
	_kill_activation_tweens(slot_ui)

	# Start invisible and small
	slot_ui.scale = Vector2.ZERO
	slot_ui.modulate = element_color

	var tween = slot_ui.create_tween()

	# Scale 0 → overshoot → 1.0
	tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.creation_overshoot_scale, _config.creation_overshoot_scale),
		_config.creation_duration * 0.6
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		slot_ui, "scale",
		Vector2.ONE,
		_config.creation_duration * 0.4
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Fade from element color glow to normal
	tween.parallel().tween_property(
		slot_ui, "modulate",
		Color.WHITE,
		_config.creation_duration + _config.creation_glow_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# =============================================================================
# HELPERS
# =============================================================================

## Stops any activation tween still running on this slot UI.
func _kill_activation_tweens(slot_ui: Control) -> void:
	var key := slot_ui.get_instance_id()
	if not _activation_tweens.has(key):
		return
	for tween in _activation_tweens[key]:
		if tween and tween.is_valid():
			tween.kill()
	_activation_tweens.erase(key)


func _get_slot_ui(slot: GridSlot) -> Control:
	if not slot:
		return null
	return _grid_ui_slots.get(slot.grid_position)


func _get_rune_element_color(rune: RuneInstance) -> Color:
	if not rune or not rune.data or rune.data.elements.is_empty():
		return Color.WHITE
	return _config.get_element_color(rune.data.elements[0])
