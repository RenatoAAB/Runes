class_name ActionCreateRune
extends EffectAction

## Creates a pure element rune in empty target slots.

const RuneLibrary = preload("res://scripts/data/rune_library.gd")

@export var element: GameEnums.Element = GameEnums.Element.WATER
@export var activation_bonus: int = 0


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	var candidates = RuneLibrary.get_pure_runes_for_element(element)
	for slot in targets:
		if slot.is_void() or not slot.is_empty():
			continue
		if candidates.is_empty():
			continue
		var rune_data: RuneData = candidates[randi_range(0, candidates.size() - 1)]
		var instance = RuneInstance.new(rune_data)

		if activation_bonus != 0:
			var mult = _get_enhancer_multiplier(slot)
			var final_bonus = activation_bonus * mult
			instance.permanent_buffs["activation_bonus"] = instance.permanent_buffs.get("activation_bonus", 0) + final_bonus

		slot.set_rune(instance)
		if ctx.battle.grid:
			ctx.battle.grid.slot_changed.emit(slot.grid_position)
		if ctx.battle.event_bus:
			ctx.battle.event_bus.notify_rune_created(slot, instance)
		else:
			ctx.battle.on_rune_created(slot, instance)


func get_description() -> String:
	var icon = ElementIcons.get_bbcode(element)
	var desc = "Create a pure %s rune in empty target" % icon
	if activation_bonus != 0:
		desc += " with +%d permanent activation" % activation_bonus
	return desc


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.CREATE, Keywords.ELEMENT_TARGET]
	if activation_bonus != 0:
		kw.append(Keywords.BUFF)
	return kw
