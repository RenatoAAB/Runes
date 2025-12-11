class_name PayloadDestroyAndAbsorb
extends EffectPayload

## Destroys target runes and absorbs their power (gains score bonus).

@export var score_per_destroyed: int = 20

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var destroyed_count = 0
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			# Don't destroy self
			if target_rune == source_rune:
				continue
			destroyed_count += 1
			slot.remove_rune()
			context.grid.slot_changed.emit(slot.grid_position)
			print("Destroyed and absorbed %s" % target_rune.data.rune_name)
	
	if destroyed_count > 0:
		var total_gain = destroyed_count * score_per_destroyed
		source_rune.permanent_buffs["score_bonus"] = source_rune.permanent_buffs.get("score_bonus", 0) + total_gain
		print("Gained +%d permanent score from absorbing %d runes" % [total_gain, destroyed_count])

func get_description() -> String:
	return "Destroys targets and gains +%d Score each" % score_per_destroyed
