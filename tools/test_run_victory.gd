extends SceneTree

# Keep the real resolution, result popup, economy, history and restart paths;
# skip content loading and inventory setup unrelated to the finish line.
class TestGameManager extends GameManager:
	var setups: int = 0
	func _ready() -> void:
		pass
	func _setup_initial_inventory() -> void:
		setups += 1
		start_level()

var checks: int = 0
var failures: int = 0
var wins: int = 0
var losses: int = 0
var endings: Array = []
var battle_results: Array = []
var panels: PanelManager
var battle_starts: int = 0
var round_end_hooks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func finish_battle(manager: GameManager, score: int, target: int) -> void:
	manager.current_target_score = target
	manager.current_phase = GameEnums.GamePhase.BATTLE
	var bus = root.get_node("EventBus")
	bus.begin_battle()
	bus.current_score = score
	panels.panel_scores.assign([score])
	panels._finish_multi_panel_battle()

func _run() -> void:
	# Run with APPDATA pointing to a temporary runes-victory-tests directory.
	# The suite exercises real history writes, never the player's profile.
	if not OS.get_user_data_dir().contains("runes-victory-tests"):
		push_error("Set APPDATA to an isolated runes-victory-tests directory before running this suite.")
		quit(1)
		return
	EffectLogger.enabled = false
	var stats = root.get_node("Stats")
	var bus = root.get_node("EventBus")
	var telemetry = root.get_node("Telemetry")
	telemetry.set("_enabled", false)
	telemetry.set("_run_active", false)
	for signal_info in bus.get_signal_list():
		for connection in bus.get_signal_connection_list(signal_info.name):
			if connection.callable.get_object() == telemetry:
				bus.disconnect(signal_info.name, connection.callable)
	bus.run_ended.connect(func(victory: bool, level: int): endings.append([victory, level]))
	bus.battle_ended.connect(func(score: int, target: int, won: bool): battle_results.append([score, target, won]))
	bus.battle_started.connect(func(_count: int): battle_starts += 1)
	bus.round_ending.connect(func(): round_end_hooks += 1)
	var manager := TestGameManager.new()
	root.add_child(manager)
	manager.add_to_group("game_manager")
	panels = PanelManager.new()
	root.add_child(panels)
	manager.set_panel_manager(panels)
	manager.game_won.connect(func(): wins += 1)
	manager.game_lost.connect(func(_level: int): losses += 1)
	manager.start_game()
	var initial_completed: int = stats.history["runs_completed"]
	var initial_won: int = stats.history["runs_won"]
	check(manager.run_victory_score == 1_000_000, "Default finish line is one million")

	finish_battle(manager, 999_999, 100)
	check(not manager._run_victory_pending, "One point below goal is not run victory")
	check(manager._result_screen.title_label.text == "ROUND CLEARED", "Round victory is distinct")
	check(manager._result_screen.continue_button.text == "Continue", "Normal round continues")
	manager._result_screen.continue_button.pressed.emit()
	check(manager.current_level == 2, "Normal round advances")
	check(wins == 0 and endings.is_empty(), "Normal round does not end run")
	check(stats.history["runs_completed"] == initial_completed, "Normal round does not finalize history")

	# Round scores sum above one million here; only this battle's score matters.
	finish_battle(manager, 100, 100)
	check(not manager._run_victory_pending, "Cumulative run score does not trigger finish")
	manager._result_screen.continue_button.pressed.emit()
	check(manager.current_level == 3, "Meeting curve exactly still advances")
	finish_battle(manager, 1_000_000, 500)
	check(manager._run_victory_pending, "Exact finish line wins")
	check(manager._result_screen.title_label.text == "VICTORY!", "Run victory title")
	check(manager._result_screen.continue_button.text == "New Run", "Run victory offers restart")
	check(manager._result_screen.score_label.text.contains("/ 1000000"), "Victory displays finish line")
	var popup := manager._result_screen
	manager._on_battle_finished(0)
	check(manager._result_screen == popup, "Duplicate completion cannot replace victory")
	var click := InputEventMouseButton.new()
	click.pressed = true
	popup._gui_input(click)
	check(popup.visible, "Background click cannot dismiss run victory")
	popup.continue_button.pressed.emit()
	popup.continue_button.pressed.emit()
	manager._on_result_continue(true)
	check(wins == 1 and losses == 0, "Victory signal fires exactly once")
	check(endings.size() == 1 and endings[0] == [true, 3], "Run ending carries victory and final level")
	check(stats.history["runs_won"] == initial_won + 1, "History records win")
	check(stats.history["runs_completed"] == initial_completed + 1, "Restart does not double finalize")
	check(manager.current_level == 1 and manager.current_phase == GameEnums.GamePhase.PLANNING, "New run starts at level one")
	check(not manager._run_victory_pending and not manager._result_pending, "New run clears terminal state")
	check(stats.get_money() == 0, "Test restart does not receive normal round victory reward")

	finish_battle(manager, 1_000_001, 2_000_000)
	check(manager._run_victory_pending and manager._result_screen._is_victory, "Finish line takes precedence over curve")
	check(battle_results[-1] == [1_000_001, 2_000_000, true], "Battle event agrees with run victory")
	manager._result_screen.continue_button.pressed.emit()
	check(wins == 2 and losses == 0, "Overshooting goal also wins")
	finish_battle(manager, 99, 100)
	check(manager._result_screen.title_label.text == "DEFEAT", "Curve still defeats player below goal")
	manager._result_screen.continue_button.pressed.emit()
	check(losses == 1 and endings[-1] == [false, 1], "Loss event remains intact")
	check(stats.history["runs_won"] == initial_won + 2, "Loss does not count as win")
	check(stats.history["runs_completed"] == initial_completed + 3, "Every terminal outcome counts once")
	manager.current_phase = GameEnums.GamePhase.BATTLE
	manager.current_target_score = 2_000_000
	bus.begin_battle(2)
	bus.current_score = 1_000
	panels.panel_scores.assign([1_000, 1_000])
	panels._finish_multi_panel_battle()
	check(manager._run_victory_pending, "Combined panels reach the finish line")
	check(battle_results[-1] == [1_000_000, 2_000_000, true], "EventBus reports combined score instead of last panel")
	check(stats.get_battle_stats()["total_score"] == 1_000_000, "History receives combined score")
	manager._result_screen.continue_button.pressed.emit()
	check(wins == 3 and stats.history["runs_won"] == initial_won + 3, "Multi-panel win finalizes correctly")
	# Exercise actual Readers, including their start/end hooks, in two panels.
	for i in range(2):
		var panel := PanelInstance.new(null, i)
		panels.panels.append(panel)
		panel.setup_grid_and_reader(root, 0.0)
		panel.reader.reading_pace = null
		var data := RuneData.new()
		data.id = "victory_test"
		var score_effect := load("res://resources/effects/rune_effects/ge_s3_score_100.tres").duplicate(true) as GameEffect
		score_effect.action.value.base = 1_000
		data.effects.assign([score_effect])
		panel.grid_manager.place_rune(data, Vector2i(0, 0))
	var starts_before := battle_starts
	var results_before := battle_results.size()
	var hooks_before := round_end_hooks
	manager.current_target_score = 100
	manager.start_battle()
	var deadline := Time.get_ticks_msec() + 5000
	while manager.current_phase == GameEnums.GamePhase.BATTLE and Time.get_ticks_msec() < deadline:
		await process_frame
	check(manager._run_victory_pending, "Real Readers produce a combined run victory")
	check(battle_starts == starts_before + 1, "Managed Readers do not restart battle statistics")
	check(battle_results.size() == results_before + 1, "Managed Readers finalize battle only once")
	check(round_end_hooks == hooks_before + 2, "Round-end hooks execute once per panel")
	check(stats.run["rounds_played"] == 1, "Two panels count as one round")
	check(stats.battle["total_score"] == 1_000_000, "Real Reader score reaches history intact")
	if manager._result_screen:
		manager._result_screen.continue_button.pressed.emit()
	for panel in panels.panels:
		panel.reader.queue_free()
		panel.grid_manager.queue_free()
	manager.queue_free()
	panels.queue_free()
	await process_frame
	print("RUN VICTORY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
