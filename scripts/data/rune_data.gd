class_name RuneData
extends Resource

@export_group("Identity")
@export var id: String
@export var rune_name: String
@export var tier: GameEnums.Tier = GameEnums.Tier.TIER_1
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export var element: GameEnums.Element = GameEnums.Element.NEUTRAL
@export var upgrades_to: RuneData

@export_group("Stats")
@export var base_max_activations: int = 1

@export_group("Visuals")
## Array of Textures corresponding to Tier 1, 2, and 3 visuals.
@export var textures: Array[Texture2D]

@export_group("Behavior")
## List of modular effects this rune possesses.
@export var effects: Array[RuneEffect]
