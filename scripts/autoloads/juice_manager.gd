extends Node

## Central coordinator for all visual juice effects.
## Autoload — listens to EventBus signals and delegates to sub-modules.
## Zero changes to game logic scripts required.

@export var config: JuiceConfig

var _score_juice: Node = null
var _drag_drop_juice: Node = null
var _level_target_juice: Node = null
var _slot_juice: Node = null

# UI references (injected by MainController)
var _score_label: Label = null
var _level_label: Label = null
var _target_label: Label = null
var _grid_ui_slots: Dictionary = {}  # Vector2i -> SlotUI


func _ready() -> void:
	# Load default config if none assigned
	if not config:
		config = load("res://resources/juice/juice_config_default.tres") as JuiceConfig
	if not config:
		push_warning("[JuiceManager] No JuiceConfig found — juice effects disabled")
		return

	# Create sub-modules
	_score_juice = _create_child("res://scripts/ui/juice/score_juice.gd", "ScoreJuice")
	_drag_drop_juice = _create_child("res://scripts/ui/juice/drag_drop_juice.gd", "DragDropJuice")
	_level_target_juice = _create_child("res://scripts/ui/juice/level_target_juice.gd", "LevelTargetJuice")
	_slot_juice = _create_child("res://scripts/ui/juice/slot_juice.gd", "SlotJuice")

	# Setup config on all modules
	_score_juice.setup(config)
	_drag_drop_juice.setup(config)
	_level_target_juice.setup(config)
	_slot_juice.setup(config)

	# Connect to EventBus signals
	_connect_event_bus()


func _create_child(script_path: String, node_name: String) -> Node:
	var script = load(script_path)
	var node = Node.new()
	node.set_script(script)
	node.name = node_name
	add_child(node)
	return node


func _connect_event_bus() -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if not event_bus:
		push_warning("[JuiceManager] EventBus not found — some juice effects disabled")
		return

	# Drag & Drop (only need drag_ended for cleanup)
	if event_bus.has_signal("drag_ended"):
		event_bus.drag_ended.connect(_on_drag_ended)

	# Rune lifecycle
	# rune_activation_started (not rune_activated) so the flash also covers
	# triggered/simultaneous/connector activations and charge-preserving slots.
	if event_bus.has_signal("rune_activation_started"):
		event_bus.rune_activation_started.connect(_on_rune_activation_started)
	if event_bus.has_signal("rune_destroyed"):
		event_bus.rune_destroyed.connect(_on_rune_destroyed)
	if event_bus.has_signal("rune_created"):
		event_bus.rune_created.connect(_on_rune_created)

	# Round advancement
	if event_bus.has_signal("round_advanced"):
		event_bus.round_advanced.connect(_on_round_advanced)


# =============================================================================
# PUBLIC API — called by MainController to inject UI references
# =============================================================================

## Register the score label for score juice effects
func register_score_label(label: Label) -> void:
	_score_label = label
	if _score_juice:
		_score_juice.set_score_label(label)


## Register level and target labels for transition juice
func register_level_labels(level_label: Label, target_label: Label) -> void:
	_level_label = level_label
	_target_label = target_label
	if _level_target_juice:
		_level_target_juice.set_labels(level_label, target_label)


## Register the grid UI slots dictionary for slot effects
func register_grid_ui_slots(slots: Dictionary) -> void:
	_grid_ui_slots = slots
	if _slot_juice:
		_slot_juice.set_grid_ui_slots(slots)


## Called by MainController when a rune is dropped on a grid slot (for impact effect)
func notify_rune_dropped_on_slot(slot_ui: Control) -> void:
	if _drag_drop_juice:
		_drag_drop_juice.play_slot_impact(slot_ui)


## Called by MainController when a rune is returned to inventory
func notify_rune_returned_to_inventory(slot_ui: Control) -> void:
	if _drag_drop_juice:
		_drag_drop_juice.play_inventory_settle(slot_ui)


## Called by MainController (or Reader signal) when score changes
func notify_score_updated(new_total: int) -> void:
	if _score_juice:
		_score_juice.on_score_updated(new_total)


## Called by RuneUI._get_drag_data to start breathing on the drag preview
func start_breathing_on_preview(preview: Control) -> void:
	if _drag_drop_juice:
		_drag_drop_juice.start_breathing(preview)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_drag_ended(success: bool) -> void:
	if _drag_drop_juice:
		_drag_drop_juice.on_drag_ended(success)


func _on_rune_activation_started(slot: GridSlot, rune: RuneInstance, batch_id: int) -> void:
	if _slot_juice:
		_slot_juice.on_rune_activated(slot, rune, batch_id)


func _on_rune_destroyed(slot: GridSlot, rune: RuneInstance) -> void:
	if _slot_juice:
		_slot_juice.on_rune_destroyed(slot, rune)


func _on_rune_created(slot: GridSlot, rune: RuneInstance) -> void:
	if _slot_juice:
		_slot_juice.on_rune_created(slot, rune)


func _on_round_advanced(old_level: int, new_level: int, new_target: int) -> void:
	if _level_target_juice:
		_level_target_juice.on_round_advanced(old_level, new_level, new_target)
