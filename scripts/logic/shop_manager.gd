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
var _available_piece_rotations: Array[int] = []  # Rotação de exibição para cada peça na vitrine
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

# --- Elemental & Overclock State ---
var elemental_weights: Dictionary = {
	GameEnums.Element.FIRE: 0.20,
	GameEnums.Element.WATER: 0.20,
	GameEnums.Element.EARTH: 0.20,
	GameEnums.Element.AIR: 0.20,
	GameEnums.Element.SPIRIT: 0.20
}
var overclock_purchased_this_round: bool = false
var relic_refresh_purchased_this_round: bool = false

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
	overclock_purchased_this_round = false
	relic_refresh_purchased_this_round = false
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


func get_piece_display_rotation(index: int) -> int:
	if index < 0 or index >= _available_piece_rotations.size():
		return 0
	return _available_piece_rotations[index]


func _generate_piece_inventory(_player_level: int) -> void:
	available_pieces.clear()
	_available_piece_rotations.clear()
	
	if _piece_pool.is_empty():
		return
	
	# Ensure at least MIN_PIECES_IN_SHOP pieces are generated
	var count = maxi(ShopConfig.PIECE_SHOP_SIZE, ShopConfig.MIN_PIECES_IN_SHOP)
	for i in range(count):
		var piece = _piece_pool[_rng.randi() % _piece_pool.size()]
		available_pieces.append(piece)
		_available_piece_rotations.append(_rng.randi() % 4)


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


## Reset elemental probabilities to a uniform 0.20 weight. Costs 1 Mana and rerolls runes.
func reset_elemental_probabilities() -> bool:
	var cost = 1
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Nao ha mana suficiente para resetar pedestais")
		return false
		
	_spend_money(cost, "pedestal_reset")
	
	elemental_weights = {
		GameEnums.Element.FIRE: 0.20,
		GameEnums.Element.WATER: 0.20,
		GameEnums.Element.EARTH: 0.20,
		GameEnums.Element.AIR: 0.20,
		GameEnums.Element.SPIRIT: 0.20
	}
	
	_generate_rune_inventory(current_level)
	print("[Shop] Elemental probabilities reset to uniform 0.20 and runes rerolled")
	transaction_completed.emit(true, "Pedestais resetados — 1 mana")
	shop_updated.emit()
	return true


## Adjust elemental probabilities using proportional redistribution. Costs 1 Mana and rerolls runes.
func adjust_elemental_probabilities(chosen_element: GameEnums.Element) -> bool:
	var cost = 1
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Nao ha mana suficiente para ajustar pedestal")
		return false
		
	var p_e = elemental_weights.get(chosen_element, 0.20)
	var d = min(0.20, 1.0 - p_e)
	
	_spend_money(cost, "pedestal_adjust_%d" % chosen_element)
	
	if d > 0.0:
		# Sum of probabilities of other elements
		var s = 0.0
		for key in elemental_weights.keys():
			if key != chosen_element:
				s += elemental_weights[key]
		
		for key in elemental_weights.keys():
			if key == chosen_element:
				elemental_weights[key] = p_e + d
			else:
				if s > 0.0:
					elemental_weights[key] = elemental_weights[key] - d * (elemental_weights[key] / s)
				else:
					elemental_weights[key] = 0.0
		
		# Micro normalization to avoid precision errors keeping sum at 1.0
		var total = 0.0
		for val in elemental_weights.values():
			total += val
		if total > 0.0:
			for key in elemental_weights.keys():
				elemental_weights[key] /= total
				
	_generate_rune_inventory(current_level)
	print("[Shop] Probe weight adjusted. New probabilities: ", elemental_weights)
	transaction_completed.emit(true, "Pedestal ajustado — 1 mana")
	shop_updated.emit()
	return true


## Get the current shop instability index based on the maximum elemental weight.
func get_instability_index() -> float:
	var p_max = 0.20
	for val in elemental_weights.values():
		if val > p_max:
			p_max = val
	var inst = (p_max - 0.20) / 0.80
	return clamp(inst, 0.0, 1.0)


## Get the decay factor for a given rarity under current shop instability.
func get_rarity_decay(rarity: GameEnums.Rarity) -> float:
	var i = get_instability_index()
	var d_rarity = 0.0
	match rarity:
		GameEnums.Rarity.COMMON:
			d_rarity = 0.0
		GameEnums.Rarity.UNCOMMON:
			d_rarity = 0.5
		GameEnums.Rarity.RARE:
			d_rarity = 1.0
		GameEnums.Rarity.EPIC:
			d_rarity = 2.0
		GameEnums.Rarity.LEGENDARY:
			d_rarity = 4.0
	return pow(1.0 - i, d_rarity)


## Get weight for a rarity, scaled by player level and decreased by instability decay.
func _get_scaled_weight(rarity: GameEnums.Rarity, player_level: int) -> float:
	var base_weight = 0.0
	var bonus_per_level = 0.0
	var ceiling = 0.0
	match rarity:
		GameEnums.Rarity.COMMON:
			base_weight = 200.0
			bonus_per_level = 0.0
			ceiling = 200.0
		GameEnums.Rarity.UNCOMMON:
			base_weight = 100.0
			bonus_per_level = 2.0
			ceiling = 120.0
		GameEnums.Rarity.RARE:
			base_weight = 50.0
			bonus_per_level = 3.0
			ceiling = 80.0
		GameEnums.Rarity.EPIC:
			base_weight = 50.0
			bonus_per_level = 4.0
			ceiling = 70.0
		GameEnums.Rarity.LEGENDARY:
			base_weight = 10.0
			bonus_per_level = 5.0
			ceiling = 50.0
	
	var base_real = min(base_weight + bonus_per_level * (player_level - 1), ceiling)
	var decay = get_rarity_decay(rarity)
	return base_real * decay


## Pick a random rune using the 4-phase algorithm with elemental weights, instability, and cascade fallback.
func _pick_weighted_rune_from_pool(pool: Array[RuneData], player_level: int) -> RuneData:
	if pool.is_empty():
		return null
	
	# Passo 1: Determinar a Raridade (R_sorteada)
	var active_rarities: Array[GameEnums.Rarity] = []
	var max_rarity = _get_max_rarity_for_level(player_level)
	for r in [GameEnums.Rarity.COMMON, GameEnums.Rarity.UNCOMMON, GameEnums.Rarity.RARE, GameEnums.Rarity.EPIC, GameEnums.Rarity.LEGENDARY]:
		if r <= max_rarity:
			active_rarities.append(r)
	
	var r_sorteada = _draw_rarity(active_rarities, player_level)
	
	# Iniciamos o loop de degradação caso necessário
	var current_rarity = r_sorteada
	
	while true:
		# Fase 1: Vigilância Elemental (até 3 tentativas de sorteio de elemento)
		var tested_elements: Array[GameEnums.Element] = []
		var target_element = -1
		var sub_pool: Array[RuneData] = []
		
		for attempt in range(3):
			# Sorteamos um elemento excluindo os já testados que falharam
			var elements_to_draw: Array[GameEnums.Element] = []
			for el in GameEnums.Element.values():
				if not el in tested_elements:
					elements_to_draw.append(el)
			
			if elements_to_draw.is_empty():
				break
			
			target_element = _draw_element_with_weights(elements_to_draw)
			if target_element == -1:
				break
				
			tested_elements.append(target_element as GameEnums.Element)
			
			# Monta sub-pool para a raridade atual e elemento atual
			sub_pool.clear()
			for rune in pool:
				if rune.rarity == current_rarity and target_element in rune.elements:
					sub_pool.append(rune)
			
			if not sub_pool.is_empty():
				# Encontrado! Seleção uniforme simples
				return sub_pool[_rng.randi() % sub_pool.size()]
		
		# Fase 2: Elasticidade Elemental
		# Despreza o elemento e cria-se o sub-pool puramente com base na raridade atual
		sub_pool.clear()
		for rune in pool:
			if rune.rarity == current_rarity:
				sub_pool.append(rune)
				
		if not sub_pool.is_empty():
			return sub_pool[_rng.randi() % sub_pool.size()]
			
		# Fase 3: Degradação progressiva
		if current_rarity > GameEnums.Rarity.COMMON:
			var values_list = GameEnums.Rarity.values()
			# Rebaixa a raridade
			var next_r_index = values_list.find(current_rarity) - 1
			if next_r_index >= 0:
				current_rarity = values_list[next_r_index]
				# Reinicia o loop com a nova raridade
				continue
		
		# Se chegamos aqui, mesmo em COMMON não achamos nada com as regras acima.
		break
	
	# Fallback absoluto de emergência: qualquer runa do pool
	return pool[_rng.randi() % pool.size()]


func _draw_rarity(active_rarities: Array[GameEnums.Rarity], player_level: int) -> GameEnums.Rarity:
	var total_w = 0.0
	var r_weights: Array[float] = []
	for r in active_rarities:
		var w = _get_scaled_weight(r, player_level)
		r_weights.append(w)
		total_w += w
	
	if total_w <= 0.0:
		return active_rarities[0]
	
	var roll = _rng.randf() * total_w
	var current_w = 0.0
	for i in range(active_rarities.size()):
		current_w += r_weights[i]
		if roll <= current_w:
			return active_rarities[i]
	return active_rarities[0]


func _draw_element_with_weights(elements_to_draw_from: Array[GameEnums.Element]) -> int:
	var total_w = 0.0
	var e_weights: Array[float] = []
	for e in elements_to_draw_from:
		var w = elemental_weights.get(e, 0.20)
		e_weights.append(w)
		total_w += w
	
	if total_w <= 0.0:
		return -1
	
	var roll = _rng.randf() * total_w
	var current_w = 0.0
	for i in range(elements_to_draw_from.size()):
		current_w += e_weights[i]
		if roll <= current_w:
			return elements_to_draw_from[i]
	return elements_to_draw_from[0]


## Buy Overclock on the machinery: costs 1 Mana, yields 1 defective slot piece and 1 anomalous modifier.
func buy_overclock() -> bool:
	if overclock_purchased_this_round:
		transaction_completed.emit(false, "Overclock already purchased this round")
		return false
	
	var cost = 1
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Not enough mana for Overclock")
		return false
	
	if _piece_pool.is_empty():
		transaction_completed.emit(false, "No pieces in pool")
		return false
	
	_spend_money(cost, "overclock_machinery")
	overclock_purchased_this_round = true
	
	# Draw one Slot Piece, duplicate, set metadata and rename
	var base_piece = _piece_pool[_rng.randi() % _piece_pool.size()]
	var defective_piece = base_piece.duplicate() as SlotPieceData
	defective_piece.set_meta("can_receive_modifiers", false)
	defective_piece.display_name = "Defective " + defective_piece.display_name
	available_pieces.append(defective_piece)
	_available_piece_rotations.append(_rng.randi() % 4)
	
	# Sortear um modificador real do pool (com slot_data_override) e combinar com flag anômalo
	# Resulta em: "Anômalo Igniter", "Anômalo Resonator", etc.
	var candidates: Array[SlotModifierData] = []
	for mod in _modifier_pool:
		if mod.slot_data_override and not mod.is_anomalous:
			candidates.append(mod)
	
	var anomalous_modifier: SlotModifierData = null
	if not candidates.is_empty():
		var base_mod = candidates[_rng.randi() % candidates.size()]
		anomalous_modifier = base_mod.duplicate() as SlotModifierData
		anomalous_modifier.is_anomalous = true
		anomalous_modifier.id = "anomalous_" + base_mod.id
		anomalous_modifier.display_name = "Anômalo " + base_mod.display_name
		# Mantém descrição original; o tooltip builder adiciona a parte do anômalo
	elif not _modifier_pool.is_empty():
		# Fallback: qualquer modifier do pool marcado como anômalo
		anomalous_modifier = _modifier_pool[_rng.randi() % _modifier_pool.size()].duplicate() as SlotModifierData
		anomalous_modifier.is_anomalous = true
		anomalous_modifier.id = "anomalous_" + anomalous_modifier.id
		anomalous_modifier.display_name = "Anômalo " + anomalous_modifier.display_name
	
	if anomalous_modifier:
		available_modifiers.append(anomalous_modifier)
		
	print("[Shop] Overclock purchased! Defective piece and Anomalous modifier added.")
	transaction_completed.emit(true, "Overclock purchased for 1 mana")
	shop_updated.emit()
	return true


## Refresh/Reroll the offered relic: costs 1 Mana, limited to 1x per round.
func reroll_relic() -> bool:
	if relic_refresh_purchased_this_round:
		transaction_completed.emit(false, "Permitido apenas 1 reroll de reliquia por rodada")
		return false
		
	var cost = 1
	if not _can_afford(cost):
		insufficient_funds.emit(cost, _get_money())
		transaction_completed.emit(false, "Nao ha mana suficiente para reroll de reliquia")
		return false
		
	_spend_money(cost, "relic_reroll")
	relic_refresh_purchased_this_round = true
	
	_generate_relic_inventory(current_level)
	
	print("[Shop] Relic rerolled successfully")
	transaction_completed.emit(true, "Relic rerolled for 1 mana")
	shop_updated.emit()
	return true


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
	var display_rotation = _available_piece_rotations[index] if index < _available_piece_rotations.size() else 0
	available_pieces.remove_at(index)
	if index < _available_piece_rotations.size():
		_available_piece_rotations.remove_at(index)
	
	# Create instance com a rotação exibida na vitrine
	var piece_instance = SlotPieceInstance.new(piece_data)
	piece_instance.current_rotation = display_rotation
	
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
