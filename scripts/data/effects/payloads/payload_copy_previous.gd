class_name PayloadCopyPrevious
extends EffectPayload

## Copies and executes the effects of the previous rune.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var current_idx = context.current_step_index
	var prev_idx = current_idx - 1
	
	if prev_idx < 0:
		print("Repeater: No previous rune to copy")
		return
	
	var y = prev_idx / GridManager.GRID_SIZE
	var x = prev_idx % GridManager.GRID_SIZE
	var prev_slot = context.grid.get_slot(Vector2i(x, y))
	
	if prev_slot.is_empty():
		print("Repeater: Previous slot is empty")
		return
	
	var prev_rune = prev_slot.rune
	
	# Find source slot
	var source_slot: GridSlot = null
	for slot in context.grid.grid:
		if slot.rune == source_rune:
			source_slot = slot
			break
	
	if not source_slot:
		return
	
	# Execute all effects of the previous rune as if from this rune's position
	for effect in prev_rune.data.effects:
		effect.execute(source_rune, context, source_slot)
	
	print("Repeater: Copied effects from %s" % prev_rune.data.rune_name)

func get_description() -> String:
	return "Copies effects of previous rune"

func get_keywords() -> Array[StringName]:
	return [Keywords.MIMIC, Keywords.ECHO]
