class_name TooltipFormatter
extends Object

## Centralized BBCode formatter for all tooltip text in the game.
##
## RESPONSABILIDADES:
##  1. Registro único de termos de domínio → BBCode (Mana Residue, Mana Anomaly, elementos)
##  2. format(text) — post-processor que substitui termos em qualquer string de texto
##  3. Helpers de colorização reutilizáveis (cor de efeito, condição, raridade, etc.)
##  4. Geração de ícones de elemento
##
## COMO USAR:
##  - Em get_description() de actions/conditions/selectors: retorne texto simples, sem BBCode.
##  - Em game_effect.get_description_colored(): chame TooltipFormatter.format() no resultado.
##  - Em tooltip_builder.gd: use os helpers daqui em vez de montar BBCode inline.
##
## ADICIONAR NOVO TERMO:
##  Registre uma entrada no dicionário TERMS abaixo. O format() aplica automaticamente.

# ---------------------------------------------------------------------------
# Termos de domínio: texto simples → BBCode
# A chave é case-insensitive na busca (ver format()).
# ---------------------------------------------------------------------------
const TERMS: Dictionary = {
	"Mana Residue": "[mana_residue_fx][color=#66B3FF]Mana\u00A0Residue[/color][/mana_residue_fx]",
	"Mana Anomaly":  "[mana_anomaly_fx][color=#EAF2FF]Mana\u00A0Anomaly[/color][/mana_anomaly_fx]",
}

# ---------------------------------------------------------------------------
# Ícones de elemento
# ---------------------------------------------------------------------------
const ELEMENT_ICON_PATHS: Dictionary = {
	GameEnums.Element.FIRE:   "res://sprites/icons/elements/fire-element-icon.png",
	GameEnums.Element.WATER:  "res://sprites/icons/elements/water-element-icon.png",
	GameEnums.Element.EARTH:  "res://sprites/icons/elements/earth-element-icon.png",
	GameEnums.Element.AIR:    "res://sprites/icons/elements/air-element-icon.png",
	GameEnums.Element.SPIRIT: "res://sprites/icons/elements/spirit-element-icon.png",
}

# ---------------------------------------------------------------------------
# format() — aplica todas as substituições de termos em uma string de texto.
# Chame este método no final do pipeline de construção de descrição.
# ---------------------------------------------------------------------------
static func format(text: String) -> String:
	var result := text
	for term: String in TERMS:
		# Substituição simples — o termo pode aparecer em qualquer capitalização
		# mas preservamos a forma canônica definida na chave do dict.
		result = result.replace(term, TERMS[term])
	return result

# ---------------------------------------------------------------------------
# Ícones de elemento
# ---------------------------------------------------------------------------

## Retorna BBCode de ícone para um único elemento.
static func element_icon(element: GameEnums.Element, size: int = 9) -> String:
	var path: String = ELEMENT_ICON_PATHS.get(element, "")
	if path.is_empty():
		return GameEnums.Element.keys()[element]
	return "[img=%dx%d]%s[/img]" % [size, size, path]

## Retorna BBCode de ícones para um array de elementos, separados por separator.
static func element_icons(elements: Array[GameEnums.Element], size: int = 9, sep: String = " ") -> String:
	if elements.is_empty():
		return ""
	var normalized := GameEnums.normalize_elements(elements)
	var parts: Array[String] = []
	for elem in normalized:
		parts.append(element_icon(elem, size))
	return sep.join(parts)

# ---------------------------------------------------------------------------
# Colorização de texto
# ---------------------------------------------------------------------------

## Coloca texto em [color=#HEX]...[/color].
static func colorize(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

## Coloriza usando a paleta de efeitos (mesmo índice do highlight do grid).
static func colorize_effect(text: String, effect_index: int) -> String:
	return EffectColors.colorize_text(text, effect_index)

## Coloriza uma condição (verde/vermelho/cinza dependendo do estado).
static func colorize_condition(text: String, is_met: bool, can_evaluate: bool = true) -> String:
	return EffectColors.colorize_condition(text, is_met, can_evaluate)

## Retorna o marcador colorido de efeito (●).
static func effect_marker(effect_index: int) -> String:
	return EffectColors.get_color_marker(effect_index)

## Coloca texto em negrito.
static func bold(text: String) -> String:
	return "[b]%s[/b]" % text

## Coloca texto em negrito e colorido com cor nomeada do BBCode (ex: "gold", "gray").
static func bold_color(text: String, color_name: String) -> String:
	return "[color=%s][b]%s[/b][/color]" % [color_name, text]

# ---------------------------------------------------------------------------
# Raridade
# ---------------------------------------------------------------------------

## Retorna BBCode de raridade no formato "(Incomum)" colorido.
static func rarity_tag(rarity: GameEnums.Rarity) -> String:
	var color := TooltipTexts.get_rarity_color_name(rarity)
	var name := TooltipTexts.get_rarity_name(rarity)
	return "[color=%s](%s)[/color]" % [color, name]

# ---------------------------------------------------------------------------
# Resíduos
# ---------------------------------------------------------------------------

## Retorna o BBCode de nome de resíduo (com efeito visual se disponível).
## Usa TooltipTexts como fonte de verdade para os dados de resíduo.
static func residue_name(residue_id: String) -> String:
	var info := TooltipTexts.get_residue_info(residue_id)
	if info.is_empty():
		return residue_id
	var bbcode: String = info.get("name_bbcode", "")
	if not bbcode.is_empty():
		return bbcode
	var color: String = info.get("color", "#FFFFFF")
	var name: String = info.get("name", residue_id)
	return "[color=%s]%s[/color]" % [color, name]

## Linha de resíduo completa para uso em slot tooltip:
## "[b]Resíduo: <nome colorido>[/b]\n<descrição>\n"
static func residue_line(residue_id: String) -> String:
	var info := TooltipTexts.get_residue_info(residue_id)
	if info.is_empty():
		return ""
	var name_part := residue_name(residue_id)
	var desc: String = info.get("description", "")
	var result := bold("Resíduo: %s" % name_part) + "\n"
	if not desc.is_empty():
		result += colorize(desc, Color.SILVER) + "\n"
	return result

# ---------------------------------------------------------------------------
# Separador
# ---------------------------------------------------------------------------

static func separator() -> String:
	return TooltipTexts.SEPARATOR
