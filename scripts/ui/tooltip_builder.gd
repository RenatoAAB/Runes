class_name TooltipBuilder
extends Object

## Single point of BBCode tooltip generation for the entire game.
## All tooltip content is generated here, then handed to TooltipManager for rendering.
## Usa TooltipFormatter para toda formatação BBCode — não adicione BBCode inline aqui.


# --- Rune Tooltip ---

static func build_rune_tooltip(rune: RuneInstance, ctx: EffectContext, can_evaluate: bool, shop_price_text: String = "") -> String:
	if not rune or not rune.data:
		return ""

	var base_elements = GameEnums.normalize_elements(rune.get_elements())
	var elements_str = _build_element_icons_text(base_elements)

	var activations = rune.get_max_activations()
	var activation_text = _format_activation_text(rune, activations)

	# Header with optional shop price
	var header = TooltipFormatter.bold(rune.data.rune_name)
	if not shop_price_text.is_empty():
		header = "%s  %s" % [TooltipFormatter.bold(rune.data.rune_name), TooltipFormatter.bold_color(shop_price_text, "gold")]

	var info = "%s\n%s | %s\n%s" % [header, elements_str, activation_text, TooltipTexts.LABEL_TIER % rune.data.tier]

	# Use description_override if set on the RuneData
	if not rune.data.description_override.is_empty():
		info += "\n" + rune.data.description_override
		return info

	# Effects
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		var color_marker = TooltipFormatter.effect_marker(i)

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
			text += TooltipFormatter.residue_line(rid)

	# Active states (skip residue states already handled above)
	for state_id in slot.active_states:
		if (state_id as String).begins_with(SlotInstance.RESIDUE_PREFIX):
			continue
		var data = slot.active_states[state_id]
		var state_desc = TooltipTexts.get_state_description(state_id)
		var duration_text = TooltipTexts.LABEL_PERMANENT if data["duration"] > 9999 else TooltipTexts.LABEL_DURATION % data["duration"]
		var state_name = state_id.capitalize().replace("_", " ")
		text += "%s %s\n" % [TooltipFormatter.colorize(state_name, Color.YELLOW), duration_text]
		if not state_desc.is_empty():
			text += "%s\n" % state_desc
		if data.get("score_bonus", 0) != 0:
			text += "%s\n" % TooltipFormatter.colorize(TooltipTexts.LABEL_SCORE_BONUS % data["score_bonus"], Color.CYAN)
		if data.get("activation_bonus", 0) != 0:
			text += "%s\n" % TooltipFormatter.colorize(TooltipTexts.LABEL_ACTIVATION_BONUS % data["activation_bonus"], Color.CYAN)
		if data.get("multiplier_bonus", 0.0) != 0.0:
			text += "%s\n" % TooltipFormatter.colorize(TooltipTexts.LABEL_MULTIPLIER_BONUS % data["multiplier_bonus"], Color.YELLOW)

	return text


# --- Relic Tooltip ---

static func build_relic_tooltip(data: RelicData, relic_instance: RelicInstance = null, shop_price_text: String = "") -> String:
	if not data:
		return ""

	var header = TooltipFormatter.bold(data.display_name)
	if not shop_price_text.is_empty():
		header += "  %s" % TooltipFormatter.bold_color(shop_price_text, "gold")
	header += " %s" % TooltipFormatter.rarity_tag(data.rarity)

	var text = header
	text += "\n%s" % TooltipFormatter.colorize("Multiplicador Pós-Painel", Color.GRAY)

	# Show calculator description (precise with values) or fallback to data.description
	if data.has_calculator():
		var calc_desc = data.calculator.get_description()
		if not calc_desc.is_empty():
			text += "\n%s" % TooltipFormatter.colorize(calc_desc, Color.SILVER)
		elif not data.description.is_empty():
			text += "\n%s" % TooltipFormatter.colorize(data.description, Color.SILVER)
	elif not data.description.is_empty():
		text += "\n%s" % TooltipFormatter.colorize(data.description, Color.SILVER)

	if relic_instance and relic_instance.last_calculated_multiplier != 1.0:
		text += "\n%s" % TooltipFormatter.colorize("Último: ×%.2f" % relic_instance.last_calculated_multiplier, Color.YELLOW)

	return text


# --- Modifier Tooltip ---

static func build_modifier_tooltip(data: SlotModifierData, shop_price_text: String = "") -> String:
	if not data:
		return ""

	var header = TooltipFormatter.bold(data.display_name)
	if not shop_price_text.is_empty():
		header += "  %s" % TooltipFormatter.bold_color(shop_price_text, "gold")
	header += " %s" % TooltipFormatter.rarity_tag(data.rarity)

	var text = header

	var type_name = TooltipTexts.get_modifier_type_name(data.modifier_type)
	text += "\n%s" % TooltipFormatter.colorize(type_name, Color.CYAN)

	# Slot type override
	if data.slot_data_override:
		text += "\n%s %s" % [TooltipFormatter.colorize("Tipo de Slot:", Color.ORANGE), data.slot_data_override.slot_name]

	if data.description and not data.description.is_empty():
		text += "\n%s" % TooltipFormatter.colorize(data.description, Color.SILVER)
	else:
		text += "\n%s" % TooltipFormatter.colorize(TooltipTexts.get_modifier_auto_description(data), Color.SILVER)

	if data.is_anomalous:
		var raw_desc = "Anômalo: produz uma anomalia de mana após ser lido."
		text += "\n%s" % TooltipFormatter.bold(TooltipFormatter.format(raw_desc))

	return text


# --- Piece Tooltip ---

static func build_piece_tooltip(data: SlotPieceData, shop_price_text: String = "") -> String:
	if not data:
		return ""

	var header = TooltipFormatter.bold(data.display_name)
	if not shop_price_text.is_empty():
		header += "  %s" % TooltipFormatter.bold_color(shop_price_text, "gold")
	header += " %s" % TooltipFormatter.rarity_tag(data.rarity)

	var text = header
	text += "\n%s" % TooltipFormatter.colorize(TooltipTexts.LABEL_SLOTS % data.get_slot_count(), Color.YELLOW)

	if data.description and not data.description.is_empty():
		text += "\n%s" % TooltipFormatter.colorize(data.description, Color.SILVER)

	if data.has_meta("can_receive_modifiers") and not data.get_meta("can_receive_modifiers"):
		text += "\n%s" % TooltipFormatter.bold(TooltipFormatter.colorize("DEFEITUOSA: Os slots desbloqueados por esta peça de overclock NUNCA poderão receber nenhum modificador.", Color.RED))

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
	var text = TooltipFormatter.bold(TooltipFormatter.colorize("Última rodada", Color.GRAY))
	text += "\n%s pts" % TooltipFormatter.colorize("+%d" % prev_score, Color.CYAN)
	text += "\n%s ativações" % TooltipFormatter.colorize("★%d" % prev_activations, Color.YELLOW)
	return text


# --- Shop: Element Distribution Tooltip ---

static func build_element_distribution_tooltip(element_weights: Dictionary, rarity_probabilities: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(TooltipFormatter.bold("Distribuição Elemental"))

	var ordered_elements: Array[GameEnums.Element] = [
		GameEnums.Element.FIRE,
		GameEnums.Element.WATER,
		GameEnums.Element.EARTH,
		GameEnums.Element.AIR,
		GameEnums.Element.SPIRIT
	]

	for element in ordered_elements:
		var icon = TooltipFormatter.element_icon(element)
		var element_name = _get_element_name_pt_br(element)
		var raw_value = float(element_weights.get(element, 0.0))
		var percent = int(round(raw_value * 100.0))
		lines.append("%s %s: [color=yellow]%d%%[/color]" % [icon, element_name, percent])

	lines.append(TooltipTexts.SEPARATOR)
	lines.append(TooltipFormatter.bold("Chance por Raridade"))

	var ordered_rarities: Array[GameEnums.Rarity] = [
		GameEnums.Rarity.COMMON,
		GameEnums.Rarity.UNCOMMON,
		GameEnums.Rarity.RARE,
		GameEnums.Rarity.EPIC,
		GameEnums.Rarity.LEGENDARY
	]

	for rarity in ordered_rarities:
		var rarity_tag = TooltipFormatter.rarity_tag(rarity)
		var raw_prob = float(rarity_probabilities.get(rarity, 0.0))
		var percent = int(round(raw_prob * 100.0))
		lines.append("%s: [color=yellow]%d%%[/color]" % [rarity_tag, percent])

	return "\n".join(lines)


# --- Private Helpers ---

static func _build_element_icons_text(base_elements: Array[GameEnums.Element]) -> String:
	if base_elements.is_empty():
		return "None"
	return TooltipFormatter.element_icons(base_elements)


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

	var perm_reader_return = rune.permanent_buffs.get("reader_return_bonus", 0)
	if perm_reader_return != 0:
		parts.append(TooltipTexts.LABEL_READER_RETURN_BONUS % perm_reader_return + " " + TooltipTexts.LABEL_PERMANENT)

	var temp_score = rune.stat_modifiers.get("score_bonus", 0)
	if temp_score != 0:
		parts.append("[color=cyan]" + TooltipTexts.LABEL_SCORE_BONUS % temp_score + "[/color]")

	var temp_mult = rune.stat_modifiers.get("score_multiplier", 1.0)
	if temp_mult != 1.0:
		parts.append("[color=cyan]" + TooltipTexts.LABEL_MULTIPLIER_BONUS % (temp_mult - 1.0) + "[/color]")

	var temp_reader_return = rune.stat_modifiers.get("reader_return_bonus", 0)
	if temp_reader_return != 0:
		parts.append("[color=cyan]" + TooltipTexts.LABEL_READER_RETURN_BONUS % temp_reader_return + "[/color]")

	if parts.is_empty():
		return ""
	return TooltipFormatter.colorize("⬆ " + ", ".join(parts), Color.YELLOW)


static func _get_element_name_pt_br(element: GameEnums.Element) -> String:
	match element:
		GameEnums.Element.FIRE:
			return "Fogo"
		GameEnums.Element.WATER:
			return "Água"
		GameEnums.Element.EARTH:
			return "Terra"
		GameEnums.Element.AIR:
			return "Ar"
		GameEnums.Element.SPIRIT:
			return "Espírito"
		_:
			return "Desconhecido"
