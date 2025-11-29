class_name RuneDropRates
extends Resource

@export var common_weight: int = 100
@export var uncommon_weight: int = 50
@export var rare_weight: int = 25
@export var epic_weight: int = 10
@export var legendary_weight: int = 1

func get_weight(rarity: GameEnums.Rarity) -> int:
	match rarity:
		GameEnums.Rarity.COMMON: return common_weight
		GameEnums.Rarity.UNCOMMON: return uncommon_weight
		GameEnums.Rarity.RARE: return rare_weight
		GameEnums.Rarity.EPIC: return epic_weight
		GameEnums.Rarity.LEGENDARY: return legendary_weight
	return 0
