extends Node

## Animates the score label with scale punch, color flash, and counting effect.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _score_label: Label = null
var _previous_score: int = 0
var _base_color: Color = Color.WHITE
var _counting_tween: Tween = null
var _punch_tween: Tween = null


func setup(config: JuiceConfig) -> void:
	_config = config


func set_score_label(label: Label) -> void:
	_score_label = label
	if _score_label:
		_base_color = _score_label.modulate
		# Parse current score from label text
		var text = _score_label.text.replace("Score: ", "")
		_previous_score = int(text) if text.is_valid_int() else 0


func on_score_updated(new_total: int) -> void:
	if not _score_label or not _config:
		return

	var delta = absi(new_total - _previous_score)
	if delta == 0:
		_previous_score = new_total
		return

	_play_scale_punch(delta)
	_play_color_flash(delta)
	_play_counting_animation(_previous_score, new_total)
	_previous_score = new_total


func _play_scale_punch(delta: int) -> void:
	# Determine magnitude
	var target_scale: float
	var ease_type: Tween.EaseType

	if delta < _config.score_small_threshold:
		target_scale = _config.score_punch_small
		ease_type = Tween.EASE_OUT
	elif delta < _config.score_large_threshold:
		target_scale = _config.score_punch_medium
		ease_type = Tween.EASE_OUT
	else:
		target_scale = _config.score_punch_large
		ease_type = Tween.EASE_OUT

	var trans_type = Tween.TRANS_BACK if delta >= _config.score_large_threshold else Tween.TRANS_QUAD

	# Kill existing punch tween
	if _punch_tween and _punch_tween.is_valid():
		_punch_tween.kill()

	_score_label.pivot_offset = _score_label.size / 2.0
	_punch_tween = _score_label.create_tween()
	_punch_tween.tween_property(
		_score_label, "scale",
		Vector2(target_scale, target_scale),
		_config.score_punch_duration * 0.4
	).set_ease(ease_type).set_trans(trans_type)
	_punch_tween.tween_property(
		_score_label, "scale",
		Vector2.ONE,
		_config.score_punch_duration * 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _play_color_flash(delta: int) -> void:
	var flash_color: Color
	if delta >= _config.score_large_threshold:
		flash_color = _config.score_flash_color_large
	else:
		flash_color = _config.score_flash_color_small

	var tween = _score_label.create_tween()
	_score_label.modulate = flash_color
	tween.tween_property(
		_score_label, "modulate",
		_base_color,
		_config.score_flash_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func _play_counting_animation(from: int, to: int) -> void:
	if _counting_tween and _counting_tween.is_valid():
		_counting_tween.kill()

	var display_value := float(from)
	_counting_tween = _score_label.create_tween()
	_counting_tween.tween_method(
		func(val: float) -> void:
			if _score_label:
				_score_label.text = "Score: %d" % int(val),
		float(from),
		float(to),
		_config.score_count_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
