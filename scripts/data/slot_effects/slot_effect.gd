class_name SlotEffect
extends Resource

## Modular slot effect composed of: Trigger (WHEN), optional Condition (IF), and Payload (WHAT).

const SlotEffectCondition = preload("res://scripts/data/slot_effects/slot_effect_condition.gd")
const SlotEffectPayload = preload("res://scripts/data/slot_effects/slot_effect_payload.gd")

enum SlotEffectTrigger {
	ROUND_START,
	BEFORE_RUNE_READ,
	AFTER_RUNE_READ,
	ROUND_END,
	PASSIVE
}

@export var trigger: SlotEffectTrigger = SlotEffectTrigger.AFTER_RUNE_READ
@export var condition: SlotEffectCondition
@export var payload: SlotEffectPayload

func execute(context: BattleContext, source_slot: GridSlot) -> void:
	if not payload:
		push_warning("SlotEffect missing payload.")
		return
	if condition and not condition.evaluate(context, source_slot):
		return
	payload.execute(context, source_slot)

func get_description() -> String:
	if payload and payload.has_method("get_description"):
		return payload.get_description()
	return ""

func get_keywords() -> Array[StringName]:
	var keywords: Array[StringName] = []
	if condition and condition.has_method("get_keywords"):
		for kw in condition.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	if payload and payload.has_method("get_keywords"):
		for kw in payload.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	return keywords
