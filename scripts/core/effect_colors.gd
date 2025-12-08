class_name EffectColors
extends Object

## Centralized color management for effect visualization.
## Ensures consistency between grid highlights and tooltip text.

# Palette of colors for effects (with versions for UI text and grid overlay)
# Each entry has:
#   - "name": identifier for the effect slot
#   - "ui": full opacity color for BBCode text
#   - "grid": semi-transparent for grid overlay
const EFFECT_PALETTE = [
	{ "name": "effect_1", "ui": Color(1.0, 0.35, 0.35), "grid": Color(1.0, 0.35, 0.35, 0.4) },      # Red
	{ "name": "effect_2", "ui": Color(0.4, 0.6, 1.0), "grid": Color(0.4, 0.6, 1.0, 0.4) },          # Blue
	{ "name": "effect_3", "ui": Color(1.0, 0.85, 0.25), "grid": Color(1.0, 0.85, 0.25, 0.4) },      # Yellow
	{ "name": "effect_4", "ui": Color(0.85, 0.4, 1.0), "grid": Color(0.85, 0.4, 1.0, 0.4) },        # Purple
	{ "name": "effect_5", "ui": Color(0.4, 1.0, 0.6), "grid": Color(0.4, 1.0, 0.6, 0.4) },          # Green-Cyan
	{ "name": "effect_6", "ui": Color(1.0, 0.6, 0.3), "grid": Color(1.0, 0.6, 0.3, 0.4) },          # Orange
]

# Condition colors (used for condition slot highlighting)
const CONDITION_UI = Color(0.3, 0.9, 0.45)
const CONDITION_GRID = Color(0.3, 0.9, 0.45, 0.3)

# Condition state colors (for tooltip text)
const CONDITION_MET = Color(0.3, 0.9, 0.45)      # Green - condition is satisfied
const CONDITION_NOT_MET = Color(0.9, 0.35, 0.35)  # Red - condition not satisfied
const CONDITION_UNKNOWN = Color(0.7, 0.7, 0.7)    # Gray - cannot evaluate (e.g., in inventory)

# Clear color for resetting
const CLEAR = Color(0, 0, 0, 0)

## Returns the UI color (full opacity) for an effect at the given index.
static func get_effect_ui_color(index: int) -> Color:
	return EFFECT_PALETTE[index % EFFECT_PALETTE.size()]["ui"]

## Returns the grid overlay color (semi-transparent) for an effect at the given index.
static func get_effect_grid_color(index: int) -> Color:
	return EFFECT_PALETTE[index % EFFECT_PALETTE.size()]["grid"]

## Returns the hex string of the UI color for BBCode formatting.
static func get_effect_hex(index: int) -> String:
	return get_effect_ui_color(index).to_html(false)

## Returns the number of colors in the palette.
static func get_palette_size() -> int:
	return EFFECT_PALETTE.size()

## Returns a color marker string for BBCode (●) with the effect color.
static func get_color_marker(index: int) -> String:
	return "[color=#%s]●[/color]" % get_effect_hex(index)

## Returns the condition color based on evaluation state.
static func get_condition_color(is_met: bool, can_evaluate: bool = true) -> Color:
	if not can_evaluate:
		return CONDITION_UNKNOWN
	return CONDITION_MET if is_met else CONDITION_NOT_MET

## Returns condition color as hex for BBCode.
static func get_condition_hex(is_met: bool, can_evaluate: bool = true) -> String:
	return get_condition_color(is_met, can_evaluate).to_html(false)

## Wraps text in BBCode color tags using the effect color.
static func colorize_text(text: String, effect_index: int) -> String:
	return "[color=#%s]%s[/color]" % [get_effect_hex(effect_index), text]

## Wraps text in BBCode color tags using condition color.
static func colorize_condition(text: String, is_met: bool, can_evaluate: bool = true) -> String:
	return "[color=#%s]%s[/color]" % [get_condition_hex(is_met, can_evaluate), text]
