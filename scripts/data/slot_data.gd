class_name SlotData
extends Resource

## Defines a Slot type that can be placed on the grid.
## Similar to RuneData, this is the static data that defines slot behavior.
## Slots can have multipliers, effects, and special properties.

const SlotEffect = preload("res://scripts/data/slot_effects/slot_effect.gd")

@export_group("Identity")
@export var id: String
@export var slot_name: String
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export_multiline var description: String = ""

@export_group("Visuals")
@export var texture: Texture2D
@export var color_tint: Color = Color.WHITE

@export_group("Multipliers")
## Base score multiplier for runes in this slot
@export var base_multiplier: float = 1.0
## Can this slot's multiplier be upgraded?
@export var can_upgrade_multiplier: bool = true
## Multiplier increase per upgrade level
@export var multiplier_per_upgrade: float = 0.5
## Maximum upgrade level
@export var max_upgrade_level: int = 3

@export_group("Triggers")
## How many times should runes trigger when activated here
@export var trigger_count: int = 1
## Does this slot preserve rune charges (infinite use)?
@export var preserves_charges: bool = false
## Does this slot protect fragile/glass runes?
@export var protects_fragile: bool = false

@export_group("Economy")
## Money generated when a rune activates here
@export var money_on_activation: int = 0
## Money generated at end of round if a rune is present
@export var money_on_round_end: int = 0

@export_group("Special")
## Is this a "broken" slot with penalties?
@export var is_broken: bool = false
## Is this an "empty space" (no physical slot, just gap)?
@export var is_void: bool = false

@export_group("Behavior")
## Slot effects that trigger during the round lifecycle
@export var slot_effects: Array[SlotEffect] = []


## Get the full description including stats
func get_full_description() -> String:
	var desc = description + "\n"
	
	if base_multiplier != 1.0:
		desc += "[color=yellow]x%.1f Multiplier[/color]\n" % base_multiplier
	
	if trigger_count > 1:
		desc += "[color=cyan]Triggers %dx[/color]\n" % trigger_count
	
	if preserves_charges:
		desc += "[color=green]Preserves Charges[/color]\n"
	
	if protects_fragile:
		desc += "[color=green]Protects Fragile[/color]\n"
	
	if money_on_activation > 0:
		desc += "[color=gold]+$%d on activation[/color]\n" % money_on_activation
	
	if money_on_round_end > 0:
		desc += "[color=gold]+$%d at round end[/color]\n" % money_on_round_end
	
	if is_broken:
		desc += "[color=red]BROKEN: x0.5 penalty[/color]\n"
	
	return desc


## Get all keywords from this slot's effects
func get_keywords() -> Array[StringName]:
	var all_keywords: Array[StringName] = []
	
	# Add implicit keywords based on properties
	if base_multiplier > 1.0:
		all_keywords.append(Keywords.MULTIPLY)
	if trigger_count > 1:
		all_keywords.append(Keywords.TRIGGER)
	if preserves_charges:
		all_keywords.append(Keywords.BUFF)
	if money_on_activation > 0 or money_on_round_end > 0:
		all_keywords.append(Keywords.INCOME)
	
	# Collect from slot effects
	for effect in slot_effects:
		if effect:
			for kw in effect.get_keywords():
				if kw not in all_keywords:
					all_keywords.append(kw)
	
	return all_keywords
