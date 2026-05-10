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
