class_name RuneData
extends Resource

@export_group("Identity")
@export var id: String
@export var rune_name: String
@export_multiline var description: String = "" ## Human-readable description of what the rune does
@export var tier: GameEnums.Tier = GameEnums.Tier.TIER_1
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export var elements: Array[GameEnums.Element] = []
@export var upgrades_to: RuneData

@export_group("Stats")
@export var base_max_activations: int = 1
@export var is_indestructible: bool = true ## If false, the rune can be destroyed

@export_group("Visuals")
## Array of Textures corresponding to Tier 1, 2, and 3 visuals.
@export var textures: Array[Texture2D]

@export_group("Behavior")
## List of modular effects this rune possesses.
@export var effects: Array[RuneEffect]
