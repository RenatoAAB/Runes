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
	
	# Remove the rune from inventory
	var inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager")
	if inventory_manager:
		inventory_manager.remove_rune(rune)
	
	# Clear the source slot UI
	if source_ui and source_ui is RuneUI:
		var slot_ui = source_ui.get_parent()
		if slot_ui and slot_ui is SlotUI:
			slot_ui.set_rune(null)
	
	rune_sold.emit(rune, price)
	print("[Sell] Sold %s (rune) for %d mana" % [rune.data.rune_name, price])


func _sell_piece(piece: SlotPieceInstance, _source_ui: Variant) -> void:
	var price = ShopConfig.get_piece_sell_price(piece.data)
	_emit_sell_event(price, "sell_piece_%s" % piece.data.id)
	
	# Remove from inventory
	var inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager")
	if inventory_manager and inventory_manager.has_method("remove_piece"):
		inventory_manager.remove_piece(piece)
	
	piece_sold.emit(piece, price)
	print("[Sell] Sold %s (piece) for %d mana" % [piece.data.display_name, price])


func _sell_modifier(modifier: SlotModifierData, _source_ui: Variant) -> void:
	var price = ShopConfig.get_modifier_sell_price(modifier)
	_emit_sell_event(price, "sell_modifier_%s" % modifier.id)
	
	# Remove from inventory
	var inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager")
	if inventory_manager and inventory_manager.has_method("remove_modifier"):
		inventory_manager.remove_modifier(modifier)
	
	modifier_sold.emit(modifier, price)
	print("[Sell] Sold %s (modifier) for %d mana" % [modifier.display_name, price])


func _sell_relic(relic: RelicInstance, _source_ui: Variant) -> void:
	var price = ShopConfig.get_relic_sell_price(relic.data)
	_emit_sell_event(price, "sell_relic_%s" % relic.data.id)
	
	# Remove from inventory
	var inventory_manager = get_node_or_null("/root/Main/Managers/InventoryManager")
	if inventory_manager and inventory_manager.has_method("remove_relic"):
		inventory_manager.remove_relic(relic)
	
	relic_sold.emit(relic, price)
	print("[Sell] Sold %s (relic) for %d mana" % [relic.data.display_name, price])


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
