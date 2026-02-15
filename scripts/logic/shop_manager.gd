class_name ShopManager
extends Node

## Manages all shop transactions and inventory.
## Handles buying, selling, upgrading, and scroll rerolls.
## Sells: Runes, Slot Pieces, Slot Modifiers, Relics

signal shop_updated  # Emitted when shop inventory changes
signal transaction_completed(success: bool, message: String)
signal insufficient_funds(cost: int, balance: int)
signal free_pick_available(count: int)  # Emitted when free picks are available

# --- Shop Inventory ---
var available_runes: Array[RuneData] = []
var available_pieces: Array[SlotPieceData] = []
var available_modifiers: Array[SlotModifierData] = []
var available_relics: Array[RelicData] = []

# --- Resource Pools (all loaded resources) ---
var _rune_pool: Array[RuneData] = []
var _piece_pool: Array[SlotPieceData] = []
var _modifier_pool: Array[SlotModifierData] = []
var _relic_pool: Array[RelicData] = []
var _drop_rates: RuneDropRates = null

# --- Upgrade Pending ---
var _upgrade_slot_1: RuneInstance = null
var _upgrade_slot_2: RuneInstance = null

# --- Free Picks & Level Tracking ---
var free_rune_picks: int = 0  # Number of free rune picks available
var current_level: int = 1

# --- Scroll (Pergaminho) State ---
var _scroll_count: int = 0  # Scrolls purchased this round (resets each round)

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
	_load_rune_pool()
	_load_piece_pool()
	_load_modifier_pool()
	_load_relic_pool()
	_load_drop_rates()


func _load_drop_rates() -> void:
	var drop_rates_path = "res://resources/runes/drop_rates.tres"
	if ResourceLoader.exists(drop_rates_path):
		_drop_rates = load(drop_rates_path) as RuneDropRates


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
				if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
					var rune_path = folder_path + file_name.replace(".remap", "")
					var rune_data = load(rune_path) as RuneData
					if rune_data and rune_data.tier == GameEnums.Tier.TIER_1:
						_rune_pool.append(rune_data)
				file_name = dir.get_next()
			dir.list_dir_end()


func _load_piece_pool() -> void:
	_piece_pool.clear()
	var piece_dir = "res://resources/slot_pieces/"
	var dir = DirAccess.open(piece_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				var piece_data = load(piece_dir + file_name.replace(".remap", "")) as SlotPieceData
				if piece_data:
					_piece_pool.append(piece_data)
			file_name = dir.get_next()
		dir.list_dir_end()


func _load_modifier_pool() -> void:
	_modifier_pool.clear()
	var modifier_dir = "res://resources/slot_modifiers/"
	var dir = DirAccess.open(modifier_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var clean_name = file_name.replace(".remap", "")
			if clean_name.ends_with(".tres") and clean_name.begins_with("slot_"):
				var modifier_data = load(modifier_dir + clean_name) as SlotModifierData
				if modifier_data and modifier_data.id.begins_with("slot_"):
					_modifier_pool.append(modifier_data)
			file_name = dir.get_next()
		dir.list_dir_end()


func _load_relic_pool() -> void:
	_relic_pool.clear()
	var relic_dir = "res://resources/relics/"
	var dir = DirAccess.open(relic_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				var relic_data = load(relic_dir + file_name.replace(".remap", "")) as RelicData
				if relic_data:
					_relic_pool.append(relic_data)
			file_name = dir.get_next()
		dir.list_dir_end()


## Initialize shop with fresh inventory (called at start of each round)
func refresh_shop(player_level: int = 1) -> void:
	current_level = player_level
	reset_scroll_count()
	_generate_rune_inventory(player_level)
	_generate_piece_inventory(player_level)
	_generate_modifier_inventory(player_level)
	_generate_relic_inventory(player_level)
	print("[Shop] Refreshed: %d runes, %d pieces, %d modifiers, %d relics" % [
		available_runes.size(), available_pieces.size(),
		available_modifiers.size(), available_relics.size()
	])
	shop_updated.emit()


## Get the current scroll (pergaminho) cost: base + number already purchased
func get_current_scroll_cost() -> int:
	return ShopConfig.BASE_SCROLL_COST + _scroll_count


## Reset scroll counter (called at start of each round)
func reset_scroll_count() -> void:
	_scroll_count = 0


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


## Buy a scroll (pergaminho) — escalating cost, only refreshes runes
func buy_scroll() -> bool:
	var cost = get_current_scroll_cost()
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough mana for scroll")
		return false
	
	_spend_money(cost, "scroll_%d" % (_scroll_count + 1))
	_scroll_count += 1
	
	# Only regenerate runes, not pieces/modifiers/relics
	_generate_rune_inventory(current_level)
	
	print("[Shop] Scroll #%d purchased for %d mana" % [_scroll_count, cost])
	transaction_completed.emit(true, "Scroll #%d — %d mana" % [_scroll_count, cost])
	shop_updated.emit()
	return true


## Buy a rune pack (uses scroll cost system)
func buy_rune_pack() -> bool:
	return buy_scroll()


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


func _generate_piece_inventory(_player_level: int) -> void:
	available_pieces.clear()
	
	if _piece_pool.is_empty():
		return
	
	# Ensure at least MIN_PIECES_IN_SHOP pieces are generated
	var count = maxi(ShopConfig.PIECE_SHOP_SIZE, ShopConfig.MIN_PIECES_IN_SHOP)
	for i in range(count):
		var piece = _piece_pool[_rng.randi() % _piece_pool.size()]
		available_pieces.append(piece)


func _generate_modifier_inventory(_player_level: int) -> void:
	available_modifiers.clear()
	
	if _modifier_pool.is_empty():
		return
	
	for i in range(ShopConfig.MODIFIER_SHOP_SIZE):
		var modifier = _modifier_pool[_rng.randi() % _modifier_pool.size()]
		available_modifiers.append(modifier)


func _generate_relic_inventory(_player_level: int) -> void:
	available_relics.clear()
	
	if _relic_pool.is_empty():
		return
	
	for i in range(ShopConfig.RELIC_SHOP_SIZE):
		var relic = _relic_pool[_rng.randi() % _relic_pool.size()]
		available_relics.append(relic)


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
		transaction_completed.emit(false, "Not enough mana")
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
	
	var message = "Took %s (FREE!)" % rune_data.rune_name if is_free else "Bought %s for %d mana" % [rune_data.rune_name, cost]
	transaction_completed.emit(true, message)
	shop_updated.emit()
	
	return rune_instance


## Buy a slot piece from the shop
func buy_piece(index: int) -> SlotPieceInstance:
	if index < 0 or index >= available_pieces.size():
		transaction_completed.emit(false, "Invalid piece index")
		return null
	
	var piece_data = available_pieces[index]
	var cost = ShopConfig.get_piece_buy_price(piece_data)
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough mana")
		return null
	
	# Deduct money
	_spend_money(cost, "shop_piece_%s" % piece_data.id)
	
	# Remove from shop
	available_pieces.remove_at(index)
	
	# Create instance
	var piece_instance = SlotPieceInstance.new(piece_data)
	
	transaction_completed.emit(true, "Bought %s for %d mana" % [piece_data.display_name, cost])
	shop_updated.emit()
	
	return piece_instance


## Buy a slot modifier from the shop
func buy_modifier(index: int) -> SlotModifierData:
	if index < 0 or index >= available_modifiers.size():
		transaction_completed.emit(false, "Invalid modifier index")
		return null
	
	var modifier_data = available_modifiers[index]
	var cost = ShopConfig.get_modifier_buy_price(modifier_data)
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough mana")
		return null
	
	# Deduct money
	_spend_money(cost, "shop_modifier_%s" % modifier_data.id)
	
	# Remove from shop
	available_modifiers.remove_at(index)
	
	transaction_completed.emit(true, "Bought %s for %d mana" % [modifier_data.display_name, cost])
	shop_updated.emit()
	
	# Return the data directly (modifiers are applied, not instantiated)
	return modifier_data


## Buy a relic from the shop
func buy_relic(index: int) -> RelicInstance:
	if index < 0 or index >= available_relics.size():
		transaction_completed.emit(false, "Invalid relic index")
		return null
	
	var relic_data = available_relics[index]
	var cost = ShopConfig.get_relic_buy_price(relic_data)
	
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough mana")
		return null
	
	_spend_money(cost, "shop_relic_%s" % relic_data.id)
	
	# Remove from shop
	available_relics.remove_at(index)
	
	# Create instance
	var relic_instance = RelicInstance.new(relic_data)
	
	transaction_completed.emit(true, "Bought %s for %d mana" % [relic_data.display_name, cost])
	shop_updated.emit()
	
	return relic_instance


# --- Sell Operations ---

## Sell a rune
func sell_rune(rune: RuneInstance) -> int:
	if not rune or not rune.data:
		transaction_completed.emit(false, "Invalid rune")
		return 0
	
	var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
	_add_money(price, "sell_rune_%s" % rune.data.id)
	
	transaction_completed.emit(true, "Sold %s for %d mana" % [rune.data.rune_name, price])
	return price


## Sell a slot piece
func sell_piece(piece: SlotPieceInstance) -> int:
	if not piece or not piece.data:
		transaction_completed.emit(false, "Invalid piece")
		return 0
	
	var price = ShopConfig.get_piece_sell_price(piece.data)
	_add_money(price, "sell_piece_%s" % piece.data.id)
	
	transaction_completed.emit(true, "Sold %s for %d mana" % [piece.data.display_name, price])
	return price


## Sell a modifier (if player has it in inventory)
func sell_modifier(modifier: SlotModifierData) -> int:
	if not modifier:
		transaction_completed.emit(false, "Invalid modifier")
		return 0
	
	var price = ShopConfig.get_modifier_sell_price(modifier)
	_add_money(price, "sell_modifier_%s" % modifier.id)
	
	transaction_completed.emit(true, "Sold %s for %d mana" % [modifier.display_name, price])
	return price


## Sell a relic
func sell_relic(relic: RelicInstance) -> int:
	if not relic or not relic.data:
		transaction_completed.emit(false, "Invalid relic")
		return 0
	
	var price = ShopConfig.get_relic_sell_price(relic.data)
	_add_money(price, "sell_relic_%s" % relic.data.id)
	
	transaction_completed.emit(true, "Sold %s for %d mana" % [relic.data.display_name, price])
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
		transaction_completed.emit(false, "Not enough mana to upgrade")
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
	
	transaction_completed.emit(true, "Upgraded 2x %s into %s for %d mana!" % [consumed_name, upgraded_data.rune_name, cost])
	
	return upgraded_rune


func _check_upgrade_compatibility() -> void:
	# This could emit a signal to update UI with compatibility status
	pass


# --- Scroll (replaces legacy Reroll) ---

## Buy a scroll to reroll rune inventory only (legacy compat wrapper)
func reroll_shop(player_level: int = 1) -> bool:
	current_level = player_level
	return buy_scroll()


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
	return "%d Mana" % price


func get_piece_price_display(piece_data: SlotPieceData) -> String:
	var price = ShopConfig.get_piece_buy_price(piece_data)
	return "%d Mana" % price


func get_modifier_price_display(modifier_data: SlotModifierData) -> String:
	var price = ShopConfig.get_modifier_buy_price(modifier_data)
	return "%d Mana" % price


func get_relic_price_display(relic_data: RelicData) -> String:
	var price = ShopConfig.get_relic_buy_price(relic_data)
	return "%d Mana" % price


func get_scroll_price_display() -> String:
	return "Pergaminho\n%d Mana" % get_current_scroll_cost()
