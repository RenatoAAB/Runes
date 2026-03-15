class_name JuiceConfig
extends Resource

## Configuration resource for all juice/visual feedback parameters.
## Tweak these values in the .tres inspector without touching code.

# =============================================================================
# SCORE JUICE
# =============================================================================

@export_group("Score - Scale Punch")
## Scale for small score deltas (< small_threshold)
@export var score_punch_small: float = 1.1
## Scale for medium score deltas (small_threshold to large_threshold)
@export var score_punch_medium: float = 1.2
## Scale for large score deltas (> large_threshold)
@export var score_punch_large: float = 1.3
## Duration of the scale punch tween
@export var score_punch_duration: float = 0.25
## Threshold: deltas below this are "small"
@export var score_small_threshold: int = 10
## Threshold: deltas above this are "large"
@export var score_large_threshold: int = 50

@export_group("Score - Color Flash")
## Flash color for small score changes
@export var score_flash_color_small: Color = Color.WHITE
## Flash color for large score changes
@export var score_flash_color_large: Color = Color(1.0, 0.85, 0.0)  # Gold
## Duration of color flash
@export var score_flash_duration: float = 0.2

@export_group("Score - Counting")
## Duration of the counting animation (number incrementing)
@export var score_count_duration: float = 0.4

# =============================================================================
# DRAG & DROP JUICE
# =============================================================================

@export_group("Drag - Breathing")
## Max scale of the breathing animation on the drag preview
@export var drag_breathing_scale: float = 1.05
## Duration of one breathing cycle (up + down)
@export var drag_breathing_duration: float = 0.8
## Scale up of the drag preview relative to slot
@export var drag_preview_scale: float = 1.1

@export_group("Drop - Impact")
## Overshoot scale on impact (drop on panel)
@export var drop_impact_scale: float = 1.15
## Undershoot scale after overshoot
@export var drop_impact_undershoot: float = 0.95
## Duration of the impact animation
@export var drop_impact_duration: float = 0.25
## Micro-shake amplitude in pixels
@export var drop_shake_amplitude: float = 2.0
## Micro-shake duration
@export var drop_shake_duration: float = 0.1

@export_group("Drop - Return to Inventory")
## Gentle settle scale
@export var drop_return_scale: float = 1.03
## Gentle settle duration
@export var drop_return_duration: float = 0.3

# =============================================================================
# LEVEL / TARGET TRANSITION
# =============================================================================

@export_group("Level Transition")
## Duration of the dissolve-out animation
@export var level_dissolve_out_duration: float = 0.3
## Duration of the reconstruct-in animation
@export var level_reconstruct_in_duration: float = 0.35
## Scale down factor during dissolve
@export var level_dissolve_scale: float = 0.85
## Scale up overshoot during reconstruct
@export var level_reconstruct_scale: float = 1.1
## Transition color (magic blue/white)
@export var level_transition_color: Color = Color(0.6, 0.8, 1.0)

# =============================================================================
# ACTIVATION / DESTRUCTION / CREATION
# =============================================================================

@export_group("Rune Activation")
## Duration of the activation flash
@export var activation_flash_duration: float = 0.2
## Scale pulse on activation
@export var activation_pulse_scale: float = 1.15
## Duration of the scale pulse
@export var activation_pulse_duration: float = 0.2

@export_group("Rune Destruction")
## Duration of the dissolve/fade out
@export var destruction_fade_duration: float = 0.5
## Scale down during destruction
@export var destruction_scale: float = 0.7

@export_group("Rune Creation")
## Duration of the materialization
@export var creation_duration: float = 0.4
## Overshoot scale when rune materializes
@export var creation_overshoot_scale: float = 1.2
## Glow duration after creation
@export var creation_glow_duration: float = 0.3

# =============================================================================
# ELEMENT COLORS
# =============================================================================

@export_group("Element Colors")
@export var element_colors: Dictionary = {
	GameEnums.Element.FIRE: Color(0.9, 0.3, 0.1),
	GameEnums.Element.WATER: Color(0.2, 0.6, 1.0),
	GameEnums.Element.EARTH: Color(0.6, 0.4, 0.2),
	GameEnums.Element.AIR: Color(0.7, 0.9, 1.0),
	GameEnums.Element.SPIRIT: Color(0.8, 0.6, 1.0),
}

func get_element_color(element: int) -> Color:
	if element_colors.has(element):
		return element_colors[element]
	return Color.WHITE
