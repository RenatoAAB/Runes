class_name ResidueProcessor
extends RefCounted

## Centralized processing for rune residues (slot states).

func should_skip_read(slot: GridSlot) -> bool:
	# Descompassado: skip first read each round
	if slot.has_state("descompassado") and not slot.slot.skipped_first_read_this_round:
		slot.slot.skipped_first_read_this_round = true
		return true
	# Desestabilizado: 50% chance to do nothing when read
	if slot.has_state("desestabilizado") and randf() < 0.5:
		return true
	return false


func before_activation(slot: GridSlot, rune: RuneInstance) -> Dictionary:
	var snapshot := {}
	# Descarregado: only one activation per round
	if slot.has_state("descarregado"):
		rune.set_max_activations_override(1)
	# Vitrificado: snapshot buffs to restore after activation
	if slot.has_state("vitrificado"):
		snapshot["permanent_buffs"] = rune.permanent_buffs.duplicate(true)
		snapshot["stat_modifiers"] = rune.stat_modifiers.duplicate(true)
		snapshot["temporary_buffs"] = rune.temporary_buffs.duplicate(true)
	return snapshot


func on_activation(slot: GridSlot, rune: RuneInstance) -> void:
	# Gosmento: permanent score penalty per activation
	if slot.has_state("gosmento"):
		var current_penalty = rune.permanent_buffs.get("score_bonus", 0)
		rune.permanent_buffs["score_bonus"] = current_penalty - 5


func after_activation(slot: GridSlot, rune: RuneInstance, snapshot: Dictionary) -> void:
	# Vitrificado: restore buffs after activation
	if slot.has_state("vitrificado") and not snapshot.is_empty():
		if snapshot.has("permanent_buffs"):
			rune.permanent_buffs = snapshot["permanent_buffs"]
		if snapshot.has("stat_modifiers"):
			rune.stat_modifiers = snapshot["stat_modifiers"]
		if snapshot.has("temporary_buffs"):
			rune.temporary_buffs = snapshot["temporary_buffs"]
	# Descarregado: clear override after activation
	if slot.has_state("descarregado"):
		rune.clear_max_activations_override()


func handle_round_end_for_slot(slot: GridSlot, grid_manager: GridManager) -> void:
	# Faminto: destroy rune at end of round
	if slot.has_state("faminto") and slot.rune:
		slot.remove_rune()
		if grid_manager:
			grid_manager.slot_changed.emit(slot.grid_position)
