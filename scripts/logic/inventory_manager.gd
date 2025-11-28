class_name InventoryManager
extends Node

## Manages the player's inventory of Runes.
## Simple list-based inventory for now, can be expanded to a grid later.

signal inventory_updated

var runes: Array[RuneInstance] = []
@export var max_slots: int = 10

func add_rune(rune: RuneInstance) -> bool:
	if runes.size() >= max_slots:
		return false
	runes.append(rune)
	inventory_updated.emit()
	return true

func remove_rune(rune: RuneInstance) -> void:
	runes.erase(rune)
	inventory_updated.emit()

func get_rune_at(index: int) -> RuneInstance:
	if index >= 0 and index < runes.size():
		return runes[index]
	return null
