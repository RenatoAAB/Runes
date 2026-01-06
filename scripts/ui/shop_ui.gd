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
@onready var reroll_button: Button = $Reroll
@onready var sell_area: SellArea = get_node_or_null("SellArea")

# GetOneOfThree section (free pick)
@onready var get_one_of_three: Control = $GetOneOfThree
@onready var available_runes_container: GridContainer = $GetOneOfThree/AvailableRunes
@onready var buy_rune_pack_button: Button = $GetOneOfThree/BuyRunePack

# Upgrade section
@onready var upgrade_section: Control = $Upgrade
@onready var runes_to_upgrade_container: GridContainer = $Upgrade/RunesToUpgrade
@onready var upgraded_rune_preview_container: GridContainer = $Upgrade/UpgradedRunePreview
@onready var upgrade_cost_label: Label = $Upgrade/Label

# --- Internal State ---
var _upgrade_rune_1: RuneInstance = null
var _upgrade_rune_2: RuneInstance = null


func _ready() -> void:
	_connect_signals()
	_setup_ui()


func _connect_signals() -> void:
	# Connect button signals
	if enter_panel_button and not enter_panel_button.pressed.is_connected(_on_enter_panel_pressed):
		enter_panel_button.pressed.connect(_on_enter_panel_pressed)
	
	if buy_rune_pack_button and not buy_rune_pack_button.pressed.is_connected(_on_buy_rune_pack_pressed):
		buy_rune_pack_button.pressed.connect(_on_buy_rune_pack_pressed)
	
	if reroll_button and not reroll_button.pressed.is_connected(_on_reroll_pressed):
		reroll_button.pressed.connect(_on_reroll_pressed)
	
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
	_update_free_pick_section()
	_update_reroll_button()
	_setup_sell_area()


func initialize(manager: ShopManager, player_level: int = 1) -> void:
	shop_manager = manager
	_connect_shop_manager_signals()
	shop_manager.refresh_shop(player_level)


func _on_shop_updated() -> void:
	_refresh_rune_shop()
	_refresh_slots_shop()  # Combined pieces & modifiers
	_refresh_relic_shop()
	_refresh_upgrade_slots()
	_update_free_pick_section()


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
	return "$%d" % ShopConfig.get_rune_buy_price(rune_data.rarity)


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
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		if i < shop_items.size():
			var item = shop_items[i]
			
			if item.type == "piece":
				var piece_data = item.data as SlotPieceData
				slot_ui.set_placeholder_display(piece_data.display_name.substr(0, 2), _get_piece_shape_color(piece_data))
				slot_ui.set_shop_mode(true, shop_manager.get_piece_price_display(piece_data))
				_connect_slot_buy_signal(slot_ui, item.index, "piece")
			else:  # modifier
				var modifier_data = item.data as SlotModifierData
				var color = SlotPieceUI.get_color_for_modifier_type(modifier_data.modifier_type)
				slot_ui.set_placeholder_display(modifier_data.display_name.substr(0, 2), color)
				slot_ui.set_shop_mode(true, shop_manager.get_modifier_price_display(modifier_data))
				_connect_slot_buy_signal(slot_ui, item.index, "modifier")
		else:
			slot_ui.clear_display()
			slot_ui.set_shop_mode(false)


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
			_connect_slot_buy_signal(slot_ui, i, "relic")
		else:
			slot_ui.clear_display()
			slot_ui.set_shop_mode(false)


# --- Free Pick Section (GetOneOfThree) ---

func _update_free_pick_section() -> void:
	if not get_one_of_three:
		return
	
	var has_free_picks = shop_manager and shop_manager.has_free_pick()
	
	# Show/hide the available runes for free pick
	if available_runes_container:
		available_runes_container.visible = has_free_picks
	
	# Update buy pack button text
	if buy_rune_pack_button:
		if has_free_picks:
			buy_rune_pack_button.text = "Pick One!"
		else:
			buy_rune_pack_button.text = "Random\n$%d" % ShopConfig.RUNE_PACK_COST


func _on_free_pick_changed(_count: int) -> void:
	_update_free_pick_section()
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
		upgrade_cost_label.text = "Click to upgrade! ($%d)" % ShopConfig.UPGRADE_COST
		upgrade_cost_label.add_theme_color_override("font_color", Color.GREEN)
	elif _upgrade_rune_1 and _upgrade_rune_2:
		upgrade_cost_label.text = "Runas diferentes!"
		upgrade_cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		upgrade_cost_label.text = "Arraste 2 runas iguais ($%d)" % ShopConfig.UPGRADE_COST
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
	
	var rune = shop_manager.buy_rune(index)
	if rune:
		rune_purchased.emit(rune)
		_refresh_rune_shop()


func _on_buy_piece_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var piece = shop_manager.buy_piece(index)
	if piece:
		piece_purchased.emit(piece)
		_refresh_slots_shop()


func _on_buy_modifier_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var modifier = shop_manager.buy_modifier(index)
	if modifier:
		modifier_purchased.emit(modifier)
		_refresh_slots_shop()


func _on_buy_relic_pressed(index: int) -> void:
	if not shop_manager:
		return
	
	var relic = shop_manager.buy_relic(index)
	if relic:
		relic_purchased.emit(relic)
		_refresh_relic_shop()


func _on_buy_rune_pack_pressed() -> void:
	# Trigger Rune Pack interaction - shows 3 random runes, player picks 1
	if not shop_manager:
		return
	
	if shop_manager.has_free_pick():
		# Already have free picks, just show the runes
		_show_rune_pack_selection()
	else:
		# Costs money to buy a rune pack
		if shop_manager.buy_rune_pack():
			_show_rune_pack_selection()


func _show_rune_pack_selection() -> void:
	# Show the GetOneOfThree panel with 3 random runes
	if not available_runes_container or not shop_manager:
		return
	
	# Hide the Random button while selection is active
	if buy_rune_pack_button:
		buy_rune_pack_button.visible = false
	
	# Generate 3 random runes for selection
	var pack_runes = shop_manager.generate_rune_pack()
	
	var slots = available_runes_container.get_children()
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		if i < pack_runes.size():
			var rune_data = pack_runes[i]
			var display_rune = RuneInstance.new(rune_data)
			slot_ui.set_rune(display_rune)
			slot_ui.set_shop_mode(true, "FREE!")
			
			# Connect click to pick this rune
			_connect_rune_pack_selection(slot_ui, i)
		else:
			slot_ui.set_rune(null)
			slot_ui.set_shop_mode(false)
	
	# Show the selection area
	if available_runes_container:
		available_runes_container.visible = true


func _connect_rune_pack_selection(slot_ui: SlotUI, index: int) -> void:
	# Disconnect any existing connection
	if slot_ui.gui_input.is_connected(_on_rune_pack_slot_clicked):
		slot_ui.gui_input.disconnect(_on_rune_pack_slot_clicked)
	
	slot_ui.gui_input.connect(_on_rune_pack_slot_clicked.bind(index))


func _on_rune_pack_slot_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_from_rune_pack(index)


func _pick_from_rune_pack(index: int) -> void:
	if not shop_manager:
		return
	
	var rune = shop_manager.pick_from_rune_pack(index)
	if rune:
		rune_purchased.emit(rune)
		_hide_rune_pack_selection()
		_update_free_pick_section()


func _hide_rune_pack_selection() -> void:
	if available_runes_container:
		available_runes_container.visible = false
	
	# Show the Random button again
	if buy_rune_pack_button:
		buy_rune_pack_button.visible = true


func _on_reroll_pressed() -> void:
	# Reroll just the purchasable runes (not the rune pack)
	if not shop_manager:
		return
	
	var game_manager = get_node_or_null("/root/Main/Managers/GameManager")
	var level = game_manager.current_level if game_manager else 1
	
	if shop_manager.reroll_shop(level):
		_update_reroll_button()


func _update_reroll_button() -> void:
	if reroll_button:
		reroll_button.text = "Reroll\n$%d" % ShopConfig.REROLL_COST


# --- Sell Area ---

func _setup_sell_area() -> void:
	if not sell_area:
		return
	
	# Connect sell area signal (SellArea script handles the drop logic)
	if sell_area.has_signal("rune_sold"):
		if not sell_area.rune_sold.is_connected(_on_sell_area_rune_sold):
			sell_area.rune_sold.connect(_on_sell_area_rune_sold)


func _on_sell_area_rune_sold(rune: RuneInstance, price: int) -> void:
	rune_sold.emit(rune)
	print("Sold rune for $%d" % price)
	
	# Refresh inventory display
	var main_controller = get_node_or_null("/root/Main/MainController")
	if main_controller and main_controller.has_method("_on_inventory_updated"):
		main_controller._on_inventory_updated()


# --- Navigation ---

func _on_enter_panel_pressed() -> void:
	view_panel_requested.emit()


# --- Transaction Feedback ---

func _on_transaction_completed(success: bool, message: String) -> void:
	print("[Shop] %s: %s" % ["Success" if success else "Failed", message])
	# TODO: Show toast/notification to player


func _on_insufficient_funds(cost: int, balance: int) -> void:
	print("[Shop] Insufficient funds: need $%d, have $%d" % [cost, balance])
	# TODO: Flash money display red


func _on_economy_changed(_event) -> void:
	_update_free_pick_section()


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
