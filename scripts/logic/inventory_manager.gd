class_name InventoryManager
extends Node

## Manages the player's inventory of Runes.
## Uses fixed slots where each slot can be empty (null) or contain a rune.
## Players can organize runes in any order they prefer.

signal inventory_updated

# Fixed-size array of slots - each slot is either null or a RuneInstance
var slots: Array = []  # Array of RuneInstance or null
@export var max_slots: int = 8


func _ready() -> void:
	# Initialize slots array with nulls
	_initialize_slots()


func _initialize_slots() -> void:
	slots.clear()
	for i in range(max_slots):
		slots.append(null)


## Add a rune to the first available slot
func add_rune(rune: RuneInstance) -> bool:
	var empty_slot = _find_first_empty_slot()
	if empty_slot == -1:
		return false
	slots[empty_slot] = rune
	inventory_updated.emit()
	return true


## Add a rune to a specific slot index
func add_rune_at(rune: RuneInstance, index: int) -> bool:
	if index < 0 or index >= max_slots:
		return false
	if slots[index] != null:
		return false  # Slot is occupied
	slots[index] = rune
	inventory_updated.emit()
	return true


## Remove a rune from inventory (finds it and clears the slot)
func remove_rune(rune: RuneInstance) -> void:
	for i in range(slots.size()):
		if slots[i] == rune:
			slots[i] = null
			inventory_updated.emit()
			return


## Remove rune at specific slot index
func remove_rune_at(index: int) -> RuneInstance:
	if index < 0 or index >= slots.size():
		return null
	var rune = slots[index]
	slots[index] = null
	if rune:
		inventory_updated.emit()
	return rune


## Get rune at specific slot index
func get_rune_at(index: int) -> RuneInstance:
	if index >= 0 and index < slots.size():
		return slots[index]
	return null


## Set rune at specific slot index (for swapping/moving)
func set_rune_at(index: int, rune: RuneInstance) -> void:
	if index >= 0 and index < slots.size():
		slots[index] = rune
		inventory_updated.emit()


## Swap runes between two slots
func swap_slots(index1: int, index2: int) -> void:
	if index1 < 0 or index1 >= slots.size():
		return
	if index2 < 0 or index2 >= slots.size():
		return
	var temp = slots[index1]
	slots[index1] = slots[index2]
	slots[index2] = temp
	inventory_updated.emit()


## Check if a rune is in the inventory
func has_rune(rune: RuneInstance) -> bool:
	return rune in slots


## Get all non-null runes (for iteration)
var runes: Array[RuneInstance]:
	get:
		var result: Array[RuneInstance] = []
		for slot in slots:
			if slot != null:
				result.append(slot)
		return result


## Find the first empty slot index, or -1 if full
func _find_first_empty_slot() -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			return i
	return -1


## Get total number of runes in inventory
func get_rune_count() -> int:
	var count = 0
	for slot in slots:
		if slot != null:
			count += 1
	return count


## Check if inventory is full
func is_full() -> bool:
	return _find_first_empty_slot() == -1


## Clear all slots in the inventory
func clear_all() -> void:
	_initialize_slots()
	inventory_updated.emit()
