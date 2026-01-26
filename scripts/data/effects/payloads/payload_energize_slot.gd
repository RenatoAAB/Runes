class_name PayloadEnergizeSlot
extends EffectPayload

## Permanently energizes target slots: extra trigger and preserved charges.
@export var trigger_bonus: int = 1
@export var preserve_charges: bool = true
@export var flag_key: String = "energized_slot"

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot:
			continue
		var slot_instance: SlotInstance = slot.slot
		if slot_instance.get_meta(flag_key, false):
			continue
		slot_instance.set_meta(flag_key, true)
		if preserve_charges:
			slot_instance.set_meta("permanent_preserves_charges", true)
		if trigger_bonus != 0:
			var current_triggers: int = slot_instance.get_meta("permanent_trigger_bonus", 0)
			slot_instance.set_meta("permanent_trigger_bonus", current_triggers + trigger_bonus)
		if context and context.grid:
			context.grid.slot_changed.emit(slot.grid_position)


func get_description() -> String:
	var parts: Array[String] = []
	if trigger_bonus != 0:
		parts.append("+%d permanent trigger" % trigger_bonus)
	if preserve_charges:
		parts.append("preserves charges")
	return "Energize slot (%s)" % ", ".join(parts)


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.CHARGED, Keywords.ALL]
