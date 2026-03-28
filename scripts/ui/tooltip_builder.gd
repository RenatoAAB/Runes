class_name TooltipBuilder
extends Object

## Single point of BBCode tooltip generation for the entire game.
## All tooltip content is generated here, then handed to TooltipManager for rendering.
## All tooltip content is generated here using the GameEffect system.

const ELEMENT_ICON_PATHS := {
	GameEnums.Element.FIRE: "res://sprites/icons/elements/fire-element-icon.png",
	GameEnums.Element.WATER: "res://sprites/icons/elements/water-element-icon.png",
	GameEnums.Element.EARTH: "res://sprites/icons/elements/earth-element-icon.png",
	GameEnums.Element.AIR: "res://sprites/icons/elements/air-element-icon.png",
	GameEnums.Element.SPIRIT: "res://sprites/icons/elements/spirit-element-icon.png",
}


# --- Rune Tooltip ---

static func build_rune_tooltip(rune: RuneInstance, ctx: EffectContext, can_evaluate: bool, shop_price_text: String = "") -> String:
	if not rune or not rune.data:
		return ""

	var base_elements = GameEnums.normalize_elements(rune.get_elements())
	var elements_str = _build_element_icons_text(base_elements)

	var activations = rune.get_max_activations()
	var activation_text = _format_activation_text(rune, activations)

	# Header with optional shop price
	var header = "[b]%s[/b]" % rune.data.rune_name
	if not shop_price_text.is_empty():
		header = "[b]%s[/b]  [color=gold][b]%s[/b][/color]" % [rune.data.rune_name, shop_price_text]

	var info = "%s\n%s | %s\n%s" % [header, elements_str, activation_text, TooltipTexts.LABEL_TIER % rune.data.tier]

	# Use description_override if set on the RuneData
	if not rune.data.description_override.is_empty():
		info += "\n" + rune.data.description_override
		return info

	# Effects
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		var color_marker = EffectColors.get_color_marker(i)

		var eval_ctx: EffectContext = null
		var is_condition_met = true
		if can_evaluate and ctx and ctx.battle and ctx.source_slot:
			eval_ctx = EffectContext.new(rune, ctx.source_slot, ctx.battle)
			eval_ctx.effect_index = i
			eval_ctx.can_evaluate = can_evaluate
			if effect.condition:
				is_condition_met = effect.condition.evaluate(eval_ctx)

		var effect_desc = _get_effect_description(effect, rune, i, is_condition_met, can_evaluate, eval_ctx)
		info += "\n%s %s" % [color_marker, effect_desc]

	# Buff summary
	var buff_text = _build_buff_summary(rune)
	if not buff_text.is_empty():
		info += "\n" + buff_text

	return info


# --- Slot Tooltip ---

static func build_slot_tooltip(slot: GridSlot) -> String:
	if not slot:
		return ""

	var text = ""
	var slot_info = slot.get_slot_info()

	# Name
	if slot_info.get("name", "Empty Slot") != "Empty Slot":
		text += "[b]%s[/b]\n" % slot_info["name"]

	# Modifier effect
	if slot.slot:
		var modifier_data = slot.slot.get_applied_modifier_data()
		if modifier_data:
			var effect_text = modifier_data.description
			if effect_text.is_empty():
				effect_text = modifier_data.get_effect_text()
			text += "[color=silver]%s[/color]\n" % effect_text
			if modifier_data.id == "slot_accumulator":
				var perma_buff = slot.slot.get_meta("accumulator_score_bonus", 0)
				text += "[color=yellow]%s[/color]\n" % (TooltipTexts.LABEL_ACCUMULATED_BUFF % perma_buff)

	# Multiplier
	var mult = slot_info.get("multiplier", 1.0)
	if mult != 1.0:
		var mult_color = "yellow" if mult > 1.0 else "red"
		text += "[color=%s]%s[/color]\n" % [mult_color, TooltipTexts.LABEL_MULTIPLIER % mult]

	# Upgrade level
	var upgrade_level = slot_info.get("upgrade_level", 0)
	if upgrade_level > 0:
		text += "[color=cyan]%s[/color]\n" % (TooltipTexts.LABEL_UPGRADE_LEVEL % upgrade_level)

	# Trigger count
	var trigger_count = slot_info.get("trigger_count", 1)
	if trigger_count > 1:
		text += "[color=purple]%s[/color]\n" % (TooltipTexts.LABEL_TRIGGERS % trigger_count)

	# Special properties
	if slot_info.get("preserves_charges", false):
		text += "[color=green]%s[/color]\n" % TooltipTexts.LABEL_PRESERVES_CHARGES
	if slot_info.get("protects_fragile", false):
		text += "[color=green]%s[/color]\n" % TooltipTexts.LABEL_PROTECTS_FRAGILE
	if slot_info.get("is_broken", false):
		text += "[color=red]%s[/color]\n" % TooltipTexts.LABEL_BROKEN

	# Residues (states with "residue:" prefix) — shown with dedicated formatting
	if slot.slot:
		var residue_ids = slot.slot.get_residue_ids()
		for rid in residue_ids:
			var info = TooltipTexts.get_residue_info(rid)
			if not info.is_empty():
				var rcolor = info.get("color", "#FFCC00")
				text += "[color=%s][b]Resíduo: %s[/b][/color]\n" % [rcolor, info["name"]]
				text += "[color=silver]%s[/color]\n" % info["description"]

	# Active states (skip residue states already handled above)
	for state_id in slot.active_states:
		if (state_id as String).begins_with(SlotInstance.RESIDUE_PREFIX):
			continue
		var data = slot.active_states[state_id]
		var state_desc = TooltipTexts.get_state_description(state_id)
		var duration_text = TooltipTexts.LABEL_PERMANENT if data["duration"] > 9999 else TooltipTexts.LABEL_DURATION % data["duration"]
		var state_name = state_id.capitalize().replace("_", " ")
		text += "[color=yellow]%s[/color] %s\n" % [state_name, duration_text]
		if not state_desc.is_empty():
			text += "%s\n" % state_desc
		if data.get("score_bonus", 0) != 0:
			text += "[color=cyan]%s[/color]\n" % (TooltipTexts.LABEL_SCORE_BONUS % data["score_bonus"])
		if data.get("activation_bonus", 0) != 0:
			text += "[color=cyan]%s[/color]\n" % (TooltipTexts.LABEL_ACTIVATION_BONUS % data["activation_bonus"])
		if data.get("multiplier_bonus", 0.0) != 0.0:
			text += "[color=yellow]%s[/color]\n" % (TooltipTexts.LABEL_MULTIPLIER_BONUS % data["multiplier_bonus"])

	return text


# --- Relic Tooltip ---

static func build_relic_tooltip(data: RelicData, relic_instance: RelicInstance = null) -> String:
	if not data:
		return ""

	var text = "[b]%s[/b]" % data.display_name
	var rarity_color = TooltipTexts.get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, TooltipTexts.get_rarity_name(data.rarity)]

	var full_desc = data.get_full_description()
	if full_desc and not full_desc.is_empty():
		text += "[color=silver]%s[/color]" % full_desc

	if relic_instance and relic_instance.last_calculated_multiplier != 1.0:
		text += "\n[color=yellow]Último: ×%.2f[/color]" % relic_instance.last_calculated_multiplier

	return text


# --- Modifier Tooltip ---

static func build_modifier_tooltip(data: SlotModifierData) -> String:
	if not data:
		return ""

	var text = "[b]%s[/b]" % data.display_name
	var rarity_color = TooltipTexts.get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, TooltipTexts.get_rarity_name(data.rarity)]

	var type_name = TooltipTexts.get_modifier_type_name(data.modifier_type)
	text += "[color=cyan]%s[/color]\n" % type_name

	# Slot type override
	if data.slot_data_override:
		text += "[color=orange]Tipo de Slot:[/color] %s\n" % data.slot_data_override.slot_name
		var slot_desc = data.slot_data_override.get_full_description()
		if slot_desc and not slot_desc.is_empty():
			text += "[color=gray]%s[/color]\n" % slot_desc

	if data.description and not data.description.is_empty():
		text += "[color=silver]%s[/color]" % data.description
	else:
		text += "[color=silver]%s[/color]" % TooltipTexts.get_modifier_auto_description(data)

	return text


# --- Piece Tooltip ---

static func build_piece_tooltip(data: SlotPieceData) -> String:
	if not data:
		return ""

	var text = "[b]%s[/b]" % data.display_name
	var rarity_color = TooltipTexts.get_rarity_color_name(data.rarity)
	text += " [color=%s](%s)[/color]\n" % [rarity_color, TooltipTexts.get_rarity_name(data.rarity)]
	text += "[color=yellow]%s[/color]\n" % (TooltipTexts.LABEL_SLOTS % data.get_slot_count())

	if data.description and not data.description.is_empty():
		text += "[color=silver]%s[/color]" % data.description

	return text


# --- Rune Stats Tooltip (secondary, previous round) ---

static func build_rune_stats_tooltip(rune: RuneInstance) -> String:
	if not rune or not rune.data:
		return ""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return ""
	var stats = tree.root.get_node_or_null("Stats")
	if not stats:
		return ""
	var rune_id = str(rune.data.id)
	var prev_score: int = stats.get_previous_round_score_for_rune(rune_id)
	var prev_activations: int = stats.get_previous_round_activations_for_rune(rune_id)
	if prev_score == 0 and prev_activations == 0:
		return ""
	var text = "[color=gray]Rodada anterior:[/color]"
	text += "\n[color=cyan]%d[/color] pts | %d ativ." % [prev_score, prev_activations]
	return text


# --- Private Helpers ---

static func _build_element_icons_text(base_elements: Array[GameEnums.Element]) -> String:
	if base_elements.is_empty():
		return "None"

	var parts: Array[String] = []
	for element in base_elements:
		var icon_path: String = ELEMENT_ICON_PATHS.get(element, "")
		if not icon_path.is_empty():
			parts.append("[img=9x9]%s[/img]" % icon_path)
		else:
			parts.append(GameEnums.Element.keys()[element])

	return " ".join(parts)


static func _format_activation_text(rune: RuneInstance, activations: int) -> String:
	var has_bonus = false
	if rune:
		has_bonus = rune.permanent_buffs.get("activation_bonus", 0) != 0 or rune.stat_modifiers.get("activation_bonus", 0) != 0
	if has_bonus:
		return TooltipTexts.LABEL_ACTIVATIONS_BUFFED % activations
	return TooltipTexts.LABEL_ACTIVATIONS % activations


static func _get_effect_description(effect: GameEffect, rune: RuneInstance, effect_index: int, is_condition_met: bool, can_evaluate: bool, ctx: EffectContext = null) -> String:
	return effect.get_description_colored(effect_index, is_condition_met, can_evaluate, ctx)


static func _build_buff_summary(rune: RuneInstance) -> String:
	if not rune:
		return ""
	var parts: Array[String] = []

	var perm_score = rune.permanent_buffs.get("score_bonus", 0)
	if perm_score != 0:
		parts.append(TooltipTexts.LABEL_SCORE_BONUS % perm_score + " " + TooltipTexts.LABEL_PERMANENT)

	var perm_mult = rune.permanent_buffs.get("score_multiplier", 1.0)
	if perm_mult != 1.0:
		parts.append(TooltipTexts.LABEL_MULTIPLIER_BONUS % (perm_mult - 1.0) + " " + TooltipTexts.LABEL_PERMANENT)

	var temp_score = rune.stat_modifiers.get("score_bonus", 0)
	if temp_score != 0:
		parts.append("[color=cyan]" + TooltipTexts.LABEL_SCORE_BONUS % temp_score + "[/color]")

	var temp_mult = rune.stat_modifiers.get("score_multiplier", 1.0)
	if temp_mult != 1.0:
		parts.append("[color=cyan]" + TooltipTexts.LABEL_MULTIPLIER_BONUS % (temp_mult - 1.0) + "[/color]")

	if parts.is_empty():
		return ""
	return "[color=yellow]⬆ " + ", ".join(parts) + "[/color]"
