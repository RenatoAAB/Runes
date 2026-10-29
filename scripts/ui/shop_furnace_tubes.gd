extends Sprite2D
## Authored pixels only. RoomLighting owns state and the shared surge clock.
const SHEET := preload("res://sprites/scenes/shop/tubes/tubes-sheet.png")
const PLAYBACK := preload("res://sprites/scenes/shop/tubes/playback.json")
var playback: Dictionary = PLAYBACK.data
var animation := "idle"
var phase_ms := 0.0

func _ready() -> void:
	name = "FurnaceTubes"
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2(playback.origin[0],playback.origin[1])
	texture = SHEET
	hframes = int(playback.sheet_grid[0])
	vframes = int(playback.sheet_grid[1])
	_select_frame()

func update_playback(delta: float, heated: bool, surge_elapsed: float) -> void:
	var next := "surge" if surge_elapsed >= 0.0 else ("heated" if heated else "idle")
	if next != animation:
		animation = next
		phase_ms = 0.0
	elif animation != "surge":
		phase_ms += delta*1000.0
	if animation == "surge":
		# No second activation clock: the 2400ms authored tag follows room heat.
		phase_ms = surge_elapsed*1000.0
	_select_frame()

func _select_frame() -> void:
	var tag: Dictionary = playback.tags[animation]
	var time := fposmod(phase_ms,float(tag.duration_ms)) if tag.loop else clampf(phase_ms,0.0,float(tag.duration_ms)-0.001)
	for index in range(int(tag.from),int(tag.to)+1):
		var duration := float(playback.frames[index].duration_ms)
		if time < duration:
			frame = index
			return
		time -= duration
	frame = int(tag.to)
