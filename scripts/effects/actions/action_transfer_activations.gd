class_name ActionTransferActivations
extends EffectAction

## Drains remaining activations from source's adjacent runes and grants
## the total as activation_bonus to target runes. Used by Gravity.

@export var include_diagonals: bool = false


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle or not ctx.source_slot or not ctx.battle.grid:
		return

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var total_drained: int = 0

	for slot in neighbors:
		if slot.is_empty():
			continue
		var rune: RuneInstance = slot.rune
		var remaining: int = rune.get_max_activations() - rune.current_activations
		if remaining > 0:
			total_drained += remaining
			rune.current_activations = rune.get_max_activations()

	if total_drained <= 0:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		var mult = _get_enhancer_multiplier(slot)
		var final_bonus = total_drained * mult
		var current: int = slot.rune.stat_modifiers.get("activation_bonus", 0)
		slot.rune.stat_modifiers["activation_bonus"] = current + final_bonus
		break  # Only apply to first target


func get_description() -> String:
	return "Drain remaining activations from adjacent runes and give them to the next rune"


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.DEBUFF, Keywords.CHARGED, Keywords.NEIGHBORS]
