class_name PayloadCreateRune
extends EffectPayload

## Creates a copy of the source rune in an empty target slot.
## Maintains the tier and buffs of the source rune.

@export var copy_source: bool = true

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Find first empty slot
	for slot in targets:
		if slot.is_empty():
			# Create a new RuneInstance based on source
			var new_rune = RuneInstance.new(source_rune.data)
			
			# Copy permanent buffs (mitosis)
			for key in source_rune.permanent_buffs:
				new_rune.permanent_buffs[key] = source_rune.permanent_buffs[key]
			
			# Place the rune
			slot.set_rune(new_rune)
			context.grid.slot_changed.emit(slot.grid_position)
			print("Created %s clone at %s" % [source_rune.data.rune_name, str(slot.grid_position)])
			return # Only create one

func get_description() -> String:
	return "Creates a copy of self in empty target slot"

func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.SELF]
