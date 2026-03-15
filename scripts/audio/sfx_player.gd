class_name SFXPlayer
extends Node

## Polyphonic one-shot player for UI / gameplay sound effects.
## Outputs to the "SFX" audio bus.

var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"SFX"
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 16
	_player.stream = poly
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamPlaybackPolyphonic


## Fire-and-forget: plays an SFX stream once.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not stream or not _playback:
		return
	_playback.play_stream(stream, 0.0, volume_db, pitch)
