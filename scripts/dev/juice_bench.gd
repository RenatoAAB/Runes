class_name JuiceBench
extends Node

## Headless-friendly bench for inspecting the READING juice: the flash/pulse a slot
## plays when its rune activates, and the punch/count the score label plays when
## points come in.
##
## Boots the real main scene, fills the panel grid with runes, fires the battle and
## records the viewport frame by frame, timestamping every juice-relevant event so a
## frame can be matched to the signal that caused it.
##
## Usage (user args go after `--`):
##   godot --path <project> res://scenes/dev/juice_bench.tscn -- \
##       --frames=30 --interval=0.05 --delay=0.5 --runes=6 \
##       --crop=grid --out=C:/tmp/juice
##
## --crop accepts `none` (whole window), `grid` (panel area) or `score` (score
## label area); the cropped region is taken from the live control rect, so it
## follows the layout instead of hard-coded pixels.
##
## On success prints `JUICE_BENCH_OUT=<absolute path>` and exits 0.
## On failure prints `JUICE_BENCH_ERROR=<message>` and exits 1.

const MAIN_SCENE := "res://scenes/main.tscn"

const DEFAULT_FRAMES := 30
const DEFAULT_INTERVAL := 0.05
const DEFAULT_DELAY := 0.5
const DEFAULT_RUNES := 6
const CONTACT_SHEET_COLUMNS := 6

## Runes picked so consecutive activations use different elements — the flash is
## tinted per element, so mixing them makes the colour ramp visible.
const RUNE_POOL := [
	"res://resources/runes/common/rune_labareda.tres",
	"res://resources/runes/common/rune_gota.tres",
	"res://resources/runes/common/rune_rocha.tres",
	"res://resources/runes/common/rune_vento.tres",
	"res://resources/runes/common/rune_derretimento.tres",
	"res://resources/runes/common/rune_quartzo.tres",
	"res://resources/runes/common/rune_chuva.tres",
	"res://resources/runes/common/rune_explosao.tres",
	"res://resources/runes/common/rune_sopro.tres",
]

## Node whose on-screen rect defines each crop mode. Resolved at capture time so
## the region follows the real layout instead of hard-coded viewport pixels.
const CROP_NODES := {
	"grid": "GridContainer",
	"score": "ScoreLabel",
}

## Extra pixels kept around the cropped node, in viewport units.
const CROP_MARGIN := 8

var _args: Dictionary = {}
var _out_dir: String = ""
var _frame_paths: Array[String] = []
var _frame_times: Array[float] = []
var _events: Array[Dictionary] = []
var _clock_start: int = 0
var _main: Node = null


func _ready() -> void:
	_args = _parse_args()

	var frames: int = int(_args.get("frames", DEFAULT_FRAMES))
	var interval: float = float(_args.get("interval", DEFAULT_INTERVAL))
	var delay: float = float(_args.get("delay", DEFAULT_DELAY))
	var rune_count: int = int(_args.get("runes", DEFAULT_RUNES))
	var crop: String = String(_args.get("crop", "none"))
	var out_arg: String = String(_args.get("out", ""))

	_out_dir = _resolve_out_dir(out_arg)
	if not DirAccess.dir_exists_absolute(_out_dir):
		var dir_err := DirAccess.make_dir_recursive_absolute(_out_dir)
		if dir_err != OK:
			_fail("could not create output dir '%s' (error %d)" % [_out_dir, dir_err])
			return

	var packed: PackedScene = load(MAIN_SCENE)
	if packed == null:
		_fail("could not load main scene: %s" % MAIN_SCENE)
		return
	_main = packed.instantiate()
	add_child(_main)

	# The controller binds panel/grid/reader over a few frames after _ready.
	for i in range(10):
		await get_tree().process_frame

	var controller := get_tree().get_first_node_in_group("main_controller")
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if controller == null or game_manager == null:
		_fail("main_controller/game_manager not found after boot")
		return

	_hook_events()

	var placed := _fill_grid(controller, rune_count)
	if placed == 0:
		_fail("could not place any rune on the grid")
		return

	# Let the UI redraw the freshly placed runes before the reading starts.
	for i in range(5):
		await get_tree().process_frame

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	_clock_start = Time.get_ticks_msec()
	_log_event("battle_start", {})
	game_manager.start_battle()

	await _capture_frames(frames, interval, crop)

	if _frame_paths.is_empty():
		_fail("no frames were captured")
		return

	_build_contact_sheet()
	_write_manifest(frames, interval, delay, placed, crop)

	print("JUICE_BENCH_OUT=%s" % ProjectSettings.globalize_path(_out_dir))
	get_tree().quit(0)


## --- Argument parsing ---

func _parse_args() -> Dictionary:
	var parsed := {}
	for raw_arg in OS.get_cmdline_user_args():
		var arg: String = raw_arg
		if not arg.begins_with("--"):
			continue
		var trimmed := arg.trim_prefix("--")
		var parts := trimmed.split("=", true, 1)
		if parts.size() == 2:
			parsed[parts[0]] = parts[1]
		else:
			parsed[parts[0]] = ""
	return parsed


func _resolve_out_dir(out_arg: String) -> String:
	if out_arg.is_empty():
		return "user://juice_captures/reading/"
	var normalized := out_arg.replace("\\", "/")
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


## --- Grid setup ---

## Places runes on the first free coordinates of the active panel grid.
func _fill_grid(controller: Node, rune_count: int) -> int:
	var grid_manager = controller.get("grid_manager")
	if grid_manager == null:
		push_warning("[JuiceBench] controller has no bound grid_manager")
		return 0

	var placed := 0
	var pool_index := 0
	for y in range(5):
		for x in range(5):
			if placed >= rune_count:
				return placed
			var rune_path: String = RUNE_POOL[pool_index % RUNE_POOL.size()]
			var rune_data: RuneData = load(rune_path) as RuneData
			pool_index += 1
			if rune_data == null:
				continue
			if grid_manager.place_rune(rune_data, Vector2i(x, y)):
				placed += 1
	return placed


## --- Event logging ---

## Subscribes to every signal that drives reading juice so each captured frame can
## be attributed to the event that triggered it.
func _hook_events() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		if event_bus.has_signal("rune_activation_started"):
			event_bus.rune_activation_started.connect(
				func(slot, rune, batch_id): _log_event("rune_activation_started", {
					"coord": str(slot.grid_position) if slot else "?",
					"rune": rune.data.rune_name if rune and rune.data else "?",
					"element": _element_name(rune),
					"batch_id": batch_id,
				})
			)
		if event_bus.has_signal("rune_destroyed"):
			event_bus.rune_destroyed.connect(
				func(slot, rune): _log_event("rune_destroyed", {
					"coord": str(slot.grid_position) if slot else "?",
					"rune": rune.data.rune_name if rune and rune.data else "?",
				})
			)
		if event_bus.has_signal("rune_created"):
			event_bus.rune_created.connect(
				func(slot, rune): _log_event("rune_created", {
					"coord": str(slot.grid_position) if slot else "?",
					"rune": rune.data.rune_name if rune and rune.data else "?",
				})
			)

	var controller := get_tree().get_first_node_in_group("main_controller")
	if controller == null:
		return
	var reader = controller.get("reader")
	if reader == null:
		return
	if reader.has_signal("step_started"):
		reader.step_started.connect(func(coord): _log_event("step_started", {"coord": str(coord)}))
	if reader.has_signal("step_completed"):
		reader.step_completed.connect(func(coord): _log_event("step_completed", {"coord": str(coord)}))
	if reader.has_signal("score_updated"):
		reader.score_updated.connect(func(total): _log_event("score_updated", {"total": total}))
	if reader.has_signal("sequence_finished"):
		reader.sequence_finished.connect(func(total): _log_event("sequence_finished", {"total": total}))


func _element_name(rune) -> String:
	if rune == null or rune.data == null or rune.data.elements.is_empty():
		return "none"
	return str(rune.data.elements[0])


func _log_event(kind: String, data: Dictionary) -> void:
	_events.append({
		"t": _elapsed(),
		"kind": kind,
		"data": data,
	})


func _elapsed() -> float:
	if _clock_start == 0:
		return 0.0
	return float(Time.get_ticks_msec() - _clock_start) / 1000.0


## --- Frame capture ---

func _capture_frames(frames: int, interval: float, crop: String) -> void:
	var crop_rect := Rect2i()
	for i in range(frames):
		# interval <= 0 captures every rendered frame, which is the only way to see
		# the first milliseconds of a 0.2s tween — a timer always misses them.
		if interval > 0.0:
			await get_tree().create_timer(interval).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		if crop_rect.size == Vector2i.ZERO:
			crop_rect = _resolve_crop_rect(crop, image.get_size())
		if crop_rect.size != Vector2i.ZERO:
			image = image.get_region(crop_rect)
		var frame_path := _out_dir.path_join("frame_%03d.png" % i)
		image.save_png(frame_path)
		_frame_paths.append(frame_path)
		_frame_times.append(_elapsed())


## Converts the on-screen rect of the crop mode's node into image pixels. The
## window is usually larger than the 640x360 design viewport, so the control rect
## has to be scaled by the same factor the stretch applied.
func _resolve_crop_rect(crop: String, image_size: Vector2i) -> Rect2i:
	if not CROP_NODES.has(crop):
		return Rect2i()
	var node := _main.find_child(CROP_NODES[crop], true, false)
	if node == null or not (node is Control):
		push_warning("[JuiceBench] crop node '%s' not found" % CROP_NODES[crop])
		return Rect2i()

	var rect: Rect2 = (node as Control).get_global_rect().grow(CROP_MARGIN)
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Rect2i()
	var scale := Vector2(image_size) / viewport_size

	var result := Rect2i(
		Vector2i(rect.position * scale),
		Vector2i(rect.size * scale)
	)
	return result.intersection(Rect2i(Vector2i.ZERO, image_size))


## --- Contact sheet ---

func _build_contact_sheet() -> void:
	var images: Array[Image] = []
	for path in _frame_paths:
		var image := Image.load_from_file(path)
		if image != null:
			images.append(image)
	if images.is_empty():
		return

	var frame_size := images[0].get_size()
	var format := images[0].get_format()
	var columns := CONTACT_SHEET_COLUMNS
	var rows := ceili(float(images.size()) / float(columns))

	var sheet := Image.create(frame_size.x * columns, frame_size.y * rows, false, format)
	sheet.fill(Color(0.0, 0.0, 0.0, 1.0))

	for i in range(images.size()):
		var image := images[i]
		if image.get_format() != format:
			image.convert(format)
		var col := i % columns
		var row := i / columns
		sheet.blit_rect(
			image,
			Rect2i(Vector2i.ZERO, image.get_size()),
			Vector2i(col * frame_size.x, row * frame_size.y)
		)

	sheet.save_png(_out_dir.path_join("contact_sheet.png"))


## --- Manifest ---

func _write_manifest(frames: int, interval: float, delay: float, placed: int, crop: String) -> void:
	var frame_entries: Array = []
	for i in range(_frame_paths.size()):
		frame_entries.append({
			"file": _frame_paths[i].get_file(),
			"t": _frame_times[i],
		})

	var manifest := {
		"scene": MAIN_SCENE,
		"frames": frames,
		"interval": interval,
		"delay": delay,
		"crop": crop,
		"runes_placed": placed,
		"out": ProjectSettings.globalize_path(_out_dir),
		"frame_list": frame_entries,
		"events": _events,
		"contact_sheet": "contact_sheet.png",
	}

	var manifest_file := FileAccess.open(_out_dir.path_join("manifest.json"), FileAccess.WRITE)
	if manifest_file:
		manifest_file.store_string(JSON.stringify(manifest, "\t"))
		manifest_file.close()


## --- Failure helper ---

func _fail(message: String) -> void:
	print("JUICE_BENCH_ERROR=%s" % message)
	get_tree().quit(1)
