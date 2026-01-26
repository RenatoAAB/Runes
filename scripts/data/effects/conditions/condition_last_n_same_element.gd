class_name ConditionLastNSameElement
extends EffectCondition

## True when the last N activations all share the same element.
@export var activation_count: int = 3

func evaluate(_source_rune: RuneInstance, context: BattleContext, _source_slot: GridSlot) -> bool:
	return context.last_n_same_element(activation_count)


func get_relevant_slots(_source_rune: RuneInstance, context: BattleContext, _source_slot: GridSlot) -> Array[GridSlot]:
	var slots: Array[GridSlot] = []
	var history = context.get_last_n_activations(activation_count)
	for entry in history:
		var pos: Vector2i = entry.get("slot_position", Vector2i(-1, -1))
		if pos.x >= 0:
			var slot = context.grid.get_slot(pos)
			if slot:
				slots.append(slot)
	return slots


func get_description() -> String:
	return "last %d activations were the same element" % activation_count


func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
