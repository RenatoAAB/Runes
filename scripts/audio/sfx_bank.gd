class_name SFXBank
extends Resource

## Maps gameplay events to sound-effect AudioStreams.

@export_group("Shop")
@export var purchase_success: AudioStream
@export var purchase_fail: AudioStream
@export var sell_item: AudioStream
@export var reroll: AudioStream

@export_group("Drag & Drop")
@export var drag_start: AudioStream
@export var drop_success: AudioStream
@export var drop_fail: AudioStream

@export_group("Battle")
@export var battle_start: AudioStream
@export var battle_victory: AudioStream
@export var battle_defeat: AudioStream
@export var rune_destroy: AudioStream
@export var rune_create: AudioStream
@export var empty_slot_tick: AudioStream   ## Subtle tick when reader passes an empty slot
@export var inert_rune_tick: AudioStream    ## Subtle tick when reader passes a rune that cannot activate
@export var rune_beat_tick: AudioStream     ## Simple beat per rune (BATTLE_TRACK mode)
@export var relic_activate: AudioStream
@export var score_pop: AudioStream
@export var infinite_loop: AudioStream

@export_group("UI")
@export var button_click: AudioStream
@export var phase_transition: AudioStream
@export var level_up: AudioStream

@export_group("Empty Slot")
## If true, plays empty_slot_tick when reader passes through an empty slot
@export var play_empty_slot_sound: bool = true
## If true, plays inert_rune_tick when the reader passes a rune that does not activate
## (0 activations left, disabled or skipped by residue). Off by default: no activation, no sound.
@export var play_inert_rune_sound: bool = false


## Generic lookup by event name for extensibility.
func get_sfx(event_name: StringName) -> AudioStream:
	match event_name:
		&"purchase_success": return purchase_success
		&"purchase_fail": return purchase_fail
		&"sell_item": return sell_item
		&"reroll": return reroll
		&"drag_start": return drag_start
		&"drop_success": return drop_success
		&"drop_fail": return drop_fail
		&"battle_start": return battle_start
		&"battle_victory": return battle_victory
		&"battle_defeat": return battle_defeat
		&"rune_destroy": return rune_destroy
		&"rune_create": return rune_create
		&"empty_slot_tick": return empty_slot_tick
		&"inert_rune_tick": return inert_rune_tick
		&"rune_beat_tick": return rune_beat_tick
		&"relic_activate": return relic_activate
		&"score_pop": return score_pop
		&"infinite_loop": return infinite_loop
		&"button_click": return button_click
		&"phase_transition": return phase_transition
		&"level_up": return level_up
	return null
