class_name TooltipFxManaResidue
extends RichTextEffect

## Subtle shimmer + vertical wave for Mana Residue text.

var bbcode := "mana_residue_fx"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var t := char_fx.elapsed_time
	var phase := float(char_fx.relative_index) * 0.35

	# Keep movement minimal to preserve readability.
	char_fx.offset.y += sin(t * 3.6 + phase) * 0.7

	var glow := 0.12 + 0.08 * sin(t * 2.2 + phase * 0.7)
	var target := Color(0.80, 0.93, 1.0, char_fx.color.a)
	char_fx.color = char_fx.color.lerp(target, clampf(glow, 0.0, 0.24))
	return true
