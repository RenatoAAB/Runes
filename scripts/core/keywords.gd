## Fixed vocabulary of game keywords.
## Keywords are the language the game uses to communicate mechanics to the player.
## Each keyword has a consistent meaning, color, and description.
## This is a static class - access via Keywords.get_keyword(), Keywords.COMBO, etc.
class_name Keywords
extends RefCounted

# =============================================================================
# KEYWORD IDS - Use these StringNames throughout the codebase
# =============================================================================

# --- Condition Keywords (When does it activate?) ---
const COMBO := &"COMBO"                  # Scales with activation count
const THRESHOLD := &"THRESHOLD"          # Requires score/money threshold
const ADJACENT := &"ADJACENT"            # Requires specific neighbors
const POSITION := &"POSITION"            # Depends on grid position
const ELEMENT_SYNC := &"ELEMENT_SYNC"    # Requires matching elements
const SEQUENCE := &"SEQUENCE"            # Depends on read order
const RESOURCE := &"RESOURCE"            # Requires money/resources

# --- Action Keywords (What does it do?) ---
const SCORE := &"SCORE"                  # Adds flat score
const MULTIPLY := &"MULTIPLY"            # Multiplies score
const SCALING := &"SCALING"              # Permanent stat growth
const CHAIN := &"CHAIN"                  # Triggers other runes
const TRIGGER := &"TRIGGER"              # Re-activates targets
const ABSORB := &"ABSORB"                # Takes stats from target
const DESTROY := &"DESTROY"              # Removes runes
const CREATE := &"CREATE"                # Creates new runes
const MOVE := &"MOVE"                    # Moves runes/reader
const BUFF := &"BUFF"                    # Applies positive effects
const DEBUFF := &"DEBUFF"                # Applies negative effects
const INCOME := &"INCOME"                # Generates money
const COST := &"COST"                    # Costs money

# --- Target Keywords (Who is affected?) ---
const SELF := &"SELF"                    # Affects only the source
const NEIGHBORS := &"NEIGHBORS"          # Affects adjacent slots
const ROW := &"ROW"                      # Affects entire row
const COLUMN := &"COLUMN"                # Affects entire column
const ELEMENT_TARGET := &"ELEMENT_TARGET"# Affects by element type
const RANDOM := &"RANDOM"                # Random target selection
const ALL := &"ALL"                      # Affects everything

# --- State Keywords (Status effects) ---
const FRAGILE := &"FRAGILE"              # Breaks after use
const PETRIFIED := &"PETRIFIED"          # Cannot be moved
const BURNING := &"BURNING"              # Takes damage over time
const WET := &"WET"                      # Extinguishes fire, conducts
const ILLUMINATED := &"ILLUMINATED"      # Reveals/empowers
const PRISMATIC := &"PRISMATIC"          # Multi-element
const CURSED := &"CURSED"                # Negative persistent effect
const DISABLED := &"DISABLED"            # Cannot activate
const CHARGED := &"CHARGED"              # Has extra activations
const DECAYING := &"DECAYING"            # Loses value over time

# --- Special Keywords ---
const VOLATILE := &"VOLATILE"            # Destroys self after effect
const ECHO := &"ECHO"                    # Effect repeats
const MIMIC := &"MIMIC"                  # Copies another effect
const INVERSE := &"INVERSE"              # Reverses normal behavior
const META := &"META"                    # Affects game rules


# =============================================================================
# KEYWORD DATABASE - Full definitions
# =============================================================================

## Category enum for organization and filtering
enum Category {
	CONDITION,
	ACTION,
	TARGET,
	STATE,
	SPECIAL
}

## Complete keyword definitions
const DATABASE: Dictionary = {
	# === CONDITIONS ===
	&"COMBO": {
		"name": "Combo",
		"description": "Efeito escala com o número de ativações.",
		"example": "Na 3ª ativação: +15 pts",
		"color": Color(1.0, 0.84, 0.0),  # Gold
		"category": Category.CONDITION,
		"icon": "combo"
	},
	&"THRESHOLD": {
		"name": "Limiar",
		"description": "Requer que um valor atinja certo limite.",
		"example": "Se score > 100: ativa",
		"color": Color(0.4, 0.8, 0.4),  # Green
		"category": Category.CONDITION,
		"icon": "threshold"
	},
	&"ADJACENT": {
		"name": "Adjacente",
		"description": "Depende dos vizinhos no grid.",
		"example": "Se vizinho é Fogo: +5 pts",
		"color": Color(0.4, 0.7, 1.0),  # Light Blue
		"category": Category.CONDITION,
		"icon": "adjacent"
	},
	&"POSITION": {
		"name": "Posição",
		"description": "Depende da localização no grid.",
		"example": "Se está no canto: x2",
		"color": Color(0.7, 0.5, 1.0),  # Purple
		"category": Category.CONDITION,
		"icon": "position"
	},
	&"ELEMENT_SYNC": {
		"name": "Sincronia",
		"description": "Requer elementos específicos por perto.",
		"example": "Para cada Água adjacente: +3 pts",
		"color": Color(0.3, 0.9, 0.9),  # Cyan
		"category": Category.CONDITION,
		"icon": "element_sync"
	},
	&"SEQUENCE": {
		"name": "Sequência",
		"description": "Depende da ordem de leitura.",
		"example": "Se ativou após Fogo: +10 pts",
		"color": Color(1.0, 0.6, 0.2),  # Orange
		"category": Category.CONDITION,
		"icon": "sequence"
	},
	&"RESOURCE": {
		"name": "Recurso",
		"description": "Requer quantidade de dinheiro.",
		"example": "Se tem $10+: x1.5",
		"color": Color(0.9, 0.75, 0.3),  # Gold-ish
		"category": Category.CONDITION,
		"icon": "resource"
	},
	
	# === ACTIONS ===
	&"SCORE": {
		"name": "Pontos",
		"description": "Adiciona pontuação direta.",
		"example": "+10 pts",
		"color": Color(0.3, 0.8, 0.3),  # Green
		"category": Category.ACTION,
		"icon": "score"
	},
	&"MULTIPLY": {
		"name": "Multiplicar",
		"description": "Multiplica a pontuação.",
		"example": "x1.5 pts",
		"color": Color(1.0, 0.5, 0.0),  # Orange
		"category": Category.ACTION,
		"icon": "multiply"
	},
	&"SCALING": {
		"name": "Escalável",
		"description": "Ganha bônus permanente a cada uso.",
		"example": "+1 pts permanente por ativação",
		"color": Color(0.8, 0.3, 0.8),  # Magenta
		"category": Category.ACTION,
		"icon": "scaling"
	},
	&"CHAIN": {
		"name": "Corrente",
		"description": "Dispara efeitos em cadeia.",
		"example": "Ativa vizinhos após este",
		"color": Color(0.2, 0.6, 1.0),  # Blue
		"category": Category.ACTION,
		"icon": "chain"
	},
	&"TRIGGER": {
		"name": "Gatilho",
		"description": "Força ativação de outra runa.",
		"example": "Ativa a runa à direita",
		"color": Color(1.0, 0.3, 0.3),  # Red
		"category": Category.ACTION,
		"icon": "trigger"
	},
	&"ABSORB": {
		"name": "Absorver",
		"description": "Rouba estatísticas de outras runas.",
		"example": "Absorve +5 pts do alvo",
		"color": Color(0.5, 0.0, 0.5),  # Dark Purple
		"category": Category.ACTION,
		"icon": "absorb"
	},
	&"DESTROY": {
		"name": "Destruir",
		"description": "Remove runas do jogo.",
		"example": "Destrói runa adjacente",
		"color": Color(0.8, 0.1, 0.1),  # Dark Red
		"category": Category.ACTION,
		"icon": "destroy"
	},
	&"CREATE": {
		"name": "Criar",
		"description": "Gera novas runas.",
		"example": "Cria cópia em slot vazio",
		"color": Color(0.2, 0.9, 0.5),  # Mint
		"category": Category.ACTION,
		"icon": "create"
	},
	&"MOVE": {
		"name": "Mover",
		"description": "Reposiciona runas ou o leitor.",
		"example": "Move leitor para início",
		"color": Color(0.4, 0.4, 0.9),  # Slate Blue
		"category": Category.ACTION,
		"icon": "move"
	},
	&"BUFF": {
		"name": "Bônus",
		"description": "Aplica efeito positivo.",
		"example": "+3 pts temporário",
		"color": Color(0.3, 0.9, 0.3),  # Bright Green
		"category": Category.ACTION,
		"icon": "buff"
	},
	&"DEBUFF": {
		"name": "Penalidade",
		"description": "Aplica efeito negativo.",
		"example": "-2 pts ao alvo",
		"color": Color(0.6, 0.2, 0.2),  # Maroon
		"category": Category.ACTION,
		"icon": "debuff"
	},
	&"INCOME": {
		"name": "Renda",
		"description": "Gera dinheiro.",
		"example": "+$2",
		"color": Color(1.0, 0.85, 0.0),  # Gold
		"category": Category.ACTION,
		"icon": "income"
	},
	&"COST": {
		"name": "Custo",
		"description": "Consome dinheiro.",
		"example": "-$3 para ativar",
		"color": Color(0.7, 0.5, 0.2),  # Bronze
		"category": Category.ACTION,
		"icon": "cost"
	},
	
	# === TARGETS ===
	&"SELF": {
		"name": "Próprio",
		"description": "Afeta apenas a própria runa.",
		"example": "Esta runa ganha +5 pts",
		"color": Color(0.6, 0.6, 0.6),  # Gray
		"category": Category.TARGET,
		"icon": "self"
	},
	&"NEIGHBORS": {
		"name": "Vizinhos",
		"description": "Afeta slots adjacentes.",
		"example": "Vizinhos ganham +2 pts",
		"color": Color(0.4, 0.7, 1.0),  # Light Blue
		"category": Category.TARGET,
		"icon": "neighbors"
	},
	&"ROW": {
		"name": "Linha",
		"description": "Afeta toda a linha horizontal.",
		"example": "Linha inteira: +1 pt",
		"color": Color(0.9, 0.6, 0.3),  # Tan
		"category": Category.TARGET,
		"icon": "row"
	},
	&"COLUMN": {
		"name": "Coluna",
		"description": "Afeta toda a coluna vertical.",
		"example": "Coluna inteira: +1 pt",
		"color": Color(0.6, 0.9, 0.3),  # Lime
		"category": Category.TARGET,
		"icon": "column"
	},
	&"ELEMENT_TARGET": {
		"name": "Elemento",
		"description": "Afeta runas de elemento específico.",
		"example": "Todas as runas de Fogo: +2 pts",
		"color": Color(0.9, 0.4, 0.4),  # Salmon
		"category": Category.TARGET,
		"icon": "element_target"
	},
	&"RANDOM": {
		"name": "Aleatório",
		"description": "Seleciona alvo aleatoriamente.",
		"example": "Uma runa aleatória: +10 pts",
		"color": Color(0.8, 0.4, 0.8),  # Pink
		"category": Category.TARGET,
		"icon": "random"
	},
	&"ALL": {
		"name": "Todos",
		"description": "Afeta todas as runas.",
		"example": "Todas as runas: +1 pt",
		"color": Color(1.0, 1.0, 0.4),  # Yellow
		"category": Category.TARGET,
		"icon": "all"
	},
	
	# === STATES ===
	&"FRAGILE": {
		"name": "Frágil",
		"description": "Runa é destruída após ser usada.",
		"example": "Destrói-se após ativar",
		"color": Color(0.9, 0.7, 0.7),  # Light Red
		"category": Category.STATE,
		"icon": "fragile"
	},
	&"PETRIFIED": {
		"name": "Petrificado",
		"description": "Não pode ser movido ou trocado.",
		"example": "Posição travada",
		"color": Color(0.5, 0.5, 0.5),  # Gray
		"category": Category.STATE,
		"icon": "petrified"
	},
	&"BURNING": {
		"name": "Queimando",
		"description": "Perde pontos gradualmente.",
		"example": "-1 pt por turno",
		"color": Color(1.0, 0.4, 0.1),  # Fire Orange
		"category": Category.STATE,
		"icon": "burning"
	},
	&"WET": {
		"name": "Molhado",
		"description": "Apaga fogo, conduz eletricidade.",
		"example": "Imune a Queimando",
		"color": Color(0.2, 0.5, 0.9),  # Water Blue
		"category": Category.STATE,
		"icon": "wet"
	},
	&"ILLUMINATED": {
		"name": "Iluminado",
		"description": "Ativação mais poderosa.",
		"example": "+50% score",
		"color": Color(1.0, 1.0, 0.7),  # Pale Yellow
		"category": Category.STATE,
		"icon": "illuminated"
	},
	&"PRISMATIC": {
		"name": "Prismático",
		"description": "Conta como todos os elementos.",
		"example": "Elemento: Todos",
		"color": Color(0.9, 0.5, 0.9),  # Pink
		"category": Category.STATE,
		"icon": "prismatic"
	},
	&"CURSED": {
		"name": "Amaldiçoado",
		"description": "Efeito negativo persistente.",
		"example": "-20% score permanente",
		"color": Color(0.3, 0.0, 0.3),  # Dark Purple
		"category": Category.STATE,
		"icon": "cursed"
	},
	&"DISABLED": {
		"name": "Desativado",
		"description": "Não pode ativar.",
		"example": "Pula esta runa",
		"color": Color(0.3, 0.3, 0.3),  # Dark Gray
		"category": Category.STATE,
		"icon": "disabled"
	},
	&"CHARGED": {
		"name": "Carregado",
		"description": "Tem ativações extras.",
		"example": "+2 ativações",
		"color": Color(0.3, 0.8, 1.0),  # Electric Blue
		"category": Category.STATE,
		"icon": "charged"
	},
	&"DECAYING": {
		"name": "Deteriorando",
		"description": "Perde valor permanentemente.",
		"example": "-1 pt base por uso",
		"color": Color(0.4, 0.3, 0.2),  # Brown
		"category": Category.STATE,
		"icon": "decaying"
	},
	
	# === SPECIAL ===
	&"VOLATILE": {
		"name": "Volátil",
		"description": "Destrói a si mesmo após o efeito.",
		"example": "Efeito único, depois some",
		"color": Color(1.0, 0.3, 0.0),  # Bright Red-Orange
		"category": Category.SPECIAL,
		"icon": "volatile"
	},
	&"ECHO": {
		"name": "Eco",
		"description": "Repete o efeito múltiplas vezes.",
		"example": "Ativa 2x",
		"color": Color(0.5, 0.7, 0.9),  # Sky Blue
		"category": Category.SPECIAL,
		"icon": "echo"
	},
	&"MIMIC": {
		"name": "Mimetizar",
		"description": "Copia efeito de outra runa.",
		"example": "Copia efeito do vizinho",
		"color": Color(0.7, 0.7, 0.3),  # Olive
		"category": Category.SPECIAL,
		"icon": "mimic"
	},
	&"INVERSE": {
		"name": "Inverso",
		"description": "Inverte comportamento normal.",
		"example": "Dano vira cura",
		"color": Color(0.2, 0.2, 0.2),  # Near Black
		"category": Category.SPECIAL,
		"icon": "inverse"
	},
	&"META": {
		"name": "Meta",
		"description": "Afeta regras do jogo.",
		"example": "Muda ordem de leitura",
		"color": Color(0.9, 0.9, 0.9),  # White
		"category": Category.SPECIAL,
		"icon": "meta"
	},
}


# =============================================================================
# QUERY METHODS
# =============================================================================

## Get the full definition of a keyword
static func get_keyword(id: StringName) -> Dictionary:
	if id in DATABASE:
		return DATABASE[id]
	push_warning("Unknown keyword: %s" % id)
	return {"name": str(id), "description": "???", "color": Color.WHITE, "category": Category.SPECIAL}


## Get just the display name
static func get_name(id: StringName) -> String:
	return get_keyword(id).get("name", str(id))


## Get just the description
static func get_description(id: StringName) -> String:
	return get_keyword(id).get("description", "")


## Get the color for a keyword
static func get_color(id: StringName) -> Color:
	return get_keyword(id).get("color", Color.WHITE)


## Get all keywords in a category
static func get_by_category(category: Category) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in DATABASE:
		if DATABASE[id].get("category") == category:
			result.append(id)
	return result


## Format a keyword for BBCode display (colored badge)
static func format_bbcode(id: StringName) -> String:
	var kw = get_keyword(id)
	var color_hex = kw.get("color", Color.WHITE).to_html(false)
	return "[color=#%s][b][%s][/b][/color]" % [color_hex, kw.get("name", id)]


## Format multiple keywords as a tag line
static func format_keyword_line(keywords: Array[StringName]) -> String:
	var parts: Array[String] = []
	for kw in keywords:
		parts.append(format_bbcode(kw))
	return " ".join(parts)


## Check if a keyword ID is valid
static func is_valid(id: StringName) -> bool:
	return id in DATABASE
