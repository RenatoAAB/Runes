class_name SellArea
extends Control

## Area where runes can be dropped to sell them.
## Displays the sell price when a rune is being dragged over.

signal rune_sold(rune: RuneInstance, price: int)

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
	
	_update_display(null)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		_update_display(null)
		return false
	
	# Can drop rune instances
	if data.has("rune_instance"):
		var rune = data["rune_instance"] as RuneInstance
		if rune:
			_update_display(rune)
			return true
	
	_update_display(null)
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	if data.has("rune_instance"):
		var rune = data["rune_instance"] as RuneInstance
		if rune:
			_sell_rune(rune, data.get("source_ui"))


func _sell_rune(rune: RuneInstance, source_ui: Variant) -> void:
	# Calculate price
	var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
	
	# Emit economy event to add money
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var stats = get_node_or_null("/root/Stats")
		var balance = stats.get_money() if stats else 0
		var event = EconomyEvent.new()
		event.transaction_type = EconomyEvent.TransactionType.SHOP_SELL
		event.source = StringName("sell_rune_%s" % rune.data.id)
		event.amount = price
		event.balance_before = balance
		event.balance_after = balance + price
		event_bus.emit(event)
	
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
	print("Sold %s for $%d" % [rune.data.rune_name, price])


func _update_display(rune: RuneInstance) -> void:
	if not label:
		return
	
	if rune:
		var price = ShopConfig.get_rune_sell_price(rune.data.rarity, rune.data.tier)
		label.text = "Sell for $%d" % price
		label.add_theme_color_override("font_color", Color.LIME)
		_dragging_over = true
	else:
		label.text = "Drag here\nto sell"
		label.add_theme_color_override("font_color", Color.WHITE)
		_dragging_over = false


func _notification(what: int) -> void:
	# Reset display when drag ends
	if what == NOTIFICATION_DRAG_END:
		_update_display(null)
