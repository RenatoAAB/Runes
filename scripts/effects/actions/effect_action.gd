class_name EffectAction
extends Resource

## Base class for the action performed by a GameEffect.
## Actions use ValueResolver for dynamic values and report value source slots for highlights.

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	pass


func get_description() -> String:
	return ""


## Returns description with resolved runtime values when context is available.
## Override in actions that display dynamic numerical values.
func get_description_with_context(ctx: EffectContext) -> String:
	return get_description()


## Returns description with keyword/target text colorized by effect index.
## Override in actions that colorize parts of their description.
func get_description_colored(effect_index: int) -> String:
	return get_description()


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	return []


func get_keywords() -> Array[StringName]:
	return []


## Returns buff multiplier for runes in an Enhancer slot.
func _get_enhancer_multiplier(target_slot: GridSlot) -> int:
	if not target_slot or not target_slot.slot or not target_slot.slot.data:
		return 1
	return 2 if target_slot.slot.data.id == "slot_enhancer" else 1


## Formats residue id into a user-facing name (optionally colorized with residue palette).
func _format_residue_name(residue_id: String, use_bbcode: bool = true) -> String:
	if residue_id.is_empty():
		return residue_id

	var fallback_name := _to_title_case(residue_id.replace("_", " "))
	var info := TooltipTexts.get_residue_info(residue_id)
	if info.is_empty():
		return fallback_name

	var display_name := str(info.get("name", fallback_name))
	if not use_bbcode:
		return display_name

	var name_bbcode := str(info.get("name_bbcode", ""))
	if not name_bbcode.is_empty():
		return name_bbcode

	var color := str(info.get("color", "#FFCC00"))
	return "[color=%s]%s[/color]" % [color, display_name]


func _to_title_case(text: String) -> String:
	var words := text.split(" ", false)
	for i in range(words.size()):
		var word = words[i]
		if word.is_empty():
			continue
		if word.length() == 1:
			words[i] = word.to_upper()
		else:
			words[i] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)


## Executes a full slot-based activation cycle for trigger actions.
## Includes slot BEFORE/AFTER hooks, residue hooks, and score context switching.
func _activate_with_slot_pipeline(ctx: EffectContext, slot: GridSlot) -> bool:
	if not ctx or not ctx.battle or not slot or slot.is_empty():
		return false
	var target_rune = slot.rune
	if not target_rune or not target_rune.can_activate():
		return false

	var battle = ctx.battle
	var previous_slot: GridSlot = battle.current_slot
	var previous_rune: RuneInstance = battle.current_rune
	var activations_before = target_rune.current_activations
	var should_preserve = slot.preserves_charges()
	var slot_id = slot.slot.data.id if slot.slot and slot.slot.data else ""
	var pressurizer_double_effect = slot_id == "slot_pressurizer" and GameEnums.has_element(target_rune.get_elements(), GameEnums.Element.AIR)
	var activation_cycles = 2 if pressurizer_double_effect else 1

	battle.current_slot = slot
	battle.current_rune = target_rune

	var residue_snapshot := {}
	if battle.grid and battle.grid.residue_processor:
		residue_snapshot = battle.grid.residue_processor.before_activation(slot, target_rune)

	for i in range(activation_cycles):
		var is_pressurizer_bonus = pressurizer_double_effect and (i == 1)
		slot.on_before_rune_read(battle)
		if is_pressurizer_bonus:
			# Bonus execution: duplicate effects while preserving activation cost.
			var original_activations = target_rune.current_activations
			target_rune.current_activations = max(target_rune.get_max_activations() - 1, 0)
			target_rune.on_activate(battle, slot)
			target_rune.current_activations = original_activations
		else:
			target_rune.on_activate(battle, slot)
		slot.on_rune_activation(battle)

		if battle.grid and battle.grid.residue_processor:
			battle.grid.residue_processor.on_activation(slot, target_rune)

	if battle.grid and battle.grid.residue_processor:
		battle.grid.residue_processor.after_activation(slot, target_rune, residue_snapshot)

	if should_preserve:
		target_rune.current_activations = activations_before

	battle.current_slot = previous_slot
	battle.current_rune = previous_rune
	return true
