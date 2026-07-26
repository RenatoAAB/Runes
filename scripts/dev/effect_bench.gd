class_name EffectBench
extends Node2D

## Headless-friendly bench for iterating on a single isolated visual effect.
## Loads ONE effect (a .tscn, a .gdshader or a ParticleProcessMaterial .tres),
## triggers it, captures N frames as PNG and assembles a contact sheet so an
## AI (or a human) can iterate quickly: edit -> run -> look at the sheet -> adjust.
##
## Usage (user args go after `--`, or `++` if `--` gets swallowed):
##   godot --path <project> res://scenes/dev/effect_bench.tscn -- \
##       --effect=res://resources/shaders/mana_anomaly.gdshader \
##       --frames=8 --interval=0.1 --delay=0.2 --bg=dark --out=C:/tmp/bench
##
## Supported --effect types:
##   .tscn      -> instantiated directly under EffectHolder.
##   .gdshader  -> wrapped in a Sprite2D using a placeholder rune texture.
##   .tres      -> must resolve to a ParticleProcessMaterial; wrapped in a
##                 GPUParticles2D with emitting = true.
##
## On success prints `EFFECT_BENCH_OUT=<absolute path>` and exits with code 0.
## On failure prints `EFFECT_BENCH_ERROR=<message>` and exits with code 1.

const DEFAULT_FRAMES := 12
const DEFAULT_INTERVAL := 0.1
const DEFAULT_DELAY := 0.2
const DEFAULT_BG := "dark"
const CONTACT_SHEET_COLUMNS := 4

const PLACEHOLDER_SPRITE_PATH := "res://sprites/runes/fenix.png"

## "checker" currently falls back to a neutral gray tone to keep this bench
## simple; a real two-tone checker shader can be added later if needed.
const BG_COLORS := {
	"dark": Color(0.05, 0.05, 0.07, 1.0),
	"neutral": Color(0.5, 0.5, 0.5, 1.0),
	"checker": Color(0.5, 0.5, 0.5, 1.0),
}

@onready var background: ColorRect = $Background
@onready var effect_holder: Node2D = $EffectHolder

var _args: Dictionary = {}
var _out_dir: String = ""
var _frame_paths: Array[String] = []


func _ready() -> void:
	_args = _parse_args()

	var effect_path: String = String(_args.get("effect", ""))
	if effect_path.is_empty():
		_fail("missing required --effect=res://... argument")
		return
	if not ResourceLoader.exists(effect_path):
		_fail("effect resource not found: %s" % effect_path)
		return

	var frames: int = int(_args.get("frames", DEFAULT_FRAMES))
	var interval: float = float(_args.get("interval", DEFAULT_INTERVAL))
	var delay: float = float(_args.get("delay", DEFAULT_DELAY))
	var bg: String = String(_args.get("bg", DEFAULT_BG))
	var out_arg: String = String(_args.get("out", ""))

	_apply_background(bg)

	var effect_node := _load_effect(effect_path)
	if effect_node == null:
		_fail("could not build an effect node from: %s" % effect_path)
		return

	effect_holder.add_child(effect_node)
	_trigger_effect(effect_holder)

	_out_dir = _resolve_out_dir(out_arg, effect_path)
	if not DirAccess.dir_exists_absolute(_out_dir):
		var dir_err := DirAccess.make_dir_recursive_absolute(_out_dir)
		if dir_err != OK:
			_fail("could not create output dir '%s' (error %d)" % [_out_dir, dir_err])
			return

	await _capture_frames(frames, interval, delay)

	if _frame_paths.is_empty():
		_fail("no frames were captured")
		return

	_build_contact_sheet()
	_write_manifest(effect_path, frames, interval, delay, bg)

	print("EFFECT_BENCH_OUT=%s" % ProjectSettings.globalize_path(_out_dir))
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


func _resolve_out_dir(out_arg: String, effect_path: String) -> String:
	if not out_arg.is_empty():
		var normalized := out_arg.replace("\\", "/")
		if not normalized.ends_with("/"):
			normalized += "/"
		return normalized
	var effect_name := effect_path.get_file().get_basename()
	return "user://effect_captures/%s/" % effect_name


## --- Effect loading ---

func _load_effect(effect_path: String) -> Node:
	var extension := effect_path.get_extension().to_lower()
	match extension:
		"tscn":
			var packed: PackedScene = load(effect_path)
			if packed == null:
				return null
			return packed.instantiate()
		"gdshader":
			var shader: Shader = load(effect_path)
			if shader == null:
				return null
			var sprite := Sprite2D.new()
			sprite.texture = load(PLACEHOLDER_SPRITE_PATH)
			var material := ShaderMaterial.new()
			material.shader = shader
			sprite.material = material
			return sprite
		"tres":
			var resource: Resource = load(effect_path)
			if resource is ParticleProcessMaterial:
				var particles := GPUParticles2D.new()
				particles.process_material = resource
				particles.emitting = true
				return particles
			push_warning("Resource at '%s' is not a ParticleProcessMaterial (got %s)" % [effect_path, resource])
			return null
		_:
			push_warning("Unsupported --effect extension: '%s'" % extension)
			return null


## Recursively fires whatever needs firing so the effect starts playing
## immediately: restarts GPUParticles2D emitters and plays the first
## animation found on any AnimationPlayer. AudioStreamPlayer nodes are
## left alone (audio playback is irrelevant for a visual contact sheet).
func _trigger_effect(root: Node) -> void:
	if root is GPUParticles2D:
		var particles := root as GPUParticles2D
		particles.emitting = true
		particles.restart()
	elif root is AnimationPlayer:
		var player := root as AnimationPlayer
		var animations := player.get_animation_list()
		if animations.size() > 0:
			player.play(animations[0])

	for child in root.get_children():
		_trigger_effect(child)


## --- Background ---

func _apply_background(bg: String) -> void:
	background.color = BG_COLORS.get(bg, BG_COLORS[DEFAULT_BG])


## --- Frame capture ---

func _capture_frames(frames: int, interval: float, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	for i in range(frames):
		if interval > 0.0:
			await get_tree().create_timer(interval).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var frame_path := _out_dir.path_join("frame_%03d.png" % i)
		image.save_png(frame_path)
		_frame_paths.append(frame_path)


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
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(col * frame_size.x, row * frame_size.y))

	sheet.save_png(_out_dir.path_join("contact_sheet.png"))


## --- Manifest ---

func _write_manifest(effect_path: String, frames: int, interval: float, delay: float, bg: String) -> void:
	var file_names: Array[String] = []
	for path in _frame_paths:
		file_names.append(path.get_file())

	var manifest := {
		"effect": effect_path,
		"frames": frames,
		"interval": interval,
		"delay": delay,
		"bg": bg,
		"out": ProjectSettings.globalize_path(_out_dir),
		"files": file_names,
		"contact_sheet": "contact_sheet.png",
	}

	var manifest_file := FileAccess.open(_out_dir.path_join("manifest.json"), FileAccess.WRITE)
	if manifest_file:
		manifest_file.store_string(JSON.stringify(manifest, "\t"))
		manifest_file.close()


## --- Failure helper ---

func _fail(message: String) -> void:
	print("EFFECT_BENCH_ERROR=%s" % message)
	get_tree().quit(1)
