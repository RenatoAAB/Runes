class_name ScorePopup
extends Label

## Floating "+N" that rises out of the slot that scored and fades.
## Lives on the juice FX layer, not inside the slot, so it can overflow the grid
## and outlive the rune that produced it.
##
## Closes the gap between cause and effect: the score label sits at the top of the
## screen while the action happens in the middle of the grid, so without this the
## player never sees which rune earned the points.
##
## Free-standing: call setup() then play(); the node deletes itself when done.


func setup(amount: int, color: Color, font_size: int, font: Font = null) -> void:
	text = "+%d" % amount
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = color

	add_theme_font_size_override("font_size", font_size)
	if font:
		add_theme_font_override("font", font)
	# A dark outline keeps the number readable over both the pale slots and the
	# dark cave background.
	add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 0.9))
	add_theme_constant_override("outline_size", maxi(2, font_size / 6))


func play(rise: float, duration: float) -> void:
	pivot_offset = size / 2.0
	scale = Vector2(0.6, 0.6)

	var tween := create_tween()

	# Pop in fast, so the number is already legible while the burst is still bright.
	tween.tween_property(self, "scale", Vector2.ONE, duration * 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Rise over the whole lifetime, decelerating.
	tween.parallel().tween_property(
		self, "position:y", position.y - rise, duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Hold opacity for the first half, then fade — a number that starts fading
	# immediately is hard to read at speed.
	tween.parallel().tween_property(
		self, "modulate:a", 0.0, duration * 0.5
	).set_delay(duration * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	tween.tween_callback(queue_free)
