class_name ShopConfig
extends RefCounted

## Shop configuration - prices, costs, and multipliers for all shop transactions.

# --- Rune Prices by Rarity ---
const RUNE_BUY_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 2,
	GameEnums.Rarity.UNCOMMON: 3,
	GameEnums.Rarity.RARE: 5,
	GameEnums.Rarity.EPIC: 7,
	GameEnums.Rarity.LEGENDARY: 10,
}

const RUNE_SELL_PRICES: Dictionary = {
	GameEnums.Rarity.COMMON: 1,
	GameEnums.Rarity.UNCOMMON: 1,
	GameEnums.Rarity.RARE: 2,
	GameEnums.Rarity.EPIC: 3,
	GameEnums.Rarity.LEGENDARY: 5,
}

# --- Economy Constants ---
const STARTING_MANA: int = 5          # Mana inicial do jogador
const VICTORY_MANA: int = 5           # Mana fixo por vitória
const INTEREST_PER_5: int = 1         # Juros: 1 mana por cada 5 guardados
const MAX_INTEREST: int = 5           # Teto de juros por rodada
const BASE_SCROLL_COST: int = 1       # Custo base do pergaminho (reroll de runas)

# --- Other Costs ---
const UPGRADE_COST: int = 5  # Cost to upgrade 2 runes into 1
const PANEL_UNLOCK_COST: int = 25

# --- Shop Inventory Sizes ---
const RUNE_SHOP_SIZE: int = 3   # Pergaminhos revelam 3 runas
const PIECE_SHOP_SIZE: int = 1  # 1 peça de slot
const MODIFIER_SHOP_SIZE: int = 1  # 1 modificador
const RELIC_SHOP_SIZE: int = 1  # 1 relíquia
const MIN_PIECES_IN_SHOP: int = 1  # Minimum pieces that must be available

# --- Helper Functions ---

static func get_rune_buy_price(rarity: GameEnums.Rarity) -> int:
	return RUNE_BUY_PRICES.get(rarity, 5)


static func get_rune_sell_price(rarity: GameEnums.Rarity, tier: GameEnums.Tier = GameEnums.Tier.TIER_1) -> int:
	var base = RUNE_SELL_PRICES.get(rarity, 1)
	# Bonus for higher tiers
	return base + (tier - 1)


## Get buy price for a slot piece (based on size/count)
static func get_piece_buy_price(piece: SlotPieceData) -> int:
	if piece:
		return 2 * piece.get_slot_count() + 1
	return 3


## Get sell price for a slot piece (based on size/count)
static func get_piece_sell_price(piece: SlotPieceData) -> int:
	if piece:
		return piece.get_slot_count()
	return 1


## Get buy price for a modifier (flat cost)
static func get_modifier_buy_price(modifier: SlotModifierData) -> int:
	return 4


## Get sell price for a modifier (flat cost)
static func get_modifier_sell_price(modifier: SlotModifierData) -> int:
	return 1


## Get buy price for a relic (flat cost)
static func get_relic_buy_price(relic: RelicData) -> int:
	return 10


## Get sell price for a relic (flat cost)
static func get_relic_sell_price(relic: RelicData) -> int:
	return 5
