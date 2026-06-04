class_name TooltipTexts
extends Object

## Centralized text constants for the entire game (PT-BR).
## All labels, rarity names, state descriptions, modifier types, and UI text
## are defined here to avoid duplication and ensure consistency.


# --- Rarities ---

static func get_rarity_name(rarity: GameEnums.Rarity) -> String:
	match rarity:
		GameEnums.Rarity.COMMON: return "Comum"
		GameEnums.Rarity.UNCOMMON: return "Incomum"
		GameEnums.Rarity.RARE: return "Rara"
		GameEnums.Rarity.EPIC: return "Épica"
		GameEnums.Rarity.LEGENDARY: return "Lendária"
		_: return "Desconhecida"


static func get_rarity_color_name(rarity: GameEnums.Rarity) -> String:
	match rarity:
		GameEnums.Rarity.COMMON: return "gray"
		GameEnums.Rarity.UNCOMMON: return "green"
		GameEnums.Rarity.RARE: return "blue"
		GameEnums.Rarity.EPIC: return "purple"
		GameEnums.Rarity.LEGENDARY: return "orange"
		_: return "white"


# --- Modifier Types ---

static func get_modifier_type_name(type: SlotModifierData.ModifierType) -> String:
	match type:
		SlotModifierData.ModifierType.MULTIPLIER: return "Multiplicador"
		SlotModifierData.ModifierType.TRIGGER: return "Gatilho"
		SlotModifierData.ModifierType.ECONOMY: return "Economia"
		SlotModifierData.ModifierType.PRESERVATION: return "Preservação"
		SlotModifierData.ModifierType.PROTECTION: return "Proteção"
		SlotModifierData.ModifierType.STATE: return "Estado"
		_: return "Desconhecido"


static func get_modifier_auto_description(data: SlotModifierData) -> String:
	match data.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			return "Adiciona +%.1fx multiplicador a este slot." % data.value
		SlotModifierData.ModifierType.TRIGGER:
			return "Slot dispara %d vez(es) extra." % int(data.value)
		SlotModifierData.ModifierType.ECONOMY:
			return "Gera $%d por ativação." % int(data.value)
		SlotModifierData.ModifierType.PRESERVATION:
			return "Runas neste slot não consomem cargas."
		SlotModifierData.ModifierType.PROTECTION:
			return "Protege runas frágeis de quebrar."
		SlotModifierData.ModifierType.STATE:
			return "Aplica um estado especial ao slot."
		_:
			return ""


# --- Slot State Descriptions ---

static func get_state_description(state_id: String) -> String:
	match state_id:
		"petrified":
			return "A runa desse slot não pode ser movida."
		"descompassado":
			return "Runa é pulada na primeira passagem do leitor a cada rodada."
		"obscurecido":
			return "Runa não tem elementos enquanto neste slot."
		"desestabilizado":
			return "50% de chance da runa não fazer nada quando lida."
		"gosmento":
			return "Runa recebe -5 de pontuação permanente por ativação."
		"vitrificado":
			return "Runa não pode receber buffs neste slot."
		"descarregado":
			return "Runa só pode ativar uma vez por rodada."
		"faminto":
			return "Runa é destruída no final da rodada."
		"lead_residue":
			return "Bloqueia efeito dourado. Slot contaminado."
		"illuminated":
			return "Concede ativações bônus para runas."
		"burning":
			return "Aumenta pontuação das runas."
		"wet":
			return "Concede ativações bônus."
		"electrified":
			return "Habilita sinergias especiais de metal."
		"prismatic":
			return "Refrata luz em todas as direções."
		_:
			return ""


## Returns residue display info: { "name": String, "name_bbcode": String, "description": String, "color": String }
static func get_residue_info(residue_id: String) -> Dictionary:
	match residue_id:
		"mana_residue":
			return {
				"name": "Mana Residue",
				"name_bbcode": "[mana_residue_fx][color=#66B3FF]Mana Residue[/color][/mana_residue_fx]",
				"description": "Ao ser lido, desaparece e dá 1 de mana.",
				"color": "#66B3FF"
			}
		"mana_anomaly":
			return {
				"name": "Mana Anomaly",
				"name_bbcode": "[mana_anomaly_fx][color=#EAF2FF]Mana Anomaly[/color][/mana_anomaly_fx]",
				"description": "Ao ser lido, desaparece.\nSe lido sozinho, -2 de mana.\nCom uma runa, destrói a runa após ativação.",
				"color": "#E61A99"
			}
		"petrified":
			return {
				"name": "Petrificado",
				"description": "A runa desse slot não pode ser movida.",
				"color": "#888888"
			}
		"faminto":
			return {
				"name": "Faminto",
				"description": "Runa é destruída no final da rodada.",
				"color": "#CC3333"
			}
		_:
			return {}


# --- Slot Tooltip Labels ---

const LABEL_MULTIPLIER := "x%.1f Multiplicador"
const LABEL_UPGRADE_LEVEL := "Upgrade Nv.%d"
const LABEL_TRIGGERS := "Dispara %dx"
const LABEL_PRESERVES_CHARGES := "Preserva Cargas"
const LABEL_PROTECTS_FRAGILE := "Protege Frágeis"
const LABEL_BROKEN := "QUEBRADO (x0.5)"
const LABEL_PERMANENT := "(permanente)"
const LABEL_DURATION := "(%d turnos)"
const LABEL_SCORE_BONUS := "+%d Pontuação"
const LABEL_ACTIVATION_BONUS := "+%d Ativações"
const LABEL_READER_RETURN_BONUS := "+%d Retorno do Reader"
const LABEL_MULTIPLIER_BONUS := "+%.1fx Mult"
const LABEL_ACCUMULATED_BUFF := "Buff Acumulado Atual: +%.1f"

# --- Rune Tooltip Labels ---

const LABEL_ACTIVATIONS := "Ativações: %d"
const LABEL_ACTIVATIONS_BUFFED := "Ativações: [color=yellow]%d[/color]"
const LABEL_TIER := "Tier: %d"
const LABEL_SLOTS := "%d slots"

# --- Separator ---

const SEPARATOR := "[color=gray]----------------[/color]"
