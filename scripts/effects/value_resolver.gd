class_name ValueResolver
extends Resource

## Resolves dynamic numerical values for Actions.
## Formula: (base + Σ(per[i].count * per[i].per_value)) * final_multiplier
## Clamped to [min_value, max_value] if set.
##
## Examples:
##   base=10, per=[] → 10 (flat score)
##   base=0, per=[{ADJACENT, earth, 5}] → 5 per adjacent earth
##   base=10, per=[{SELF_REMAINING, 10}] → 10 + 10 * remaining

@export var base: float = 0.0
@export var per: Array[ValuePer] = []
@export var final_multiplier: float = 1.0
@export var min_value: float = -INF
@export var max_value: float = INF


func resolve(ctx: EffectContext, targets: Array[GridSlot] = []) -> float:
	var result = base
	for vp in per:
		if vp:
			var cnt = vp.count(ctx, targets)
			result += cnt * vp.per_value
	result *= final_multiplier
	result = clampf(result, min_value, max_value)

	EffectLogger.log_value_resolved(ctx, self, base, result)
	return result


func resolve_int(ctx: EffectContext, targets: Array[GridSlot] = []) -> int:
	return int(resolve(ctx, targets))


func get_description() -> String:
	var parts: Array[String] = []

	if base != 0.0:
		var prefix = "+" if base > 0 else ""
		if base == int(base):
			parts.append("%s%d" % [prefix, int(base)])
		else:
			parts.append("%s%.1f" % [prefix, base])

	for vp in per:
		if not vp:
			continue
		var prefix = "+" if vp.per_value > 0 else ""
		var val_str: String
		if vp.per_value == int(vp.per_value):
			val_str = "%s%d" % [prefix, int(vp.per_value)]
		else:
			val_str = "%s%.1f" % [prefix, vp.per_value]
		parts.append("%s per %s" % [val_str, vp.get_description()])

	if parts.is_empty():
		return "0"

	var desc = " ".join(parts)

	if final_multiplier != 1.0:
		desc += " (×%.1f)" % final_multiplier

	return desc


func get_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	var result: Array[GridSlot] = []
	for vp in per:
		if not vp:
			continue
		for slot in vp.get_source_slots(ctx):
			if slot not in result:
				result.append(slot)
	return result
