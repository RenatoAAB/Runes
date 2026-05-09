# LEGACY SCRIPT - PENDING VERIFICATION
#
# This script is archived from a historical migration phase.
# Do not execute in normal workflows.
#
# Execute only after explicit verification that:
# 1) The current repository state still requires the Phase 10 migration.
# 2) A full backup or branch snapshot was created.
# 3) Post-run validation criteria were defined and approved.
#
# Phase 10: Migration Script
# Creates new ge_*.tres files, shared resources, and rewrites rune .tres files
# to remove inline RuneEffect sub-resources

$root = "c:\Users\55119\Documents\runes"
$ge_dir = "$root\resources\effects\rune_effects"
$shared_dir = "$root\resources\effects\shared"
$rune_dir = "$root\resources\runes"

function Write-Tres($path, $content) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $utf8)
    Write-Output "  Created: $($path -replace [regex]::Escape($root), '')"
}

# Helper to extract uid from a rune .tres gd_resource header
function Get-RuneUid($filePath) {
    $line = (Get-Content $filePath -First 1)
    if ($line -match 'uid="([^"]+)"') { return $Matches[1] }
    return $null
}

# Helper to extract texture ext_resource info from rune .tres
function Get-TextureInfo($filePath) {
    $content = Get-Content $filePath -Raw
    if ($content -match '\[ext_resource type="Texture2D" uid="([^"]+)" path="([^"]+)" id="([^"]+)"\]') {
        return @{ uid = $Matches[1]; path = $Matches[2]; id = $Matches[3] }
    }
    if ($content -match '\[ext_resource type="Texture2D" path="([^"]+)" uid="([^"]+)" id="([^"]+)"\]') {
        return @{ uid = $Matches[2]; path = $Matches[1]; id = $Matches[3] }
    }
    return $null
}

Write-Output "=== Phase 10: Creating shared resources ==="

# --- SHARED FILTERS ---
Write-Tres "$shared_dir\filters\filter_fire_earth.tres" @'
[gd_resource type="Resource" script_class="SlotFilter" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/effects/slot_filter.gd" id="1"]

[resource]
script = ExtResource("1")
slot_state = 2
required_elements = Array[int]([0, 2])
'@

Write-Tres "$shared_dir\filters\filter_water_air.tres" @'
[gd_resource type="Resource" script_class="SlotFilter" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/effects/slot_filter.gd" id="1"]

[resource]
script = ExtResource("1")
slot_state = 2
required_elements = Array[int]([1, 3])
'@

# --- SHARED CONDITIONS ---
Write-Tres "$shared_dir\conditions\condition_2_distinct.tres" @'
[gd_resource type="Resource" script_class="ConditionDistinctElementsAdjacentNew" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/effects/conditions/condition_distinct_elements_new.gd" id="1"]

[resource]
script = ExtResource("1")
min_distinct_elements = 2
'@

Write-Output "`n=== Phase 10: Creating new ge_*.tres GameEffects ==="

# 1. ge_permanent_5_per_earth_adjacent.tres (crystal)
Write-Tres "$ge_dir\ge_permanent_5_per_earth_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_earth.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 5.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 2. ge_permanent_5_per_fire_earth_adjacent.tres (lava)
Write-Tres "$ge_dir\ge_permanent_5_per_fire_earth_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_fire_earth.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 5.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 3. ge_permanent_minus5_per_water_adjacent.tres (lava, plasma)
Write-Tres "$ge_dir\ge_permanent_minus5_per_water_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_water.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = -5.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 4. ge_buff_below_activation_permanent.tres (rain)
Write-Tres "$ge_dir\ge_buff_below_activation_permanent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_buff_activation.gd" id="2_ab"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_below.tres" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ab")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
'@

# 5. ge_permanent_5_to_earth_adjacent.tres (rock) - EACH_TARGET mode
Write-Tres "$ge_dir\ge_permanent_5_to_earth_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/selectors/selector_adjacent.gd" id="4_sa"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_earth.tres" id="5_filt"]

[sub_resource type="Resource" id="Resource_sel01"]
script = ExtResource("4_sa")
filter = ExtResource("5_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 5.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true
apply_mode = 1

[resource]
script = ExtResource("1_ge")
selector = SubResource("Resource_sel01")
action = SubResource("Resource_act01")
'@

# 6. ge_permanent_10_if_2_distinct.tres (metal)
Write-Tres "$ge_dir\ge_permanent_10_if_2_distinct.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="4_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_2_distinct.tres" id="5_cond"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 10.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
'@

# 7. ge_permanent_5_per_remaining.tres (mud)
Write-Tres "$ge_dir\ge_permanent_5_per_remaining.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 4
per_value = 5.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 8. ge_petrify_self.tres (obsidian)
Write-Tres "$ge_dir\ge_petrify_self.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_petrify.gd" id="2_ap"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ap")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
'@

# 9. ge_score_20_per_fire_adjacent.tres (explosion)
Write-Tres "$ge_dir\ge_score_20_per_fire_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_fire.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 20.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 10. ge_score_minus10_per_water_adjacent.tres (acid)
Write-Tres "$ge_dir\ge_score_minus10_per_water_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_water.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = -10.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 11. ge_score_30_per_earth_adjacent.tres (acid)
Write-Tres "$ge_dir\ge_score_30_per_earth_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_earth.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 30.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 12. ge_buff_adjacent_activation_1.tres (water - +1 to adjacent)
Write-Tres "$ge_dir\ge_buff_adjacent_activation_1.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_buff_activation.gd" id="2_ab"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_adjacent.tres" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ab")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
'@

# 13. ge_trigger_adjacent.tres (lightning)
Write-Tres "$ge_dir\ge_trigger_adjacent.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_trigger_activation.gd" id="2_at"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_adjacent.tres" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_at")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
'@

# 14. ge_trigger_adjacent_if_water.tres (lightning)
Write-Tres "$ge_dir\ge_trigger_adjacent_if_water.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_trigger_activation.gd" id="2_at"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_adjacent.tres" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_water_adjacent.tres" id="4_cond"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_at")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
'@

# 15. ge_score_per_water_air_panel.tres (cloud)
Write-Tres "$ge_dir\ge_score_per_water_air_panel.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_water_air.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 2
per_value = 10.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 16. ge_reader_random_if_center.tres (instability)
Write-Tres "$ge_dir\ge_reader_random_if_center.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_move_reader.gd" id="2_am"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_center.tres" id="4_cond"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 2

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
'@

# 17. ge_permanent_30_per_destroyed.tres (sterility)
Write-Tres "$ge_dir\ge_permanent_30_per_destroyed.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 8
per_value = 30.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 18. ge_destroy_next.tres (erosion)
Write-Tres "$ge_dir\ge_destroy_next.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_destroy_rune.gd" id="2_ad"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_sequence_next.tres" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ad")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
'@

# 19. ge_permanent_30_if_previous_effect.tres (erosion)
Write-Tres "$ge_dir\ge_permanent_30_if_previous_effect.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="4_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_previous_effect.tres" id="5_cond"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 30.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
'@

# 20. ge_permanent_score_from_history.tres (machine)
Write-Tres "$ge_dir\ge_permanent_score_from_history.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp_act"]
script = ExtResource("4_vp")
source = 7
per_value = 1.0

[sub_resource type="Resource" id="Resource_vp_uniq"]
script = ExtResource("4_vp")
source = 10
per_value = -1.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp_act"), SubResource("Resource_vp_uniq")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
'@

# 21. ge_score_1.tres (machine flat score)
Write-Tres "$ge_dir\ge_score_1.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_self.tres" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
'@

# 22. ge_score_per_fire_remaining_adj_diag.tres (oil)
Write-Tres "$ge_dir\ge_score_per_fire_remaining_adj_diag.tres" @'
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/effects/game_effect.gd" id="1_ge"]
[ext_resource type="Script" path="res://scripts/effects/actions/action_score.gd" id="2_as"]
[ext_resource type="Script" path="res://scripts/effects/value_resolver.gd" id="3_vr"]
[ext_resource type="Script" path="res://scripts/effects/value_per.gd" id="4_vp"]
[ext_resource type="Script" path="res://scripts/effects/selectors/selector_adjacent.gd" id="5_sa"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_fire.tres" id="6_filt"]

[sub_resource type="Resource" id="Resource_sel01"]
script = ExtResource("5_sa")
include_diagonals = true
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 6
per_value = 10.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = SubResource("Resource_sel01")
action = SubResource("Resource_act01")
'@

# 23. ge_score_30_swap_empty.tres (dust - composite: score 30 already via ge_score_30)
# dust uses ge_score_30 + ge_swap_to_empty_adjacent - no new file needed

Write-Output "`n=== Phase 10: Rewriting rune .tres files ==="

# Function to write a rune file
function Write-RuneFile {
    param(
        [string]$runeFile,    # filename like "rune_earth.tres"
        [string]$content
    )
    $fullPath = Get-ChildItem $rune_dir -Recurse -Filter $runeFile | Select-Object -First 1 -ExpandProperty FullName
    if (-not $fullPath) {
        Write-Output "  WARNING: $runeFile not found!"
        return
    }
    Write-Tres $fullPath $content
}

# --- RUNE REWRITES ---
# Each rune is rewritten to use only ext_resource references to ge_*.tres files

# 1. rune_earth
Write-RuneFile "rune_earth.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://supn6813u1vc"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://stoxufejh7un" path="res://sprites/icons/runes/Icon1.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "earth"
rune_name = "Terra"
description = "+10 pontos"
elements = Array[int]([2])
base_max_activations = 3
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 2. rune_fire
Write-RuneFile "rune_fire.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://c6gjg03cc4ok1"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_20_if_last_fire.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://dalvpfawsmee6" path="res://sprites/icons/runes/Icon3.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "fire"
rune_name = "Labareda"
description = "+10 ponto. +20 pontos se a ultima runa ativada foi de Fogo."
elements = Array[int]([0])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 3. rune_water
Write-RuneFile "rune_water.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://bpgga3tetlmun"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_buff_adjacent_activation_1.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://cnxowsbe1l4x" path="res://sprites/icons/runes/Icon47.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "water"
rune_name = "Agua"
description = "+1 ativacao para runas adjacentes."
elements = Array[int]([1])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = Array[Resource]([ExtResource("2_e1")])
'@

# 4. rune_crystal
Write-RuneFile "rune_crystal.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://2s5sow7ix6xs"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_5_per_earth_adjacent.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://dvihkxsbppc8n" path="res://sprites/icons/runes/Icon15.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "crystal"
rune_name = "Cristal"
description = "+10 pontos
+5 pontos permanentes por terra adjacente"
elements = Array[int]([2])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 5. rune_lava
Write-RuneFile "rune_lava.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=6 format=3 uid="uid://cinxv3ffxhab6"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_5_per_fire_earth_adjacent.tres" id="3_e2"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_minus5_per_water_adjacent.tres" id="4_e3"]
[ext_resource type="Texture2D" uid="uid://yiofifoch6f2" path="res://sprites/icons/runes/Icon6.png" id="5_tex"]

[resource]
script = ExtResource("1_data")
id = "lava"
rune_name = "Lava"
description = "+5 pontos permanentes por Fogo ou Terra adjacentes; -5 permanentes por Agua adjacente."
rarity = 1
elements = Array[int]([0, 2])
textures = Array[Texture2D]([ExtResource("5_tex")])
effects = Array[Resource]([ExtResource("2_e1"), ExtResource("3_e2"), ExtResource("4_e3")])
'@

# 6. rune_rain
Write-RuneFile "rune_rain.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://d4c7213tdx4ar"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_buff_below_activation_permanent.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://c06ho32qsno82" path="res://sprites/icons/runes/Icon46.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "rain"
rune_name = "Chuva"
description = "+1 ativacao permanente para a runa abaixo"
elements = Array[int]([1])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 7. rune_rock
Write-RuneFile "rune_rock.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://b5fb5gnvq8lye"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_5_to_earth_adjacent.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://cojsngv40kha" path="res://sprites/icons/runes/Icon8.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "rock"
rune_name = "Rocha"
description = "+5 pontos permanentes para runas adjacentes de Terra"
elements = Array[int]([2])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 8. rune_metal
Write-RuneFile "rune_metal.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://c5b674oqjdf3d"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_10_if_2_distinct.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://dv8jxh35mbun8" path="res://sprites/icons/runes/Icon7.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "metal"
rune_name = "Metal"
description = "+10 pontos
+5 pontos permanentes se adjacente a pelo menos 2 elementos distintos"
elements = Array[int]([2])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 9. rune_mud
Write-RuneFile "rune_mud.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://dawftohoid1yg"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_5_per_remaining.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://ci75h8h7nyo4n" path="res://sprites/icons/runes/Icon2.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "mud"
rune_name = "Lama"
description = "+10 pontos. +5 pontos permanentes por ativacao restante."
rarity = 1
elements = Array[int]([1, 2])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 10. rune_obsidian
Write-RuneFile "rune_obsidian.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://b68ko7mf7bcei"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_100.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_petrify_self.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://dxfk6ugmy1vel" path="res://sprites/icons/runes/Icon36.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "obsidian"
rune_name = "Obsidiana"
description = "+100 pontos. Petrifica o proprio slot."
rarity = 1
elements = Array[int]([0, 2])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = Array[Resource]([ExtResource("2_e1"), ExtResource("3_e2")])
'@

# 11. rune_sound
Write-RuneFile "rune_sound.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://ckyhnu5tbt81e"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_reader_per_remaining.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://b3283fyugwbql" path="res://sprites/icons/runes/Icon42.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "sound"
rune_name = "Som"
description = "Reader volta 1 slot por ativacao restante"
elements = Array[int]([3])
base_max_activations = 2
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 12. rune_explosion
Write-RuneFile "rune_explosion.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://cdkuh3d8ffjym"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_20_per_fire_adjacent.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://563tvcf2dxxk" path="res://sprites/icons/runes/Icon4.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "explosion"
rune_name = "Explosao"
description = "+20 pontos por cada runa de fogo adjacente"
elements = Array[int]([0])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 13. rune_acid
Write-RuneFile "rune_acid.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=6 format=3 uid="uid://tyjpv4xrba67"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_30.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_minus10_per_water_adjacent.tres" id="3_e2"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_30_per_earth_adjacent.tres" id="4_e3"]
[ext_resource type="Texture2D" uid="uid://bfiduljaix53t" path="res://sprites/icons/runes/Icon21.png" id="5_tex"]

[resource]
script = ExtResource("1_data")
id = "acid"
rune_name = "Acido"
description = "+30 pontos; -10 pontos por cada agua adjacente; +30 pontos por cada terra adjacente."
rarity = 1
elements = Array[int]([0, 1])
textures = Array[Texture2D]([ExtResource("5_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2"), ExtResource("4_e3")]
'@

# 14. rune_dust
Write-RuneFile "rune_dust.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://ddl1xxtx0uouu"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_30.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_swap_to_empty_adjacent.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://bqihkscoo1b4v" path="res://sprites/icons/runes/Icon43.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "dust"
rune_name = "Poeira"
description = "3 ativacoes; a cada ativacao, move para um espaco vazio do painel."
rarity = 1
elements = Array[int]([3, 2])
base_max_activations = 3
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 15. rune_plasma
Write-RuneFile "rune_plasma.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://ml10vvmqv6al"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_100.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_minus5_per_water_adjacent.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://ci6658j10sogw" path="res://sprites/icons/runes/Icon5.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "plasma"
rune_name = "Plasma"
description = "+100 pontos
-5 ponto permanente para cada runa de agua proxima"
elements = Array[int]([0])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 16. rune_lightning
Write-RuneFile "rune_lightning.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://ku8l814wlnyq"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_trigger_adjacent.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_trigger_adjacent_if_water.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://du3ing3fp8a4l" path="res://sprites/icons/runes/Icon12.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "lightning"
rune_name = "Raio"
description = "Ativa runas adjacentes 1 vez; se adjacente a Agua, repete."
rarity = 1
elements = Array[int]([0, 3])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 17. rune_cloud
Write-RuneFile "rune_cloud.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://du7qyukvntuwb"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_per_water_air_panel.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://b3283fyugwbql" path="res://sprites/icons/runes/Icon42.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "cloud"
rune_name = "Nuvem"
description = "+10 pontos por runa de Agua ou Ar no painel."
rarity = 1
elements = Array[int]([1, 3])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 18. rune_instability
Write-RuneFile "rune_instability.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=4 format=3 uid="uid://dh6yg1oku5je7"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_reader_random_if_center.tres" id="2_e1"]
[ext_resource type="Texture2D" uid="uid://n2u3u4q6apqk" path="res://sprites/icons/runes/Icon31.png" id="3_tex"]

[resource]
script = ExtResource("1_data")
id = "instability"
rune_name = "Instabilidade"
description = "Se estiver no centro, o Reader volta para um slot aleatorio ja percorrido."
rarity = 2
elements = Array[int]([0, 1, 3])
textures = Array[Texture2D]([ExtResource("3_tex")])
effects = [ExtResource("2_e1")]
'@

# 19. rune_sterility
Write-RuneFile "rune_sterility.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://rti8qrt6p4pg"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_30_per_destroyed.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://cenk6cpr1e0xq" path="res://sprites/icons/runes/Icon32.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "sterility"
rune_name = "Esterilidade"
description = "+10 pontos. +30 pontos permanentes por runa destruida nesta rodada."
rarity = 2
elements = Array[int]([0, 2, 3])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 20. rune_erosion
Write-RuneFile "rune_erosion.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=6 format=3 uid="uid://bbtjk5hmdjtik"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_destroy_next.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_30_if_previous_effect.tres" id="3_e2"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_10.tres" id="4_e3"]
[ext_resource type="Texture2D" uid="uid://bk2u5koeddaeq" path="res://sprites/icons/runes/Icon35.png" id="5_tex"]

[resource]
script = ExtResource("1_data")
id = "erosion"
rune_name = "Erosao"
description = "Destroi a runa seguinte, ganha +30 pontos permanentes; +10 pontos."
rarity = 1
elements = Array[int]([3, 2])
textures = Array[Texture2D]([ExtResource("5_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2"), ExtResource("4_e3")]
'@

# 21. rune_machine
Write-RuneFile "rune_machine.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://c45euh0d5cuc1"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_permanent_score_from_history.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_1.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://dcxf7yfnk5rub" path="res://sprites/icons/runes/Icon39.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "machine"
rune_name = "Maquina"
description = "+1 ponto permanente por ativacao anterior nesta rodada e -1 permanente por runa unica ja ativada."
rarity = 3
elements = Array[int]([0, 1, 2, 3])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# 22. rune_oil
Write-RuneFile "rune_oil.tres" @'
[gd_resource type="Resource" script_class="RuneData" load_steps=5 format=3 uid="uid://gvpsjpvb5tkd"]

[ext_resource type="Script" uid="uid://s48ipf5uo7mv" path="res://scripts/data/rune_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_30.tres" id="2_e1"]
[ext_resource type="Resource" path="res://resources/effects/rune_effects/ge_score_per_fire_remaining_adj_diag.tres" id="3_e2"]
[ext_resource type="Texture2D" uid="uid://n2u3u4q6apqk" path="res://sprites/icons/runes/Icon31.png" id="4_tex"]

[resource]
script = ExtResource("1_data")
id = "oil"
rune_name = "Oleo"
description = "+30 pontos; +10 por cada ativacao restante em runas de fogo adjacentes (inclui diagonais)."
rarity = 1
elements = Array[int]([0, 1])
textures = Array[Texture2D]([ExtResource("4_tex")])
effects = [ExtResource("2_e1"), ExtResource("3_e2")]
'@

# --- UNCHANGED RUNES (3 complex - gravity, stagnation, energy) ---
Write-Output "`n=== Skipping 3 complex runes (gravity, stagnation, energy) - keeping inline RuneEffect ==="

Write-Output "`n=== Phase 10: Migration complete! ==="
Write-Output "Created: 3 shared resources, 22 ge_*.tres files, rewrote 22 rune .tres files"
Write-Output "Skipped: gravity, stagnation, energy (need custom GameEffect actions)"
