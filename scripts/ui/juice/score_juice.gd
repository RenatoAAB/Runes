extends Node

## Animates the score label with scale punch, color flash, and counting effect.
## Added as a child of JuiceManager.

var _config: JuiceConfig
var _score_label: Label = null
var _previous_score: int = 0
var _base_color: Color = Color.WHITE
var _counting_tween: Tween = null
var _punch_tween: Tween = null

## The number currently on screen, which lags behind _previous_score while the
## counting tween runs. Restarting the count from _previous_score made the label
## jump straight to the old total before counting on — during a fast reading that
## turned the score into a stutter.
var _displayed_value: float = 0.0

## When the last score update arrived, used to shorten the count so it always
## finishes before the next rune activates.
var _last_update_msec: int = 0


func setup(config: JuiceConfig) -> void:
	_config = config


func set_score_label(label: Label) -> void:
	_score_label = label
	if _score_label:
		_base_color = _score_label.modulate
		# Parse current score from label text
		var text = _score_label.text.replace("Score: ", "")
		_previous_score = int(text) if text.is_valid_int() else 0
		_displayed_value = float(_previous_score)


func on_score_updated(new_total: int) -> void:
	if not _score_label or not _config:
		return

	var delta = absi(new_total - _previous_score)
	if delta == 0:
		_previous_score = new_total
		return

	_play_scale_punch(delta)
	_play_color_flash(delta)
	_play_counting_animation(new_total)
	_previous_score = new_total
	_last_update_msec = Time.get_ticks_msec()


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


func _play_counting_animation(to: int) -> void:
	if _counting_tween and _counting_tween.is_valid():
		_counting_tween.kill()

	# Continue from whatever is on screen right now, not from the last total.
	var from := _displayed_value

	_counting_tween = _score_label.create_tween()
	_counting_tween.tween_method(
		func(val: float) -> void:
			_displayed_value = val
			if _score_label:
				_score_label.text = "Score: %d" % int(val),
		from,
		float(to),
		_count_duration()
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## Fits the count inside the gap between activations. The reader speeds up as a
## reading goes on (0.5s per step down to 0.05s), so a fixed 0.4s count would spend
## most of a long reading chasing a total it never reaches.
func _count_duration() -> float:
	if _last_update_msec == 0:
		return _config.score_count_duration
	var gap := float(Time.get_ticks_msec() - _last_update_msec) / 1000.0
	return clampf(minf(_config.score_count_duration, gap * 0.85), 0.08, _config.score_count_duration)
