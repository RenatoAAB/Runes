# Phase 8.7 - Update rune .tres effect references from old RuneEffect to new GameEffect
# Only updates runes that reference EXTERNAL effect .tres files (not inline sub-resources)
# Inline sub-resource effects are left as RuneEffect (dual support handles them)

$runesDir = "c:\Users\55119\Documents\runes\resources\runes"

# Mapping: old effect paths → new GameEffect paths
$pathMap = @{
    "res://resources/effects/effect_reader_back_2.tres" = "res://resources/effects/rune_effects/ge_reader_back_2.tres"
    "res://resources/effects/effect_score_per_earth_adjacent.tres" = "res://resources/effects/rune_effects/ge_score_per_earth_adjacent.tres"
    "res://resources/effects/effect_score_10.tres" = "res://resources/effects/rune_effects/ge_score_10.tres"
    "res://resources/effects/effect_permanent_score_5_on_adjacent_activated.tres" = "res://resources/effects/rune_effects/ge_permanent_score_5_on_adjacent_activated.tres"
    "res://resources/effects/effect_permanent_score_minus_20_on_adjacent_spirit_activated.tres" = "res://resources/effects/rune_effects/ge_permanent_score_minus20_on_adjacent_spirit.tres"
    "res://resources/effects/effect_score_30.tres" = "res://resources/effects/rune_effects/ge_score_30.tres"
    "res://resources/effects/effect_permanent_score_50_if_not_activated.tres" = "res://resources/effects/rune_effects/ge_permanent_score_50_if_not_activated.tres"
    "res://resources/effects/effect_buff_next_activation.tres" = "res://resources/effects/rune_effects/ge_buff_next_activation.tres"
    "res://resources/effects/effect_score_10_on_adjacent_fire.tres" = "res://resources/effects/rune_effects/ge_score_10_on_adjacent_fire.tres"
    "res://resources/effects/effect_permanent_score_10_per_empty_adjacent.tres" = "res://resources/effects/rune_effects/ge_permanent_score_10_per_empty_adjacent.tres"
    "res://resources/effects/effect_reader_per_adjacent.tres" = "res://resources/effects/rune_effects/ge_reader_per_adjacent.tres"
    "res://resources/effects/effect_djinn_spawn_air.tres" = "res://resources/effects/rune_effects/ge_djinn_spawn_air.tres"
    "res://resources/effects/effect_golem_create_earth.tres" = "res://resources/effects/rune_effects/ge_golem_create_earth.tres"
    "res://resources/effects/effect_score_10_per_remaining.tres" = "res://resources/effects/rune_effects/ge_score_10_per_remaining.tres"
    "res://resources/effects/effect_destroy_adjacent.tres" = "res://resources/effects/rune_effects/ge_destroy_adjacent.tres"
    "res://resources/effects/effect_score_200.tres" = "res://resources/effects/rune_effects/ge_score_200.tres"
    "res://resources/effects/effect_nymph_spawn_water.tres" = "res://resources/effects/rune_effects/ge_nymph_spawn_water.tres"
    "res://resources/effects/effect_score_50.tres" = "res://resources/effects/rune_effects/ge_score_50.tres"
    "res://resources/effects/effect_phoenix_resurrect.tres" = "res://resources/effects/rune_effects/ge_phoenix_resurrect.tres"
    "res://resources/effects/effect_tempo_jump_previous_air.tres" = "res://resources/effects/rune_effects/ge_tempo_jump_previous_air.tres"
    "res://resources/effects/effect_nature_score_20.tres" = "res://resources/effects/rune_effects/ge_score_20.tres"
    "res://resources/effects/effect_nature_duplicate_self.tres" = "res://resources/effects/rune_effects/ge_nature_duplicate_self.tres"
    "res://resources/effects/effect_score_20_if_last_fire.tres" = "res://resources/effects/rune_effects/ge_score_20_if_last_fire.tres"
    "res://resources/effects/effect_score_20_if_last_spirit.tres" = "res://resources/effects/rune_effects/ge_score_20_if_last_spirit.tres"
    "res://resources/effects/effect_mundo_score_10.tres" = "res://resources/effects/rune_effects/ge_score_10.tres"
    "res://resources/effects/effect_mundo_jump_on_destroy.tres" = "res://resources/effects/rune_effects/ge_mundo_jump_on_destroy.tres"
    "res://resources/effects/effect_score_50_if_corner.tres" = "res://resources/effects/rune_effects/ge_score_50_if_corner.tres"
    "res://resources/effects/effect_score_50_if_no_neighbors.tres" = "res://resources/effects/rune_effects/ge_score_50_if_no_neighbors.tres"
    "res://resources/effects/effect_score_100_if_not_activated.tres" = "res://resources/effects/rune_effects/ge_score_100_if_not_activated.tres"
    "res://resources/effects/effect_score_20_if_3_distinct.tres" = "res://resources/effects/rune_effects/ge_score_20_if_3_distinct.tres"
    "res://resources/effects/effect_score_30_if_4_distinct.tres" = "res://resources/effects/rune_effects/ge_score_30_if_4_distinct.tres"
    "res://resources/effects/effect_buff_adjacent_activation.tres" = "res://resources/effects/rune_effects/ge_buff_adjacent_activation.tres"
    "res://resources/effects/effect_buff_next_if_water_adjacent.tres" = "res://resources/effects/rune_effects/ge_buff_next_if_water_adjacent.tres"
    "res://resources/effects/effect_buff_2_if_5_distinct.tres" = "res://resources/effects/rune_effects/ge_buff_2_if_5_distinct.tres"
    "res://resources/effects/effect_score_per_water_adjacent.tres" = "res://resources/effects/rune_effects/ge_score_per_water_adjacent.tres"
    "res://resources/effects/effect_score_per_remaining.tres" = "res://resources/effects/rune_effects/ge_reader_per_remaining.tres"
    "res://resources/effects/effect_score_20_per_remaining.tres" = "res://resources/effects/rune_effects/ge_score_20_per_remaining.tres"
    "res://resources/effects/effect_score_30_per_remaining.tres" = "res://resources/effects/rune_effects/ge_score_30_per_remaining.tres"
    "res://resources/effects/effect_destroy_below.tres" = "res://resources/effects/rune_effects/ge_destroy_below.tres"
    "res://resources/effects/effect_destroy_previous.tres" = "res://resources/effects/rune_effects/ge_destroy_previous.tres"
    "res://resources/effects/effect_petrify_adjacent.tres" = "res://resources/effects/rune_effects/ge_petrify_adjacent.tres"
    "res://resources/effects/effect_petrify_below.tres" = "res://resources/effects/rune_effects/ge_petrify_below.tres"
    "res://resources/effects/effect_swap_to_empty_adjacent.tres" = "res://resources/effects/rune_effects/ge_swap_to_empty_adjacent.tres"
    "res://resources/effects/effect_trigger_next_twice.tres" = "res://resources/effects/rune_effects/ge_trigger_next_twice.tres"
    "res://resources/effects/effect_score_50_on_adjacent_activated.tres" = "res://resources/effects/rune_effects/ge_score_50_on_adjacent_activated.tres"
}

$updated = 0
$skipped = 0

Get-ChildItem "$runesDir" -Recurse -Filter "rune_*.tres" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw -Encoding UTF8
    $original = $content
    $changed = $false
    
    # Replace effect paths
    foreach ($old in $pathMap.Keys) {
        if ($content -match [regex]::Escape($old)) {
            $content = $content -replace [regex]::Escape($old), $pathMap[$old]
            $changed = $true
        }
    }
    
    # Strip typed array annotation from effects line
    # Pattern: effects = Array[ExtResource("XXX")]([...]) → effects = [...]
    if ($content -match 'effects = Array\[ExtResource\("[^"]+"\)\]\(') {
        $content = $content -replace 'effects = Array\[ExtResource\("[^"]+"\)\]\(', 'effects = '
        # Also fix the closing ]) → ] 
        # Find the effects line and replace trailing )
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^effects = \[') {
                # Remove trailing ) before any newline
                $lines[$i] = $lines[$i] -replace '\)\s*$', ''
            }
        }
        $content = $lines -join "`n"
        $changed = $true
    }
    
    if ($changed) {
        Set-Content $file -Value $content -NoNewline -Encoding UTF8
        Write-Output "UPDATED: $($_.Name)"
        $updated++
    } else {
        $skipped++
    }
}

Write-Output "`nUpdated: $updated runes, Skipped: $skipped runes"
