class_name SlotProcessor
extends RefCounted

## Centralized processing and storage for slot effects.

var _slot_data: Dictionary = {}
var _global_data: Dictionary = {}


func _slot_key(slot: GridSlot) -> String:
	return "%d_%d" % [slot.grid_position.x, slot.grid_position.y]


func set_slot_data(slot: GridSlot, key: String, value: Variant) -> void:
	if not slot:
		return
	var slot_key = _slot_key(slot)
	var data = _slot_data.get(slot_key, {})
	data[key] = value
	_slot_data[slot_key] = data


func get_slot_data(slot: GridSlot, key: String, default_value: Variant = null) -> Variant:
	if not slot:
		return default_value
	var slot_key = _slot_key(slot)
	if not _slot_data.has(slot_key):
		return default_value
	var data = _slot_data[slot_key]
	return data.get(key, default_value)


func clear_slot_data(slot: GridSlot, key: String) -> void:
	if not slot:
		return
	var slot_key = _slot_key(slot)
	if not _slot_data.has(slot_key):
		return
	var data = _slot_data[slot_key]
	data.erase(key)
	if data.is_empty():
		_slot_data.erase(slot_key)
	else:
		_slot_data[slot_key] = data


func set_global_data(key: String, value: Variant) -> void:
	_global_data[key] = value


func get_global_data(key: String, default_value: Variant = null) -> Variant:
	return _global_data.get(key, default_value)


func clear_global_data(key: String) -> void:
	_global_data.erase(key)
