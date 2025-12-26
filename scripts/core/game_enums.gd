class_name GameEnums
extends Object

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum Element {
	FIRE,
	WATER,
	EARTH,
	AIR,
	LIGHTNING,
	LAVA,
	METAL,
	CRYSTAL,
	LIFE,
	LIGHT,
	DARK,
	OBSIDIAN,
	MONADA,
	TIME,
	CATALYST,
	DIMENSIONAL,
	MEMORY,
	RHYTHM,
	CHAOS,
	DECAY,
	FOOLS_GOLD,
	MERCURY,
	GEAR,
	REPEATER,
	ETHER,
	SPACE,
	NEUTRAL
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
	UPGRADE,
	SHOP  # Future: shop phase between reward and planning
}
