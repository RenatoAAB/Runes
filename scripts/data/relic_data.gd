class_name RelicData
extends Resource

const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Defines a Relic - a global modifier that affects an entire panel.
## Relics are attached to panels and apply effects to all activations.
## They can trigger at different moments (start, end, each activation, passive).

enum RelicTrigger {
	PASSIVE,            ## Always active while attached
	ON_PANEL_START,     ## Triggers at the start of panel battle
	ON_PANEL_END,       ## Triggers at the end of panel battle
	ON_EACH_ACTIVATION, ## Triggers on every rune activation
	ON_FIRST_ACTIVATION,## Triggers only on first activation
	ON_LAST_ACTIVATION, ## Triggers on last slot of panel
	ON_THRESHOLD        ## Triggers when score reaches a threshold
}

@export_group("Identity")
@export var id: String
@export var display_name: String
@export_multiline var description: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.RARE

@export_group("Trigger")
## When does this relic's effects activate?
@export var trigger_type: RelicTrigger = RelicTrigger.PASSIVE

## For ON_THRESHOLD: The score threshold that triggers the effect
@export var threshold_value: int = 100

## Can this relic trigger multiple times per battle?
@export var can_repeat: bool = false

@export_group("Effects")
## Effects applied by this relic
@export var effects: Array[RuneEffect] = []

## Global score multiplier bonus (for PASSIVE relics)
@export var multiplier_bonus: float = 0.0

## Global score flat bonus (for PASSIVE relics)
@export var score_bonus: int = 0

## Element affinity (boosts specific elements if set). Empty = no affinity.
@export var element_affinity: Array[GameEnums.Element] = []

## Affinity multiplier (applied if affinity list is not empty)
@export var affinity_multiplier: float = 1.0

@export_group("Restrictions")
## Maximum number of this relic that can be attached (0 = unlimited)
@export var max_per_panel: int = 1

## Incompatible relic IDs (cannot coexist on same panel)
@export var incompatible_relic_ids: Array[String] = []

@export_group("Visuals")
@export var icon: Texture2D
@export var color_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT

## Economy values are defined in ShopConfig based on rarity


## Get the trigger type as a display string
func get_trigger_text() -> String:
	match trigger_type:
		RelicTrigger.PASSIVE:
			return "Passive"
		RelicTrigger.ON_PANEL_START:
			return "On Battle Start"
		RelicTrigger.ON_PANEL_END:
			return "On Battle End"
		RelicTrigger.ON_EACH_ACTIVATION:
			return "On Each Activation"
		RelicTrigger.ON_FIRST_ACTIVATION:
			return "On First Activation"
		RelicTrigger.ON_LAST_ACTIVATION:
			return "On Last Activation"
		RelicTrigger.ON_THRESHOLD:
			return "When Score ≥ %d" % threshold_value
		_:
			return "Unknown"


## Get the full description with effects
func get_full_description() -> String:
	var text = "[color=gray]%s[/color]\n" % get_trigger_text()
	text += description
	
	if multiplier_bonus > 0:
		text += "\n[color=yellow]+%.0f%% Panel Multiplier[/color]" % (multiplier_bonus * 100)
	
	if score_bonus > 0:
		text += "\n[color=cyan]+%d Base Score[/color]" % score_bonus
	
	if element_affinity.size() > 0 and affinity_multiplier > 1.0:
		var names = ElementIcons.join(element_affinity, 9, ", ")
		text += "\n[color=magenta]%s x%.1f[/color]" % [names, affinity_multiplier]
	
	return text


## Check if this relic can be attached to a panel
func can_attach_to_panel(panel: PanelInstance) -> bool:
	if panel == null:
		return false
	
	# Check available slots
	if panel.get_available_relic_slots() <= 0:
		return false
	
	# Check max per panel
	if max_per_panel > 0:
		var count = 0
		for relic in panel.attached_relics:
			if relic.data.id == id:
				count += 1
		if count >= max_per_panel:
			return false
	
	# Check incompatibilities
	for relic in panel.attached_relics:
		if relic.data.id in incompatible_relic_ids:
			return false
		if id in relic.data.incompatible_relic_ids:
			return false
	
	return true


## Get all keywords from this relic's effects
func get_keywords() -> Array[StringName]:
	var all_keywords: Array[StringName] = []
	
	# Add implicit keywords
	if multiplier_bonus > 0:
		all_keywords.append(&"MULTIPLY")
	if score_bonus > 0:
		all_keywords.append(&"SCORE")
	if element_affinity.size() > 0:
		all_keywords.append(&"ELEMENT_TARGET")
	
	# Add keywords from effects
	for effect in effects:
		if effect and effect.has_method("get_keywords"):
			for kw in effect.get_keywords():
				if kw not in all_keywords:
					all_keywords.append(kw)
	
	return all_keywords
