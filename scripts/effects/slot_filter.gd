class_name SlotFilter
extends Resource

## Reusable filter for grid slots. Used by Selectors, ValuePer, and Actions
## to restrict which slots qualify for an operation.

enum SlotState {
	ANY,
	EMPTY,
	OCCUPIED,
	PETRIFIED,
	HAS_RESIDUE,
	HAS_MANA_RESIDUE,
	HAS_MANA_ANOMALY,
}

@export var required_elements: Array[GameEnums.Element] = []
@export var excluded_elements: Array[GameEnums.Element] = []
@export var slot_state: SlotState = SlotState.ANY
@export var require_activations_remaining: bool = false
@export var is_indestructible_filter: int = -1  ## -1 = don't care, 0 = must be destructible, 1 = must be indestructible
## Filter by specific residue ID (empty = don't filter by residue ID)
@export var required_residue_id: String = ""


func matches(slot: GridSlot, _context: BattleContext = null) -> bool:
	if not slot or slot.is_void():
		return false

	match slot_state:
		SlotState.EMPTY:
			if not slot.is_empty():
				return false
		SlotState.OCCUPIED:
			if slot.is_empty():
				return false
		SlotState.PETRIFIED:
			if not slot.slot or not slot.slot.is_petrified():
				return false
		SlotState.HAS_RESIDUE:
			if not slot.slot or not slot.slot.has_residue():
				return false
		SlotState.HAS_MANA_RESIDUE:
			if not slot.slot or not slot.slot.has_specific_residue("mana_residue"):
				return false
		SlotState.HAS_MANA_ANOMALY:
			if not slot.slot or not slot.slot.has_specific_residue("mana_anomaly"):
				return false

	# Check specific residue ID filter
	if not required_residue_id.is_empty():
		if not slot.slot or not slot.slot.has_specific_residue(required_residue_id):
			return false

	if slot.is_empty():
		# For empty slots, only element/rune filters fail
		if not required_elements.is_empty():
			return false
		if require_activations_remaining:
			return false
		return true

	var rune = slot.rune
	var rune_elements = GameEnums.normalize_elements(rune.get_elements())

	if not required_elements.is_empty():
		var has_match = false
		for req_elem in required_elements:
			if req_elem in rune_elements:
				has_match = true
				break
		if not has_match:
			return false

	if not excluded_elements.is_empty():
		for exc_elem in excluded_elements:
			if exc_elem in rune_elements:
				return false

	if require_activations_remaining:
		var remaining = rune.get_max_activations() - rune.current_activations
		if remaining <= 0:
			return false

	if is_indestructible_filter >= 0:
		var is_indestructible = rune.data.is_indestructible
		if is_indestructible_filter == 0 and is_indestructible:
			return false
		if is_indestructible_filter == 1 and not is_indestructible:
			return false

	return true


func get_description() -> String:
	var parts: Array[String] = []

	match slot_state:
		SlotState.EMPTY:
			parts.append("empty")
		SlotState.OCCUPIED:
			parts.append("occupied")
		SlotState.PETRIFIED:
			parts.append("petrified")
		SlotState.HAS_RESIDUE:
			parts.append("with residue")
		SlotState.HAS_MANA_RESIDUE:
			parts.append("with mana residue")
		SlotState.HAS_MANA_ANOMALY:
			parts.append("with mana anomaly")

	if not required_residue_id.is_empty():
		parts.append("with %s" % required_residue_id)

	if not required_elements.is_empty():
		parts.append(ElementIcons.join(required_elements))

	if require_activations_remaining:
		parts.append("with charges")

	if parts.is_empty():
		return ""
	return " ".join(parts)
