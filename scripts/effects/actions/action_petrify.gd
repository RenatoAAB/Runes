class_name ActionPetrify
extends EffectAction

## Petrifies target slots (rune can't move but still activates).

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx:
		return

	for slot in targets:
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_method("petrify"):
			slot.slot.petrify()


func get_description() -> String:
	return "Petrify target slots"


func get_keywords() -> Array[StringName]:
	return [Keywords.PETRIFIED]
