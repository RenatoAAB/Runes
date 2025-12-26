class_name BattleResultScreen
extends Control

## Shows battle results with detailed statistics before proceeding.

signal continue_pressed

@export var title_label: Label
@export var score_label: RichTextLabel
@export var stats_container: VBoxContainer
@export var keywords_container: HFlowContainer
@export var continue_button: Button

## Colors for victory/defeat styling
const VICTORY_COLOR := Color(0.3, 0.8, 0.3)
const DEFEAT_COLOR := Color(0.8, 0.3, 0.3)

var _is_victory: bool = false


func _ready() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	hide()


func _gui_input(event: InputEvent) -> void:
	# Any click on the screen closes it
	if event is InputEventMouseButton and event.pressed:
		_on_continue_pressed()


## Show the battle result screen with statistics
func show_result(is_victory: bool, final_score: int, target_score: int) -> void:
	_is_victory = is_victory
	
	# Update title
	if title_label:
		if is_victory:
			title_label.text = "VICTORY!"
			title_label.add_theme_color_override("font_color", VICTORY_COLOR)
		else:
			title_label.text = "DEFEAT"
			title_label.add_theme_color_override("font_color", DEFEAT_COLOR)
	
	# Update score display
	_update_score_display(final_score, target_score)
	
	# Update statistics from StatisticsManager
	_update_stats_display()
	
	# Update keywords display
	_update_keywords_display()
	
	# Show the screen
	show()


func _update_score_display(final_score: int, target_score: int) -> void:
	if not score_label:
		return
	
	var score_color = "green" if final_score >= target_score else "red"
	
	var text = "[center][b]Final Score[/b]\n"
	text += "[color=%s][font_size=24]%d[/font_size][/color] / %d[/center]" % [score_color, final_score, target_score]
	
	score_label.text = text


func _update_stats_display() -> void:
	if not stats_container:
		return
	
	# Clear previous stats
	for child in stats_container.get_children():
		child.queue_free()
	
	# Get statistics from autoload
	var stats = get_node_or_null("/root/Stats")
	if not stats:
		return
	
	var battle_stats = stats.get_battle_stats()
	if battle_stats.is_empty():
		return
	
	# Add stat lines (compact version)
	_add_stat_line("Activations", str(battle_stats.get("total_activations", 0)))
	_add_stat_line("Best Activation", str(battle_stats.get("highest_single_activation", 0)))
	
	# Top performing runes (only top 2 to save space)
	var score_by_rune: Dictionary = battle_stats.get("score_by_rune", {})
	if score_by_rune.size() > 0:
		var sorted_runes = score_by_rune.keys()
		sorted_runes.sort_custom(func(a, b): return score_by_rune[a] > score_by_rune[b])
		
		for i in range(mini(2, sorted_runes.size())):
			var rune_name = sorted_runes[i]
			var rune_score = score_by_rune[rune_name]
			_add_stat_line(str(rune_name), "%d pts" % rune_score)


func _update_keywords_display() -> void:
	if not keywords_container:
		return
	
	# Clear previous keywords
	for child in keywords_container.get_children():
		child.queue_free()
	
	var stats = get_node_or_null("/root/Stats")
	if not stats:
		return
	
	var battle_stats = stats.get_battle_stats()
	if battle_stats.is_empty():
		return
	
	var keyword_counts: Dictionary = battle_stats.get("keywords_triggered", {})
	if keyword_counts.is_empty():
		return
	
	# Sort by count
	var sorted_keywords = keyword_counts.keys()
	sorted_keywords.sort_custom(func(a, b): return keyword_counts[a] > keyword_counts[b])
	
	# Show top 8 keywords
	for i in range(mini(8, sorted_keywords.size())):
		var kw_id = sorted_keywords[i]
		var count = keyword_counts[kw_id]
		_create_keyword_badge(kw_id, count)


func _create_keyword_badge(keyword_id: StringName, count: int) -> void:
	var panel = PanelContainer.new()
	
	var label = Label.new()
	var kw_data = Keywords.get_keyword(keyword_id)
	
	label.text = "%s ×%d" % [kw_data.get("name", keyword_id), count]
	
	# Set color from keyword data
	var color = kw_data.get("color", Color.WHITE)
	label.add_theme_color_override("font_color", color)
	
	panel.add_child(label)
	keywords_container.add_child(panel)


func _add_stat_line(stat_name: String, stat_value: String) -> void:
	var hbox = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)
	
	stats_container.add_child(hbox)


func _add_section_header(title: String) -> void:
	var label = Label.new()
	label.text = title
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
	stats_container.add_child(label)


func _on_continue_pressed() -> void:
	hide()
	continue_pressed.emit()


## Static helper to create and show the result screen
static func create_popup(parent: Node, is_victory: bool, final_score: int, target_score: int) -> BattleResultScreen:
	var screen = BattleResultScreen.new()
	
	# Set up basic layout
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Create background panel (clickable)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			screen._on_continue_pressed()
	)
	screen.add_child(bg)
	
	# Create center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	
	# Create main panel with limited size
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 250)
	center.add_child(panel)
	
	# Create margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	# Create content container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	screen.title_label = title
	vbox.add_child(title)
	
	# Score display
	var score_rich = RichTextLabel.new()
	score_rich.bbcode_enabled = true
	score_rich.fit_content = true
	score_rich.custom_minimum_size = Vector2(250, 50)
	screen.score_label = score_rich
	vbox.add_child(score_rich)
	
	# Stats container (limited height)
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 2)
	screen.stats_container = stats_vbox
	vbox.add_child(stats_vbox)
	
	# Keywords header
	var kw_header = Label.new()
	kw_header.text = "Keywords Used"
	kw_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
	kw_header.add_theme_font_size_override("font_size", 12)
	vbox.add_child(kw_header)
	
	# Keywords container
	var kw_flow = HFlowContainer.new()
	kw_flow.custom_minimum_size = Vector2(250, 30)
	screen.keywords_container = kw_flow
	vbox.add_child(kw_flow)
	
	# Continue button
	var button = Button.new()
	button.text = "Continue" if is_victory else "Try Again"
	button.custom_minimum_size = Vector2(100, 30)
	button.pressed.connect(screen._on_continue_pressed)
	screen.continue_button = button
	vbox.add_child(button)
	
	# Add to parent and show
	parent.add_child(screen)
	screen.show_result(is_victory, final_score, target_score)
	
	return screen
