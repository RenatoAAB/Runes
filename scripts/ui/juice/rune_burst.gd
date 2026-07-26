class_name RuneBurst
extends Control

## One-shot activation burst: a ring that expands outward plus radial sparks.
## Drawn procedurally so it needs no art, and lives on the juice FX layer instead
## of inside the slot — that way it can overflow the slot bounds and survive the
## rune being destroyed in the same step.
##
## Free-standing: call setup() then play(); the node deletes itself when done.

var _color: Color = Color.WHITE
var _radius_start: float = 8.0
var _radius_end: float = 28.0
var _ring_width: float = 3.0
var _spark_count: int = 6
var _spark_length: float = 10.0
var _spark_phase: float = 0.0

## Animation cursor, 0 → 1, driven by the tween in play().
var _progress: float = 0.0


func setup(
	color: Color,
	radius_start: float,
	radius_end: float,
	ring_width: float,
	spark_count: int,
	spark_length: float
) -> void:
	_color = color
	_radius_start = radius_start
	_radius_end = radius_end
	_ring_width = ring_width
	_spark_count = spark_count
	_spark_length = spark_length
	# Rotating the spark fan per burst stops repeated activations on the same slot
	# from looking like one stamped image.
	_spark_phase = randf() * TAU
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0

	# Radius eases out (fast punch, slow settle) while alpha falls off late, so the
	# ring reads as energy leaving the rune rather than a shape fading in place.
	var expand := 1.0 - pow(1.0 - _progress, 2.0)
	var radius: float = lerpf(_radius_start, _radius_end, expand)
	var alpha: float = pow(1.0 - _progress, 1.6)

	var ring_color := _color
	ring_color.a = _color.a * alpha
	var width: float = maxf(1.0, _ring_width * (1.0 - _progress * 0.7))
	draw_arc(center, radius, 0.0, TAU, 32, ring_color, width)

	if _spark_count <= 0:
		return

	var spark_color := _color
	spark_color.a = _color.a * alpha * 0.9
	var spark_len: float = _spark_length * (1.0 - _progress)
	var spark_width: float = maxf(1.0, width * 0.8)
	for i in range(_spark_count):
		var angle: float = _spark_phase + TAU * float(i) / float(_spark_count)
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(
			center + dir * radius,
			center + dir * (radius + spark_len),
			spark_color,
			spark_width
		)
