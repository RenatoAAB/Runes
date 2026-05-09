class_name TooltipFxManaAnomaly
extends RichTextEffect

## Harsher anomaly glitch inspired by mana_anomaly shader behavior.
## Includes periodic burst trigger, rapid flicker, blocky horizontal shifts,
## and aggressive color injections (magenta/green/white).

var bbcode := "mana_anomaly_fx"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var t: float = char_fx.elapsed_time
	var idx: float = float(char_fx.relative_index)
	var base_color: Color = char_fx.color

	# Matches shader-like burst logic (glitch_frequency ~= 3.0).
	var burst: float = _glitch_trigger(t, idx)
	var block_intensity: float = _block_glitch(t, idx)
	var strength: float = clampf(maxf(burst, block_intensity), 0.0, 1.0)

	# Baseline unstable motion.
	var jitter_seed: float = t * 17.0 + idx * 6.7
	char_fx.offset.x += sin(jitter_seed) * (0.70 + strength * 0.45)
	char_fx.offset.y += cos(jitter_seed * 0.73) * (0.45 + strength * 0.25)

	# Rectilinear-like block displacement (shader glitch_block_size ~= 2.0).
	char_fx.offset.x += _block_shift(t, idx) * strength * 2.8

	# Rapid flicker during bursts (shader flicker around ~30 Hz).
	var flicker_seed: float = float(floor(t * 30.0)) + idx * 1.91
	var flicker_pick: float = _hash1(flicker_seed)
	if strength > 0.60 and flicker_pick > 0.92:
		char_fx.visible = false
		return true
	char_fx.visible = true

	# Aggressive color injection sequence: magenta, green, white.
	var cycle_seed: float = float(floor(t * 18.0)) + float(floor(idx * 0.5)) * 2.37
	var cycle_pick: float = _hash1(cycle_seed)
	var injected: Color = Color(0.93, 0.10, 0.60, base_color.a)
	if cycle_pick < 0.33:
		injected = Color(0.93, 0.10, 0.60, base_color.a) # Magenta
	elif cycle_pick < 0.66:
		injected = Color(0.10, 1.00, 0.40, base_color.a) # Green
	else:
		injected = Color(1.00, 1.00, 1.00, base_color.a) # White flash

	var inject_mix: float = strength * 0.85
	char_fx.color = base_color.lerp(injected, clampf(inject_mix, 0.0, 0.85))

	# Lightweight chromatic aberration feel.
	if strength > 0.20:
		char_fx.color.r = clampf(char_fx.color.r + strength * 0.12, 0.0, 1.0)
		char_fx.color.b = clampf(char_fx.color.b + strength * 0.05, 0.0, 1.0)
	return true


func _glitch_trigger(t: float, idx: float) -> float:
	var time: float = t + idx * 0.011
	var wave: float = sin(time * 3.0 * 0.7) * sin(time * 3.0 * 1.3)
	var trigger: float = smoothstep(0.6, 0.9, wave)
	var flicker_seed: float = float(floor(time * 30.0)) + idx * 0.77
	var flicker: float = 1.0 if _hash1(flicker_seed) > 0.70 else 0.0
	return trigger * lerpf(0.5, 1.0, flicker)


func _block_glitch(t: float, idx: float) -> float:
	var block_id: float = float(floor(idx / 2.0))
	var h: float = _hash1(block_id + float(floor(t * 12.0)))
	var active: float = 1.0 if h > 0.6 else 0.0
	return active * _glitch_trigger(t, idx)


func _block_shift(t: float, idx: float) -> float:
	var block_id: float = float(floor(idx / 2.0))
	var shift_seed: float = block_id * 3.7 + float(floor(t * 20.0))
	return (_hash1(shift_seed) - 0.5) * 1.6


func _hash1(p: float) -> float:
	return fposmod(sin(p * 127.1) * 43758.5453, 1.0)
