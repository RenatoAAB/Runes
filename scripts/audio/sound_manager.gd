extends Node

## Central audio coordinator (Autoload).
## Listens to EventBus/GameManager/ShopManager signals and dispatches audio
## to its child players: RunicSymphony, SFXPlayer, AmbientPlayer.
## Supports two battle audio modes: SYMPHONY and BATTLE_TRACK.

enum BattleAudioMode {
	SYMPHONY,      ## Runic symphony IS the battle music (elemental chords)
	BATTLE_TRACK   ## Dedicated battle music + simple ticks per rune
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var element_bank: ElementSoundBank
@export var sfx_bank: SFXBank
@export var ambient_config: AmbientConfig
@export var reading_pace: ReadingPaceConfig

@export_group("Volume")
@export var master_volume: float = 1.0
@export var music_volume: float = 1.0
@export var sfx_volume: float = 1.0

@export_group("Toggles")
@export var symphony_enabled: bool = true
@export var sfx_enabled: bool = true
@export var ambient_enabled: bool = true
@export var battle_audio_mode: BattleAudioMode = BattleAudioMode.SYMPHONY

# ---------------------------------------------------------------------------
# Child players (created at runtime)
# ---------------------------------------------------------------------------
var runic_symphony: RunicSymphony
var sfx_player: SFXPlayer
var ambient_player: AmbientPlayer

# ---------------------------------------------------------------------------
# Cached references
# ---------------------------------------------------------------------------
var _event_bus: Node
var _game_manager: Node
var _panel_manager: Node
var _shop_manager: Node

## Currently connected Reader instance (changes per-panel)
var _connected_reader: Reader


func _ready() -> void:
	# Try to load default resources if none assigned
	if not element_bank:
		element_bank = load("res://resources/audio/element_bank_default.tres") as ElementSoundBank
	if not sfx_bank:
		sfx_bank = load("res://resources/audio/sfx_bank_default.tres") as SFXBank
	if not ambient_config:
		ambient_config = load("res://resources/audio/ambient_config_default.tres") as AmbientConfig
	if not reading_pace:
		reading_pace = load("res://resources/audio/reading_pace_default.tres") as ReadingPaceConfig

	_create_child_players()
	_load_volume_settings()
	# Defer signal connections so all autoloads/managers are ready
	call_deferred("_connect_signals")
	# Apply initial volumes
	_apply_bus_volumes()


## Switches between SYMPHONY and BATTLE_TRACK mode at runtime.
func set_battle_audio_mode(mode: BattleAudioMode) -> void:
	battle_audio_mode = mode


# ---------------------------------------------------------------------------
# Internal setup
# ---------------------------------------------------------------------------

func _create_child_players() -> void:
	# Runic Symphony
	runic_symphony = RunicSymphony.new()
	runic_symphony.name = "RunicSymphony"
	runic_symphony.element_bank = element_bank
	runic_symphony.reading_pace = reading_pace
	add_child(runic_symphony)

	# SFX Player
	sfx_player = SFXPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)

	# Ambient Player
	ambient_player = AmbientPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.ambient_config = ambient_config
	add_child(ambient_player)


func _connect_signals() -> void:
	# EventBus
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus:
		_safe_connect(_event_bus, "battle_started", _on_battle_started)
		_safe_connect(_event_bus, "battle_ended", _on_battle_ended)
		_safe_connect(_event_bus, "rune_destroyed", _on_rune_destroyed)
		_safe_connect(_event_bus, "rune_created", _on_rune_created)
		_safe_connect(_event_bus, "relic_activated", _on_relic_activated)
		_safe_connect(_event_bus, "infinite_loop_detected", _on_infinite_loop)
		_safe_connect(_event_bus, "slot_read", _on_slot_read)
		_safe_connect(_event_bus, "drag_started", _on_drag_started)
		_safe_connect(_event_bus, "drag_ended", _on_drag_ended)

	# GameManager (may not exist immediately; retry once after a short delay)
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	if _game_manager:
		_safe_connect(_game_manager, "phase_changed", _on_phase_changed)

	# PanelManager
	_panel_manager = get_tree().get_first_node_in_group("panel_manager")
	if _panel_manager:
		_safe_connect(_panel_manager, "panel_switched", _on_panel_switched)
		_safe_connect(_panel_manager, "panel_battle_started", _on_panel_battle_started)

	# ShopManager
	_shop_manager = _find_node_by_class("ShopManager")
	if _shop_manager:
		_safe_connect(_shop_manager, "transaction_completed", _on_transaction_completed)
		_safe_connect(_shop_manager, "insufficient_funds", _on_insufficient_funds)

	# If managers weren't found yet, try again next frame (scene may still be loading)
	if not _game_manager or not _panel_manager:
		get_tree().process_frame.connect(_retry_connect, CONNECT_ONE_SHOT)


func _retry_connect() -> void:
	if not _game_manager:
		_game_manager = get_tree().get_first_node_in_group("game_manager")
		if _game_manager:
			_safe_connect(_game_manager, "phase_changed", _on_phase_changed)

	if not _panel_manager:
		_panel_manager = get_tree().get_first_node_in_group("panel_manager")
		if _panel_manager:
			_safe_connect(_panel_manager, "panel_switched", _on_panel_switched)
			_safe_connect(_panel_manager, "panel_battle_started", _on_panel_battle_started)

	if not _shop_manager:
		_shop_manager = _find_node_by_class("ShopManager")
		if _shop_manager:
			_safe_connect(_shop_manager, "transaction_completed", _on_transaction_completed)
			_safe_connect(_shop_manager, "insufficient_funds", _on_insufficient_funds)


func _find_node_by_class(class_name_str: String) -> Node:
	# Walk the tree looking for the named node added as child of MainController
	var main = get_tree().get_first_node_in_group("main_controller")
	if main:
		for child in main.get_children():
			if child.name == class_name_str:
				return child
	return null


func _safe_connect(source: Object, signal_name: StringName, callable: Callable) -> void:
	if source.has_signal(signal_name) and not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)


## Bind to the Reader from the currently active panel.
func _bind_reader(panel: Object) -> void:
	# Disconnect old reader
	if _connected_reader:
		if _connected_reader.step_started.is_connected(_on_step_started):
			_connected_reader.step_started.disconnect(_on_step_started)
		if _connected_reader.step_completed.is_connected(_on_step_completed):
			_connected_reader.step_completed.disconnect(_on_step_completed)
		_connected_reader = null

	if panel == null:
		return

	var reader_ref = panel.get("reader") as Reader
	if reader_ref:
		_connected_reader = reader_ref
		_connected_reader.step_started.connect(_on_step_started)
		_connected_reader.step_completed.connect(_on_step_completed)


func _get_active_grid_manager() -> GridManager:
	if _connected_reader and _connected_reader.grid_manager:
		return _connected_reader.grid_manager
	if _panel_manager and _panel_manager.has_method("get_active_panel"):
		var panel = _panel_manager.get_active_panel()
		if panel:
			return panel.grid_manager
	return null


# ---------------------------------------------------------------------------
# Volume helpers
# ---------------------------------------------------------------------------

func _apply_bus_volumes() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func set_master_volume(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	_set_bus_volume("Master", master_volume)
	_save_volume_settings()


func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)
	_set_bus_volume("Music", music_volume)
	_save_volume_settings()


func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)
	_set_bus_volume("SFX", sfx_volume)
	_save_volume_settings()


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if linear <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


# ===========================================================================
# Signal handlers — Reader step events (connected per-panel)
# ===========================================================================

func _on_step_started(coord: Vector2i) -> void:
	var gm = _get_active_grid_manager()
	if not gm:
		return

	var slot = gm.get_slot(coord)
	if not slot:
		return

	# Empty slot handling
	if slot.is_empty():
		if sfx_bank and sfx_bank.play_empty_slot_sound and sfx_bank.empty_slot_tick:
			_play_sfx(sfx_bank.empty_slot_tick)
		return

	var rune: RuneInstance = slot.rune
	if not rune:
		return

	var activation_count: int = 0
	if _connected_reader:
		activation_count = _connected_reader._activation_count

	match battle_audio_mode:
		BattleAudioMode.SYMPHONY:
			if symphony_enabled and runic_symphony:
				runic_symphony.play_rune_sound(rune, activation_count)
		BattleAudioMode.BATTLE_TRACK:
			if sfx_bank and sfx_bank.rune_beat_tick:
				_play_sfx(sfx_bank.rune_beat_tick)


func _on_step_completed(_coord: Vector2i) -> void:
	if battle_audio_mode == BattleAudioMode.SYMPHONY and runic_symphony:
		runic_symphony.stop_current_sound()


# ===========================================================================
# Signal handlers — EventBus
# ===========================================================================

func _on_battle_started(_panel_count: int) -> void:
	# Bind to the reader of the active panel
	if _panel_manager and _panel_manager.has_method("get_active_panel"):
		_bind_reader(_panel_manager.get_active_panel())

	if sfx_enabled and sfx_bank and sfx_bank.battle_start:
		_play_sfx(sfx_bank.battle_start)

	match battle_audio_mode:
		BattleAudioMode.SYMPHONY:
			if ambient_player and ambient_config:
				ambient_player.attenuate(ambient_config.battle_attenuation_db)
		BattleAudioMode.BATTLE_TRACK:
			if ambient_player and ambient_config:
				ambient_player.attenuate(ambient_config.battle_attenuation_db)
				if ambient_config.battle_track:
					ambient_player.play_track(ambient_config.battle_track)


func _on_battle_ended(total_score: int, target_score: int, victory: bool) -> void:
	# Stop ongoing symphony sounds
	if runic_symphony:
		runic_symphony.stop_current_sound()

	# Disconnect current reader
	_bind_reader(null)

	# Stop battle track if playing
	if battle_audio_mode == BattleAudioMode.BATTLE_TRACK and ambient_player:
		ambient_player.stop_track()

	# Play victory/defeat sting
	if sfx_enabled:
		if victory and ambient_config and ambient_config.victory_sting:
			_play_sfx(ambient_config.victory_sting)
		elif not victory and ambient_config and ambient_config.defeat_sting:
			_play_sfx(ambient_config.defeat_sting)

	# Restore ambient volume
	if ambient_player:
		ambient_player.restore_volume()


func _on_rune_destroyed(_slot, _rune) -> void:
	if sfx_enabled and sfx_bank and sfx_bank.rune_destroy:
		_play_sfx(sfx_bank.rune_destroy)


func _on_rune_created(_slot, _rune) -> void:
	if sfx_enabled and sfx_bank and sfx_bank.rune_create:
		_play_sfx(sfx_bank.rune_create)


func _on_relic_activated(_event) -> void:
	if sfx_enabled and sfx_bank and sfx_bank.relic_activate:
		_play_sfx(sfx_bank.relic_activate)


func _on_infinite_loop(_event) -> void:
	if sfx_enabled and sfx_bank and sfx_bank.infinite_loop:
		_play_sfx(sfx_bank.infinite_loop)


func _on_slot_read(event) -> void:
	# Score pop with dynamic pitch
	if not sfx_enabled or not sfx_bank or not sfx_bank.score_pop:
		return
	if event and not event.was_empty and not event.was_disabled:
		var score_delta: int = event.score_after - event.score_before
		if score_delta > 0:
			# Pitch proportional to score delta (subtle variation)
			var pitch := clampf(1.0 + float(score_delta) / 200.0, 0.8, 1.6)
			_play_sfx(sfx_bank.score_pop, 0.0, pitch)


func _on_drag_started() -> void:
	if sfx_enabled and sfx_bank and sfx_bank.drag_start:
		_play_sfx(sfx_bank.drag_start)


func _on_drag_ended(success: bool) -> void:
	if not sfx_enabled or not sfx_bank:
		return
	if success and sfx_bank.drop_success:
		_play_sfx(sfx_bank.drop_success)
	elif not success and sfx_bank.drop_fail:
		_play_sfx(sfx_bank.drop_fail)


# ===========================================================================
# Signal handlers — GameManager
# ===========================================================================

func _on_phase_changed(new_phase) -> void:
	if not ambient_enabled or not ambient_player:
		return
	match new_phase:
		GameEnums.GamePhase.PLANNING:
			if ambient_config and ambient_config.planning_track:
				ambient_player.crossfade_to(ambient_config.planning_track)
		GameEnums.GamePhase.REWARD, GameEnums.GamePhase.UPGRADE:
			if ambient_config and ambient_config.shop_track:
				ambient_player.crossfade_to(ambient_config.shop_track)
			elif ambient_config and ambient_config.planning_track:
				ambient_player.crossfade_to(ambient_config.planning_track)

	# Phase transition SFX
	if sfx_enabled and sfx_bank and sfx_bank.phase_transition:
		_play_sfx(sfx_bank.phase_transition)


# ===========================================================================
# Signal handlers — PanelManager
# ===========================================================================

func _on_panel_switched(_from_index: int, _to_index: int) -> void:
	# Re-bind reader to the newly active panel
	if _panel_manager and _panel_manager.has_method("get_active_panel"):
		_bind_reader(_panel_manager.get_active_panel())


func _on_panel_battle_started(panel_index: int) -> void:
	if _panel_manager and _panel_manager.has_method("get_panel"):
		var panel = _panel_manager.get_panel(panel_index)
		_bind_reader(panel)


# ===========================================================================
# Signal handlers — ShopManager
# ===========================================================================

func _on_transaction_completed(success: bool, _message: String) -> void:
	if not sfx_enabled or not sfx_bank:
		return
	if success and sfx_bank.purchase_success:
		_play_sfx(sfx_bank.purchase_success)


func _on_insufficient_funds(_cost: int, _balance: int) -> void:
	if sfx_enabled and sfx_bank and sfx_bank.purchase_fail:
		_play_sfx(sfx_bank.purchase_fail)


# ===========================================================================
# Convenience
# ===========================================================================

func _play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if sfx_player:
		sfx_player.play_sfx(stream, volume_db, pitch)


# ===========================================================================
# Volume persistence
# ===========================================================================

const SETTINGS_PATH := "user://settings.cfg"

func _save_volume_settings() -> void:
	var cfg := ConfigFile.new()
	# Load existing file first to preserve other sections
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "battle_audio_mode", battle_audio_mode)
	cfg.save(SETTINGS_PATH)


func _load_volume_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	var saved_mode = cfg.get_value("audio", "battle_audio_mode", battle_audio_mode)
	if saved_mode is int:
		battle_audio_mode = saved_mode as BattleAudioMode
