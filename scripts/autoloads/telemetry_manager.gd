## Telemetry Manager - collects per-run balancing statistics from beta testers
## and uploads them to Supabase (REST, anon key, INSERT-only RLS).
## Offline-first: payloads are written to user://telemetry/queue/ and drained
## sequentially; nothing is lost if the tester is offline.
## This is an Autoload - registered as "Telemetry" AFTER EventBus and Stats.
extends Node

const CONFIG_PATH = "res://telemetry.cfg"
const SETTINGS_PATH = "user://telemetry/settings.json"
const QUEUE_DIR = "user://telemetry/queue"
const DEAD_DIR = "user://telemetry/dead"
const MAX_QUEUE_FILES = 200
const MAX_ATTEMPTS = 3
const HTTP_TIMEOUT = 15.0

const CONSENT_TEXT = """Esta versão beta envia estatísticas anônimas de jogo (itens usados, pontuações) para ajudar no balanceamento. Nenhum dado pessoal é coletado.

This beta build sends anonymous gameplay statistics (items used, scores) to help balance the game. No personal data is collected."""

# --- Config / identity ---
var _enabled := false
var _supabase_url := ""
var _anon_key := ""
var _client_version := "dev"
var _player_id := ""
var _consent := false
var _consent_asked := false

# --- Per-run state ---
var _run_active := false
var _run_id := ""
var _run_seed := 0
var _run_started_iso := ""
var _run_started_msec := 0
var _current_level := 1
var _battle_started_msec := 0
var _rounds: Array = []       # {level, score, target, victory, duration_msec}
var _upgrades: Array = []     # {from, to}
var _items: Dictionary = {}   # "type:id" -> per-item counters
var _economy := {"earned": 0, "spent": 0, "final_money": 0, "spend_by_source": {}}
var _shop_connected := false

# --- Upload state ---
var _http: HTTPRequest = null
var _uploading := false
var _current_file := ""
var _retry_timer: Timer = null
var _session_failures := 0
var _closing := false
var _enqueue_counter := 0


func _ready() -> void:
	_load_config()
	if not _enabled:
		print("[Telemetry] Disabled (no config or turned off)")
		return

	DirAccess.make_dir_recursive_absolute(QUEUE_DIR)
	DirAccess.make_dir_recursive_absolute(DEAD_DIR)
	_load_settings()

	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.run_started.connect(_on_run_started)
		event_bus.run_ended.connect(_on_run_ended)
		event_bus.slot_read.connect(_on_slot_read)
		event_bus.relic_activated.connect(_on_relic_activated)
		event_bus.economy_transaction.connect(_on_economy_transaction)
		event_bus.item_acquired.connect(_on_item_acquired)
		event_bus.planning_action.connect(_on_planning_action)
		event_bus.battle_started.connect(_on_battle_started)
		event_bus.battle_ended.connect(_on_battle_ended)
		print("[Telemetry] enabled (v%s)" % _client_version)
	else:
		push_warning("[Telemetry] EventBus not found - telemetry inactive")
		_enabled = false
		return

	_http = HTTPRequest.new()
	_http.use_threads = true
	_http.timeout = HTTP_TIMEOUT
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)

	_retry_timer = Timer.new()
	_retry_timer.one_shot = true
	_retry_timer.timeout.connect(_drain_queue)
	add_child(_retry_timer)

	if not _consent_asked:
		_show_consent_dialog.call_deferred()
	elif _consent:
		_drain_queue.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _enabled:
		_closing = true
		# Persist an in-progress run to the disk queue only; it uploads next launch
		if _run_active and _rounds.size() > 0:
			_finalize_run("abandoned", _get_game_level())


# =============================================================================
# CONFIG / SETTINGS
# =============================================================================

func _load_config() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	_supabase_url = cfg.get_value("supabase", "url", "")
	_anon_key = cfg.get_value("supabase", "anon_key", "")
	var enabled = cfg.get_value("telemetry", "enabled", false)
	var allow_in_editor = cfg.get_value("telemetry", "allow_in_editor", false)
	_client_version = str(ProjectSettings.get_setting("application/config/version", "dev"))
	if OS.has_feature("editor") and not allow_in_editor:
		return
	_enabled = enabled and _supabase_url != "" and _anon_key != ""


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				_player_id = parsed.get("player_id", "")
				_consent = parsed.get("consent", false)
				_consent_asked = parsed.get("consent_asked", false)
	if _player_id == "":
		_player_id = _uuid_v4()
		_save_settings()


func _save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"player_id": _player_id,
			"consent": _consent,
			"consent_asked": _consent_asked,
		}, "\t"))
		file.close()


func _show_consent_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Estatísticas da Beta / Beta Statistics"
	dialog.dialog_text = CONSENT_TEXT
	dialog.ok_button_text = "Aceitar / Accept"
	dialog.cancel_button_text = "Recusar / Decline"
	dialog.dialog_autowrap = true
	dialog.min_size = Vector2i(520, 0)
	dialog.confirmed.connect(_on_consent_answered.bind(true))
	dialog.canceled.connect(_on_consent_answered.bind(false))
	get_tree().root.add_child(dialog)
	dialog.popup_centered()


func _on_consent_answered(accepted: bool) -> void:
	_consent = accepted
	_consent_asked = true
	_save_settings()
	print("[Telemetry] Consent: %s" % ("accepted" if accepted else "declined"))
	if _consent:
		_drain_queue()


## Options-menu hook: flip consent at any time
func set_consent(accepted: bool) -> void:
	_on_consent_answered(accepted)


func has_consent() -> bool:
	return _consent


# =============================================================================
# RUN LIFECYCLE
# =============================================================================

func _on_run_started(run_seed: int, level: int) -> void:
	# A run that never played a round is discarded silently (boot/restart double-fire)
	_run_active = true
	_run_id = _uuid_v4()
	_run_seed = run_seed
	_run_started_iso = Time.get_datetime_string_from_system(true)
	_run_started_msec = Time.get_ticks_msec()
	_current_level = level
	_rounds = []
	_upgrades = []
	_items = {}
	_economy = {"earned": 0, "spent": 0, "final_money": 0, "spend_by_source": {}}
	_connect_shop_stocked()


func _on_run_ended(victory: bool, final_level: int) -> void:
	if not _run_active:
		return
	_finalize_run("win" if victory else "loss", final_level)


func _finalize_run(outcome: String, final_level: int) -> void:
	_run_active = false
	if _rounds.is_empty() and _items.is_empty():
		return

	_mark_final_loadout()

	var best_round := 0
	var total := 0
	for round_entry in _rounds:
		total += round_entry["score"]
		if round_entry["score"] > best_round:
			best_round = round_entry["score"]

	# Postgres bigint/int columns reject JSON floats ("270.0"), and scores can arrive
	# as floats from the battle signals, so coerce every numeric column to int here.
	var run_row := {
		"run_id": _run_id,
		"player_id": _player_id,
		"client_version": _client_version,
		"seed": int(_run_seed),
		"outcome": outcome,
		"final_level": int(final_level),
		"rounds_played": _rounds.size(),
		"best_round_score": int(best_round),
		"total_score": int(total),
		"duration_msec": int(Time.get_ticks_msec() - _run_started_msec),
		"started_at": _run_started_iso,
		"ended_at": Time.get_datetime_string_from_system(true),
		"summary": {
			"rounds": _rounds,
			"economy": _economy,
			"upgrades": _upgrades,
			"final_loadout": _get_final_loadout_keys(),
			"final_grid": _get_final_grid(),
			"final_modifier_grid": _get_final_modifier_grid(),
			"curve": _get_curve(),
		},
	}

	var item_rows: Array = []
	for key in _items:
		var parts: PackedStringArray = key.split(":", true, 1)
		var entry: Dictionary = _items[key]
		item_rows.append({
			"run_id": _run_id,
			"player_id": _player_id,
			"client_version": _client_version,
			"item_type": parts[0],
			"item_id": parts[1],
			"times_offered": int(entry["offered"]),
			"times_bought": int(entry["bought"]),
			"times_acquired": int(entry["acquired"]),
			"times_sold": int(entry["sold"]),
			"times_upgraded_into": int(entry["upgraded_into"]),
			"activations": int(entry["activations"]),
			"score_contribution": int(entry["score"]),
			"in_final_loadout": entry["in_final_loadout"],
			"acquired_at_level": int(entry["acquired_at_level"]),
			"run_outcome": outcome,
			"run_final_level": int(final_level),
		})

	# runs before run_items so the dashboard rarely sees orphan items
	_enqueue("runs", run_row)
	if not item_rows.is_empty():
		_enqueue("run_items", item_rows)
	print("[Telemetry] Run finalized (%s, level %d, %d items)" % [outcome, final_level, item_rows.size()])


func _mark_final_loadout() -> void:
	var main_controller = get_tree().get_first_node_in_group("main_controller")
	if main_controller and main_controller.get("inventory_manager"):
		for rune in main_controller.inventory_manager.runes:
			if rune.data:
				_item_entry("rune", str(rune.data.id))["in_final_loadout"] = true

	var panel_manager = get_tree().get_first_node_in_group("panel_manager")
	if panel_manager and panel_manager.get("panels") != null:
		for panel in panel_manager.panels:
			if not panel.grid_manager:
				continue
			for slot in panel.grid_manager.grid:
				if slot.rune and slot.rune.data:
					_item_entry("rune", str(slot.rune.data.id))["in_final_loadout"] = true

	var extra = get_tree().get_first_node_in_group("extra_inventory")
	if extra:
		for relic in extra.relics:
			if relic.data:
				_item_entry("relic", str(relic.data.id))["in_final_loadout"] = true
		for modifier in extra.modifiers:
			_item_entry("slot_modifier", str(modifier.id))["in_final_loadout"] = true
		for piece in extra.slot_pieces:
			if piece.data:
				_item_entry("slot_piece", str(piece.data.id))["in_final_loadout"] = true


func _get_final_loadout_keys() -> Array:
	var keys: Array = []
	for key in _items:
		if _items[key]["in_final_loadout"]:
			keys.append(key)
	return keys


## Snapshot of each panel's 5x5 grid at run end: one array of 25 cells per panel,
## row-major (index = y*5 + x), each cell a rune id string or null for empty.
const _GRID_SIZE := 5

func _get_final_grid() -> Array:
	var panels_out: Array = []
	var panel_manager = get_tree().get_first_node_in_group("panel_manager")
	if panel_manager and panel_manager.get("panels") != null:
		for panel in panel_manager.panels:
			if not panel.grid_manager:
				continue
			var cells: Array = []
			cells.resize(_GRID_SIZE * _GRID_SIZE)
			cells.fill(null)
			for slot in panel.grid_manager.grid:
				if slot.rune and slot.rune.data:
					var idx: int = slot.grid_position.y * _GRID_SIZE + slot.grid_position.x
					if idx >= 0 and idx < cells.size():
						cells[idx] = str(slot.rune.data.id)
			panels_out.append(cells)
	return panels_out


## Parallel snapshot of the slot modifier applied at each grid position (same
## layout as _get_final_grid): one array of 25 cells per panel, modifier id or null.
func _get_final_modifier_grid() -> Array:
	var panels_out: Array = []
	var panel_manager = get_tree().get_first_node_in_group("panel_manager")
	if panel_manager and panel_manager.get("panels") != null:
		for panel in panel_manager.panels:
			if not panel.grid_manager:
				continue
			var cells: Array = []
			cells.resize(_GRID_SIZE * _GRID_SIZE)
			cells.fill(null)
			for slot in panel.grid_manager.grid:
				var mod_id := str(slot.slot.slot_modifier_id) if slot.slot else ""
				if mod_id != "":
					var idx: int = slot.grid_position.y * _GRID_SIZE + slot.grid_position.x
					if idx >= 0 and idx < cells.size():
						cells[idx] = mod_id
			panels_out.append(cells)
	return panels_out


## Effective target-score curve parameters, read live from GameManager (which
## already reflects any per-scene @export overrides). Lets the dashboard rebuild
## the exact curve per run/version instead of hardcoding a copy that drifts.
## Target(n) = base * (growth_initial + growth_acceleration*(level-1)) ^ (level-1)
func _get_curve() -> Dictionary:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		return {}
	return {
		"base": int(gm.base_target_score),
		"growth_initial": float(gm.score_growth_initial),
		"growth_acceleration": float(gm.score_growth_acceleration),
	}


# =============================================================================
# EVENT HANDLERS (aggregation)
# =============================================================================

func _item_entry(item_type: String, item_id: String) -> Dictionary:
	var key := "%s:%s" % [item_type, item_id]
	if key not in _items:
		_items[key] = {
			"offered": 0, "bought": 0, "acquired": 0, "sold": 0,
			"upgraded_into": 0, "activations": 0, "score": 0,
			"in_final_loadout": false,
			"acquired_at_level": -1,  # run level when first bought/acquired (-1 = never)
		}
	return _items[key]


## Stamp the acquisition level the first time an item is taken (buy or free pick)
func _stamp_acquired_level(entry: Dictionary) -> void:
	if entry["acquired_at_level"] < 0:
		entry["acquired_at_level"] = _get_game_level()


func _on_slot_read(event: SlotReadEvent) -> void:
	if not _run_active or event.was_empty or event.was_disabled:
		return
	var entry := _item_entry("rune", str(event.rune_id))
	entry["activations"] += event.activations_used
	entry["score"] += event.get_score_delta()


func _on_relic_activated(event: RelicActivatedEvent) -> void:
	if not _run_active:
		return
	_item_entry("relic", str(event.relic_id))["activations"] += 1


func _on_item_acquired(item_type: StringName, item_id: StringName) -> void:
	if not _run_active:
		return
	var entry := _item_entry(str(item_type), str(item_id))
	entry["acquired"] += 1
	_stamp_acquired_level(entry)


func _on_planning_action(event: PlanningEvent) -> void:
	if not _run_active:
		return
	if event.action_type == PlanningEvent.ActionType.UPGRADE_RUNE and event.upgraded_to != &"":
		_item_entry("rune", str(event.upgraded_to))["upgraded_into"] += 1
		var from_id := str(event.rune_ids[0]) if event.rune_ids.size() > 0 else ""
		_upgrades.append({"from": from_id, "to": str(event.upgraded_to)})


func _on_battle_started(_panel_count: int) -> void:
	_battle_started_msec = Time.get_ticks_msec()


## Live game level from the GameManager (single source of truth). battle_ended
## fires more than once per level (reader.gd per panel + panel_manager at the end),
## so counting signals double-counts levels — anchor on the real level instead.
func _get_game_level() -> int:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.get("current_level") != null:
		return int(gm.current_level)
	return _current_level


func _on_battle_ended(total_score: int, target_score: int, victory: bool) -> void:
	if not _run_active:
		return
	# One round per real level. The last write for a level (panel_manager's, after
	# all panels) carries the final multiplied score, so replace-in-place per level.
	var lv := _get_game_level()
	var entry := {
		"level": lv,
		"score": total_score,
		"target": target_score,
		"victory": victory,
		"duration_msec": Time.get_ticks_msec() - _battle_started_msec,
	}
	var replaced := false
	for i in _rounds.size():
		if _rounds[i]["level"] == lv:
			_rounds[i] = entry
			replaced = true
			break
	if not replaced:
		_rounds.append(entry)
	_current_level = lv


# Prefixes ride on ShopManager's _spend_money/_add_money source strings; a rename
# there silently breaks these counts, hence the warning on unknown purchase sources
const _BUY_PREFIXES := {
	"shop_rune_": "rune", "shop_piece_": "slot_piece",
	"shop_modifier_": "slot_modifier", "shop_relic_": "relic",
}
const _SELL_PREFIXES := {
	"sell_rune_": "rune", "sell_piece_": "slot_piece",
	"sell_modifier_": "slot_modifier", "sell_relic_": "relic",
}

func _on_economy_transaction(event: EconomyEvent) -> void:
	if not _run_active:
		return
	_economy["final_money"] = event.balance_after
	if event.amount > 0:
		_economy["earned"] += event.amount
	else:
		_economy["spent"] += abs(event.amount)
		var category := _spend_category(str(event.source))
		var by_source: Dictionary = _economy["spend_by_source"]
		by_source[category] = by_source.get(category, 0) + abs(event.amount)

	var source := str(event.source)
	if event.transaction_type == EconomyEvent.TransactionType.SHOP_PURCHASE:
		var matched := false
		for prefix in _BUY_PREFIXES:
			if source.begins_with(prefix):
				var bought_entry := _item_entry(_BUY_PREFIXES[prefix], source.substr(prefix.length()))
				bought_entry["bought"] += 1
				_stamp_acquired_level(bought_entry)
				matched = true
				break
		if not matched and not source.begins_with("scroll_") \
				and source not in ["overclock_machinery", "relic_reroll", "upgrade_rune", "panel_unlock", "pedestal_neutral"] \
				and not source.begins_with("pedestal_adjust_"):
			push_warning("[Telemetry] Unknown SHOP_PURCHASE source: %s" % source)
	elif event.transaction_type == EconomyEvent.TransactionType.SHOP_SELL:
		for prefix in _SELL_PREFIXES:
			if source.begins_with(prefix):
				_item_entry(_SELL_PREFIXES[prefix], source.substr(prefix.length()))["sold"] += 1
				break


func _spend_category(source: String) -> String:
	for prefix in _BUY_PREFIXES:
		if source.begins_with(prefix):
			return prefix.trim_suffix("_")
	if source.begins_with("scroll_"):
		return "scroll"
	if source.begins_with("pedestal_"):
		return "pedestal"
	match source:
		"overclock_machinery": return "overclock"
		"upgrade_rune": return "upgrade"
		"relic_reroll": return "relic_reroll"
		"panel_unlock": return "panel_unlock"
	return "other"


func _connect_shop_stocked() -> void:
	if _shop_connected:
		return
	var main_controller = get_tree().get_first_node_in_group("main_controller")
	if main_controller and main_controller.has_method("get_shop_manager"):
		var shop_manager = main_controller.get_shop_manager()
		if shop_manager and shop_manager.has_signal("shop_stocked"):
			shop_manager.shop_stocked.connect(_on_shop_stocked)
			_shop_connected = true


func _on_shop_stocked(offers: Array[Dictionary]) -> void:
	if not _run_active:
		return
	for offer in offers:
		_item_entry(offer["type"], offer["id"])["offered"] += 1


# =============================================================================
# OFFLINE QUEUE + UPLOAD
# =============================================================================

func _enqueue(endpoint: String, body: Variant) -> void:
	if not _consent:
		return
	_enqueue_counter += 1
	var path := "%s/%d_%03d_%s.json" % [
		QUEUE_DIR, Time.get_unix_time_from_system() * 1000.0, _enqueue_counter, endpoint
	]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[Telemetry] Failed to write queue file: %s" % FileAccess.get_open_error())
		return
	# Store the body already serialized: Godot's JSON.parse_string turns every JSON
	# number into a float, so re-stringifying a parsed body would resurrect "270.0"
	# and Postgres would reject it on bigint columns. Keeping it as an opaque string
	# means the drain never re-parses the numbers.
	file.store_string(JSON.stringify({"endpoint": endpoint, "body_json": JSON.stringify(body), "attempts": 0}))
	file.close()
	_trim_queue()
	if not _closing:
		_drain_queue()


func _trim_queue() -> void:
	var files := _queue_files()
	while files.size() > MAX_QUEUE_FILES:
		DirAccess.remove_absolute("%s/%s" % [QUEUE_DIR, files.pop_front()])


func _queue_files() -> Array:
	var files: Array = []
	var dir = DirAccess.open(QUEUE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	files.sort()
	return files


func _drain_queue() -> void:
	if _uploading or _closing or not _consent or not _enabled:
		return
	var files := _queue_files()
	if files.is_empty():
		return
	_current_file = "%s/%s" % [QUEUE_DIR, files[0]]

	var file = FileAccess.open(_current_file, FileAccess.READ)
	if not file:
		return
	var payload = JSON.parse_string(file.get_as_text())
	file.close()
	if payload == null or not payload is Dictionary:
		DirAccess.rename_absolute(_current_file, "%s/%s" % [DEAD_DIR, files[0]])
		_drain_queue()
		return

	var url := "%s/rest/v1/%s" % [_supabase_url.trim_suffix("/"), payload["endpoint"]]
	var headers := [
		"apikey: %s" % _anon_key,
		"Authorization: Bearer %s" % _anon_key,
		"Content-Type: application/json",
		"Prefer: return=minimal",
	]
	# body_json is a pre-serialized string (numbers already correct). Old queue files
	# stored the object under "body" instead; re-stringify those as a fallback.
	var body_str: String = payload.get("body_json", "")
	if body_str == "":
		body_str = JSON.stringify(payload.get("body", {}))
	_uploading = true
	print("[Telemetry] POST %s -> %s" % [payload["endpoint"], _current_file.get_file()])
	var err = _http.request(url, headers, HTTPClient.METHOD_POST, body_str)
	if err != OK:
		push_warning("[Telemetry] HTTPRequest failed to start (err %d)" % err)
		_uploading = false
		_schedule_retry()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_uploading = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("[Telemetry] Uploaded %s (HTTP %d)" % [_current_file.get_file(), response_code])
		DirAccess.remove_absolute(_current_file)
		_session_failures = 0
		_drain_queue()
		return

	if response_code >= 400 and response_code < 500:
		# Client-side problem (schema mismatch, bad key): don't retry forever
		var attempts := _bump_attempts(_current_file)
		# print() so it shows in the Output panel (push_warning only hits Debugger>Errors)
		var msg := "[Telemetry] Upload REJECTED (HTTP %d, attempt %d): %s" % [
			response_code, attempts, body.get_string_from_utf8().left(300)
		]
		print(msg)
		push_warning(msg)
		if attempts >= MAX_ATTEMPTS:
			print("[Telemetry] Giving up on %s -> dead/" % _current_file.get_file())
			DirAccess.rename_absolute(_current_file, "%s/%s" % [DEAD_DIR, _current_file.get_file()])
			_drain_queue()
			return
	else:
		print("[Telemetry] Upload failed (result %d, HTTP %d) — will retry" % [result, response_code])

	_schedule_retry()


func _bump_attempts(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return MAX_ATTEMPTS
	var payload = JSON.parse_string(file.get_as_text())
	file.close()
	if not payload is Dictionary:
		return MAX_ATTEMPTS
	payload["attempts"] = int(payload.get("attempts", 0)) + 1
	file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))
		file.close()
	return payload["attempts"]


func _schedule_retry() -> void:
	_session_failures += 1
	var delay: float = minf(pow(2.0, _session_failures) * 10.0, 600.0)
	_retry_timer.start(delay)


# =============================================================================
# HELPERS
# =============================================================================

static func _uuid_v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
		hex.substr(16, 4), hex.substr(20, 12)
	]
