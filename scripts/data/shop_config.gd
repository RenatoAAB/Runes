class_name ShopConfig
extends RefCounted

## Shop configuration - prices, costs, and multipliers for all shop transactions.

# --- Rune Prices by Rarity ---
const RUNE_BUY_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 3,
	GameEnums.Rarity.UNCOMMON: 5,
	GameEnums.Rarity.RARE: 8,
	GameEnums.Rarity.EPIC: 12,
	GameEnums.Rarity.LEGENDARY: 20,
}

const RUNE_SELL_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 1,
	GameEnums.Rarity.UNCOMMON: 2,
	GameEnums.Rarity.RARE: 3,
	GameEnums.Rarity.EPIC: 5,
	GameEnums.Rarity.LEGENDARY: 8,
}

# --- Slot Prices by Type ---
const SLOT_BUY_PRICES: Dictionary = {
	"default": 0,  # Can't buy default
	"amplifier": 10,
	"repeater": 15,
	"eternal": 12,
	"merchant": 8,
	"broken": 0,  # Can't buy broken
}

const SLOT_SELL_PRICES: Dictionary = {
	"default": 0,
	"amplifier": 4,
	"repeater": 6,
	"eternal": 5,
	"merchant": 3,
	"broken": 0,
}

# --- Other Costs ---
const REROLL_COST: int = 2
const PANEL_UNLOCK_COST: int = 25
const RELIC_BASE_COST: int = 15

# --- Shop Inventory Sizes ---
const RUNE_SHOP_SIZE: int = 3  # How many runes to show in shop
const SLOT_SHOP_SIZE: int = 2  # How many slots to show in shop
const RELIC_SHOP_SIZE: int = 2  # How many relics to show (placeholder)

# --- Helper Functions ---

static func get_rune_buy_price(rarity: GameEnums.Rarity) -> int:
	return RUNE_BUY_PRICES.get(rarity, 5)


static func get_rune_sell_price(rarity: GameEnums.Rarity, tier: GameEnums.Tier = GameEnums.Tier.TIER_1) -> int:
	var base = RUNE_SELL_PRICES.get(rarity, 1)
	# Bonus for higher tiers
	return base + (tier - 1)


static func get_slot_buy_price(slot_id: String) -> int:
	return SLOT_BUY_PRICES.get(slot_id, 10)


static func get_slot_sell_price(slot_id: String) -> int:
	return SLOT_SELL_PRICES.get(slot_id, 2)
