extends Node

## Handles level/target label transition juice: dissolve out old text, reconstruct new text.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _level_label: Label = null
var _target_label: Label = null


func setup(config: JuiceConfig) -> void:
	_config = config


func set_labels(level_label: Label, target_label: Label) -> void:
	_level_label = level_label
	_target_label = target_label


## Called when a round advances (new level/target). Plays dissolve → update → reconstruct.
func on_round_advanced(old_level: int, new_level: int, new_target: int) -> void:
	if not _config:
		return

	if _level_label:
		_animate_label_transition(_level_label, "Level %d" % new_level)
	if _target_label:
		_animate_label_transition(_target_label, "%d" % new_target)


func _animate_label_transition(label: Label, new_text: String) -> void:
	if not label:
		return

	label.pivot_offset = label.size / 2.0
	var base_color = label.modulate

	var tween = label.create_tween()

	# Phase 1: Dissolve out — fade + scale down + transition color
	tween.tween_property(
		label, "modulate",
		_config.level_transition_color,
		_config.level_dissolve_out_duration * 0.5
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(
		label, "modulate:a",
		0.0,
		_config.level_dissolve_out_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(
		label, "scale",
		Vector2(_config.level_dissolve_scale, _config.level_dissolve_scale),
		_config.level_dissolve_out_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Update text at the midpoint
	tween.tween_callback(func() -> void:
		label.text = new_text
		label.modulate = _config.level_transition_color
		label.modulate.a = 0.0
	)

	# Phase 2: Reconstruct in — fade in + scale overshoot → settle
	tween.tween_property(
		label, "modulate:a",
		1.0,
		_config.level_reconstruct_in_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(
		label, "scale",
		Vector2(_config.level_reconstruct_scale, _config.level_reconstruct_scale),
		_config.level_reconstruct_in_duration * 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		label, "scale",
		Vector2.ONE,
		_config.level_reconstruct_in_duration * 0.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Restore base color
	tween.tween_property(
		label, "modulate",
		base_color,
		_config.level_reconstruct_in_duration * 0.3
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
