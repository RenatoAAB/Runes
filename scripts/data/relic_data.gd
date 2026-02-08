class_name RelicData
extends Resource

## Defines a Relic — a post-panel multiplier attached to a panel.
## After the Reader finishes, each relic's calculator receives the round statistics
## and produces a multiplier.  All multipliers are accumulated (product).

@export_group("Identity")
@export var id: String
@export var display_name: String
@export_multiline var description: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.RARE

@export_group("Calculator")
## The multiplier calculator for this relic.
## Receives BattleRoundStatistics and returns a float multiplier.
@export var calculator: RelicMultiplierCalculator

@export_group("Restrictions")
## Maximum number of this relic that can be attached to a single panel (0 = unlimited)
@export var max_per_panel: int = 1

## Incompatible relic IDs (cannot coexist on same panel)
@export var incompatible_relic_ids: Array[String] = []

@export_group("Visuals")
@export var icon: Texture2D
@export var color_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT

## Economy values are defined in ShopConfig based on rarity


## Whether this relic has a calculator assigned
func has_calculator() -> bool:
	return calculator != null


## Full rich-text description for tooltips
func get_full_description() -> String:
	var text = "[color=gray]Post-Panel Multiplier[/color]\n"
	text += description
	if has_calculator():
		var calc_desc = calculator.get_description()
		if not calc_desc.is_empty():
			text += "\n[color=yellow]%s[/color]" % calc_desc
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


## Collect keywords for UI filtering / tooltips
func get_keywords() -> Array[StringName]:
	var all_keywords: Array[StringName] = []
	all_keywords.append(&"MULTIPLY")
	return all_keywords
