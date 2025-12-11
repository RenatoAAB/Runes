class_name PayloadBuffRowColumn
extends EffectPayload

## Adds activations to all runes in the same row and/or column.

enum Axis { ROW, COLUMN, BOTH }

@export var axis: Axis = Axis.ROW
@export var activation_bonus: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Find source slot
	var source_slot: GridSlot = null
	for slot in context.grid.grid:
		if slot.rune == source_rune:
			source_slot = slot
			break
	
	if not source_slot:
		return
	
	var slots_to_buff: Array[GridSlot] = []
	
	if axis == Axis.ROW or axis == Axis.BOTH:
		slots_to_buff.append_array(context.grid.get_row(source_slot.grid_position.y))
	
	if axis == Axis.COLUMN or axis == Axis.BOTH:
		slots_to_buff.append_array(context.grid.get_column(source_slot.grid_position.x))
	
	for slot in slots_to_buff:
		if not slot.is_empty() and slot.rune != source_rune:
			slot.rune.stat_modifiers["activation_bonus"] = slot.rune.stat_modifiers.get("activation_bonus", 0) + activation_bonus
			print("Buffed %s with +%d activations" % [slot.rune.data.rune_name, activation_bonus])

func get_description() -> String:
	match axis:
		Axis.ROW: return "+%d activations to entire row" % activation_bonus
		Axis.COLUMN: return "+%d activations to entire column" % activation_bonus
		Axis.BOTH: return "+%d activations to row and column" % activation_bonus
	return ""
