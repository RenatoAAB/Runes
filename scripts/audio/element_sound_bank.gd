class_name ElementSoundBank
extends Resource

## Maps elements to audio samples and controls pitch/volume for the Runic Symphony.
## When use_generated_notes is true, programmatic sine waves replace real samples.

@export_group("Element Samples")
@export var fire_sound: AudioStream
@export var water_sound: AudioStream
@export var earth_sound: AudioStream
@export var air_sound: AudioStream
@export var spirit_sound: AudioStream

@export_group("Pitch")
## Pitch base (1.0 = original)
@export var base_pitch: float = 1.0
## How much pitch rises per activation (ascending combo feel)
@export var pitch_increment_per_activation: float = 0.02
## Maximum allowed pitch
@export var max_pitch: float = 2.0
## Pitch curve type: "linear", "logarithmic", "exponential"
@export var pitch_curve_type: String = "linear"
## Enable/disable ascending pitch
@export var pitch_scaling_enabled: bool = true

@export_group("Volume")
## Base volume in dB
@export var base_volume_db: float = 0.0
## Per-note attenuation for chords (avoids clipping on multi-element runes)
@export var chord_attenuation_per_note_db: float = -3.0

@export_group("Test Mode")
## Generate sine-wave notes programmatically instead of using samples
@export var use_generated_notes: bool = false
## Frequencies for generated notes (pentatonic: C4, D4, E4, G4, A4)
@export var generated_frequencies: Dictionary = {
	"FIRE": 261.63,
	"WATER": 293.66,
	"EARTH": 329.63,
	"AIR": 392.00,
	"SPIRIT": 440.00
}


## Returns the AudioStream for a single element.
func get_sound_for_element(element: GameEnums.Element) -> AudioStream:
	match element:
		GameEnums.Element.FIRE:
			return fire_sound
		GameEnums.Element.WATER:
			return water_sound
		GameEnums.Element.EARTH:
			return earth_sound
		GameEnums.Element.AIR:
			return air_sound
		GameEnums.Element.SPIRIT:
			return spirit_sound
	return null


## Returns an array of AudioStreams for all given elements (for chords).
func get_sounds_for_elements(elements: Array[GameEnums.Element]) -> Array[AudioStream]:
	var sounds: Array[AudioStream] = []
	for element in elements:
		var s = get_sound_for_element(element)
		if s:
			sounds.append(s)
	return sounds


## Calculates the pitch scale for a given activation count.
func calculate_pitch(activation_count: int) -> float:
	if not pitch_scaling_enabled:
		return base_pitch

	var x := float(activation_count)
	var pitch: float = base_pitch

	match pitch_curve_type:
		"linear":
			pitch = base_pitch + pitch_increment_per_activation * x
		"logarithmic":
			pitch = base_pitch + pitch_increment_per_activation * log(1.0 + x)
		"exponential":
			pitch = base_pitch * exp(pitch_increment_per_activation * x)
		_:
			pitch = base_pitch + pitch_increment_per_activation * x

	return minf(pitch, max_pitch)


## Returns the element name string for frequency lookup.
static func _element_to_key(element: GameEnums.Element) -> String:
	match element:
		GameEnums.Element.FIRE: return "FIRE"
		GameEnums.Element.WATER: return "WATER"
		GameEnums.Element.EARTH: return "EARTH"
		GameEnums.Element.AIR: return "AIR"
		GameEnums.Element.SPIRIT: return "SPIRIT"
	return "FIRE"


## Returns the generated frequency for an element (test mode).
func get_generated_frequency(element: GameEnums.Element) -> float:
	var key = _element_to_key(element)
	if generated_frequencies.has(key):
		return generated_frequencies[key]
	return 440.0
