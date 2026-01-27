class_name RuneLibrary
extends Object

## Utility to load rune data assets and filter by element composition.

const RUNE_FOLDERS := [
	"res://resources/runes/common/",
	"res://resources/runes/uncommon/",
	"res://resources/runes/rare/",
	"res://resources/runes/epic/",
	"res://resources/runes/legendary/"
]

static var _cache_all: Array[RuneData] = []
static var _cache_pure_by_element: Dictionary = {}

## Returns all rune assets (all rarities/tiers). Cached after first load.
static func get_all_runes() -> Array[RuneData]:
	if _cache_all.size() > 0:
		return _cache_all
	var result: Array[RuneData] = []
	for folder_path in RUNE_FOLDERS:
		var dir = DirAccess.open(folder_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var rune_path = folder_path + file_name
				var rune_data: RuneData = load(rune_path)
				if rune_data:
					result.append(rune_data)
			file_name = dir.get_next()
		dir.list_dir_end()
	_cache_all = result
	return _cache_all

## Returns all runes whose elements are a pure single element matching `element`.
static func get_pure_runes_for_element(element: GameEnums.Element) -> Array[RuneData]:
	if _cache_pure_by_element.has(element):
		return _cache_pure_by_element[element]
	var all = get_all_runes()
	var filtered: Array[RuneData] = []
	for rune_data in all:
		if GameEnums.is_pure_element(rune_data.elements) and GameEnums.has_element(rune_data.elements, element):
			filtered.append(rune_data)
	_cache_pure_by_element[element] = filtered
	return filtered
