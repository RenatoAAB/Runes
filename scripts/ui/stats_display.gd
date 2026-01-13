class_name StatsDisplay
extends Control

## Displays real-time statistics during gameplay.
## Shows score breakdown and rune performance.

@export var stats_container: VBoxContainer
@export var score_label: RichTextLabel
@export var activations_label: Label

## Reference to StatisticsManager autoload
var stats: Node

## Update frequency in seconds
@export var update_interval: float = 0.5
var _update_timer: float = 0.0

func _ready() -> void:
	# Get reference to Stats autoload
	stats = get_node_or_null("/root/Stats")
	
	if not stats:
		push_warning("StatsDisplay: Stats autoload not found")
		return
	
	# Connect to EventBus for real-time updates
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		if event_bus.has_signal("slot_read"):
			event_bus.slot_read.connect(_on_slot_read)


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_refresh_display()


func _refresh_display() -> void:
	if not stats:
		return
	
	_update_score_display()
	_update_activations_display()


func _update_score_display() -> void:
	if not score_label:
		return
	
	var battle_stats = stats.get_battle_stats()
	if battle_stats.is_empty():
		return
	
	var score = battle_stats.get("current_score", 0)
	var high_activation = battle_stats.get("highest_single_activation", 0)
	
	score_label.text = "[b]Score:[/b] %d\n[color=yellow]Best: %d[/color]" % [score, high_activation]


func _update_activations_display() -> void:
	if not activations_label:
		return
	
	var battle_stats = stats.get_battle_stats()
	if battle_stats.is_empty():
		return
	
	var total_activations = battle_stats.get("total_activations", 0)
	var rune_count = battle_stats.get("score_by_rune", {}).size()
	
	activations_label.text = "Activations: %d | Runes: %d" % [total_activations, rune_count]


func _on_slot_read(event: SlotReadEvent) -> void:
	# Immediate update on slot read for responsiveness
	_refresh_display()


## Get a summary string for end-of-battle display
func get_battle_summary() -> String:
	if not stats:
		return "No stats available"
	
	var battle_stats = stats.get_battle_stats()
	if battle_stats.is_empty():
		return "No battle data"
	
	var summary = "[b]=== Battle Summary ===[/b]\n\n"
	
	# Score info
	summary += "[b]Final Score:[/b] %d\n" % battle_stats.get("current_score", 0)
	summary += "[b]Best Activation:[/b] %d pts\n" % battle_stats.get("highest_single_activation", 0)
	summary += "[b]Total Activations:[/b] %d\n\n" % battle_stats.get("total_activations", 0)
	
	# Top runes
	var score_by_rune: Dictionary = battle_stats.get("score_by_rune", {})
	if score_by_rune.size() > 0:
		summary += "[b]Score by Rune:[/b]\n"
		var sorted_runes = score_by_rune.keys()
		sorted_runes.sort_custom(func(a, b): return score_by_rune[a] > score_by_rune[b])
		
		for i in range(mini(5, sorted_runes.size())):
			var rune_id = sorted_runes[i]
			summary += "  %s: %d pts\n" % [rune_id, score_by_rune[rune_id]]
		summary += "\n"
	
	return summary


## Get run summary for end-of-run display
func get_run_summary() -> String:
	if not stats:
		return "No stats available"
	
	var run_stats = stats.get_run_stats()
	if run_stats.is_empty():
		return "No run data"
	
	var summary = "[b]=== Run Summary ===[/b]\n\n"
	
	summary += "[b]Rounds Played:[/b] %d\n" % run_stats.get("rounds_played", 0)
	summary += "[b]Rounds Won:[/b] %d\n" % run_stats.get("rounds_won", 0)
	summary += "[b]Total Score:[/b] %d\n" % run_stats.get("total_score", 0)
	summary += "[b]Money Earned:[/b] $%d\n" % run_stats.get("money_earned", 0)
	summary += "[b]Runes Collected:[/b] %d\n" % run_stats.get("runes_acquired", []).size()
	
	return summary


## Static helper to create a minimal stats display panel
static func create_panel(parent: Node, position: Vector2 = Vector2(10, 270)) -> StatsDisplay:
	var display = StatsDisplay.new()
	display.position = position
	display.custom_minimum_size = Vector2(150, 100)
	
	# Create panel background
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 100)
	display.add_child(panel)
	
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	display.stats_container = vbox
	
	# Score label
	var score_rich = RichTextLabel.new()
	score_rich.bbcode_enabled = true
	score_rich.fit_content = true
	score_rich.custom_minimum_size = Vector2(140, 30)
	vbox.add_child(score_rich)
	display.score_label = score_rich
	
	# Activations label
	var activations = Label.new()
	activations.add_theme_font_size_override("font_size", 12)
	vbox.add_child(activations)
	display.activations_label = activations
	
	parent.add_child(display)
	return display
