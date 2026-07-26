extends Node

## Handles rune activation flash, destruction dissolve, and creation materialization.
## Added as a child of JuiceManager.
##
## Effects are split across three targets on purpose:
##   - the rune's TextureRect takes the colour flash, so the slot frame, background
##     and residue overlay are not tinted into one flat block of hue;
##   - the SlotUI takes the scale pop, so the whole cell reads as "being read";
##   - the FX layer takes the burst and the dissolve ghost, so they can overflow the
##     slot bounds and outlive the rune node itself.
## That last point matters: a rune that activates and destroys itself in the same
## step (very common) used to lose its activation feedback entirely, because the
## dissolve killed the flash one millisecond after it started.

## Loaded by path rather than by class_name: this module is itself loaded
## dynamically by JuiceManager, and a freshly added class_name is not in the
## global class cache until the editor rescans the project.
const RUNE_BURST := preload("res://scripts/ui/juice/rune_burst.gd")

var _config: JuiceConfig
var _grid_ui_slots: Dictionary = {}  # Vector2i -> SlotUI
var _fx_layer: Control = null

## Running activation tweens per slot UI (instance_id -> Array[Tween]).
## Chained/simultaneous activations can hit the same slot within one frame, so the
## previous flash is killed before starting a new one to avoid stuck modulate/scale.
var _activation_tweens: Dictionary = {}


func setup(config: JuiceConfig) -> void:
	_config = config


func set_grid_ui_slots(slots: Dictionary) -> void:
	_grid_ui_slots = slots


func set_fx_layer(layer: Control) -> void:
	_fx_layer = layer


# =============================================================================
# ACTIVATION — flash + scale pop + burst
# =============================================================================

## Plays the activation feedback. batch_id >= 0 means the rune is part of a
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

	var tweens: Array = []

	# Colour flash on the rune itself. Held near full intensity with EASE_IN and
	# only then released — EASE_OUT dumped 75% of the colour in the first 0.1s,
	# which left the flash visible for barely one or two frames.
	var rune_ui: Control = slot_ui.get("rune_ui")
	if rune_ui:
		var flash_tween = rune_ui.create_tween()
		rune_ui.modulate = _flash_color(element_color)
		flash_tween.tween_property(
			rune_ui, "modulate",
			Color.WHITE,
			_config.activation_flash_duration
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tweens.append(flash_tween)

	# Scale pop on the whole cell — overshoot hard, settle with a small bounce.
	var scale_tween = slot_ui.create_tween()
	scale_tween.tween_property(
		slot_ui, "scale",
		Vector2(_config.activation_pulse_scale, _config.activation_pulse_scale),
		_config.activation_pulse_duration * 0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(
		slot_ui, "scale",
		Vector2.ONE,
		_config.activation_pulse_duration * 0.7
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tweens.append(scale_tween)

	_activation_tweens[slot_ui.get_instance_id()] = tweens

	_spawn_burst(slot_ui, element_color)


## Expanding ring + sparks on the FX layer, centred on the slot.
func _spawn_burst(slot_ui: Control, element_color: Color) -> void:
	if not _config.burst_enabled or not _fx_layer:
		return

	var burst: Control = RUNE_BURST.new()
	var half: float = slot_ui.size.x / 2.0
	burst.setup(
		_flash_color(element_color),
		half * _config.burst_radius_start,
		half * _config.burst_radius_end,
		_config.burst_ring_width,
		_config.burst_spark_count,
		half * _config.burst_spark_length
	)
	_add_to_fx_layer(burst, slot_ui)
	burst.play(_config.burst_duration)


# =============================================================================
# DESTRUCTION — the rune dissolves, the slot stays put
# =============================================================================

func on_rune_destroyed(slot: GridSlot, rune: RuneInstance) -> void:
	if not _config or not rune:
		return

	var slot_ui = _get_slot_ui(slot)
	if not slot_ui:
		return

	var element_color = _get_rune_element_color(rune)

	# The old version tinted and faded the entire SlotUI, which turned the cell
	# into a flat coloured square for half a second — the rune vanished inside it
	# instead of visibly dissolving. Now only a ghost of the rune dissolves, on the
	# FX layer, and the slot frame/background/residue stay untouched.
	_spawn_dissolve_ghost(slot_ui, element_color)


## Copies the rune's texture onto the FX layer and dissolves the copy, so the
## effect is independent of the SlotUI freeing its RuneUI child this same frame.
func _spawn_dissolve_ghost(slot_ui: Control, element_color: Color) -> void:
	if not _fx_layer:
		return

	var rune_ui: Control = slot_ui.get("rune_ui")
	if not rune_ui or not (rune_ui is TextureRect):
		return
	var source := rune_ui as TextureRect
	if not source.texture:
		return

	var ghost := TextureRect.new()
	ghost.texture = source.texture
	ghost.expand_mode = source.expand_mode
	ghost.stretch_mode = source.stretch_mode
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = source.size
	_add_to_fx_layer(ghost, slot_ui)
	ghost.pivot_offset = ghost.size / 2.0

	var tween := ghost.create_tween()

	# Charge up into the element/mana colour, then scatter.
	tween.tween_property(
		ghost, "modulate",
		_flash_color(element_color),
		_config.destruction_fade_duration * 0.25
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.parallel().tween_property(
		ghost, "scale",
		Vector2(_config.destruction_scale, _config.destruction_scale),
		_config.destruction_fade_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(
		ghost, "modulate:a",
		0.0,
		_config.destruction_fade_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	tween.tween_callback(ghost.queue_free)


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
	slot_ui.modulate = _flash_color(element_color)

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

## Places an effect node on the FX layer, centred over the given slot.
func _add_to_fx_layer(node: Control, slot_ui: Control) -> void:
	_fx_layer.add_child(node)
	if node.size == Vector2.ZERO:
		node.size = slot_ui.size
	node.global_position = slot_ui.global_position \
		+ (slot_ui.size - node.size) / 2.0


## Element colours all have channels below 1.0, so using one straight as a
## modulate can only ever darken the sprite — the "flash" read as a shadow. Mixing
## in white and pushing past 1.0 makes it read as light instead.
func _flash_color(element_color: Color) -> Color:
	var mixed := element_color.lerp(Color.WHITE, _config.activation_flash_whiten)
	var boost := _config.activation_flash_overdrive
	return Color(mixed.r * boost, mixed.g * boost, mixed.b * boost, 1.0)


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
