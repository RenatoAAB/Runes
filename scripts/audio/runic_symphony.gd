class_name RunicSymphony
extends Node

## Polyphonic player for the Runic Symphony system (SYMPHONY battle mode).
## Plays elemental chords during the reader's step sequence.
## Supports test-mode generated sine waves when no real samples are available.

var element_bank: ElementSoundBank
var reading_pace: ReadingPaceConfig

## Internal AudioStreamPlayer with Polyphonic stream
var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic

## Active playback stream IDs for the current step (so we can stop them)
var _active_ids: Array[int] = []

## How many activations are currently stacked on top of the first one this step
var _layered_groups: int = 0

## Cache of generated test AudioStreams keyed by element enum value
var _generated_cache: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 32
	_player.stream = poly
	add_child(_player)
	_player.play()
	# The playback is available once playing
	_playback = _player.get_stream_playback() as AudioStreamPlaybackPolyphonic


## Plays the sound(s) for a rune — either a custom sound or an elemental chord.
## When layer is true the notes stack over whatever is already sounding instead of
## cutting it, so chained/simultaneous activations build a chord.
func play_rune_sound(rune: RuneInstance, activation_count: int, layer: bool = false) -> void:
	if not _playback or not element_bank:
		return

	if layer:
		_layered_groups += 1
	else:
		stop_current_sound()

	var pitch: float = element_bank.calculate_pitch(activation_count)
	# Each stacked activation ducks a bit further to avoid clipping the bus
	var layer_db: float = element_bank.chord_attenuation_per_note_db * _layered_groups

	# --- Custom sound override ---
	if rune.data.custom_sound:
		var id = _playback.play_stream(rune.data.custom_sound, 0.0, element_bank.base_volume_db + layer_db, pitch)
		if id >= 0:
			_active_ids.append(id)
		return

	# --- Elemental chord ---
	var elements: Array[GameEnums.Element] = rune.get_elements()
	var note_count := elements.size()
	if note_count == 0:
		return

	var volume_db: float = element_bank.base_volume_db + layer_db
	if note_count > 1:
		volume_db += element_bank.chord_attenuation_per_note_db * (note_count - 1)

	for element in elements:
		var stream: AudioStream = _get_stream_for_element(element)
		if stream:
			var id = _playback.play_stream(stream, 0.0, volume_db, pitch)
			if id >= 0:
				_active_ids.append(id)


## Stops all notes that are currently sounding.
func stop_current_sound() -> void:
	if not _playback:
		return
	for id in _active_ids:
		if _playback.is_stream_playing(id):
			_playback.stop_stream(id)
	_active_ids.clear()
	_layered_groups = 0


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Returns the AudioStream for a given element, using real samples or generated tones.
func _get_stream_for_element(element: GameEnums.Element) -> AudioStream:
	if element_bank.use_generated_notes:
		return _get_or_generate_tone(element)
	return element_bank.get_sound_for_element(element)


## Lazily generates and caches a sine-wave tone for an element (test mode).
func _get_or_generate_tone(element: GameEnums.Element) -> AudioStream:
	if _generated_cache.has(element):
		return _generated_cache[element]

	var freq: float = element_bank.get_generated_frequency(element)
	var tone := _generate_sine_wav(freq, 2.0)  # 2 seconds, will be cut by stop_current_sound
	_generated_cache[element] = tone
	return tone


## Generates an AudioStreamWAV containing a sine wave at the given frequency.
func _generate_sine_wav(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit = 2 bytes per sample

	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var value := sin(TAU * frequency * t)
		# Apply short fade-in (20ms) and fade-out (50ms) to avoid clicks
		var env := 1.0
		var fade_in_samples := int(0.02 * sample_rate)
		var fade_out_samples := int(0.05 * sample_rate)
		if i < fade_in_samples:
			env = float(i) / float(fade_in_samples)
		elif i > num_samples - fade_out_samples:
			env = float(num_samples - i) / float(fade_out_samples)
		value *= env * 0.5  # 0.5 amplitude to avoid clipping
		var sample_int := clampi(int(value * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	return wav
