class_name SlotModifierData
extends Resource

## Defines a Slot Modifier - a consumable item that can be applied to slots.
## Modifiers enhance slots permanently (like enchantments).
## Different from SlotData which replaces the entire slot.

enum ModifierType {
	MULTIPLIER,     ## Increases score multiplier
	TRIGGER,        ## Adds extra activations
	ECONOMY,        ## Generates money
	PRESERVATION,   ## Preserves charges
	PROTECTION,     ## Protects fragile runes
	STATE           ## Applies a permanent state
}

@export_group("Identity")
@export var id: String
@export var display_name: String
@export_multiline var description: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.UNCOMMON

@export_group("Type")
@export var modifier_type: ModifierType = ModifierType.MULTIPLIER
## If set, this modifier replaces the slot's data (turning it into a slot type).
@export var slot_data_override: SlotData

@export_group("Value")
## The value of the modifier (interpretation depends on type)
## MULTIPLIER: Added to slot multiplier (e.g., 0.5 = +0.5x)
## TRIGGER: Extra triggers (e.g., 1 = +1 activation)
## ECONOMY: Money per activation (e.g., 2 = +$2)
## PRESERVATION: Not used (binary)
## PROTECTION: Not used (binary)
## STATE: Duration in rounds (0 = permanent)
@export var value: float = 0.5

@export_group("Stacking")
## Can this modifier be applied multiple times to the same slot?
@export var stacks: bool = false
## Maximum number of stacks (if stacks = true)
@export var max_stacks: int = 3

@export_group("Restrictions")
## Can only be applied to specific slot types (empty = any)
@export var compatible_slot_ids: Array[String] = []
## Cannot be applied with these other modifiers
@export var incompatible_modifier_ids: Array[String] = []

@export_group("Visuals")
@export var icon: Texture2D
@export var color_tint: Color = Color.WHITE
## Visual effect when applied
@export var particle_effect: String = ""

## Economy values are defined in ShopConfig based on rarity


## Get the display text for the modifier's effect
func get_effect_text() -> String:
	match modifier_type:
		ModifierType.MULTIPLIER:
			return "+%.1fx Multiplier" % value
		ModifierType.TRIGGER:
			return "+%d Extra Trigger(s)" % int(value)
		ModifierType.ECONOMY:
			return "+$%d per Activation" % int(value)
		ModifierType.PRESERVATION:
			return "Preserves Rune Charges"
		ModifierType.PROTECTION:
			return "Protects Fragile Runes"
		ModifierType.STATE:
			return "Applies Permanent State"
		_:
			return "Unknown Effect"


## Get the full description including effect
func get_full_description() -> String:
	var text = description
	if not text.is_empty():
		text += "\n"
	text += "[color=cyan]%s[/color]" % get_effect_text()
	
	if stacks:
		text += "\n[color=gray]Stacks up to %dx[/color]" % max_stacks
	
	return text


## Check if this modifier can be applied to a slot
func can_apply_to_slot(slot_instance) -> bool:  # SlotInstance
	if slot_instance == null:
		return false
	
	# Check slot compatibility
	if not compatible_slot_ids.is_empty():
		var slot_id = slot_instance.data.id if slot_instance.data else "default"
		if slot_id not in compatible_slot_ids:
			return false
	
	# Slot type overrides replace existing modifiers, so skip stacking checks
	if slot_data_override:
		return true

	# Check for incompatible modifiers already applied
	if slot_instance.has_method("has_modifier"):
		for incompatible_id in incompatible_modifier_ids:
			if slot_instance.has_modifier(incompatible_id):
				return false
	
	# Check stacking limit
	if slot_instance.has_method("get_modifier_stack_count"):
		var current_stacks = slot_instance.get_modifier_stack_count(id)
		if current_stacks >= max_stacks:
			return false
		if not stacks and current_stacks > 0:
			return false
	
	return true


## Get keywords for this modifier
func get_keywords() -> Array[StringName]:
	var keywords: Array[StringName] = []
	
	match modifier_type:
		ModifierType.MULTIPLIER:
			keywords.append(&"MULTIPLY")
			keywords.append(&"BUFF")
		ModifierType.TRIGGER:
			keywords.append(&"TRIGGER")
		ModifierType.ECONOMY:
			keywords.append(&"INCOME")
		ModifierType.PRESERVATION:
			keywords.append(&"BUFF")
		ModifierType.PROTECTION:
			keywords.append(&"BUFF")
		ModifierType.STATE:
			keywords.append(&"BUFF")
	
	return keywords
