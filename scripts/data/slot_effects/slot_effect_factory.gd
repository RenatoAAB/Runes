class_name SlotEffectFactory
extends Object

const SlotEffect = preload("res://scripts/data/slot_effects/slot_effect.gd")

const SlotPayloadTransmuterSet = preload("res://scripts/data/slot_effects/payloads/slot_payload_transmuter_set.gd")
const SlotPayloadClearElementOverride = preload("res://scripts/data/slot_effects/payloads/slot_payload_clear_element_override.gd")
const SlotPayloadEnhancerSnapshot = preload("res://scripts/data/slot_effects/payloads/slot_payload_enhancer_snapshot.gd")
const SlotPayloadEnhancerApply = preload("res://scripts/data/slot_effects/payloads/slot_payload_enhancer_apply.gd")
const SlotPayloadCreateRandomRuneIfEmpty = preload("res://scripts/data/slot_effects/payloads/slot_payload_create_random_rune_if_empty.gd")
const SlotPayloadActivateAllConnectors = preload("res://scripts/data/slot_effects/payloads/slot_payload_activate_all_connectors.gd")
const SlotPayloadCharger = preload("res://scripts/data/slot_effects/payloads/slot_payload_charger.gd")
const SlotPayloadResonatorApply = preload("res://scripts/data/slot_effects/payloads/slot_payload_resonator_apply.gd")
const SlotPayloadRestoreMultiplier = preload("res://scripts/data/slot_effects/payloads/slot_payload_restore_multiplier.gd")
const SlotPayloadIgniterApply = preload("res://scripts/data/slot_effects/payloads/slot_payload_igniter_apply.gd")
const SlotPayloadAccumulatorApply = preload("res://scripts/data/slot_effects/payloads/slot_payload_accumulator_apply.gd")
const SlotPayloadAccumulatorStore = preload("res://scripts/data/slot_effects/payloads/slot_payload_accumulator_store.gd")
const SlotPayloadStabilizerBegin = preload("res://scripts/data/slot_effects/payloads/slot_payload_stabilizer_begin.gd")
const SlotPayloadStabilizerEnd = preload("res://scripts/data/slot_effects/payloads/slot_payload_stabilizer_end.gd")
const SlotPayloadPurifierNext = preload("res://scripts/data/slot_effects/payloads/slot_payload_purifier_next.gd")

static func build(slot_id: String) -> Array[SlotEffect]:
	var effects: Array[SlotEffect] = []
	match slot_id:
		"slot_transmuter":
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, SlotPayloadTransmuterSet.new()))
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadClearElementOverride.new()))
		"slot_enhancer":
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, SlotPayloadEnhancerSnapshot.new()))
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadEnhancerApply.new()))
		"slot_dispenser":
			effects.append(_make(SlotEffect.SlotEffectTrigger.ROUND_END, SlotPayloadCreateRandomRuneIfEmpty.new()))
		"slot_conector":
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadActivateAllConnectors.new()))
		"slot_charger":
			effects.append(_make(SlotEffect.SlotEffectTrigger.ROUND_START, SlotPayloadCharger.new()))
		"slot_resonator":
			var apply = SlotPayloadResonatorApply.new()
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, apply))
			var restore = SlotPayloadRestoreMultiplier.new()
			restore.meta_key_prefix = "resonator_mult"
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, restore))
		"slot_igniter":
			var apply_ignite = SlotPayloadIgniterApply.new()
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, apply_ignite))
			var restore_ignite = SlotPayloadRestoreMultiplier.new()
			restore_ignite.meta_key_prefix = "igniter_mult"
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, restore_ignite))
		"slot_accumulator":
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, SlotPayloadAccumulatorApply.new()))
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadAccumulatorStore.new()))
		"slot_stabilizer":
			effects.append(_make(SlotEffect.SlotEffectTrigger.BEFORE_RUNE_READ, SlotPayloadStabilizerBegin.new()))
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadStabilizerEnd.new()))
		"slot_purifier":
			effects.append(_make(SlotEffect.SlotEffectTrigger.AFTER_RUNE_READ, SlotPayloadPurifierNext.new()))
		_:
			pass
	return effects

static func _make(trigger: int, payload: SlotEffectPayload) -> SlotEffect:
	var effect = SlotEffect.new()
	effect.trigger = trigger
	effect.payload = payload
	return effect
