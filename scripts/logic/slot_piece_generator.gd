class_name SlotPieceGenerator
extends RefCounted

## Procedural generator for Slot Pieces.
## Creates random polyomino shapes with 1-4 slots.
## Can generate with weighted probabilities for size and slot types.

## Predefined templates for each size (normalized shapes)
const TEMPLATES: Dictionary = {
	1: [
		[Vector2i(0, 0)]  # Single slot
	],
	2: [
		[Vector2i(0, 0), Vector2i(1, 0)],  # Horizontal
		[Vector2i(0, 0), Vector2i(0, 1)]   # Vertical
	],
	3: [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],  # I horizontal
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],  # I vertical
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],  # L
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],  # L rotated
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],  # L rotated 2
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]   # L rotated 3
	],
	4: [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],  # I
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],  # O (square)
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)],  # L
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)],  # J
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],  # S
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],  # Z
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]   # T
	]
}

## Size weights (probability for each piece size)
var size_weights: Dictionary = {
	1: 0.15,  # 15% single slot
	2: 0.35,  # 35% two slots
	3: 0.35,  # 35% three slots
	4: 0.15   # 15% four slots
}

## Chance for a slot to be special (non-default)
var special_slot_chance: float = 0.2

## Available special slot types to use
var available_slot_types: Array[SlotData] = []

## Random number generator
var rng: RandomNumberGenerator


func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()


## Set seed for reproducible generation
func set_seed(seed_value: int) -> void:
	rng.seed = seed_value


## Set available special slot types
func set_available_slot_types(slots: Array[SlotData]) -> void:
	available_slot_types = slots


## Generate a random slot piece
func generate_random_piece() -> SlotPieceData:
	var size = _pick_random_size()
	return generate_piece_of_size(size)


## Generate a piece of a specific size
func generate_piece_of_size(size: int) -> SlotPieceData:
	size = clampi(size, 1, 4)
	
	var templates = TEMPLATES[size]
	var template_index = rng.randi() % templates.size()
	var shape = templates[template_index].duplicate()
	
	# Convert to typed array
	var typed_shape: Array[Vector2i] = []
	for pos in shape:
		typed_shape.append(pos)
	
	var piece = SlotPieceData.new()
	piece.id = "generated_%d_%d" % [size, rng.randi()]
	piece.display_name = _generate_piece_name(size)
	piece.shape = typed_shape
	piece.rarity = _determine_rarity(size)
	
	# Slot pieces should not carry modifiers or special slot types
	piece.slot_types = []
	piece.slot_modifiers = []
	
	# Generate description
	piece.description = _generate_description(piece)
	
	return piece


## Generate a guaranteed high-quality piece (for rewards)
func generate_reward_piece(min_size: int = 2, guaranteed_special: bool = true) -> SlotPieceData:
	var size = maxi(min_size, _pick_random_size_weighted_high())
	
	var piece = generate_piece_of_size(size)
	
	# Slot pieces should not carry modifiers or special slot types
	piece.slot_types = []
	piece.slot_modifiers = []
	
	# Upgrade rarity
	piece.rarity = mini(piece.rarity + 1, GameEnums.Rarity.LEGENDARY) as GameEnums.Rarity
	
	return piece


## Pick a random size based on weights
func _pick_random_size() -> int:
	var total = 0.0
	for weight in size_weights.values():
		total += weight
	
	var roll = rng.randf() * total
	var cumulative = 0.0
	
	for size in size_weights.keys():
		cumulative += size_weights[size]
		if roll <= cumulative:
			return size
	
	return 2  # Default fallback


## Pick a size weighted towards larger pieces
func _pick_random_size_weighted_high() -> int:
	var weights = {
		1: 0.05,
		2: 0.20,
		3: 0.40,
		4: 0.35
	}
	
	var total = 0.0
	for weight in weights.values():
		total += weight
	
	var roll = rng.randf() * total
	var cumulative = 0.0
	
	for size in weights.keys():
		cumulative += weights[size]
		if roll <= cumulative:
			return size
	
	return 3


## Determine rarity based on size and special slots
func _determine_rarity(size: int) -> GameEnums.Rarity:
	match size:
		1:
			return GameEnums.Rarity.COMMON
		2:
			return GameEnums.Rarity.COMMON if rng.randf() < 0.7 else GameEnums.Rarity.UNCOMMON
		3:
			return GameEnums.Rarity.UNCOMMON if rng.randf() < 0.6 else GameEnums.Rarity.RARE
		4:
			if rng.randf() < 0.4:
				return GameEnums.Rarity.RARE
			elif rng.randf() < 0.7:
				return GameEnums.Rarity.EPIC
			else:
				return GameEnums.Rarity.LEGENDARY
		_:
			return GameEnums.Rarity.COMMON


## Generate slot types for the piece
func _generate_slot_types(size: int) -> Array[SlotData]:
	var types: Array[SlotData] = []
	
	for i in range(size):
		if rng.randf() < special_slot_chance and not available_slot_types.is_empty():
			types.append(available_slot_types[rng.randi() % available_slot_types.size()])
		else:
			types.append(null)  # null = default slot
	
	return types


## Generate a name for the piece
func _generate_piece_name(size: int) -> String:
	var prefixes = ["Rune", "Ancient", "Crystal", "Stone", "Mystic", "Arcane"]
	var suffixes_by_size = {
		1: ["Shard", "Fragment", "Piece"],
		2: ["Duo", "Pair", "Link"],
		3: ["Trio", "Trinity", "Triad"],
		4: ["Quad", "Formation", "Array"]
	}
	
	var prefix = prefixes[rng.randi() % prefixes.size()]
	var suffixes = suffixes_by_size.get(size, ["Piece"])
	var suffix = suffixes[rng.randi() % suffixes.size()]
	
	return "%s %s" % [prefix, suffix]


## Generate description based on piece properties
func _generate_description(piece: SlotPieceData) -> String:
	var parts: Array[String] = []
	parts.append("A piece with %d slot(s)." % piece.get_slot_count())
	
	return " ".join(parts)


## Generate a batch of pieces (for shop or rewards)
func generate_batch(count: int) -> Array[SlotPieceData]:
	var pieces: Array[SlotPieceData] = []
	for i in range(count):
		pieces.append(generate_random_piece())
	return pieces
