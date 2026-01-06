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

# --- Slot Piece Prices (uses rarity from the piece data, fallback here) ---
# Temporarily all under 10 for testing
const PIECE_BUY_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 3,
	GameEnums.Rarity.UNCOMMON: 4,
	GameEnums.Rarity.RARE: 5,
	GameEnums.Rarity.EPIC: 6,
	GameEnums.Rarity.LEGENDARY: 8,
}

const PIECE_SELL_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 1,
	GameEnums.Rarity.UNCOMMON: 1,
	GameEnums.Rarity.RARE: 2,
	GameEnums.Rarity.EPIC: 2,
	GameEnums.Rarity.LEGENDARY: 3,
}

# --- Slot Modifier Prices (uses rarity from modifier data, fallback here) ---
# Temporarily all under 10 for testing
const MODIFIER_BUY_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 2,
	GameEnums.Rarity.UNCOMMON: 3,
	GameEnums.Rarity.RARE: 4,
	GameEnums.Rarity.EPIC: 5,
	GameEnums.Rarity.LEGENDARY: 7,
}

const MODIFIER_SELL_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 1,
	GameEnums.Rarity.UNCOMMON: 1,
	GameEnums.Rarity.RARE: 1,
	GameEnums.Rarity.EPIC: 2,
	GameEnums.Rarity.LEGENDARY: 3,
}

# --- Relic Prices ---
# Temporarily all under 10 for testing
const RELIC_BUY_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 4,
	GameEnums.Rarity.UNCOMMON: 5,
	GameEnums.Rarity.RARE: 6,
	GameEnums.Rarity.EPIC: 7,
	GameEnums.Rarity.LEGENDARY: 9,
}

const RELIC_SELL_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 1,
	GameEnums.Rarity.UNCOMMON: 2,
	GameEnums.Rarity.RARE: 2,
	GameEnums.Rarity.EPIC: 3,
	GameEnums.Rarity.LEGENDARY: 4,
}

# --- Other Costs ---
const REROLL_COST: int = 2
const RUNE_PACK_COST: int = 3  # Cost to open a rune pack (pick 1 of 3)
const UPGRADE_COST: int = 5  # Cost to upgrade 2 runes into 1
const PANEL_UNLOCK_COST: int = 25
const RELIC_BASE_COST: int = 15  # Legacy, use RELIC_BUY_PRICES instead

# --- Shop Inventory Sizes ---
const RUNE_SHOP_SIZE: int = 3  # How many runes to show in shop
const PIECE_SHOP_SIZE: int = 2  # How many slot pieces to show
const MODIFIER_SHOP_SIZE: int = 2  # How many modifiers to show
const RELIC_SHOP_SIZE: int = 2  # How many relics to show
const MIN_PIECES_IN_SHOP: int = 1  # Minimum pieces that must be available

# --- Helper Functions ---

static func get_rune_buy_price(rarity: GameEnums.Rarity) -> int:
	return RUNE_BUY_PRICES.get(rarity, 5)


static func get_rune_sell_price(rarity: GameEnums.Rarity, tier: GameEnums.Tier = GameEnums.Tier.TIER_1) -> int:
	var base = RUNE_SELL_PRICES.get(rarity, 1)
	# Bonus for higher tiers
	return base + (tier - 1)


## Get buy price for a slot piece (based on rarity)
static func get_piece_buy_price(piece: SlotPieceData) -> int:
	return PIECE_BUY_PRICES.get(piece.rarity, 10)


## Get sell price for a slot piece (based on rarity)
static func get_piece_sell_price(piece: SlotPieceData) -> int:
	return PIECE_SELL_PRICES.get(piece.rarity, 3)


## Get buy price for a modifier (based on rarity)
static func get_modifier_buy_price(modifier: SlotModifierData) -> int:
	return MODIFIER_BUY_PRICES.get(modifier.rarity, 6)


## Get sell price for a modifier (based on rarity)
static func get_modifier_sell_price(modifier: SlotModifierData) -> int:
	return MODIFIER_SELL_PRICES.get(modifier.rarity, 2)


## Get buy price for a relic (based on rarity)
static func get_relic_buy_price(relic: RelicData) -> int:
	return RELIC_BUY_PRICES.get(relic.rarity, 15)


## Get sell price for a relic (based on rarity)
static func get_relic_sell_price(relic: RelicData) -> int:
	return RELIC_SELL_PRICES.get(relic.rarity, 5)
