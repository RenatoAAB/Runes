class_name ShopUI
extends Control

## UI for the shop scene.
## Uses nodes defined in the scene tree instead of creating via code.
## Contains sections for: Buy Runes, Buy Pieces, Buy Modifiers, Upgrade, Sell, Relics

signal rune_purchased(rune: RuneInstance)
signal piece_purchased(piece: SlotPieceInstance)
signal modifier_purchased(modifier: SlotModifierData)
signal relic_purchased(relic: RelicInstance)
signal rune_sold(rune: RuneInstance)
signal piece_sold(piece: SlotPieceInstance)
signal upgrade_completed(new_rune: RuneInstance)
signal view_panel_requested
signal shop_closed

# --- References ---
var shop_manager: ShopManager

# --- UI Node References (from scene via @onready) ---
@onready var enter_panel_button: Button = $EnterPanel
@onready var purchasable_runes_container: GridContainer = $PurchasableRunes
@onready var purchasable_slots_container: GridContainer = get_node_or_null("PurchasableSlots")  # For pieces & modifiers
@onready var purchasable_relics_container: GridContainer = get_node_or_null("PurchasableRelics")
@onready var sell_area: SellArea = get_node_or_null("SellArea")

# Pergaminho (scroll) button — repurposed from old GetOneOfThree section
@onready var pergaminho_section: Control = $Pergaminho
@onready var pergaminho_button: Button = $Pergaminho/BuyRunePack

# Upgrade section
@onready var upgrade_section: Control = $Upgrade
@onready var runes_to_upgrade_container: GridContainer = $Upgrade/RunesToUpgrade
@onready var upgraded_rune_preview_container: GridContainer = $Upgrade/UpgradedRunePreview
@onready var upgrade_cost_label: Label = $Upgrade/Label

# --- Internal State ---
var _upgrade_rune_1: RuneInstance = null
var _upgrade_rune_2: RuneInstance = null
var _piece_preview_grids: Array[SlotPiecePreviewGrid] = []  # Track for cleanup


func _ready() -> void:
	_connect_signals()
	_setup_ui()


func _connect_signals() -> void:
	# Connect button signals
	if enter_panel_button and not enter_panel_button.pressed.is_connected(_on_enter_panel_pressed):
		enter_panel_button.pressed.connect(_on_enter_panel_pressed)
	
	# Pergaminho (scroll) button
	if pergaminho_button and not pergaminho_button.pressed.is_connected(_on_reroll_pressed):
		pergaminho_button.pressed.connect(_on_reroll_pressed)
	
	# Connect to economy updates
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("economy_transaction"):
		if not event_bus.economy_transaction.is_connected(_on_economy_changed):
			event_bus.economy_transaction.connect(_on_economy_changed)


func _connect_shop_manager_signals() -> void:
	if shop_manager:
		if not shop_manager.shop_updated.is_connected(_on_shop_updated):
			shop_manager.shop_updated.connect(_on_shop_updated)
		if not shop_manager.transaction_completed.is_connected(_on_transaction_completed):
			shop_manager.transaction_completed.connect(_on_transaction_completed)
		if not shop_manager.insufficient_funds.is_connected(_on_insufficient_funds):
			shop_manager.insufficient_funds.connect(_on_insufficient_funds)
		if not shop_manager.free_pick_available.is_connected(_on_free_pick_changed):
			shop_manager.free_pick_available.connect(_on_free_pick_changed)


func _setup_ui() -> void:
	_update_reroll_button()
	_setup_sell_area()


func initialize(manager: ShopManager, player_level: int = 1, refresh_now: bool = true) -> void:
	shop_manager = manager
	_connect_shop_manager_signals()
	if refresh_now:
		shop_manager.refresh_shop(player_level)
	else:
		_on_shop_updated()


func _on_shop_updated() -> void:
	_refresh_rune_shop()
	_refresh_slots_shop()  # Combined pieces & modifiers
	_refresh_relic_shop()
	_refresh_upgrade_slots()
	_update_reroll_button()


# --- Purchasable Runes Section ---

func _refresh_rune_shop() -> void:
	if not purchasable_runes_container or not shop_manager:
		return
	
	var slots = purchasable_runes_container.get_children()
	
	# Update each slot with available runes
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		if i < shop_manager.available_runes.size():
			var rune_data = shop_manager.available_runes[i]
			# Create temporary RuneInstance for display
			var display_rune = RuneInstance.new(rune_data)
			slot_ui.set_rune(display_rune)
			slot_ui.set_shop_mode(true, _get_rune_price_text(rune_data))
			
			# Connect buy signal if not already connected
			_connect_slot_buy_signal(slot_ui, i, "rune")
		else:
			slot_ui.set_rune(null)
			slot_ui.set_shop_mode(false)


func _get_rune_price_text(rune_data: RuneData) -> String:
	if shop_manager and shop_manager.has_free_pick():
		return "FREE!"
	return "%d Mana" % ShopConfig.get_rune_buy_price(rune_data.rarity)


func _connect_slot_buy_signal(slot_ui: SlotUI, index: int, item_type: String) -> void:
	# Disconnect any existing connection first
	if slot_ui.gui_input.is_connected(_on_shop_slot_clicked):
		slot_ui.gui_input.disconnect(_on_shop_slot_clicked)
	
	# Connect new handler with item type
	slot_ui.gui_input.connect(_on_shop_slot_clicked.bind(index, item_type))


func _on_shop_slot_clicked(event: InputEvent, index: int, item_type: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match item_type:
			"rune":
				_on_buy_rune_pressed(index)
			"piece":
				_on_buy_piece_pressed(index)
			"modifier":
				_on_buy_modifier_pressed(index)
			"relic":
				_on_buy_relic_pressed(index)


# --- Purchasable Pieces Section ---

# --- Purchasable Slots Section (Pieces & Modifiers combined) ---

func _refresh_slots_shop() -> void:
	if not purchasable_slots_container or not shop_manager:
		return
	
	var slots = purchasable_slots_container.get_children()
	
	# Combine pieces and modifiers into a single list
	var shop_items: Array = []  # Each item is {type: "piece"/"modifier", data: ..., index: ...}
	
	for i in range(shop_manager.available_pieces.size()):
		shop_items.append({"type": "piece", "data": shop_manager.available_pieces[i], "index": i})
	
	for i in range(shop_manager.available_modifiers.size()):
		shop_items.append({"type": "modifier", "data": shop_manager.available_modifiers[i], "index": i})
	
	# Display items in available slots
	# Clean up old preview grids
	for pg in _piece_preview_grids:
		if is_instance_valid(pg):
			pg.queue_free()
	_piece_preview_grids.clear()
	
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		if i < shop_items.size():
			var item = shop_items[i]
			
			if item.type == "piece":
				var piece_data = item.data as SlotPieceData
				# Use SlotPiecePreviewGrid for visual representation
				slot_ui.clear_display()
				var preview_grid = SlotPiecePreviewGrid.new()
				preview_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
				preview_grid.set_anchors_preset(Control.PRESET_CENTER)
				slot_ui.add_child(preview_grid)
				preview_grid.setup_auto_fit(piece_data, Vector2(28, 28), 2)
				_piece_preview_grids.append(preview_grid)
				# Set background color based on piece
				var bg_style = StyleBoxFlat.new()
				bg_style.bg_color = _get_piece_shape_color(piece_data).darkened(0.6)
				bg_style.set_border_width_all(2)
				bg_style.border_color = _get_piece_shape_color(piece_data).darkened(0.2)
				bg_style.set_corner_radius_all(4)
				slot_ui.add_theme_stylebox_override("panel", bg_style)
				slot_ui.set_shop_mode(true, shop_manager.get_piece_price_display(piece_data))
				slot_ui.set_shop_item("piece", piece_data)
				_connect_slot_buy_signal(slot_ui, item.index, "piece")
			else:  # modifier
				var modifier_data = item.data as SlotModifierData
				var color = SlotPieceUI.get_color_for_modifier_type(modifier_data.modifier_type)
				slot_ui.set_placeholder_display(modifier_data.display_name.substr(0, 2), color)
				slot_ui.set_shop_mode(true, shop_manager.get_modifier_price_display(modifier_data))
				slot_ui.set_shop_item("modifier", modifier_data)
				_connect_slot_buy_signal(slot_ui, item.index, "modifier")
		else:
			slot_ui.clear_display()
			slot_ui.set_shop_mode(false)
			slot_ui.set_shop_item("", null)


func _get_piece_shape_color(piece_data: SlotPieceData) -> Color:
	# Return color based on first modifier if present
	if piece_data.slot_modifiers.size() > 0 and piece_data.slot_modifiers[0]:
		var modifier = piece_data.slot_modifiers[0] as SlotModifierData
		if modifier:
			return SlotPieceUI.get_color_for_modifier_type(modifier.modifier_type)
	return Color.GRAY


# --- Relic Section ---

func _refresh_relic_shop() -> void:
	if not purchasable_relics_container or not shop_manager:
		return
	
	var slots = purchasable_relics_container.get_children()
	
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		if i < shop_manager.available_relics.size():
			var relic_data = shop_manager.available_relics[i]
			# Show relic icon or placeholder
			var display_text = relic_data.display_name.substr(0, 2) if relic_data.display_name else "?"
			slot_ui.set_placeholder_display(display_text, Color.PURPLE.darkened(0.3))
			slot_ui.set_shop_mode(true, shop_manager.get_relic_price_display(relic_data))
			slot_ui.set_shop_item("relic", relic_data)
			_connect_slot_buy_signal(slot_ui, i, "relic")
		else:
			slot_ui.clear_display()
			slot_ui.set_shop_mode(false)
			slot_ui.set_shop_item("", null)


func _on_free_pick_changed(_count: int) -> void:
	_refresh_rune_shop()


# --- Upgrade Section ---

func _refresh_upgrade_slots() -> void:
	if not runes_to_upgrade_container:
		return
	
	var slots = runes_to_upgrade_container.get_children()
	
	# Slot 1
	if slots.size() > 0:
		var slot1 = slots[0] as SlotUI
		if slot1:
			slot1.set_rune(_upgrade_rune_1)
			# Allow dropping runes for upgrade
			if not slot1.rune_dropped.is_connected(_on_upgrade_slot_1_drop):
				slot1.rune_dropped.connect(_on_upgrade_slot_1_drop)
	
	# Slot 2
	if slots.size() > 1:
		var slot2 = slots[1] as SlotUI
		if slot2:
			slot2.set_rune(_upgrade_rune_2)
			if not slot2.rune_dropped.is_connected(_on_upgrade_slot_2_drop):
				slot2.rune_dropped.connect(_on_upgrade_slot_2_drop)
	
	_update_upgrade_preview()


func _on_upgrade_slot_1_drop(rune: RuneInstance, _target: SlotUI, _source: SlotUI) -> void:
	set_upgrade_rune(0, rune)


func _on_upgrade_slot_2_drop(rune: RuneInstance, _target: SlotUI, _source: SlotUI) -> void:
	set_upgrade_rune(1, rune)


func set_upgrade_rune(slot_index: int, rune: RuneInstance) -> void:
	if slot_index == 0:
		_upgrade_rune_1 = rune
		if shop_manager:
			shop_manager.set_upgrade_rune_1(rune)
	else:
		_upgrade_rune_2 = rune
		if shop_manager:
			shop_manager.set_upgrade_rune_2(rune)
	
	_refresh_upgrade_slots()


func _update_upgrade_preview() -> void:
	if not upgraded_rune_preview_container:
		return
	
	var preview_slots = upgraded_rune_preview_container.get_children()
	if preview_slots.is_empty():
		return
	
	var preview_slot = preview_slots[0] as SlotUI
	if not preview_slot:
		return
	
	# Check if upgrade is possible
	if shop_manager and shop_manager.can_upgrade() and _upgrade_rune_1:
		var upgraded_data = _upgrade_rune_1.data.upgrades_to
		if upgraded_data:
			var preview_rune = RuneInstance.new(upgraded_data)
			preview_slot.set_rune(preview_rune)
			
			# Connect click to perform upgrade
			if not preview_slot.gui_input.is_connected(_on_upgrade_preview_clicked):
				preview_slot.gui_input.connect(_on_upgrade_preview_clicked)
		else:
			preview_slot.set_rune(null)
	else:
		preview_slot.set_rune(null)
	
	_update_upgrade_cost_label()


func _update_upgrade_cost_label() -> void:
	if not upgrade_cost_label:
		return
	
	if shop_manager and shop_manager.can_upgrade():
		upgrade_cost_label.text = "Clique para aprimorar! (%d Mana)" % ShopConfig.UPGRADE_COST
		upgrade_cost_label.add_theme_color_override("font_color", Color.GREEN)
	elif _upgrade_rune_1 and _upgrade_rune_2:
		upgrade_cost_label.text = "Runas diferentes!"
		upgrade_cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		upgrade_cost_label.text = "Arraste 2 runas iguais (%d Mana)" % ShopConfig.UPGRADE_COST
		upgrade_cost_label.add_theme_color_override("font_color", Color.GRAY)


func _on_upgrade_preview_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_perform_upgrade()


func _perform_upgrade() -> void:
	if not shop_manager or not shop_manager.can_upgrade():
		return
	
	var new_rune = shop_manager.perform_upgrade()
	if new_rune:
		_upgrade_rune_1 = null
		_upgrade_rune_2 = null
		_refresh_upgrade_slots()
		upgrade_completed.emit(new_rune)


# --- Buy Handlers ---

func _on_buy_rune_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	# Check if inventory is full
	var main_ctrl = get_tree().get_first_node_in_group("main_controller")
	if main_ctrl and main_ctrl.is_inventory_full():
		shop_manager.transaction_completed.emit(false, "Inventory full!")
		return
	
	var rune = shop_manager.buy_rune(index)
	if rune:
		rune_purchased.emit(rune)
		_refresh_rune_shop()


func _on_buy_piece_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var main_ctrl = get_tree().get_first_node_in_group("main_controller")
	if main_ctrl and main_ctrl.is_inventory_full():
		shop_manager.transaction_completed.emit(false, "Inventory full!")
		return
	
	var piece = shop_manager.buy_piece(index)
	if piece:
		piece_purchased.emit(piece)
		_refresh_slots_shop()


func _on_buy_modifier_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var main_ctrl = get_tree().get_first_node_in_group("main_controller")
	if main_ctrl and main_ctrl.is_inventory_full():
		shop_manager.transaction_completed.emit(false, "Inventory full!")
		return
	
	var modifier = shop_manager.buy_modifier(index)
	if modifier:
		modifier_purchased.emit(modifier)
		_refresh_slots_shop()


func _on_buy_relic_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var main_ctrl = get_tree().get_first_node_in_group("main_controller")
	if main_ctrl and main_ctrl.is_inventory_full():
		shop_manager.transaction_completed.emit(false, "Inventory full!")
		return
	
	var relic = shop_manager.buy_relic(index)
	if relic:
		relic_purchased.emit(relic)
		_refresh_relic_shop()


func _on_reroll_pressed() -> void:
	# Buy a scroll (pergaminho) — only rerolls runes
	if not shop_manager:
		return
	
	if shop_manager.buy_scroll():
		_update_reroll_button()


func _update_reroll_button() -> void:
	if not pergaminho_button or not shop_manager:
		return
	
	var cost = shop_manager.get_current_scroll_cost()
	pergaminho_button.text = "Pergaminho\n%d Mana" % cost
	pergaminho_button.disabled = _get_money() < cost


# --- Sell Area ---

func _setup_sell_area() -> void:
	if not sell_area:
		return
	
	# Connect sell area signals for all item types
	if sell_area.has_signal("rune_sold"):
		if not sell_area.rune_sold.is_connected(_on_sell_area_rune_sold):
			sell_area.rune_sold.connect(_on_sell_area_rune_sold)
	if sell_area.has_signal("piece_sold"):
		if not sell_area.piece_sold.is_connected(_on_sell_area_piece_sold):
			sell_area.piece_sold.connect(_on_sell_area_piece_sold)
	if sell_area.has_signal("modifier_sold"):
		if not sell_area.modifier_sold.is_connected(_on_sell_area_modifier_sold):
			sell_area.modifier_sold.connect(_on_sell_area_modifier_sold)
	if sell_area.has_signal("relic_sold"):
		if not sell_area.relic_sold.is_connected(_on_sell_area_relic_sold):
			sell_area.relic_sold.connect(_on_sell_area_relic_sold)


func _on_sell_area_rune_sold(rune: RuneInstance, price: int) -> void:
	rune_sold.emit(rune)
	print("[Sell] Sold rune for %d mana" % price)
	_refresh_after_sell()


func _on_sell_area_piece_sold(piece: SlotPieceInstance, price: int) -> void:
	piece_sold.emit(piece)
	print("[Sell] Sold piece for %d mana" % price)
	_refresh_after_sell()


func _on_sell_area_modifier_sold(_modifier: SlotModifierData, price: int) -> void:
	print("[Sell] Sold modifier for %d mana" % price)
	_refresh_after_sell()


func _on_sell_area_relic_sold(_relic: RelicInstance, price: int) -> void:
	print("[Sell] Sold relic for %d mana" % price)
	_refresh_after_sell()


func _refresh_after_sell() -> void:
	# Refresh inventory display
	var main_controller = get_node_or_null("/root/Main/MainController")
	if main_controller and main_controller.has_method("_on_inventory_updated"):
		main_controller._on_inventory_updated()
	_update_reroll_button()


# --- Navigation ---

func _on_enter_panel_pressed() -> void:
	view_panel_requested.emit()


# --- Transaction Feedback ---

func _on_transaction_completed(success: bool, message: String) -> void:
	print("[Shop] %s: %s" % ["Success" if success else "Failed", message])
	# TODO: Show toast/notification to player


func _on_insufficient_funds(cost: int, balance: int) -> void:
	print("[Shop] Insufficient mana: need %d, have %d" % [cost, balance])
	# TODO: Flash money display red


func _on_economy_changed(_event) -> void:
	_update_reroll_button()


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


func _get_money() -> int:
	var stats = get_node_or_null("/root/Stats")
	return stats.get_money() if stats else 0
