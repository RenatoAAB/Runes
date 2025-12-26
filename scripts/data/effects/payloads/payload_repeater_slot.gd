class_name PayloadRepeaterSlot
extends EffectPayload

## Makes target slots trigger their runes multiple times.
## This is the "Trigger Duplo" effect from GDD 3.3.

@export var extra_triggers: int = 1  ## Additional triggers beyond the base 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		var new_count = slot.get_trigger_count() + extra_triggers
		slot.set_trigger_count(new_count)
		
		# Notify UI of slot change
		context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	if extra_triggers == 1:
		return "Runes in this slot trigger twice"
	else:
		return "Runes in this slot trigger %d extra times" % extra_triggers

func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER, Keywords.CHAIN]
