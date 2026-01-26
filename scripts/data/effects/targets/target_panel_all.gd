class_name TargetPanelAll
extends EffectTarget

## Targets every usable slot on the panel (ignores void/disabled slots).
func get_targets(_source_rune: RuneInstance, context: BattleContext, _source_slot: GridSlot) -> Array[GridSlot]:
	var slots: Array[GridSlot] = []
	for slot in context.grid.grid:
		if slot.is_void():
			continue
		slots.append(slot)
	return slots

func get_description() -> String:
	return "All valid panel slots"

func get_keywords() -> Array[StringName]:
	return []
