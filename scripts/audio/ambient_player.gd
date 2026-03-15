class_name AmbientPlayer
extends Node

## Manages background music with crossfade support.
## Uses two AudioStreamPlayers to allow smooth transitions.
## Outputs to the "Music" audio bus.

var ambient_config: AmbientConfig

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
## Which player is currently active (true = A, false = B)
var _active_is_a: bool = true
## Stored volume for restore after attenuation
var _base_volume_db: float = 0.0
## Whether the volume is currently attenuated
var _attenuated: bool = false


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = &"Music"
	_player_a.name = "AmbientA"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = &"Music"
	_player_b.name = "AmbientB"
	add_child(_player_b)


func _get_active_player() -> AudioStreamPlayer:
	return _player_a if _active_is_a else _player_b


func _get_inactive_player() -> AudioStreamPlayer:
	return _player_b if _active_is_a else _player_a


## Plays a track with fade-in on the active player.
func play_track(stream: AudioStream) -> void:
	if not stream:
		return
	var player := _get_active_player()
	player.stream = stream
	player.volume_db = -80.0
	player.play()
	_fade(player, -80.0, _base_volume_db, _get_fade_in_duration())


## Stops the currently playing track with fade-out.
func stop_track() -> void:
	var player := _get_active_player()
	if player.playing:
		_fade(player, player.volume_db, -80.0, _get_fade_out_duration())
		# Actually stop after fade
		var dur := _get_fade_out_duration()
		get_tree().create_timer(dur).timeout.connect(player.stop, CONNECT_ONE_SHOT)


## Smoothly crossfade from the current track to a new one.
func crossfade_to(stream: AudioStream) -> void:
	if not stream:
		return

	var old_player := _get_active_player()
	_active_is_a = not _active_is_a
	var new_player := _get_active_player()

	# Fade out old
	if old_player.playing:
		_fade(old_player, old_player.volume_db, -80.0, _get_fade_out_duration())
		var dur := _get_fade_out_duration()
		get_tree().create_timer(dur).timeout.connect(old_player.stop, CONNECT_ONE_SHOT)

	# Fade in new
	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()
	var target_db := _base_volume_db if not _attenuated else _base_volume_db + _get_attenuation()
	_fade(new_player, -80.0, target_db, _get_fade_in_duration())


## Reduce the ambient volume (e.g. during battle). 
func attenuate(target_db: float) -> void:
	_attenuated = true
	var player := _get_active_player()
	if player.playing:
		_fade(player, player.volume_db, target_db, _get_fade_out_duration())


## Restore ambient volume to normal level.
func restore_volume() -> void:
	_attenuated = false
	var player := _get_active_player()
	if player.playing:
		_fade(player, player.volume_db, _base_volume_db, _get_fade_in_duration())


# ---------------------------------------------------------------------------
# Fade helpers
# ---------------------------------------------------------------------------

func _fade(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, duration).from(from_db)


func _get_fade_in_duration() -> float:
	if ambient_config:
		return ambient_config.fade_in_duration
	return 1.0


func _get_fade_out_duration() -> float:
	if ambient_config:
		return ambient_config.fade_out_duration
	return 0.5


func _get_attenuation() -> float:
	if ambient_config:
		return ambient_config.battle_attenuation_db
	return -40.0
