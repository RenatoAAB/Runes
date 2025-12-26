class_name ShopUI
extends Control

## UI for the shop scene.
## Contains sections for: Buy Runes, Buy Slots, Upgrade, Sell, Relics (placeholder), Panels (placeholder)

signal rune_purchased(rune: RuneInstance)
signal slot_purchased(slot: SlotInstance)
signal rune_sold(rune: RuneInstance)
signal slot_sold(slot: SlotInstance)
signal upgrade_completed(new_rune: RuneInstance)
signal view_panel_requested
signal shop_closed

# --- References ---
@export var shop_manager: ShopManager

# --- UI Sections ---
@export_group("Money Display")
@export var money_label: Label

@export_group("Rune Shop")
@export var rune_shop_container: HBoxContainer
@export var reroll_button: Button

@export_group("Slot Shop")
@export var slot_shop_container: HBoxContainer

@export_group("Upgrade Section")
@export var upgrade_slot_1: Control  # Will hold a SlotUI for drag-drop
@export var upgrade_slot_2: Control
@export var upgrade_result_label: Label
@export var upgrade_button: Button

@export_group("Sell Section")
@export var sell_zone: Control  # Drop zone for selling

@export_group("Relics (Placeholder)")
@export var relic_container: HBoxContainer

@export_group("Panel Unlock")
@export var panel_unlock_button: Button
@export var view_panel_button: Button

# --- Internal State ---
var _rune_shop_items: Array[Control] = []
var _slot_shop_items: Array[Control] = []
var _upgrade_rune_1: RuneInstance = null
var _upgrade_rune_2: RuneInstance = null


func _ready() -> void:
	_connect_signals()
	_setup_ui()


func _connect_signals() -> void:
	if shop_manager:
		if not shop_manager.shop_updated.is_connected(_on_shop_updated):
			shop_manager.shop_updated.connect(_on_shop_updated)
		if not shop_manager.transaction_completed.is_connected(_on_transaction_completed):
			shop_manager.transaction_completed.connect(_on_transaction_completed)
		if not shop_manager.insufficient_funds.is_connected(_on_insufficient_funds):
			shop_manager.insufficient_funds.connect(_on_insufficient_funds)
		if not shop_manager.free_pick_available.is_connected(_on_free_pick_changed):
			shop_manager.free_pick_available.connect(_on_free_pick_changed)
	
	if reroll_button and not reroll_button.pressed.is_connected(_on_reroll_pressed):
		reroll_button.pressed.connect(_on_reroll_pressed)
	
	if upgrade_button and not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	
	if panel_unlock_button and not panel_unlock_button.pressed.is_connected(_on_panel_unlock_pressed):
		panel_unlock_button.pressed.connect(_on_panel_unlock_pressed)
	
	if view_panel_button and not view_panel_button.pressed.is_connected(_on_view_panel_pressed):
		view_panel_button.pressed.connect(_on_view_panel_pressed)
	
	# Connect to economy updates
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("economy_transaction"):
		if not event_bus.economy_transaction.is_connected(_on_economy_changed):
			event_bus.economy_transaction.connect(_on_economy_changed)


func _on_free_pick_changed(_count: int) -> void:
	# Refresh the rune shop to update prices/labels
	_refresh_rune_shop()


func _setup_ui() -> void:
	_update_money_display()
	_update_reroll_button()
	_update_upgrade_button()
	_update_panel_buttons()


func initialize(manager: ShopManager, player_level: int = 1) -> void:
	shop_manager = manager
	_connect_signals()
	shop_manager.refresh_shop(player_level)


func _on_shop_updated() -> void:
	_refresh_rune_shop()
	_refresh_slot_shop()
	_refresh_relic_shop()
	_update_money_display()
	_update_reroll_button()


func _refresh_rune_shop() -> void:
	# Clear existing items
	for item in _rune_shop_items:
		item.queue_free()
	_rune_shop_items.clear()
	
	if not rune_shop_container or not shop_manager:
		return
	
	# Create shop items for each available rune
	for i in range(shop_manager.available_runes.size()):
		var rune_data = shop_manager.available_runes[i]
		var shop_item = _create_rune_shop_item(rune_data, i)
		rune_shop_container.add_child(shop_item)
		_rune_shop_items.append(shop_item)


func _create_rune_shop_item(rune_data: RuneData, index: int) -> Control:
	var item = VBoxContainer.new()
	item.custom_minimum_size = Vector2(80, 120)
	
	# Rune visual (texture or placeholder)
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if rune_data.textures.size() > 0:
		texture_rect.texture = rune_data.textures[0]
	item.add_child(texture_rect)
	
	# Name label
	var name_label = Label.new()
	name_label.text = rune_data.rune_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	item.add_child(name_label)
	
	# Price label - show FREE if free picks available
	var price = ShopConfig.get_rune_buy_price(rune_data.rarity)
	var price_label = Label.new()
	if shop_manager and shop_manager.has_free_pick():
		price_label.text = "FREE!"
		price_label.add_theme_color_override("font_color", Color.LIME)
	else:
		price_label.text = "$%d" % price
		price_label.add_theme_color_override("font_color", Color.GOLD)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.add_child(price_label)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Take" if (shop_manager and shop_manager.has_free_pick()) else "Buy"
	buy_button.pressed.connect(_on_buy_rune_pressed.bind(index))
	item.add_child(buy_button)
	
	# Rarity color indicator
	var rarity_color = _get_rarity_color(rune_data.rarity)
	var style = StyleBoxFlat.new()
	style.bg_color = rarity_color.darkened(0.7)
	style.border_color = rarity_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	item.add_theme_stylebox_override("panel", style)
	
	return item


func _refresh_slot_shop() -> void:
	for item in _slot_shop_items:
		item.queue_free()
	_slot_shop_items.clear()
	
	if not slot_shop_container or not shop_manager:
		return
	
	for i in range(shop_manager.available_slots.size()):
		var slot_data = shop_manager.available_slots[i]
		var shop_item = _create_slot_shop_item(slot_data, i)
		slot_shop_container.add_child(shop_item)
		_slot_shop_items.append(shop_item)


func _create_slot_shop_item(slot_data: SlotData, index: int) -> Control:
	var item = VBoxContainer.new()
	item.custom_minimum_size = Vector2(80, 100)
	
	# Slot visual (colored box)
	var visual = ColorRect.new()
	visual.custom_minimum_size = Vector2(64, 64)
	visual.color = slot_data.color_tint if slot_data.color_tint else Color.GRAY
	item.add_child(visual)
	
	# Name label
	var name_label = Label.new()
	name_label.text = slot_data.slot_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	item.add_child(name_label)
	
	# Price label
	var price = ShopConfig.get_slot_buy_price(slot_data.id)
	var price_label = Label.new()
	price_label.text = "$%d" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color.GOLD)
	item.add_child(price_label)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.pressed.connect(_on_buy_slot_pressed.bind(index))
	item.add_child(buy_button)
	
	return item


func _refresh_relic_shop() -> void:
	if not relic_container or not shop_manager:
		return
	
	# Clear existing
	for child in relic_container.get_children():
		child.queue_free()
	
	# Add placeholder relics
	for i in range(shop_manager.available_relics.size()):
		var relic = shop_manager.available_relics[i]
		var item = _create_relic_placeholder(relic, i)
		relic_container.add_child(item)


func _create_relic_placeholder(relic: Dictionary, index: int) -> Control:
	var item = VBoxContainer.new()
	item.custom_minimum_size = Vector2(80, 100)
	
	# Placeholder visual
	var visual = ColorRect.new()
	visual.custom_minimum_size = Vector2(64, 64)
	visual.color = Color.PURPLE.darkened(0.3)
	item.add_child(visual)
	
	# Question mark
	var label = Label.new()
	label.text = "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	visual.add_child(label)
	
	# Name
	var name_label = Label.new()
	name_label.text = relic.get("name", "Relic")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	item.add_child(name_label)
	
	# Price
	var price_label = Label.new()
	price_label.text = "$%d" % ShopConfig.RELIC_BASE_COST
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color.GOLD)
	item.add_child(price_label)
	
	# Buy button (disabled - placeholder)
	var buy_button = Button.new()
	buy_button.text = "Soon™"
	buy_button.disabled = true
	item.add_child(buy_button)
	
	return item


# --- Buy Handlers ---

func _on_buy_rune_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var rune = shop_manager.buy_rune(index)
	if rune:
		rune_purchased.emit(rune)


func _on_buy_slot_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var slot = shop_manager.buy_slot(index)
	if slot:
		slot_purchased.emit(slot)


# --- Upgrade System ---

func set_upgrade_rune(slot_index: int, rune: RuneInstance) -> void:
	if slot_index == 0:
		_upgrade_rune_1 = rune
		shop_manager.set_upgrade_rune_1(rune) if shop_manager else null
	else:
		_upgrade_rune_2 = rune
		shop_manager.set_upgrade_rune_2(rune) if shop_manager else null
	
	_update_upgrade_ui()


func _update_upgrade_ui() -> void:
	_update_upgrade_button()
	
	if upgrade_result_label:
		if shop_manager and shop_manager.can_upgrade():
			var result_name = _upgrade_rune_1.data.upgrades_to.rune_name if _upgrade_rune_1 else "?"
			upgrade_result_label.text = "→ %s" % result_name
			upgrade_result_label.add_theme_color_override("font_color", Color.GREEN)
		elif _upgrade_rune_1 and _upgrade_rune_2:
			upgrade_result_label.text = "Runas diferentes!"
			upgrade_result_label.add_theme_color_override("font_color", Color.RED)
		else:
			upgrade_result_label.text = "Coloque 2 runas iguais"
			upgrade_result_label.add_theme_color_override("font_color", Color.GRAY)


func _on_upgrade_pressed() -> void:
	if not shop_manager or not shop_manager.can_upgrade():
		return
	
	var new_rune = shop_manager.perform_upgrade()
	if new_rune:
		_upgrade_rune_1 = null
		_upgrade_rune_2 = null
		_update_upgrade_ui()
		upgrade_completed.emit(new_rune)


func _update_upgrade_button() -> void:
	if upgrade_button:
		upgrade_button.disabled = not (shop_manager and shop_manager.can_upgrade())


# --- Sell System ---

func sell_item(item) -> void:
	if not shop_manager:
		return
	
	if item is RuneInstance:
		shop_manager.sell_rune(item)
		rune_sold.emit(item)
	elif item is SlotInstance:
		shop_manager.sell_slot(item)
		slot_sold.emit(item)


# --- Reroll ---

func _on_reroll_pressed() -> void:
	if shop_manager:
		var game_manager = get_node_or_null("/root/Main/Managers/GameManager")
		var level = game_manager.current_level if game_manager else 1
		shop_manager.reroll_shop(level)


func _update_reroll_button() -> void:
	if reroll_button:
		var can_afford = _get_money() >= ShopConfig.REROLL_COST
		reroll_button.disabled = not can_afford
		reroll_button.text = "Reroll ($%d)" % ShopConfig.REROLL_COST


# --- Panel Buttons ---

func _on_panel_unlock_pressed() -> void:
	if shop_manager:
		shop_manager.unlock_new_panel()


func _on_view_panel_pressed() -> void:
	view_panel_requested.emit()


func _update_panel_buttons() -> void:
	if panel_unlock_button:
		var can_afford = _get_money() >= ShopConfig.PANEL_UNLOCK_COST
		panel_unlock_button.disabled = not can_afford
		panel_unlock_button.text = "Unlock Panel ($%d)" % ShopConfig.PANEL_UNLOCK_COST
	
	if view_panel_button:
		# Will be disabled during battle - for now always enabled
		view_panel_button.disabled = false


# --- Money Display ---

func _update_money_display() -> void:
	if money_label:
		money_label.text = "$%d" % _get_money()


func _get_money() -> int:
	var stats = get_node_or_null("/root/Stats")
	return stats.get_money() if stats else 0


func _on_economy_changed(_event) -> void:
	_update_money_display()
	_update_reroll_button()
	_update_panel_buttons()


# --- Transaction Feedback ---

func _on_transaction_completed(success: bool, message: String) -> void:
	print("[Shop] %s: %s" % ["Success" if success else "Failed", message])
	# TODO: Show toast/notification to player


func _on_insufficient_funds(cost: int, balance: int) -> void:
	print("[Shop] Insufficient funds: need $%d, have $%d" % [cost, balance])
	# TODO: Flash money display red


# --- Helpers ---

func _get_rarity_color(rarity: GameEnums.Rarity) -> Color:
	match rarity:
		GameEnums.Rarity.COMMON:
			return Color.GRAY
		GameEnums.Rarity.UNCOMMON:
			return Color.GREEN
		GameEnums.Rarity.RARE:
			return Color.BLUE
		GameEnums.Rarity.EPIC:
			return Color.PURPLE
		GameEnums.Rarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE


# --- Static Factory ---

static func create_shop_ui() -> ShopUI:
	var shop_ui = ShopUI.new()
	shop_ui.name = "ShopUI"
	shop_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainContainer"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	shop_ui.add_child(main_vbox)
	
	# Header with money
	var header = HBoxContainer.new()
	header.name = "Header"
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	
	header.add_child(Control.new())  # Spacer
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var money = Label.new()
	money.name = "MoneyLabel"
	money.text = "$0"
	money.add_theme_font_size_override("font_size", 20)
	money.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(money)
	shop_ui.money_label = money
	
	# Rune shop section
	var rune_section = _create_section("Buy Runes")
	main_vbox.add_child(rune_section)
	
	var rune_hbox = HBoxContainer.new()
	rune_hbox.name = "RuneShopContainer"
	rune_hbox.add_theme_constant_override("separation", 10)
	rune_section.add_child(rune_hbox)
	shop_ui.rune_shop_container = rune_hbox
	
	var reroll_btn = Button.new()
	reroll_btn.name = "RerollButton"
	reroll_btn.text = "Reroll ($2)"
	rune_section.add_child(reroll_btn)
	shop_ui.reroll_button = reroll_btn
	
	# Slot shop section
	var slot_section = _create_section("Buy Slots")
	main_vbox.add_child(slot_section)
	
	var slot_hbox = HBoxContainer.new()
	slot_hbox.name = "SlotShopContainer"
	slot_hbox.add_theme_constant_override("separation", 10)
	slot_section.add_child(slot_hbox)
	shop_ui.slot_shop_container = slot_hbox
	
	# Upgrade section
	var upgrade_section = _create_section("Upgrade (2 same runes)")
	main_vbox.add_child(upgrade_section)
	
	var upgrade_hbox = HBoxContainer.new()
	upgrade_hbox.add_theme_constant_override("separation", 20)
	upgrade_section.add_child(upgrade_hbox)
	
	var slot1 = ColorRect.new()
	slot1.name = "UpgradeSlot1"
	slot1.custom_minimum_size = Vector2(64, 64)
	slot1.color = Color(0.2, 0.2, 0.2)
	upgrade_hbox.add_child(slot1)
	shop_ui.upgrade_slot_1 = slot1
	
	var plus_label = Label.new()
	plus_label.text = "+"
	plus_label.add_theme_font_size_override("font_size", 24)
	upgrade_hbox.add_child(plus_label)
	
	var slot2 = ColorRect.new()
	slot2.name = "UpgradeSlot2"
	slot2.custom_minimum_size = Vector2(64, 64)
	slot2.color = Color(0.2, 0.2, 0.2)
	upgrade_hbox.add_child(slot2)
	shop_ui.upgrade_slot_2 = slot2
	
	var result_label = Label.new()
	result_label.name = "UpgradeResultLabel"
	result_label.text = "Coloque 2 runas iguais"
	result_label.add_theme_color_override("font_color", Color.GRAY)
	upgrade_hbox.add_child(result_label)
	shop_ui.upgrade_result_label = result_label
	
	var upgrade_btn = Button.new()
	upgrade_btn.name = "UpgradeButton"
	upgrade_btn.text = "Upgrade"
	upgrade_btn.disabled = true
	upgrade_hbox.add_child(upgrade_btn)
	shop_ui.upgrade_button = upgrade_btn
	
	# Relic section (placeholder)
	var relic_section = _create_section("Relics (Coming Soon)")
	main_vbox.add_child(relic_section)
	
	var relic_hbox = HBoxContainer.new()
	relic_hbox.name = "RelicContainer"
	relic_hbox.add_theme_constant_override("separation", 10)
	relic_section.add_child(relic_hbox)
	shop_ui.relic_container = relic_hbox
	
	# Panel section
	var panel_section = _create_section("Panels")
	main_vbox.add_child(panel_section)
	
	var panel_hbox = HBoxContainer.new()
	panel_hbox.add_theme_constant_override("separation", 10)
	panel_section.add_child(panel_hbox)
	
	var unlock_btn = Button.new()
	unlock_btn.name = "PanelUnlockButton"
	unlock_btn.text = "Unlock Panel ($25)"
	panel_hbox.add_child(unlock_btn)
	shop_ui.panel_unlock_button = unlock_btn
	
	var view_btn = Button.new()
	view_btn.name = "ViewPanelButton"
	view_btn.text = "View Panel"
	panel_hbox.add_child(view_btn)
	shop_ui.view_panel_button = view_btn
	
	return shop_ui


static func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	section.add_child(label)
	
	var separator = HSeparator.new()
	section.add_child(separator)
	
	return section
