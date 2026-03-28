class_name ResidueVisual
extends ColorRect

## Visual overlay for runic residues on a slot.
## Manages shader materials for mana_residue and mana_anomaly.
## Automatically switches material based on active residue IDs.
## Materials are saved as .tres resources for easy tweaking in the Godot Inspector.

# Preloaded ShaderMaterial resources (edit these .tres files in Godot to tweak visuals)
static var _mana_residue_mat: ShaderMaterial
static var _mana_anomaly_mat: ShaderMaterial
static var _materials_loaded := false

var _current_residue_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)  # White base for shader to operate on
	_ensure_materials_loaded()
	# Start invisible
	visible = false


static func _ensure_materials_loaded() -> void:
	if _materials_loaded:
		return
	_mana_residue_mat = load("res://resources/shaders/mat_mana_residue.tres") as ShaderMaterial
	_mana_anomaly_mat = load("res://resources/shaders/mat_mana_anomaly.tres") as ShaderMaterial
	_materials_loaded = true


## Update visual to match the given residue IDs from a SlotInstance.
## Pass an empty array to hide the visual.
func update_residues(residue_ids: Array[String]) -> void:
	# Priority: mana_anomaly > mana_residue (anomaly is more visually dominant)
	var target_id := ""
	if residue_ids.has("mana_anomaly"):
		target_id = "mana_anomaly"
	elif residue_ids.has("mana_residue"):
		target_id = "mana_residue"

	if target_id == _current_residue_id:
		return  # No change needed

	_current_residue_id = target_id

	if target_id.is_empty():
		visible = false
		material = null
		return

	_apply_shader(target_id)
	visible = true


func _apply_shader(residue_id: String) -> void:
	_ensure_materials_loaded()

	match residue_id:
		"mana_residue":
			material = _mana_residue_mat
		"mana_anomaly":
			material = _mana_anomaly_mat
		_:
			visible = false
			return


## Clear residue visual
func clear() -> void:
	_current_residue_id = ""
	visible = false
	material = null


## Get the currently displayed residue ID (empty if none)
func get_current_residue_id() -> String:
	return _current_residue_id
