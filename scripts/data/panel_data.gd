class_name PanelData
extends Resource

## Defines the configuration for a Panel.
## Panels are independent grids that multiply their scores together.
## Each panel has its own grid, reader, and attached relics.

@export_group("Identity")
@export var id: String
@export var display_name: String
@export_multiline var description: String = ""

@export_group("Grid Configuration")
## Initial grid size (center of max_size)
@export var base_size: Vector2i = Vector2i(3, 3)
## Maximum grid size that can be expanded to
@export var max_size: Vector2i = Vector2i(5, 5)
## Initial slots that are unlocked (relative to center)
## If empty, uses a centered rectangle of base_size
@export var initial_unlocked_slots: Array[Vector2i] = []

@export_group("Economy")
## Cost to unlock this panel (for 2nd, 3rd panels, etc.)
@export var unlock_cost: int = 25
## Is this panel unlocked by default? (first panel should be true)
@export var unlocked_by_default: bool = false

@export_group("Visuals")
@export var icon: Texture2D
@export var background_color: Color = Color(0.1, 0.1, 0.15)

@export_group("Behavior")
## Maximum number of relics that can be attached
@export var max_relics: int = 3
## Passive effects that apply to all activations in this panel
@export var passive_effects: Array[GameEffect] = []
## Panel-wide score multiplier (base value)
@export var base_panel_multiplier: float = 1.0


## Get the center offset for grid positioning
func get_center_offset() -> Vector2i:
	return max_size / 2


## Get the initial unlocked positions (defaults to top-left aligned base_size rectangle)
func get_initial_unlocked_positions() -> Array[Vector2i]:
	if not initial_unlocked_slots.is_empty():
		return initial_unlocked_slots
	
	# Generate top-left aligned rectangle of base_size
	# Priority: top rows first, left columns first
	var positions: Array[Vector2i] = []
	
	for y in range(base_size.y):
		for x in range(base_size.x):
			positions.append(Vector2i(x, y))
	
	return positions


## Check if a coordinate is within the max grid bounds
func is_valid_coord(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < max_size.x and coord.y >= 0 and coord.y < max_size.y


## Get the total number of possible slots
func get_max_slot_count() -> int:
	return max_size.x * max_size.y


## Get all keywords from passive effects
func get_keywords() -> Array[StringName]:
	var all_keywords: Array[StringName] = []
	
	for effect in passive_effects:
		if effect and effect.has_method("get_keywords"):
			for kw in effect.get_keywords():
				if kw not in all_keywords:
					all_keywords.append(kw)
	
	return all_keywords
