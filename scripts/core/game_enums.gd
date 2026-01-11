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
	# Pure Base Elements
	FIRE,
	WATER,
	EARTH,
	AIR,
	SPIRIT,
	
	# Fire variants (1 element)
	PLASMA,         # Fire
	
	# Water variants (1 element)
	DROP,           # Water (Gota)
	
	# Earth variants (1 element)
	METAL,          # Earth
	CRYSTAL,        # Earth
	ROCK,           # Earth (Rocha)
	BONE,           # Earth (Osso)
	
	# Air variants (1 element)
	WIND,           # Air (Vento)
	SOUND,          # Air (Som)
	
	# Dual combinations - Fire + Water
	ACID,           # Fire + Water
	OIL,            # Fire + Water
	
	# Dual combinations - Fire + Air
	LIGHTNING,      # Fire + Air (Raio)
	
	# Dual combinations - Fire + Earth
	LAVA,           # Fire + Earth
	OBSIDIAN,       # Fire + Earth
	METEOR,         # Fire + Earth
	
	# Dual combinations - Water + Air
	ICE,            # Water + Air
	CLOUD,          # Water + Air (Nuvem)
	
	# Dual combinations - Water + Earth
	MUD,            # Water + Earth (Lama)
	
	# Dual combinations - Air + Earth
	DUST,           # Air + Earth (Poeira)
	EROSION,        # Air + Earth
	
	# Triple combinations (3 elements)
	INSTABILITY,    # Fire + Water + Air
	STERILITY,      # Fire + Earth + Air
	STAGNATION,     # Water + Air + Earth
	GRAVITY,        # Fire + Water + Earth
	
	# Quad combinations (4 elements)
	ENERGY,         # Fire + Water + Earth + Air
	MACHINE,        # Fire + Water + Earth + Air
	
	# Spirit variants (1 element)
	LIGHT,          # Spirit (Luz)
	DARKNESS,       # Spirit (Trevas)
	DREAM,          # Spirit (Sonho)
	VACUUM,         # Spirit (Vácuo)
	
	# Spirit dual combinations (2 elements)
	PHOENIX,        # Spirit + Fire (Fênix)
	SACRED,         # Spirit + Fire (Sagrado)
	EMPATHY,        # Spirit + Water (Empatia)
	NYMPH,          # Spirit + Water (Ninfa)
	GOLEM,          # Spirit + Earth
	TIME,           # Spirit + Air (Tempo)
	DJINN,          # Spirit + Air
	
	# Spirit triple+ (3+ elements)
	NATURE,         # Spirit + Water + Earth (Natureza)
	WORLD,          # Spirit + Fire + Water + Earth + Air (Mundo)
	
	# Utility
	NEUTRAL
}

## Maps each element to its base element components
const ELEMENT_COMPOSITION: Dictionary = {
	# Pure base elements
	Element.FIRE: [Element.FIRE],
	Element.WATER: [Element.WATER],
	Element.EARTH: [Element.EARTH],
	Element.AIR: [Element.AIR],
	Element.SPIRIT: [Element.SPIRIT],
	
	# Fire variants (1 element)
	Element.PLASMA: [Element.FIRE],
	
	# Water variants (1 element)
	Element.DROP: [Element.WATER],
	
	# Earth variants (1 element)
	Element.METAL: [Element.EARTH],
	Element.CRYSTAL: [Element.EARTH],
	Element.ROCK: [Element.EARTH],
	Element.BONE: [Element.EARTH],
	
	# Air variants (1 element)
	Element.WIND: [Element.AIR],
	Element.SOUND: [Element.AIR],
	
	# Fire + Water (2 elements)
	Element.ACID: [Element.FIRE, Element.WATER],
	Element.OIL: [Element.FIRE, Element.WATER],
	
	# Fire + Air (2 elements)
	Element.LIGHTNING: [Element.FIRE, Element.AIR],
	
	# Fire + Earth (2 elements)
	Element.LAVA: [Element.FIRE, Element.EARTH],
	Element.OBSIDIAN: [Element.FIRE, Element.EARTH],
	Element.METEOR: [Element.FIRE, Element.EARTH],
	
	# Water + Air (2 elements)
	Element.ICE: [Element.WATER, Element.AIR],
	Element.CLOUD: [Element.WATER, Element.AIR],
	
	# Water + Earth (2 elements)
	Element.MUD: [Element.WATER, Element.EARTH],
	
	# Air + Earth (2 elements)
	Element.DUST: [Element.AIR, Element.EARTH],
	Element.EROSION: [Element.AIR, Element.EARTH],
	
	# Triple combinations (3 elements)
	Element.INSTABILITY: [Element.FIRE, Element.WATER, Element.AIR],
	Element.STERILITY: [Element.FIRE, Element.EARTH, Element.AIR],
	Element.STAGNATION: [Element.WATER, Element.AIR, Element.EARTH],
	Element.GRAVITY: [Element.FIRE, Element.WATER, Element.EARTH],
	
	# Quad combinations (4 elements)
	Element.ENERGY: [Element.FIRE, Element.WATER, Element.EARTH, Element.AIR],
	Element.MACHINE: [Element.FIRE, Element.WATER, Element.EARTH, Element.AIR],
	
	# Spirit variants (1 element)
	Element.LIGHT: [Element.SPIRIT],
	Element.DARKNESS: [Element.SPIRIT],
	Element.DREAM: [Element.SPIRIT],
	Element.VACUUM: [Element.SPIRIT],
	
	# Spirit + Fire (2 elements)
	Element.PHOENIX: [Element.SPIRIT, Element.FIRE],
	Element.SACRED: [Element.SPIRIT, Element.FIRE],
	Element.EMPATHY: [Element.SPIRIT, Element.WATER],
	Element.NYMPH: [Element.SPIRIT, Element.WATER],
	Element.GOLEM: [Element.SPIRIT, Element.EARTH],
	Element.TIME: [Element.SPIRIT, Element.AIR],
	Element.DJINN: [Element.SPIRIT, Element.AIR],
	
	Element.NATURE: [Element.SPIRIT, Element.WATER, Element.EARTH],
	Element.WORLD: [Element.SPIRIT, Element.FIRE, Element.WATER, Element.EARTH, Element.AIR],
	
	Element.NEUTRAL: []
}

## Returns the base elements that compose a given element
static func get_base_elements(element: Element) -> Array:
	return ELEMENT_COMPOSITION.get(element, [])

## Checks if an element contains a specific base element
static func has_base_element(element: Element, base: Element) -> bool:
	var composition = ELEMENT_COMPOSITION.get(element, [])
	return base in composition

## Checks if an element is a "pure" element (single base element)
static func is_pure_element(element: Element) -> bool:
	var composition = ELEMENT_COMPOSITION.get(element, [])
	return composition.size() == 1

## Returns the count of distinct base elements in a given element
static func get_element_count(element: Element) -> int:
	return ELEMENT_COMPOSITION.get(element, []).size()

## Returns the rarity based on element composition count
## 1 element = Common, 2 = Uncommon, 3 = Rare, 4 = Epic, 5 = Legendary
static func get_rarity_by_composition(element: Element) -> Rarity:
	var count = get_element_count(element)
	match count:
		1: return Rarity.COMMON
		2: return Rarity.UNCOMMON
		3: return Rarity.RARE
		4: return Rarity.EPIC
		5: return Rarity.LEGENDARY
		_: return Rarity.COMMON  # NEUTRAL or unknown

## Defines when an effect should trigger
enum EffectTrigger {
	ON_READ,                # When the rune is read by the reader (default)
	ON_ACTIVATED,           # When the rune is activated (includes external triggers)
	ON_DESTROY,             # When the rune is destroyed
	ON_ADJACENT_ACTIVATED,  # When an adjacent rune is activated
	ON_ROUND_START,         # At the start of the round
	ON_ROUND_END,           # At the end of the round
	ON_CREATED,             # When the rune is created during the round
	PASSIVE                 # Always active (for permanent buffs, checked contextually)
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
