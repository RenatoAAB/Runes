class_name PayloadMultiplySlot
extends EffectPayload

## Multiplies the score multiplier of target slots.
## Can be temporary (one round) or permanent.

@export var multiplier_bonus: float = 0.5  ## Additive bonus to multiplier
@export var is_permanent: bool = false     ## If true, lasts across rounds

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if is_permanent:
			slot.add_permanent_multiplier(multiplier_bonus)
		else:
			slot.add_temp_multiplier(multiplier_bonus)
		
		# Notify UI of slot change
		context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	var duration_text = "permanently" if is_permanent else "this round"
	if multiplier_bonus >= 0:
		return "Adds +%.1fx multiplier to slot %s" % [multiplier_bonus, duration_text]
	else:
		return "Reduces slot multiplier by %.1fx %s" % [absf(multiplier_bonus), duration_text]

func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.MULTIPLY, Keywords.BUFF]
	if is_permanent:
		kw.append(Keywords.SCALING)
	return kw
