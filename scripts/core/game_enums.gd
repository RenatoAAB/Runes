class_name GameEnums
extends Object

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

## Base elements that can combine
enum Element {
	FIRE,
	WATER,
	EARTH,
	AIR,
	SPIRIT
}

const BASE_ELEMENTS: Array[Element] = [
	Element.FIRE,
	Element.WATER,
	Element.EARTH,
	Element.AIR,
	Element.SPIRIT
]

## Ensures only base elements are kept and removes duplicates while preserving order.
static func normalize_elements(elements: Array[Element]) -> Array[Element]:
	var normalized: Array[Element] = []
	for element in elements:
		if element in BASE_ELEMENTS and element not in normalized:
			normalized.append(element)
	return normalized

## Checks if the provided base element is present in the list.
static func has_element(elements: Array[Element], target: Element) -> bool:
	return target in elements

## Returns the count of distinct base elements in the list.
static func get_element_count(elements: Array[Element]) -> int:
	return normalize_elements(elements).size()

## Checks if the list represents a pure element (single base element).
static func is_pure_element(elements: Array[Element]) -> bool:
	return get_element_count(elements) == 1

## Returns the rarity based on how many base elements a rune has.
## 1 element = Common, 2 = Uncommon, 3 = Rare, 4 = Epic, 5 = Legendary
static func get_rarity_by_elements(elements: Array[Element]) -> Rarity:
	var count = get_element_count(elements)
	match count:
		1: return Rarity.COMMON
		2: return Rarity.UNCOMMON
		3: return Rarity.RARE
		4: return Rarity.EPIC
		5: return Rarity.LEGENDARY
		_: return Rarity.COMMON

## Defines when an effect should trigger
enum EffectTrigger {
	ON_READ,                # When the rune is read by the reader (default)
	ON_ACTIVATED,           # When the rune is activated (includes external triggers)
	ON_DESTROY,             # When the rune is destroyed
	ON_ADJACENT_ACTIVATED,  # When an adjacent rune is activated
	ON_ROUND_START,         # At the start of the round
	ON_ROUND_END,           # At the end of the round
	ON_CREATED,             # When the rune is created during the round
	PASSIVE,                # Always active (for permanent buffs, checked contextually)
	ON_BUFF_RECEIVED,       # When a permanent buff is applied to this rune
}

enum Tier {
	TIER_1 = 1,
	TIER_2 = 2,
	TIER_3 = 3
}

## Phases of the game loop
enum GamePhase {
	SETUP,
	PLANNING,
	BATTLE,
	RESOLUTION,
	REWARD,
	UPGRADE
}
