class_name SellArea
extends Control

## Area where items can be dropped to sell them.
## Accepts: RuneInstance, SlotPieceInstance, SlotModifierData, RelicInstance.
## Displays the sell price when an item is being dragged over.

signal rune_sold(rune: RuneInstance, price: int)
signal piece_sold(piece: SlotPieceInstance, price: int)
signal modifier_sold(modifier: SlotModifierData, price: int)
signal relic_sold(relic: RelicInstance, price: int)

@onready var label: Label = $Label if has_node("Label") else null

var _dragging_over: bool = false


func _log_sell_event(action: String, details: Dictionary) -> void:
	var keys := details.keys()
	keys.sort()
	var parts: Array[String] = []
	for key in keys:
		parts.append("%s=%s" % [String(key), str(details[key])])
	var details_text := ", ".join(parts)
	if details_text.is_empty():
		print("[SellLog] %s" % action)
	else:
		print("[SellLog] %s | %s" % [action, details_text])


func _describe_sell_source(source_ui: Variant) -> String:
	if source_ui == null:
		return "unknown"

	var source_slot: SlotUI = null
	if source_ui is SlotUI:
		source_slot = source_ui as SlotUI
	elif source_ui is Node and source_ui.get_parent() is SlotUI:
		source_slot = source_ui.get_parent() as SlotUI

	if source_slot:
		if source_slot.grid_coord != Vector2i(-1, -1):
			return "grid(%d,%d)" % [source_slot.grid_coord.x, source_slot.grid_coord.y]
		if source_slot.is_relic_slot:
			return "relic_slot[%d]" % source_slot.relic_slot_index
		if source_slot.inventory_index >= 0:
			return "inventory[%d]" % source_slot.inventory_index
		return "inventory_visual_slot"

	if source_ui is Object:
		return (source_ui as Object).get_class()

	return "unknown"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Make sure children don't block mouse events
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create label if it doesn't exist
	if not label:
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	
	_update_display_default()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		_update_display_default()
		return false
	
	# Rune instances
	if data.has("rune_instance") and data["rune_instance"] is RuneInstance:
		var rune = data["rune_instance"] as RuneInstance
		var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
		_update_display_sell(rune.data.rune_name, price)
		return true
	
	# Slot pieces (from SlotPieceUI)
	if data.has("type") and data["type"] == "slot_piece" and data.has("piece"):
		var piece = data["piece"] as SlotPieceInstance
		if piece and piece.data:
			var price = ShopConfig.get_piece_sell_price(piece.data)
			_update_display_sell(piece.data.display_name, price)
			return true
	
	# Pieces from ItemUI
	if data.has("item_type") and data["item_type"] == "piece" and data.has("item_data"):
		var piece_data = data["item_data"] as SlotPieceData
		if piece_data:
			var price = ShopConfig.get_piece_sell_price(piece_data)
			_update_display_sell(piece_data.display_name, price)
			return true
	
	# Modifiers from ItemUI
	if data.has("item_type") and data["item_type"] == "modifier" and data.has("item_data"):
		var modifier_data = data["item_data"] as SlotModifierData
		if modifier_data:
			var price = ShopConfig.get_modifier_sell_price(modifier_data)
			_update_display_sell(modifier_data.display_name, price)
			return true
	
	# Relics (from RelicSlotUI or ItemUI)
	if data.has("relic_instance") and data["relic_instance"] is RelicInstance:
		var relic = data["relic_instance"] as RelicInstance
		if relic and relic.data:
			var price = ShopConfig.get_relic_sell_price(relic.data)
			_update_display_sell(relic.data.display_name, price)
			return true
	
	_update_display_default()
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	# Rune
	if data.has("rune_instance") and data["rune_instance"] is RuneInstance:
		_sell_rune(data["rune_instance"] as RuneInstance, data.get("source_ui"))
		return
	
	# Slot piece (from SlotPieceUI)
	if data.has("type") and data["type"] == "slot_piece" and data.has("piece"):
		var piece = data["piece"] as SlotPieceInstance
		if piece:
			_sell_piece(piece, data.get("source_ui"))
			return
	
	# Piece from ItemUI
	if data.has("item_type") and data["item_type"] == "piece" and data.has("item_instance"):
		var piece = data["item_instance"] as SlotPieceInstance
		if piece:
			_sell_piece(piece, data.get("source_ui"))
			return
	
	# Modifier from ItemUI
	if data.has("item_type") and data["item_type"] == "modifier" and data.has("item_data"):
		var modifier = data["item_data"] as SlotModifierData
		if modifier:
			_sell_modifier(modifier, data.get("source_ui"))
			return
	
	# Relic
	if data.has("relic_instance") and data["relic_instance"] is RelicInstance:
		var relic = data["relic_instance"] as RelicInstance
		if relic:
			_sell_relic(relic, data.get("source_ui"))
			return


func _sell_rune(rune: RuneInstance, source_ui: Variant) -> void:
	var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
	_emit_sell_event(price, "sell_rune_%s" % rune.data.id)
	var origin := _describe_sell_source(source_ui)
	var main_controller := _get_main_controller()
	var source_slot_ui: SlotUI = null
	var removed_from_inventory := false
	var removed_from_grid := false

	if source_ui is RuneUI and source_ui.get_parent() is SlotUI:
		source_slot_ui = source_ui.get_parent() as SlotUI
	elif source_ui is SlotUI:
		source_slot_ui = source_ui as SlotUI

	# Selling from grid must also remove from GridManager logic state.
	if source_slot_ui and source_slot_ui.grid_coord != Vector2i(-1, -1):
		if main_controller and main_controller.grid_manager:
			var logic_slot = main_controller.grid_manager.get_slot(source_slot_ui.grid_coord)
			if logic_slot and logic_slot.rune == rune:
				logic_slot.remove_rune()
				main_controller.grid_manager.slot_changed.emit(source_slot_ui.grid_coord)
				removed_from_grid = true
	
	# Remove the rune from inventory
	var inventory_manager: InventoryManager = null
	if main_controller and main_controller.inventory_manager:
		inventory_manager = main_controller.inventory_manager
	else:
		inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager") as InventoryManager
	if inventory_manager:
		var had_rune := inventory_manager.has_rune(rune)
		inventory_manager.remove_rune(rune)
		removed_from_inventory = had_rune and not inventory_manager.has_rune(rune)
	
	# Clear the source slot UI
	if source_ui and source_ui is RuneUI:
		var slot_ui = source_ui.get_parent()
		if slot_ui and slot_ui is SlotUI:
			slot_ui.set_rune(null)
	
	rune_sold.emit(rune, price)
	var rune_name := rune.data.rune_name if rune and rune.data else "unknown_rune"
	_log_sell_event("sell_rune", {
		"origin": origin,
		"price": price,
		"removed_from_grid": removed_from_grid,
		"result": "ok" if (removed_from_inventory or removed_from_grid) else "not_found",
		"rune": rune_name
	})


func _sell_piece(piece: SlotPieceInstance, source_ui: Variant) -> void:
	var price = ShopConfig.get_piece_sell_price(piece.data)
	_emit_sell_event(price, "sell_piece_%s" % piece.data.id)
	var origin := _describe_sell_source(source_ui)
	var removed_from_extra := false
	
	# Remove from extra inventory (pieces are not managed by InventoryManager)
	var extra_inventory := _get_extra_inventory_manager()
	if extra_inventory:
		if extra_inventory.has_method("remove_piece"):
			removed_from_extra = extra_inventory.remove_piece(piece)
		elif extra_inventory.has_method("remove_slot_piece"):
			removed_from_extra = extra_inventory.remove_slot_piece(piece)
	
	piece_sold.emit(piece, price)
	var piece_name := piece.data.display_name if piece and piece.data else "unknown_piece"
	_log_sell_event("sell_piece", {
		"origin": origin,
		"piece": piece_name,
		"price": price,
		"result": "ok" if removed_from_extra else "not_found"
	})


func _sell_modifier(modifier: SlotModifierData, source_ui: Variant) -> void:
	var price = ShopConfig.get_modifier_sell_price(modifier)
	_emit_sell_event(price, "sell_modifier_%s" % modifier.id)
	var origin := _describe_sell_source(source_ui)
	var removed_from_extra := false
	
	# Remove from extra inventory (modifiers are not managed by InventoryManager)
	var extra_inventory := _get_extra_inventory_manager()
	if extra_inventory:
		removed_from_extra = extra_inventory.remove_modifier(modifier)
	
	modifier_sold.emit(modifier, price)
	var modifier_name := modifier.display_name if modifier else "unknown_modifier"
	_log_sell_event("sell_modifier", {
		"modifier": modifier_name,
		"origin": origin,
		"price": price,
		"result": "ok" if removed_from_extra else "not_found"
	})


func _sell_relic(relic: RelicInstance, source_ui: Variant) -> void:
	var price = ShopConfig.get_relic_sell_price(relic.data)
	_emit_sell_event(price, "sell_relic_%s" % relic.data.id)
	var origin := _describe_sell_source(source_ui)
	var removal_result := false
	
	# Relics can come from attached relic slots or from extra inventory.
	var sold_from_relic_slot := source_ui is SlotUI and (source_ui as SlotUI).is_relic_slot
	if sold_from_relic_slot or relic.is_attached():
		var panel_manager := _get_panel_manager()
		if panel_manager and relic.attached_panel_index >= 0:
			var panel = panel_manager.get_panel(relic.attached_panel_index)
			if panel:
				panel.detach_relic(relic)
		relic.detach_from_panel()
		if source_ui is SlotUI:
			(source_ui as SlotUI)._relic_instance = null
		removal_result = true
	else:
		var extra_inventory := _get_extra_inventory_manager()
		if extra_inventory:
			removal_result = extra_inventory.remove_relic(relic)

	_refresh_main_controller_views()
	
	relic_sold.emit(relic, price)
	var relic_name := relic.data.display_name if relic and relic.data else "unknown_relic"
	_log_sell_event("sell_relic", {
		"origin": origin,
		"price": price,
		"relic": relic_name,
		"result": "ok" if removal_result else "not_found",
		"sold_from_relic_slot": sold_from_relic_slot
	})


func _get_extra_inventory_manager() -> ExtraInventoryManager:
	var manager = get_tree().get_first_node_in_group("extra_inventory")
	if manager and manager is ExtraInventoryManager:
		return manager as ExtraInventoryManager
	return get_node_or_null("/root/Main/ExtraInventory") as ExtraInventoryManager


func _get_panel_manager() -> PanelManager:
	var manager = get_tree().get_first_node_in_group("panel_manager")
	if manager and manager is PanelManager:
		return manager as PanelManager
	return get_node_or_null("/root/Main/PanelManager") as PanelManager


func _get_main_controller() -> MainController:
	var controller = get_tree().get_first_node_in_group("main_controller")
	if controller and controller is MainController:
		return controller as MainController
	return get_node_or_null("/root/Main") as MainController


func _refresh_main_controller_views() -> void:
	var main_controller = get_tree().get_first_node_in_group("main_controller")
	if not main_controller:
		main_controller = get_node_or_null("/root/Main")
	if main_controller and main_controller.has_method("_update_other_inventory_display"):
		main_controller._update_other_inventory_display()
	if main_controller and main_controller.has_method("_update_relic_slots_display"):
		main_controller._update_relic_slots_display()


func _emit_sell_event(price: int, source: String) -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var stats = get_node_or_null("/root/Stats")
		var balance = stats.get_money() if stats else 0
		var event = EconomyEvent.new()
		event.transaction_type = EconomyEvent.TransactionType.SHOP_SELL
		event.source = StringName(source)
		event.amount = price
		event.balance_before = balance
		event.balance_after = balance + price
		event_bus.emit(event)


func _update_display_sell(item_name: String, price: int) -> void:
	if not label:
		return
	label.text = "Reciclar %s\n%d Mana" % [item_name, price]
	label.add_theme_color_override("font_color", Color.LIME)
	_dragging_over = true


func _update_display_default() -> void:
	if not label:
		return
	label.text = "Arraste aqui\npara reciclar"
	label.add_theme_color_override("font_color", Color.WHITE)
	_dragging_over = false


func _notification(what: int) -> void:
	# Reset display when drag ends
	if what == NOTIFICATION_DRAG_END:
		_update_display_default()
