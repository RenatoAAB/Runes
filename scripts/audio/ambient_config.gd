class_name AmbientConfig
extends Resource

## Configuration for ambient/background music per game phase.

@export var planning_track: AudioStream
@export var shop_track: AudioStream
@export var battle_track: AudioStream       ## Execution music (BATTLE_TRACK mode only)
@export var victory_sting: AudioStream
@export var defeat_sting: AudioStream

@export_group("Transitions")
@export var fade_in_duration: float = 1.0
@export var fade_out_duration: float = 0.5
@export var crossfade: bool = true
## How much to attenuate the ambient during battle in SYMPHONY mode (dB)
@export var battle_attenuation_db: float = -40.0
