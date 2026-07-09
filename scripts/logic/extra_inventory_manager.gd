class_name ExtraInventoryManager
extends Node

## Manages non-rune items: relics, slot modifiers, and slot pieces.
## Provides a central place to store and organize these items.

signal relic_added(relic: RelicInstance)
signal relic_removed(relic: RelicInstance)
signal modifier_added(modifier: SlotModifierData)
signal modifier_removed(modifier: SlotModifierData)
signal piece_added(piece: SlotPieceInstance)
signal piece_removed(piece: SlotPieceInstance)
signal inventory_changed

## Owned relics (not attached to panels)
var relics: Array[RelicInstance] = []

## Owned slot modifiers (consumable)
var modifiers: Array[SlotModifierData] = []

## Owned slot pieces (not placed)
var slot_pieces: Array[SlotPieceInstance] = []

## Capacity limits
var max_relics: int = 10
var max_modifiers: int = 20
var max_slot_pieces: int = 10


func _ready() -> void:
	add_to_group("extra_inventory")


func _notify_acquired(item_type: StringName, item_id: String) -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.item_acquired.emit(item_type, StringName(item_id))


# --- Relic Management ---

## Add a relic to the inventory
func add_relic(relic: RelicInstance) -> bool:
	if relics.size() >= max_relics:
		push_warning("Relic inventory full")
		return false
	
	if relic in relics:
		return false
	
	relics.append(relic)
	relic_added.emit(relic)
	inventory_changed.emit()
	_notify_acquired(&"relic", relic.data.id)
	return true


## Create and add a relic from data
func add_relic_from_data(data: RelicData) -> RelicInstance:
	var relic = RelicInstance.new(data)
	if add_relic(relic):
		return relic
	return null


## Remove a relic from inventory
func remove_relic(relic: RelicInstance) -> bool:
	var index = relics.find(relic)
	if index == -1:
		return false
	
	relics.remove_at(index)
	relic_removed.emit(relic)
	inventory_changed.emit()
	return true


## Get all unattached relics
func get_available_relics() -> Array[RelicInstance]:
	var available: Array[RelicInstance] = []
	for relic in relics:
		if not relic.is_attached():
			available.append(relic)
	return available


## Get relics attached to a specific panel
func get_relics_on_panel(panel_index: int) -> Array[RelicInstance]:
	var panel_relics: Array[RelicInstance] = []
	for relic in relics:
		if relic.attached_panel_index == panel_index:
			panel_relics.append(relic)
	return panel_relics


# --- Modifier Management ---

## Add a modifier to inventory
func add_modifier(modifier: SlotModifierData) -> bool:
	if modifiers.size() >= max_modifiers:
		push_warning("Modifier inventory full")
		return false
	
	modifiers.append(modifier)
	modifier_added.emit(modifier)
	inventory_changed.emit()
	_notify_acquired(&"slot_modifier", modifier.id)
	return true


## Remove a modifier from inventory (when used)
func remove_modifier(modifier: SlotModifierData) -> bool:
	var index = modifiers.find(modifier)
	if index == -1:
		return false
	
	modifiers.remove_at(index)
	modifier_removed.emit(modifier)
	inventory_changed.emit()
	return true


## Get all modifiers of a specific type
func get_modifiers_by_type(type: SlotModifierData.ModifierType) -> Array[SlotModifierData]:
	var filtered: Array[SlotModifierData] = []
	for modifier in modifiers:
		if modifier.modifier_type == type:
			filtered.append(modifier)
	return filtered


## Get count of a specific modifier
func get_modifier_count(modifier_id: String) -> int:
	var count = 0
	for modifier in modifiers:
		if modifier.id == modifier_id:
			count += 1
	return count


# --- Slot Piece Management ---

## Add a slot piece to inventory
func add_slot_piece(piece: SlotPieceInstance) -> bool:
	if slot_pieces.size() >= max_slot_pieces:
		push_warning("Slot piece inventory full")
		return false
	
	if piece in slot_pieces:
		return false
	
	slot_pieces.append(piece)
	piece_added.emit(piece)
	inventory_changed.emit()
	_notify_acquired(&"slot_piece", piece.data.id)
	return true


## Create and add a slot piece from data
func add_slot_piece_from_data(data: SlotPieceData) -> SlotPieceInstance:
	var piece = SlotPieceInstance.new(data)
	if add_slot_piece(piece):
		return piece
	return null


## Remove a slot piece from inventory (when placed)
func remove_slot_piece(piece: SlotPieceInstance) -> bool:
	var index = slot_pieces.find(piece)
	if index == -1:
		return false
	
	slot_pieces.remove_at(index)
	piece_removed.emit(piece)
	inventory_changed.emit()
	return true


## Get unplaced slot pieces
func get_available_slot_pieces() -> Array[SlotPieceInstance]:
	var available: Array[SlotPieceInstance] = []
	for piece in slot_pieces:
		if not piece.is_placed:
			available.append(piece)
	return available


## Get pieces by size
func get_slot_pieces_by_size(size: int) -> Array[SlotPieceInstance]:
	var filtered: Array[SlotPieceInstance] = []
	for piece in slot_pieces:
		if piece.data.get_slot_count() == size and not piece.is_placed:
			filtered.append(piece)
	return filtered


## Find a slot piece by its data
func find_piece_by_data(data: SlotPieceData) -> SlotPieceInstance:
	for piece in slot_pieces:
		if piece.data == data:
			return piece
	return null


## Remove a slot piece from inventory by data (convenience method)
func remove_piece(piece: SlotPieceInstance) -> bool:
	return remove_slot_piece(piece)


# --- Inventory Summary ---

## Get a summary of all inventory contents
func get_inventory_summary() -> Dictionary:
	return {
		"relics": {
			"count": relics.size(),
			"max": max_relics,
			"unattached": get_available_relics().size()
		},
		"modifiers": {
			"count": modifiers.size(),
			"max": max_modifiers
		},
		"slot_pieces": {
			"count": slot_pieces.size(),
			"max": max_slot_pieces,
			"unplaced": get_available_slot_pieces().size()
		}
	}


## Get total item count
func get_total_item_count() -> int:
	return relics.size() + modifiers.size() + slot_pieces.size()


## Check if inventory has any items
func is_empty() -> bool:
	return get_total_item_count() == 0


# --- Serialization ---

## Convert inventory to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"relics": relics.map(func(r): return r.data.id),
		"modifiers": modifiers.map(func(m): return m.id),
		"slot_pieces": slot_pieces.map(func(p): return {
			"id": p.data.id,
			"rotation": p.current_rotation,
			"is_placed": p.is_placed,
			"panel": p.placed_on_panel_index,
			"coord": {"x": p.placed_at_coord.x, "y": p.placed_at_coord.y}
		})
	}


## Clear all inventory (for new run)
func clear_all() -> void:
	relics.clear()
	modifiers.clear()
	slot_pieces.clear()
	inventory_changed.emit()


## Reset for new battle (reset relic states)
func reset_for_battle() -> void:
	for relic in relics:
		relic.reset_for_battle()
