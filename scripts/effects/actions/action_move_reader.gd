class_name ActionMoveReader
extends EffectAction

## Moves the reader using ValueResolver for step count.
## Replaces PayloadMoveReaderDynamic with a simpler, composable design.

enum MoveMode {
	REWIND_STEPS,           ## Rewind by resolved value steps
	TO_PREVIOUS_ELEMENT,    ## Jump to last rune of specific element
	TO_RANDOM_VISITED,      ## Jump to random previously visited slot
	TO_START,               ## Jump to first slot
	FORWARD_STEPS,          ## Advance by resolved value steps
	TO_NEAREST_RESIDUE,     ## Jump to nearest slot with specific residue (search backwards)
}

@export var mode: MoveMode = MoveMode.REWIND_STEPS
@export var value: ValueResolver
@export var target_element: GameEnums.Element = GameEnums.Element.FIRE
@export var target_residue_id: String = "mana_residue"  ## For TO_NEAREST_RESIDUE mode


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	var path_length = ctx.battle.get_reader_path_length()
	if path_length <= 0:
		return

	var current_idx = clampi(ctx.battle.current_step_index, 0, path_length - 1)
	var base_idx = current_idx
	if ctx.battle.has_meta("reader_pending_jump_index"):
		base_idx = clampi(int(ctx.battle.get_meta("reader_pending_jump_index", current_idx)), 0, path_length - 1)
	var target_idx = -1

	match mode:
		MoveMode.REWIND_STEPS:
			var steps = value.resolve_int(ctx, targets) if value else 1
			target_idx = max(0, base_idx - steps)
		MoveMode.FORWARD_STEPS:
			var steps = value.resolve_int(ctx, targets) if value else 1
			target_idx = min(path_length - 1, base_idx + steps)
		MoveMode.TO_PREVIOUS_ELEMENT:
			target_idx = _find_previous_element(ctx, base_idx)
		MoveMode.TO_RANDOM_VISITED:
			target_idx = ctx.battle.get_random_visited_slot()
		MoveMode.TO_START:
			target_idx = 0
		MoveMode.TO_NEAREST_RESIDUE:
			target_idx = ctx.battle.find_nearest_residue_slot(target_residue_id, base_idx, true)

	if target_idx >= 0 and target_idx < path_length:
		ctx.battle.set_meta("reader_pending_jump_index", target_idx)
		ctx.battle.request_reader_jump(target_idx)


func _find_previous_element(ctx: EffectContext, current_index: int) -> int:
	for i in range(current_index - 1, -1, -1):
		var coord = ctx.battle.get_reader_coord(i)
		if coord.x >= 0:
			var slot = ctx.battle.grid.get_slot(coord)
			if slot and not slot.is_empty():
				if target_element in slot.rune.get_elements():
					return i
	return -1


func get_description() -> String:
	match mode:
		MoveMode.REWIND_STEPS:
			var val_desc = value.get_description() if value else "1"
			return "Reader rewinds %s step(s)" % val_desc
		MoveMode.FORWARD_STEPS:
			var val_desc = value.get_description() if value else "1"
			return "Reader advances %s step(s)" % val_desc
		MoveMode.TO_PREVIOUS_ELEMENT:
			return "Reader jumps to previous %s rune" % ElementIcons.get_bbcode(target_element)
		MoveMode.TO_RANDOM_VISITED:
			return "Reader jumps to random visited slot"
		MoveMode.TO_START:
			return "Reader jumps to start"
		MoveMode.TO_NEAREST_RESIDUE:
			var display := TooltipTexts.get_residue_info(target_residue_id).get("name", target_residue_id) as String
			return "Reader jumps back to nearest %s" % display
	return "Reader moves"


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not value:
		return []
	return value.get_source_slots(ctx)


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
