class_name ShopManager
extends Node

## Manages all shop transactions and inventory.
## Handles buying, selling, upgrading, and rerolling.

signal shop_updated  # Emitted when shop inventory changes
signal transaction_completed(success: bool, message: String)
signal insufficient_funds(cost: int, balance: int)
signal free_pick_available(count: int)  # Emitted when free picks are available

# --- Shop Inventory ---
var available_runes: Array[RuneData] = []
var available_slots: Array[SlotData] = []
var available_relics: Array = []  # Placeholder - will be RelicData when implemented

# --- References ---
var _drop_rates: RuneDropRates
var _slot_data_cache: Dictionary = {}  # slot_id -> SlotData
var _rune_pool: Array[RuneData] = []  # All available runes for shop

# --- Upgrade Pending ---
var _upgrade_slot_1: RuneInstance = null
var _upgrade_slot_2: RuneInstance = null

# --- Free Picks & Level Tracking ---
var free_rune_picks: int = 0  # Number of free rune picks available
var current_level: int = 1

# --- Seed Control ---
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_seed: int = 0


func _ready() -> void:
	_load_resources()
	_initialize_seed()


func _initialize_seed() -> void:
	# Use current time as default seed, can be set externally for reproducible runs
	set_seed(Time.get_unix_time_from_system() as int)


## Set the random seed for reproducible shop generation
func set_seed(new_seed: int) -> void:
	_current_seed = new_seed
	_rng.seed = new_seed


## Get the current seed (for saving/loading)
func get_seed() -> int:
	return _current_seed


func _load_resources() -> void:
	# Load drop rates for rune generation
	_drop_rates = load("res://resources/runes/drop_rates.tres") as RuneDropRates
	
	# Load all runes for shop pool
	_load_rune_pool()
	
	# Cache slot data
	var slot_dir = "res://resources/slots/"
	var dir = DirAccess.open(slot_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var slot_data = load(slot_dir + file_name) as SlotData
				if slot_data:
					_slot_data_cache[slot_data.id] = slot_data
			file_name = dir.get_next()
		dir.list_dir_end()


func _load_rune_pool() -> void:
	_rune_pool.clear()
	var rune_folders = [
		"res://resources/runes/common/",
		"res://resources/runes/uncommon/",
		"res://resources/runes/rare/",
		"res://resources/runes/epic/",
		"res://resources/runes/legendary/"
	]
	
	for folder_path in rune_folders:
		var dir = DirAccess.open(folder_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var rune_path = folder_path + file_name
					var rune_data = load(rune_path) as RuneData
					if rune_data and rune_data.tier == GameEnums.Tier.TIER_1:
						_rune_pool.append(rune_data)
				file_name = dir.get_next()
			dir.list_dir_end()


## Initialize shop with fresh inventory
func refresh_shop(player_level: int = 1) -> void:
	current_level = player_level
	_generate_rune_inventory(player_level)
	_generate_slot_inventory()
	_generate_relic_inventory()
	shop_updated.emit()


## Grant a free rune pick (used at start or as reward)
func grant_free_pick(count: int = 1) -> void:
	free_rune_picks += count
	free_pick_available.emit(free_rune_picks)


## Check if player has free picks available
func has_free_pick() -> bool:
	return free_rune_picks > 0


# --- Rune Pack System ---
var _rune_pack_options: Array[RuneData] = []  # Current rune pack offerings


## Generate a pack of 3 random runes for the player to choose from
func generate_rune_pack() -> Array[RuneData]:
	_rune_pack_options.clear()
	
	var level_pool = _get_level_filtered_pool(current_level)
	if level_pool.is_empty():
		return _rune_pack_options
	
	for i in range(3):
		var rune_data = _pick_weighted_rune_from_pool(level_pool, current_level)
		if rune_data:
			_rune_pack_options.append(rune_data)
	
	return _rune_pack_options


## Buy a rune pack (costs money, enables picking one rune)
func buy_rune_pack() -> bool:
	var cost = ShopConfig.RUNE_PACK_COST if "RUNE_PACK_COST" in ShopConfig else ShopConfig.REROLL_COST
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money for rune pack")
		return false
	
	_spend_money(cost, "rune_pack")
	transaction_completed.emit(true, "Rune pack opened for $%d" % cost)
	return true


## Pick one rune from the current rune pack
func pick_from_rune_pack(index: int) -> RuneInstance:
	if index < 0 or index >= _rune_pack_options.size():
		transaction_completed.emit(false, "Invalid rune pack selection")
		return null
	
	var rune_data = _rune_pack_options[index]
	
	# Use free pick if available
	if free_rune_picks > 0:
		free_rune_picks -= 1
		free_pick_available.emit(free_rune_picks)
	
	# Clear pack options
	_rune_pack_options.clear()
	
	# Create instance
	var rune_instance = RuneInstance.new(rune_data)
	transaction_completed.emit(true, "Picked %s from rune pack!" % rune_data.rune_name)
	
	return rune_instance


func _generate_rune_inventory(player_level: int) -> void:
	available_runes.clear()
	
	if _rune_pool.is_empty():
		push_warning("ShopManager: No runes in pool")
		return
	
	# Filter pool based on level - higher levels unlock rarer runes
	var level_pool = _get_level_filtered_pool(player_level)
	
	for i in range(ShopConfig.RUNE_SHOP_SIZE):
		var rune_data = _pick_weighted_rune_from_pool(level_pool, player_level)
		if rune_data:
			available_runes.append(rune_data)


## Get rune pool filtered by level restrictions
func _get_level_filtered_pool(player_level: int) -> Array[RuneData]:
	var filtered: Array[RuneData] = []
	var max_rarity = _get_max_rarity_for_level(player_level)
	
	for rune in _rune_pool:
		if rune.rarity <= max_rarity:
			filtered.append(rune)
	
	return filtered


## Determine maximum rarity available at a given level
func _get_max_rarity_for_level(player_level: int) -> GameEnums.Rarity:
	# Level 1-2: Up to Uncommon (uncommon available from start)
	# Level 3-4: Up to Rare
	# Level 5-6: Up to Epic
	# Level 7+: All including Legendary
	if player_level <= 2:
		return GameEnums.Rarity.UNCOMMON
	elif player_level <= 4:
		return GameEnums.Rarity.RARE
	elif player_level <= 6:
		return GameEnums.Rarity.EPIC
	else:
		return GameEnums.Rarity.LEGENDARY


## Pick a random rune using weighted probabilities adjusted by level
func _pick_weighted_rune_from_pool(pool: Array[RuneData], player_level: int) -> RuneData:
	if pool.is_empty():
		return null
	
	# Calculate weights with level scaling
	var total_weight = 0
	var weights: Array[int] = []
	
	for rune in pool:
		var weight = _get_scaled_weight(rune.rarity, player_level)
		weights.append(weight)
		total_weight += weight
	
	if total_weight == 0:
		return pool[_rng.randi() % pool.size()]
	
	# Roll and pick using seeded RNG
	var roll = _rng.randi() % total_weight
	var current_weight = 0
	for i in range(pool.size()):
		current_weight += weights[i]
		if roll < current_weight:
			return pool[i]
	
	return pool[0]


## Get weight for a rarity, scaled by player level
## Higher levels increase weight of rarer items
func _get_scaled_weight(rarity: GameEnums.Rarity, player_level: int) -> int:
	if not _drop_rates:
		return 10
	
	var base_weight = _drop_rates.get_weight(rarity)
	
	# Level scaling: each level adds bonus weight to rarer items
	var rarity_bonus_per_level = {
		GameEnums.Rarity.COMMON: 0,      # Common doesn't scale up
		GameEnums.Rarity.UNCOMMON: 2,    # +2 per level
		GameEnums.Rarity.RARE: 3,        # +3 per level
		GameEnums.Rarity.EPIC: 4,        # +4 per level
		GameEnums.Rarity.LEGENDARY: 5,   # +5 per level
	}
	
	var bonus = rarity_bonus_per_level.get(rarity, 0) * (player_level - 1)
	return base_weight + bonus


## Pick a random rune using weighted probabilities (legacy, uses current level)
func _pick_weighted_rune() -> RuneData:
	var pool = _get_level_filtered_pool(current_level)
	return _pick_weighted_rune_from_pool(pool, current_level)


func _generate_slot_inventory() -> void:
	available_slots.clear()
	
	# Available slot types for purchase (exclude default and broken)
	var purchasable_slots = ["amplifier", "repeater", "eternal", "merchant"]
	
	for i in range(ShopConfig.SLOT_SHOP_SIZE):
		var random_id = purchasable_slots[_rng.randi() % purchasable_slots.size()]
		if _slot_data_cache.has(random_id):
			available_slots.append(_slot_data_cache[random_id])


func _generate_relic_inventory() -> void:
	available_relics.clear()
	# Placeholder - relics not implemented yet
	for i in range(ShopConfig.RELIC_SHOP_SIZE):
		available_relics.append({"id": "placeholder_relic_%d" % i, "name": "Relic %d" % (i + 1)})


# --- Buy Operations ---

## Buy a rune from the shop (or take for free if free picks available)
func buy_rune(index: int) -> RuneInstance:
	if index < 0 or index >= available_runes.size():
		transaction_completed.emit(false, "Invalid rune index")
		return null
	
	var rune_data = available_runes[index]
	var is_free = free_rune_picks > 0
	var cost = 0 if is_free else ShopConfig.get_rune_buy_price(rune_data.rarity)
	
	if not is_free and not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money")
		return null
	
	# Deduct money or free pick
	if is_free:
		free_rune_picks -= 1
		free_pick_available.emit(free_rune_picks)
	else:
		_spend_money(cost, "shop_rune_%s" % rune_data.id)
	
	# Remove from shop
	available_runes.remove_at(index)
	
	# Create instance
	var rune_instance = RuneInstance.new(rune_data)
	
	var message = "Took %s (FREE!)" % rune_data.rune_name if is_free else "Bought %s for $%d" % [rune_data.rune_name, cost]
	transaction_completed.emit(true, message)
	shop_updated.emit()
	
	return rune_instance


## Buy a slot from the shop
func buy_slot(index: int) -> SlotInstance:
	if index < 0 or index >= available_slots.size():
		transaction_completed.emit(false, "Invalid slot index")
		return null
	
	var slot_data = available_slots[index]
	var cost = ShopConfig.get_slot_buy_price(slot_data.id)
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money")
		return null
	
	# Deduct money
	_spend_money(cost, "shop_slot_%s" % slot_data.id)
	
	# Remove from shop
	available_slots.remove_at(index)
	
	# Create instance
	var slot_instance = SlotInstance.new(slot_data)
	
	transaction_completed.emit(true, "Bought %s for $%d" % [slot_data.slot_name, cost])
	shop_updated.emit()
	
	return slot_instance


## Buy a relic (placeholder)
func buy_relic(index: int) -> Dictionary:
	if index < 0 or index >= available_relics.size():
		transaction_completed.emit(false, "Invalid relic index")
		return {}
	
	var cost = ShopConfig.RELIC_BASE_COST
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money")
		return {}
	
	_spend_money(cost, "shop_relic")
	
	var relic = available_relics[index]
	available_relics.remove_at(index)
	
	transaction_completed.emit(true, "Bought relic for $%d" % cost)
	shop_updated.emit()
	
	return relic


# --- Sell Operations ---

## Sell a rune
func sell_rune(rune: RuneInstance) -> int:
	if not rune or not rune.data:
		transaction_completed.emit(false, "Invalid rune")
		return 0
	
	var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
	_add_money(price, "sell_rune_%s" % rune.data.id)
	
	transaction_completed.emit(true, "Sold %s for $%d" % [rune.data.rune_name, price])
	return price


## Sell a slot
func sell_slot(slot: SlotInstance) -> int:
	if not slot or not slot.data:
		transaction_completed.emit(false, "Invalid slot")
		return 0
	
	var price = ShopConfig.get_slot_sell_price(slot.data.id)
	_add_money(price, "sell_slot_%s" % slot.data.id)
	
	transaction_completed.emit(true, "Sold %s for $%d" % [slot.data.slot_name, price])
	return price


# --- Upgrade System (2 identical runes) ---

## Set first rune for upgrade
func set_upgrade_rune_1(rune: RuneInstance) -> void:
	_upgrade_slot_1 = rune
	_check_upgrade_compatibility()


## Set second rune for upgrade
func set_upgrade_rune_2(rune: RuneInstance) -> void:
	_upgrade_slot_2 = rune
	_check_upgrade_compatibility()


## Clear upgrade slots
func clear_upgrade_slots() -> void:
	_upgrade_slot_1 = null
	_upgrade_slot_2 = null


## Check if current upgrade combination is valid
func can_upgrade() -> bool:
	if not _upgrade_slot_1 or not _upgrade_slot_2:
		return false
	
	# Must be same rune type (same data id)
	if _upgrade_slot_1.data.id != _upgrade_slot_2.data.id:
		return false
	
	# Must have an upgrade path
	if not _upgrade_slot_1.data.upgrades_to:
		return false
	
	return true


## Perform the upgrade - consumes both runes, returns upgraded rune
func perform_upgrade() -> RuneInstance:
	if not can_upgrade():
		transaction_completed.emit(false, "Cannot upgrade - runes don't match or no upgrade available")
		return null
	
	# Check if player can afford the upgrade
	var cost = ShopConfig.UPGRADE_COST
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money to upgrade")
		return null
	
	# Charge the upgrade cost
	_spend_money(cost, "upgrade_rune")
	
	# Remove the consumed runes from inventory
	var inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager")
	if inventory_manager:
		inventory_manager.remove_rune(_upgrade_slot_1)
		inventory_manager.remove_rune(_upgrade_slot_2)
	
	var upgraded_data = _upgrade_slot_1.data.upgrades_to
	var upgraded_rune = RuneInstance.new(upgraded_data)
	
	# Clear the slots
	var consumed_name = _upgrade_slot_1.data.rune_name
	_upgrade_slot_1 = null
	_upgrade_slot_2 = null
	
	transaction_completed.emit(true, "Upgraded 2x %s into %s for $%d!" % [consumed_name, upgraded_data.rune_name, cost])
	
	return upgraded_rune


func _check_upgrade_compatibility() -> void:
	# This could emit a signal to update UI with compatibility status
	pass


# --- Reroll ---

## Reroll the shop inventory
func reroll_shop(player_level: int = 1) -> bool:
	var cost = ShopConfig.REROLL_COST
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money to reroll")
		return false
	
	_spend_money(cost, "shop_reroll")
	refresh_shop(player_level)
	
	transaction_completed.emit(true, "Shop rerolled for $%d" % cost)
	return true


# --- Panel Unlock (Placeholder) ---

func unlock_new_panel() -> bool:
	var cost = ShopConfig.PANEL_UNLOCK_COST
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough money to unlock panel")
		return false
	
	_spend_money(cost, "panel_unlock")
	
	# TODO: Actually unlock a panel when panel system is implemented
	transaction_completed.emit(true, "New panel unlocked! (placeholder)")
	return true


# --- Money Helpers ---

func _get_money() -> int:
	var stats = get_node_or_null("/root/Stats")
	return stats.get_money() if stats else 0


func _can_afford(cost: int) -> bool:
	return _get_money() >= cost


func _spend_money(amount: int, source: String) -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var stats = get_node_or_null("/root/Stats")
		var balance = stats.get_money() if stats else 0
		var event = EconomyEvent.new()
		event.transaction_type = EconomyEvent.TransactionType.SHOP_PURCHASE
		event.source = StringName(source)
		event.amount = -amount
		event.balance_before = balance
		event.balance_after = balance - amount
		event_bus.emit(event)


func _add_money(amount: int, source: String) -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var stats = get_node_or_null("/root/Stats")
		var balance = stats.get_money() if stats else 0
		var event = EconomyEvent.new()
		event.transaction_type = EconomyEvent.TransactionType.SHOP_SELL
		event.source = StringName(source)
		event.amount = amount
		event.balance_before = balance
		event.balance_after = balance + amount
		event_bus.emit(event)


# --- Price Display Helpers ---

func get_rune_price_display(rune_data: RuneData) -> String:
	var price = ShopConfig.get_rune_buy_price(rune_data.rarity)
	return "$%d" % price


func get_slot_price_display(slot_data: SlotData) -> String:
	var price = ShopConfig.get_slot_buy_price(slot_data.id)
	return "$%d" % price
