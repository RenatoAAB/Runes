class_name PayloadTransferAdjacentActivations
extends EffectPayload

## Drains remaining activations from adjacent runes and grants them to the first target rune.
@export var include_diagonals: bool = false

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context or not context.current_slot:
		return
	var neighbors: Array[GridSlot] = context.grid.get_neighbors(context.current_slot.grid_position, include_diagonals)
	var total_transferred: int = 0
	for slot in neighbors:
		if slot.is_empty():
			continue
		var rune: RuneInstance = slot.rune
		var remaining: int = rune.get_max_activations() - rune.current_activations
		if remaining > 0:
			total_transferred += remaining
			rune.current_activations = rune.get_max_activations()
			print("%s drained %d activation(s) from %s" % [source_rune.data.rune_name, remaining, rune.data.rune_name])
	if total_transferred <= 0:
		return
	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune: RuneInstance = slot.rune
		var current_bonus: int = target_rune.stat_modifiers.get("activation_bonus", 0)
		target_rune.stat_modifiers["activation_bonus"] = current_bonus + total_transferred
		print("%s granted %d activation bonus to %s" % [source_rune.data.rune_name, total_transferred, target_rune.data.rune_name])
		break


func get_description() -> String:
	return "Drain remaining activations from adjacent runes and give them to the next rune"


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.DEBUFF, Keywords.CHARGED, Keywords.NEIGHBORS, Keywords.TRIGGER]
