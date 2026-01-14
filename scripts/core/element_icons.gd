class_name ElementIcons
extends Object

## Helper to render element icons in tooltip BBCode.
## Falls back to the element name if an icon is missing.

const ICON_PATHS := {
	GameEnums.Element.FIRE: "res://sprites/icons/elements/fire-element-icon.png",
	GameEnums.Element.WATER: "res://sprites/icons/elements/water-element-icon.png",
	GameEnums.Element.EARTH: "res://sprites/icons/elements/earth-element-icon.png",
	GameEnums.Element.AIR: "res://sprites/icons/elements/air-element-icon.png",
	GameEnums.Element.SPIRIT: "res://sprites/icons/elements/spirit-element-icon.png",
}

static func get_bbcode(element: GameEnums.Element, size: int = 9) -> String:
	var path = ICON_PATHS.get(element, "")
	if path.is_empty():
		return GameEnums.Element.keys()[element]
	return "[img=%dx%d]%s[/img]" % [size, size, path]

static func join(elements: Array[GameEnums.Element], size: int = 9, separator: String = " or ") -> String:
	if elements.is_empty():
		return ""
	var normalized := GameEnums.normalize_elements(elements)
	var parts: Array[String] = []
	for elem in normalized:
		parts.append(get_bbcode(elem, size))
	return separator.join(parts)
