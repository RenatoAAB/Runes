## Statistics Manager - Tracks all game statistics across three levels.
## Listens to EventBus and aggregates data for analytics and conditions.
## Persists history to JSON file.
## This is an Autoload - add to Project Settings > Autoload as "Stats".
extends Node

const SAVE_PATH = "user://statistics.json"

# =============================================================================
# BATTLE STATISTICS (Reset each battle sequence)
# =============================================================================

var battle: Dictionary = {}

func _reset_battle_stats() -> void:
	battle = {
		"started_at": Time.get_ticks_msec(),
		"ended_at": 0,
		"duration_msec": 0,
		"events": [],
		"score_by_rune": {},        # rune_id -> total_score
		"activations_by_rune": {},  # rune_id -> count
		"activations_by_element": {},# Element -> count
		"empty_slots_read": 0,
		"disabled_runes": 0,
		"total_score": 0,
		"highest_single_activation": 0,
		"panels_completed": 0,
	}


# =============================================================================
# RUN STATISTICS (Reset each new run/game)
# =============================================================================

var run: Dictionary = {}

func _reset_run_stats() -> void:
	run = {
		"started_at": Time.get_datetime_string_from_system(),
		"rounds_played": 0,
		"rounds_won": 0,
		"current_level": 1,
		"highest_level": 1,
		"total_score": 0,
		"highest_round_score": 0,
		"money": 0,
		"money_earned": 0,
		"money_spent": 0,
		"runes_acquired": [],       # Array of rune_ids
		"runes_destroyed": [],      # Array of rune_ids
		"runes_upgraded": [],       # Array of {from, to}
		"planning_actions": 0,
		"lifetime_rune_stats": {},  # rune_id -> {activations, score}
	}


# =============================================================================
# HISTORY STATISTICS (Persisted across sessions)
# =============================================================================

var history: Dictionary = {}

func _init_history_stats() -> void:
	history = {
		"version": 1,
		"first_played": Time.get_datetime_string_from_system(),
		"last_played": Time.get_datetime_string_from_system(),
		"runs_completed": 0,
		"runs_won": 0,
		"best_score": 0,
		"best_level": 0,
		"total_playtime_msec": 0,
		"total_rounds_played": 0,
		"total_runes_activated": 0,
		"total_score_all_time": 0,
		"rune_usage": {},           # rune_id -> {times_used, total_score}
		"achievements": {},         # achievement_id -> {unlocked, date}
	}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_reset_battle_stats()
	_reset_run_stats()
	load_history()
	
	# Connect to EventBus if available
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.slot_read.connect(_on_slot_read)
		event_bus.panel_completed.connect(_on_panel_completed)
		event_bus.planning_action.connect(_on_planning_action)
		event_bus.economy_transaction.connect(_on_economy_transaction)
		event_bus.battle_started.connect(_on_battle_started)
		event_bus.battle_ended.connect(_on_battle_ended)
		print("[Stats] Connected to EventBus")
	else:
		push_warning("[Stats] EventBus not found - statistics will not be tracked")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_history()


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_battle_started(_panel_count: int) -> void:
	_reset_battle_stats()


func _on_battle_ended(total_score: int, target_score: int, victory: bool) -> void:
	battle["ended_at"] = Time.get_ticks_msec()
	battle["duration_msec"] = battle["ended_at"] - battle["started_at"]
	battle["total_score"] = total_score
	
	# Update run stats
	run["rounds_played"] += 1
	run["total_score"] += total_score
	if total_score > run["highest_round_score"]:
		run["highest_round_score"] = total_score
	
	if victory:
		run["rounds_won"] += 1
		run["current_level"] += 1
		if run["current_level"] > run["highest_level"]:
			run["highest_level"] = run["current_level"]
	
	# Merge rune stats to run lifetime
	for rune_id in battle["score_by_rune"]:
		if rune_id not in run["lifetime_rune_stats"]:
			run["lifetime_rune_stats"][rune_id] = {"activations": 0, "score": 0}
		run["lifetime_rune_stats"][rune_id]["score"] += battle["score_by_rune"][rune_id]
	
	for rune_id in battle["activations_by_rune"]:
		if rune_id not in run["lifetime_rune_stats"]:
			run["lifetime_rune_stats"][rune_id] = {"activations": 0, "score": 0}
		run["lifetime_rune_stats"][rune_id]["activations"] += battle["activations_by_rune"][rune_id]
	
	# Update history
	history["total_rounds_played"] += 1
	history["total_score_all_time"] += total_score
	if total_score > history["best_score"]:
		history["best_score"] = total_score
	
	# Auto-save periodically
	if run["rounds_played"] % 5 == 0:
		save_history()


func _on_slot_read(event: SlotReadEvent) -> void:
	battle["events"].append(event.to_dict())
	
	if event.was_empty:
		battle["empty_slots_read"] += 1
		return
	
	if event.was_disabled:
		battle["disabled_runes"] += 1
		return
	
	var rune_id = str(event.rune_id)
	var score_delta = event.get_score_delta()
	
	# Track score by rune
	if rune_id not in battle["score_by_rune"]:
		battle["score_by_rune"][rune_id] = 0
	battle["score_by_rune"][rune_id] += score_delta
	
	# Track activations by rune
	if rune_id not in battle["activations_by_rune"]:
		battle["activations_by_rune"][rune_id] = 0
	battle["activations_by_rune"][rune_id] += event.activations_used
	
	# Track activations by element (each base element present on the rune)
	var elements: Array[GameEnums.Element] = GameEnums.normalize_elements(event.rune_elements)
	for elem in elements:
		var element_key = GameEnums.Element.keys()[elem]
		if element_key not in battle["activations_by_element"]:
			battle["activations_by_element"][element_key] = 0
		battle["activations_by_element"][element_key] += event.activations_used
	
	# Track highest single activation
	if score_delta > battle["highest_single_activation"]:
		battle["highest_single_activation"] = score_delta
	
	# Update history rune usage
	if rune_id not in history["rune_usage"]:
		history["rune_usage"][rune_id] = {"times_used": 0, "total_score": 0}
	history["rune_usage"][rune_id]["times_used"] += 1
	history["rune_usage"][rune_id]["total_score"] += score_delta
	history["total_runes_activated"] += 1


func _on_panel_completed(event: PanelCompleteEvent) -> void:
	battle["panels_completed"] += 1
	# Panel-specific stats could be tracked here


func _on_planning_action(event: PlanningEvent) -> void:
	run["planning_actions"] += 1
	
	match event.action_type:
		PlanningEvent.ActionType.UPGRADE_RUNE:
			run["runes_upgraded"].append({
				"from": str(event.rune_ids[0]) if event.rune_ids.size() > 0 else "",
				"to": str(event.upgraded_to)
			})


func _on_economy_transaction(event: EconomyEvent) -> void:
	run["money"] = event.balance_after
	
	if event.amount > 0:
		run["money_earned"] += event.amount
	else:
		run["money_spent"] += abs(event.amount)


# =============================================================================
# RUN MANAGEMENT
# =============================================================================

## Call when starting a new run/game
func start_new_run() -> void:
	# Finalize previous run if any
	if run["rounds_played"] > 0:
		_finalize_run(false)
	
	_reset_run_stats()
	_reset_battle_stats()


## Call when a run ends (win or loss)
func end_run(victory: bool) -> void:
	_finalize_run(victory)
	save_history()


func _finalize_run(victory: bool) -> void:
	history["runs_completed"] += 1
	if victory:
		history["runs_won"] += 1
	
	if run["highest_level"] > history["best_level"]:
		history["best_level"] = run["highest_level"]
	
	history["last_played"] = Time.get_datetime_string_from_system()


# =============================================================================
# QUERY METHODS (for conditions and UI)
# =============================================================================

## Get full battle stats dictionary (for UI display)
func get_battle_stats() -> Dictionary:
	return battle


## Get full run stats dictionary (for UI display)
func get_run_stats() -> Dictionary:
	return run


## Get full history stats dictionary (for UI display)
func get_history_stats() -> Dictionary:
	return history


## Get score contributed by a rune in current battle
func get_battle_score_for_rune(rune_id: String) -> int:
	return battle["score_by_rune"].get(rune_id, 0)


## Get activations for a rune in current battle
func get_battle_activations_for_rune(rune_id: String) -> int:
	return battle["activations_by_rune"].get(rune_id, 0)


## Get total activations for an element in current battle
func get_battle_activations_for_element(element: GameEnums.Element) -> int:
	var key = GameEnums.Element.keys()[element]
	return battle["activations_by_element"].get(key, 0)


## Get lifetime usage of a rune
func get_rune_lifetime_stats(rune_id: String) -> Dictionary:
	return history["rune_usage"].get(rune_id, {"times_used": 0, "total_score": 0})


## Get current money
func get_money() -> int:
	return run["money"]


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_history() -> void:
	history["last_played"] = Time.get_datetime_string_from_system()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(history, "\t")
		file.store_string(json_string)
		file.close()
		print("[Stats] History saved to %s" % SAVE_PATH)
	else:
		push_error("[Stats] Failed to save history: %s" % FileAccess.get_open_error())


func load_history() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var parsed = JSON.parse_string(json_string)
			if parsed is Dictionary:
				history = parsed
				print("[Stats] History loaded from %s" % SAVE_PATH)
				return
	
	# Initialize fresh history if file doesn't exist or is invalid
	_init_history_stats()
	print("[Stats] Initialized new history")


## Export all current stats as a single Dictionary (for debugging/analytics)
func export_all() -> Dictionary:
	return {
		"battle": battle.duplicate(true),
		"run": run.duplicate(true),
		"history": history.duplicate(true),
	}
