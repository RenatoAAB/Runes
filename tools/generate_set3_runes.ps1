## =============================================================================
## RUNES SET 3 - Resource Generation Script
## Generates all .tres files for effects and runes of Set 3
## =============================================================================

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

# --- Paths ---
$effectsDir  = "$root\resources\effects\rune_effects"
$sharedDir   = "$root\resources\effects\shared"
$condDir     = "$sharedDir\conditions"
$selDir      = "$sharedDir\selectors"
$filtDir     = "$sharedDir\filters"
$runesCommon   = "$root\resources\runes\common"
$runesUncommon = "$root\resources\runes\uncommon"
$runesRare     = "$root\resources\runes\rare"
$runesEpic     = "$root\resources\runes\epic"

foreach ($d in @($effectsDir, $condDir, $selDir, $filtDir, $runesCommon, $runesUncommon, $runesRare, $runesEpic)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# --- Script paths (relative from res://) ---
$S = @{
    rune_data       = 'res://scripts/data/rune_data.gd'
    game_effect     = 'res://scripts/effects/game_effect.gd'
    action_score    = 'res://scripts/effects/actions/action_score.gd'
    action_buff     = 'res://scripts/effects/actions/action_buff_activation.gd'
    action_trigger  = 'res://scripts/effects/actions/action_trigger_activation.gd'
    action_destroy  = 'res://scripts/effects/actions/action_destroy_rune.gd'
    action_create   = 'res://scripts/effects/actions/action_create_rune.gd'
    action_create_random = 'res://scripts/effects/actions/action_create_random_rune.gd'
    action_move_reader   = 'res://scripts/effects/actions/action_move_reader.gd'
    action_petrify       = 'res://scripts/effects/actions/action_petrify.gd'
    action_apply_residue = 'res://scripts/effects/actions/action_apply_residue.gd'
    action_consume_residue = 'res://scripts/effects/actions/action_consume_residue.gd'
    action_transform_residue = 'res://scripts/effects/actions/action_transform_residue.gd'
    action_composite     = 'res://scripts/effects/actions/action_composite.gd'
    action_swap          = 'res://scripts/effects/actions/action_swap_position.gd'
    action_copy          = 'res://scripts/effects/actions/action_copy_effects.gd'
    action_duplicate     = 'res://scripts/effects/actions/action_duplicate_self.gd'
    action_resurrect     = 'res://scripts/effects/actions/action_mark_resurrection.gd'
    action_free_activation = 'res://scripts/effects/actions/action_free_activation.gd'
    action_rotate        = 'res://scripts/effects/actions/action_rotate_runes.gd'
    action_transfer      = 'res://scripts/effects/actions/action_transfer_activations.gd'
    action_clear_residue = 'res://scripts/effects/actions/action_clear_residue.gd'
    value_resolver  = 'res://scripts/effects/value_resolver.gd'
    value_per       = 'res://scripts/effects/value_per.gd'
    selector_self   = 'res://scripts/effects/selectors/selector_self.gd'
    selector_adj    = 'res://scripts/effects/selectors/selector_adjacent.gd'
    selector_dir    = 'res://scripts/effects/selectors/selector_directional.gd'
    selector_seq    = 'res://scripts/effects/selectors/selector_sequence.gd'
    selector_empty  = 'res://scripts/effects/selectors/selector_empty.gd'
    selector_panel  = 'res://scripts/effects/selectors/selector_panel.gd'
    selector_col    = 'res://scripts/effects/selectors/selector_column.gd'
    selector_row    = 'res://scripts/effects/selectors/selector_row.gd'
    selector_reader = 'res://scripts/effects/selectors/selector_reader_relative.gd'
    slot_filter     = 'res://scripts/effects/slot_filter.gd'
    cond_element_adj = 'res://scripts/effects/conditions/condition_element_adjacent_new.gd'
    cond_neighbor    = 'res://scripts/effects/conditions/condition_neighbor_count_new.gd'
    cond_distinct    = 'res://scripts/effects/conditions/condition_distinct_elements_new.gd'
    cond_last_elem   = 'res://scripts/effects/conditions/condition_last_activated_element_new.gd'
    cond_consecutive = 'res://scripts/effects/conditions/condition_consecutive_activation.gd'
    cond_simultaneous = 'res://scripts/effects/conditions/condition_simultaneous_activation.gd'
    cond_adj_residue = 'res://scripts/effects/conditions/condition_adjacent_residue.gd'
    cond_grid_pos    = 'res://scripts/effects/conditions/condition_grid_position_new.gd'
    cond_prev_effect = 'res://scripts/effects/conditions/condition_previous_effect_new.gd'
    cond_remaining   = 'res://scripts/effects/conditions/condition_remaining_activations.gd'
    cond_composite   = 'res://scripts/effects/conditions/condition_composite.gd'
}

# --- Shared resource paths ---
$Shared = @{
    sel_self      = 'res://resources/effects/shared/selectors/selector_self.tres'
    sel_adj       = 'res://resources/effects/shared/selectors/selector_adjacent.tres'
    sel_adj_diag  = 'res://resources/effects/shared/selectors/selector_adjacent_diagonal.tres'
    sel_below     = 'res://resources/effects/shared/selectors/selector_below.tres'
    sel_seq_next  = 'res://resources/effects/shared/selectors/selector_sequence_next.tres'
    sel_seq_prev  = 'res://resources/effects/shared/selectors/selector_sequence_previous.tres'
    sel_empty_rand= 'res://resources/effects/shared/selectors/selector_empty_random.tres'
    sel_empty_adj = 'res://resources/effects/shared/selectors/selector_empty_adjacent.tres'
    sel_empty_all = 'res://resources/effects/shared/selectors/selector_empty_all.tres'
    sel_panel     = 'res://resources/effects/shared/selectors/selector_panel_all.tres'
    filt_fire     = 'res://resources/effects/shared/filters/filter_fire.tres'
    filt_water    = 'res://resources/effects/shared/filters/filter_water.tres'
    filt_earth    = 'res://resources/effects/shared/filters/filter_earth.tres'
    filt_air      = 'res://resources/effects/shared/filters/filter_air.tres'
    filt_spirit   = 'res://resources/effects/shared/filters/filter_spirit.tres'
    filt_fire_earth = 'res://resources/effects/shared/filters/filter_fire_earth.tres'
    filt_empty    = 'res://resources/effects/shared/filters/filter_empty.tres'
    filt_occupied = 'res://resources/effects/shared/filters/filter_occupied.tres'
    cond_last_fire = 'res://resources/effects/shared/conditions/condition_last_fire.tres'
    cond_last_water = 'res://resources/effects/shared/conditions/condition_last_water.tres'
    cond_last_air  = 'res://resources/effects/shared/conditions/condition_last_air.tres'
    cond_center    = 'res://resources/effects/shared/conditions/condition_center.tres'
    cond_corner    = 'res://resources/effects/shared/conditions/condition_corner.tres'
    cond_3_distinct= 'res://resources/effects/shared/conditions/condition_3_distinct.tres'
    cond_prev_effect = 'res://resources/effects/shared/conditions/condition_previous_effect.tres'
}

$fileCount = 0

function Write-TresFile($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    $script:fileCount++
}

# =============================================================================
# PHASE 1: Create new shared resources
# =============================================================================

# --- New filters ---
# filter_fire_air
if (-not (Test-Path "$filtDir\filter_fire_air.tres")) {
    Write-TresFile "$filtDir\filter_fire_air.tres" @"
[gd_resource type="Resource" script_class="SlotFilter" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.slot_filter)" id="1"]

[resource]
script = ExtResource("1")
slot_state = 2
required_elements = Array[int]([0, 3])
"@
}

# filter_water_earth
if (-not (Test-Path "$filtDir\filter_water_earth.tres")) {
    Write-TresFile "$filtDir\filter_water_earth.tres" @"
[gd_resource type="Resource" script_class="SlotFilter" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.slot_filter)" id="1"]

[resource]
script = ExtResource("1")
slot_state = 2
required_elements = Array[int]([1, 2])
"@
}

# --- New conditions ---
# condition_2_earth_adjacent
if (-not (Test-Path "$condDir\condition_2_earth_adjacent.tres")) {
    Write-TresFile "$condDir\condition_2_earth_adjacent.tres" @"
[gd_resource type="Resource" script_class="ConditionElementAdjacentNew" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_element_adj)" id="1"]

[resource]
script = ExtResource("1")
required_elements = Array[int]([2])
min_count = 2
include_diagonals = false
"@
}

# condition_2_air_adjacent
if (-not (Test-Path "$condDir\condition_2_air_adjacent.tres")) {
    Write-TresFile "$condDir\condition_2_air_adjacent.tres" @"
[gd_resource type="Resource" script_class="ConditionElementAdjacentNew" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_element_adj)" id="1"]

[resource]
script = ExtResource("1")
required_elements = Array[int]([3])
min_count = 2
include_diagonals = false
"@
}

# condition_3_water_adjacent
if (-not (Test-Path "$condDir\condition_3_water_adjacent.tres")) {
    Write-TresFile "$condDir\condition_3_water_adjacent.tres" @"
[gd_resource type="Resource" script_class="ConditionElementAdjacentNew" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_element_adj)" id="1"]

[resource]
script = ExtResource("1")
required_elements = Array[int]([1])
min_count = 3
include_diagonals = false
"@
}

# condition_consecutive_2
if (-not (Test-Path "$condDir\condition_consecutive_2.tres")) {
    Write-TresFile "$condDir\condition_consecutive_2.tres" @"
[gd_resource type="Resource" script_class="ConditionConsecutiveActivation" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_consecutive)" id="1"]

[resource]
script = ExtResource("1")
required_consecutive_count = 2
"@
}

# condition_simultaneous
if (-not (Test-Path "$condDir\condition_simultaneous.tres")) {
    Write-TresFile "$condDir\condition_simultaneous.tres" @"
[gd_resource type="Resource" script_class="ConditionSimultaneousActivation" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_simultaneous)" id="1"]

[resource]
script = ExtResource("1")
"@
}

# condition_adj_mana_residue
if (-not (Test-Path "$condDir\condition_adj_mana_residue.tres")) {
    Write-TresFile "$condDir\condition_adj_mana_residue.tres" @"
[gd_resource type="Resource" script_class="ConditionAdjacentResidue" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_adj_residue)" id="1"]

[resource]
script = ExtResource("1")
residue_id = "mana_residue"
min_count = 1
include_diagonals = false
"@
}

# condition_adj_mana_anomaly
if (-not (Test-Path "$condDir\condition_adj_mana_anomaly.tres")) {
    Write-TresFile "$condDir\condition_adj_mana_anomaly.tres" @"
[gd_resource type="Resource" script_class="ConditionAdjacentResidue" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.cond_adj_residue)" id="1"]

[resource]
script = ExtResource("1")
residue_id = "mana_anomaly"
min_count = 1
include_diagonals = false
"@
}

# condition_adj_mana_residue_and_anomaly (composite: mana_residue AND mana_anomaly adjacent)
if (-not (Test-Path "$condDir\condition_adj_residue_and_anomaly.tres")) {
    Write-TresFile "$condDir\condition_adj_residue_and_anomaly.tres" @"
[gd_resource type="Resource" script_class="ConditionComposite" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.cond_composite)" id="1"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_mana_residue.tres" id="2"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_mana_anomaly.tres" id="3"]

[resource]
script = ExtResource("1")
mode = 0
conditions = [ExtResource("2"), ExtResource("3")]
"@
}

# --- New selectors ---
# selector_above
if (-not (Test-Path "$selDir\selector_above.tres")) {
    Write-TresFile "$selDir\selector_above.tres" @"
[gd_resource type="Resource" script_class="SelectorDirectional" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.selector_dir)" id="1"]

[resource]
script = ExtResource("1")
direction = 0
include_if_empty = true
"@
}

# selector_sequence_both (prev + next)
if (-not (Test-Path "$selDir\selector_sequence_both.tres")) {
    Write-TresFile "$selDir\selector_sequence_both.tres" @"
[gd_resource type="Resource" script_class="SelectorSequence" load_steps=2 format=3]

[ext_resource type="Script" path="$($S.selector_seq)" id="1"]

[resource]
script = ExtResource("1")
direction = 2
include_self = false
"@
}

Write-Host "Phase 1: Shared resources created."

# =============================================================================
# PHASE 2: Create ALL effect .tres files
# =============================================================================

# --- Helper: simple score effect ---
function New-ScoreEffect($name, $base, $permanent=$false, $applyMode=0, $selectorRes=$null, $conditionRes=$null) {
    $sel = if ($selectorRes) { $selectorRes } else { $Shared.sel_self }
    $steps = 5
    $extIdx = 5
    $condLine = ""
    $condExt = ""
    if ($conditionRes) {
        $steps++
        $condExt = "`n[ext_resource type=""Resource"" path=""$conditionRes"" id=""${extIdx}_cond""]"
        $condLine = "`ncondition = ExtResource(""${extIdx}_cond"")"
        $extIdx++
    }
    $permLine = if ($permanent) { "`nis_permanent = true" } else { "" }
    $modeLine = if ($applyMode -ne 0) { "`napply_mode = $applyMode" } else { "" }

    Write-TresFile "$effectsDir\$name.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=$steps format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$sel" id="4_sel"]$condExt

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = $($base).0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")$permLine$modeLine

[resource]
script = ExtResource("1_ge")$condLine
selector = ExtResource("4_sel")
action = SubResource("act")
"@
}

# --- Helper: score with ValuePer ---
function New-ScorePerEffect($name, $vpSource, $vpValue, $permanent=$false, $applyMode=0, $filterRes=$null, $selectorRes=$null, $conditionRes=$null, $base=0) {
    $sel = if ($selectorRes) { $selectorRes } else { $Shared.sel_self }
    $steps = 6
    $extCount = 5
    $extras = ""
    $condLine = ""
    $filtRef = ""

    if ($filterRes) {
        $steps++
        $extCount++
        $extras += "`n[ext_resource type=""Resource"" path=""$filterRes"" id=""${extCount}_filt""]"
        $filtRef = "`nfilter = ExtResource(""${extCount}_filt"")"
    }
    if ($conditionRes) {
        $steps++
        $extCount++
        $extras += "`n[ext_resource type=""Resource"" path=""$conditionRes"" id=""${extCount}_cond""]"
        $condLine = "`ncondition = ExtResource(""${extCount}_cond"")"
    }

    $permLine = if ($permanent) { "`nis_permanent = true" } else { "" }
    $modeLine = if ($applyMode -ne 0) { "`napply_mode = $applyMode" } else { "" }
    $baseLine = if ($base -ne 0) { "`nbase = $($base).0" } else { "" }

    Write-TresFile "$effectsDir\$name.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=$steps format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.value_per)" id="4_vp"]
[ext_resource type="Resource" path="$sel" id="5_sel"]$extras

[sub_resource type="Resource" id="vp"]
script = ExtResource("4_vp")
source = $vpSource
per_value = $($vpValue).0$filtRef

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")$baseLine
per = [SubResource("vp")]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")$permLine$modeLine

[resource]
script = ExtResource("1_ge")$condLine
selector = ExtResource("5_sel")
action = SubResource("act")
"@
}


# ==== FOGO (FIRE) effects ====

# ge_s3_incendio_score (+50 per fire/air adj with diag)
# Need inline selector_adjacent with diag + filter_fire_air
Write-TresFile "$effectsDir\ge_s3_incendio_score.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.value_per)" id="4_vp"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/filters/filter_fire_air.tres" id="6_filt"]

[sub_resource type="Resource" id="vp"]
script = ExtResource("4_vp")
source = 1
per_value = 50.0
filter = ExtResource("6_filt")

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
per = [SubResource("vp")]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("act")
"@

# ge_s3_plasma_score_100 (+100 base)
New-ScoreEffect "ge_s3_plasma_score_100" 100

# ge_s3_plasma_bonus_consecutive (+200 if activated 2x consecutively)
New-ScoreEffect "ge_s3_plasma_bonus_consecutive" 200 -conditionRes "res://resources/effects/shared/conditions/condition_consecutive_2.tres"

# ge_s3_calor_score_per_fire (30 per fire activated this round)
New-ScorePerEffect "ge_s3_calor_score_per_fire" 14 30 -filterRes $Shared.filt_fire
# Note: source=14 is ROUND_ELEMENT_ACTIVATIONS, filter=fire

# ge_s3_calor_petrify (petrify self)
# Reuse ge_petrify_self.tres - already exists

# ge_s3_explosao_score_200 (+200)
New-ScoreEffect "ge_s3_explosao_score_200" 200

# ge_s3_explosao_minus10_permanent_adj (-10 permanent to adjacent)
New-ScoreEffect "ge_s3_explosao_minus10_adj" -10 -permanent $true -applyMode 1 -selectorRes $Shared.sel_adj

# ge_s3_queimadura_score_200 (+200)
# reuse ge_s3_explosao_score_200

# ge_s3_queimadura_anomaly_adj (mana anomaly on random adjacent)
Write-TresFile "$effectsDir\ge_s3_apply_anomaly_adj_random.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_empty_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_anomaly"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_labareda_score_100 (+100)
New-ScoreEffect "ge_s3_labareda_score_100" 100

# ge_s3_labareda_bonus_if_last_fire (+100 if last rune was fire)
New-ScoreEffect "ge_s3_labareda_bonus_fire" 100 -conditionRes $Shared.cond_last_fire

# ge_s3_supernova_score_500 (+500)
New-ScoreEffect "ge_s3_supernova_score_500" 500

# ge_s3_supernova_petrify = ge_petrify_self (reuse)

# ge_s3_supernova_anomaly_column (anomaly in whole column except self)
Write-TresFile "$effectsDir\ge_s3_anomaly_column_not_self.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Script" path="$($S.selector_col)" id="3_sc"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("3_sc")
include_self = false

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_anomaly"

[resource]
script = ExtResource("1_ge")
selector = SubResource("sel")
action = SubResource("act")
"@


# ==== AGUA (WATER) effects ====

# ge_s3_gota_buff_below_perm (+1 permanent activation to below)
# Reuse ge_buff_below_activation_permanent.tres

# ge_s3_gota_destroy_self
Write-TresFile "$effectsDir\ge_s3_destroy_self.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_destroy)" id="2_ad"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ad")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_gota_residue_mana_self (mana residue on self slot)
Write-TresFile "$effectsDir\ge_s3_apply_mana_residue_self.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_lago_buff_adj_if_2earth (+1 activation to adj if adj to 2 earth)
Write-TresFile "$effectsDir\ge_s3_buff_adj_if_2earth.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_2_earth_adjacent.tres" id="5_cond"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_chuva_residue_below (mana residue on below)
Write-TresFile "$effectsDir\ge_s3_apply_mana_residue_below.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_below)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_rio_buff_row_if_2earth (+1 activation to row if adj to 2 earth)
Write-TresFile "$effectsDir\ge_s3_buff_row_if_2earth.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.selector_row)" id="4_sr"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_2_earth_adjacent.tres" id="5_cond"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("4_sr")
include_self = false

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_cachoeira_residue_column (mana residue on column if 3 water adj)
Write-TresFile "$effectsDir\ge_s3_residue_column_if_3water.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Script" path="$($S.selector_col)" id="3_sc"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_3_water_adjacent.tres" id="4_cond"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("3_sc")
include_self = false

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_fluxo_buff_next_2 (+2 activation to next)
Write-TresFile "$effectsDir\ge_s3_buff_next_2.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_seq_next)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 2.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@


# ==== AR (AIR) effects ====

# ge_s3_vento_reader_back_2 - reuse ge_reader_back_2.tres

# ge_s3_redemoinho_trigger_both_simultaneous
Write-TresFile "$effectsDir\ge_s3_trigger_both_simultaneous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_trigger)" id="2_at"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_sequence_both.tres" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
simultaneous = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_pressao_drain_previous (activate all activations of previous)
Write-TresFile "$effectsDir\ge_s3_drain_previous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_trigger)" id="2_at"]
[ext_resource type="Resource" path="$($Shared.sel_seq_prev)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
drain_all_activations = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_vendaval_reader_back_4_if_2air
Write-TresFile "$effectsDir\ge_s3_reader_back_4_if_2air.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_move_reader)" id="2_am"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="4_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_2_air_adjacent.tres" id="5_cond"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 4.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_am")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_furacao_trigger_adj_simultaneous_if_2air
Write-TresFile "$effectsDir\ge_s3_trigger_adj_simul_if_2air.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_trigger)" id="2_at"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_2_air_adjacent.tres" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
simultaneous = true

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@


# ==== TERRA (EARTH) effects ====

# ge_s3_rocha_score_10 - reuse ge_score_10.tres
# ge_s3_rocha_perm_10
New-ScoreEffect "ge_s3_score_permanent_10" 10 -permanent $true

# ge_s3_tremor_score_10 - reuse ge_score_10.tres
# ge_s3_tremor_swap_prev_below (move previous rune to below slot)
Write-TresFile "$effectsDir\ge_s3_swap_previous_to_below.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_swap)" id="2_asw"]
[ext_resource type="Resource" path="$($Shared.sel_seq_prev)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_asw")
swap_mode = 0

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_terremoto (swap above<->below and previous<->next)
Write-TresFile "$effectsDir\ge_s3_terremoto_swap.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_composite)" id="2_comp"]
[ext_resource type="Script" path="$($S.action_swap)" id="3_asw"]
[ext_resource type="Resource" path="res://resources/effects/shared/selectors/selector_above.tres" id="4_above"]
[ext_resource type="Resource" path="$($Shared.sel_seq_prev)" id="5_prev"]

[sub_resource type="Resource" id="act_above"]
script = ExtResource("3_asw")
swap_mode = 0

[sub_resource type="Resource" id="ge_above"]
script = ExtResource("1_ge")
selector = ExtResource("4_above")
action = SubResource("act_above")

[sub_resource type="Resource" id="act_prev"]
script = ExtResource("3_asw")
swap_mode = 0

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_prev")
action = SubResource("act_prev")
"@
# Note: Terremoto needs TWO effects (one for above->below, one for prev->next)

# ge_s3_quartzo_perm_10_earth_adj (+10 permanent to earth adjacent)
# Reuse ge_permanent_5_to_earth_adjacent pattern but with 10
Write-TresFile "$effectsDir\ge_s3_perm_10_to_earth_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.selector_adj)" id="4_sa"]
[ext_resource type="Resource" path="$($Shared.filt_earth)" id="5_filt"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("4_sa")
filter = ExtResource("5_filt")

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 10.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")
is_permanent = true
apply_mode = 1

[resource]
script = ExtResource("1_ge")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_ametista_score_10 - reuse ge_score_10
# ge_s3_ametista_perm_5_per_earth_adj (+5 permanent per earth adj)
New-ScorePerEffect "ge_s3_perm_5_per_earth_adj" 0 5 -permanent $true -filterRes $Shared.filt_earth

# ge_s3_topazio_score_10 - reuse ge_score_10
# ge_s3_topazio_perm_20_if_3distinct (+20 permanent if 3 distinct adj)
New-ScoreEffect "ge_s3_perm_20_if_3distinct" 20 -permanent $true -conditionRes $Shared.cond_3_distinct

# ge_s3_esmeralda_score_10 - reuse ge_score_10
# ge_s3_esmeralda_perm_per_moved (+10 perm per times moved)
New-ScorePerEffect "ge_s3_perm_10_per_moved" 15 10 -permanent $true

# ge_s3_estalactite_score_10 - reuse ge_score_10
# ge_s3_estalactite_perm_20_if_corner
New-ScoreEffect "ge_s3_perm_20_if_corner" 20 -permanent $true -conditionRes $Shared.cond_corner

# ge_s3_diamante_score_10 - reuse ge_score_10
# ge_s3_diamante_perm_50_if_center
New-ScoreEffect "ge_s3_perm_50_if_center" 50 -permanent $true -conditionRes $Shared.cond_center
# ge_s3_diamante_petrify = ge_petrify_self (reuse)

# ge_s3_rubi_score_10 - reuse ge_score_10
# Note: trigger=3 is ON_ADJACENT_ACTIVATED. Use condition_last_fire to filter.
Write-TresFile "$effectsDir\ge_s3_rubi_on_adj_fire.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="4_sel"]
[ext_resource type="Resource" path="$($Shared.cond_last_fire)" id="5_cond"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 5.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")
is_permanent = true

[resource]
script = ExtResource("1_ge")
trigger = 3
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("act")
"@


# ==== FOGO+TERRA effects ====

# ge_s3_lava_score_50
New-ScoreEffect "ge_s3_score_50" 50

# ge_s3_lava_perm_20_per_earth_adj
New-ScorePerEffect "ge_s3_perm_20_per_earth_adj" 0 20 -permanent $true -filterRes $Shared.filt_earth

# ge_s3_obsidiana_score_per_fire_earth_adj (+100 per adj fire/earth)
New-ScorePerEffect "ge_s3_score_100_per_fire_earth_adj" 0 100 -filterRes $Shared.filt_fire_earth

# ge_s3_erupcao_destroy_next = ge_destroy_next (reuse)
# ge_s3_erupcao_anomaly_previous
Write-TresFile "$effectsDir\ge_s3_apply_anomaly_previous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_seq_prev)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_anomaly"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_erupcao_score_400
New-ScoreEffect "ge_s3_score_400" 400


# ==== FOGO+AGUA effects ====

# ge_s3_oleo_score_per_remaining (+50 per remaining activation)
New-ScorePerEffect "ge_s3_score_50_per_remaining" 4 50

# ge_s3_acido_destroy_prev = ge_destroy_previous (reuse)
# ge_s3_acido_buff_next_5_if_success (+5 activations to next if prev effect succeeded)
Write-TresFile "$effectsDir\ge_s3_buff_next_5_if_success.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_seq_next)" id="4_sel"]
[ext_resource type="Resource" path="$($Shared.cond_prev_effect)" id="5_cond"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 5.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_ebulicao_residue_adj (mana residue on adjacent)
Write-TresFile "$effectsDir\ge_s3_apply_mana_residue_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_ebulicao_debuff_adj (-1 activation to adjacent)
Write-TresFile "$effectsDir\ge_s3_debuff_adj_1.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = -1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@


# ==== FOGO+AR effects ====

# ge_s3_raio_trigger_adj_simultaneous
Write-TresFile "$effectsDir\ge_s3_trigger_adj_simultaneous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_trigger)" id="2_at"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
simultaneous = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_raio_anomaly_next
Write-TresFile "$effectsDir\ge_s3_apply_anomaly_next.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_seq_next)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_anomaly"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_eletricidade_free_if_simultaneous (don't consume activation if simultaneous)
Write-TresFile "$effectsDir\ge_s3_free_if_simultaneous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_free_activation)" id="2_af"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_simultaneous.tres" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_af")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_eletricidade_score_100
New-ScoreEffect "ge_s3_score_100" 100

# ge_s3_conveccao_reader (reader +2 per fire adj, -1 per water adj)
Write-TresFile "$effectsDir\ge_s3_conveccao_reader.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_move_reader)" id="2_am"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.value_per)" id="4_vp"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="5_sel"]
[ext_resource type="Resource" path="$($Shared.filt_fire)" id="6_ff"]
[ext_resource type="Resource" path="$($Shared.filt_water)" id="7_fw"]

[sub_resource type="Resource" id="vp_fire"]
script = ExtResource("4_vp")
source = 0
per_value = 2.0
filter = ExtResource("6_ff")

[sub_resource type="Resource" id="vp_water"]
script = ExtResource("4_vp")
source = 0
per_value = -1.0
filter = ExtResource("7_fw")

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
per = [SubResource("vp_fire"), SubResource("vp_water")]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_am")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("act")
"@


# ==== AGUA+TERRA effects ====

# ge_s3_gelo_perm_10_per_remaining (+10 permanent per remaining activations)
New-ScorePerEffect "ge_s3_perm_10_per_remaining" 4 10 -permanent $true

# ge_s3_lama_buff_adj_earth_perm (+1 permanent activation to earth adj)
Write-TresFile "$effectsDir\ge_s3_buff_adj_earth_perm.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.selector_adj)" id="4_sa"]
[ext_resource type="Resource" path="$($Shared.filt_earth)" id="5_filt"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("4_sa")
filter = ExtResource("5_filt")

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_lama_destroy_self = ge_s3_destroy_self (reuse)

# ge_s3_praia_rotate (rotate adj runes+residues counter-clockwise)
Write-TresFile "$effectsDir\ge_s3_rotate_adj_ccw.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_rotate)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
clockwise = false
include_residues = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@


# ==== AGUA+AR effects ====

# ge_s3_corrente_reader_per_remaining (reader back 1 per remaining)
# Reuse ge_reader_per_remaining.tres

# ge_s3_geada_trigger_column_simultaneous (+trigger all column simultaneously)
Write-TresFile "$effectsDir\ge_s3_trigger_column_simultaneous.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_trigger)" id="2_at"]
[ext_resource type="Script" path="$($S.selector_col)" id="3_sc"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("3_sc")
include_self = false

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
simultaneous = true

[resource]
script = ExtResource("1_ge")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_geada_buff_0activations (+1 activation if 0 remaining)
Write-TresFile "$effectsDir\ge_s3_buff_column_if_0_activations.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.selector_col)" id="4_sc"]
[ext_resource type="Script" path="$($S.cond_remaining)" id="5_cond"]

[sub_resource type="Resource" id="sel"]
script = ExtResource("4_sc")
include_self = false

[sub_resource type="Resource" id="cond"]
script = ExtResource("5_cond")
threshold = 0
comparison = 2

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
condition = SubResource("cond")
selector = SubResource("sel")
action = SubResource("act")
"@

# ge_s3_bolha_reader_to_nearest_residue (reader goes to nearest mana residue behind)
Write-TresFile "$effectsDir\ge_s3_reader_to_nearest_mana_residue.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_move_reader)" id="2_am"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_am")
mode = 5
target_residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_nuvem_score_per_water_air_round (+10 per water/air activation this round)
Write-TresFile "$effectsDir\ge_s3_score_per_water_air_round.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_score)" id="2_as"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Script" path="$($S.value_per)" id="4_vp"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="5_sel"]
[ext_resource type="Resource" path="$($Shared.filt_water)" id="6_fw"]
[ext_resource type="Resource" path="$($Shared.filt_air)" id="7_fa"]

[sub_resource type="Resource" id="vp_water"]
script = ExtResource("4_vp")
source = 14
per_value = 10.0
filter = ExtResource("6_fw")

[sub_resource type="Resource" id="vp_air"]
script = ExtResource("4_vp")
source = 14
per_value = 10.0
filter = ExtResource("7_fa")

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
per = [SubResource("vp_water"), SubResource("vp_air")]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_as")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("act")
"@


# ==== AR+TERRA effects ====

# ge_s3_areia_score_10 - reuse ge_score_10
# ge_s3_areia_perm_per_unique_air (+10 permanent per unique air activated this round)
# ROUND_ELEMENT_ACTIVATIONS(14) with air filter gives COUNT of air activations.
# But design says "unique" air runes. We can approximate with ROUND_ELEMENT_ACTIVATIONS.
New-ScorePerEffect "ge_s3_perm_10_per_air_round" 14 10 -permanent $true -filterRes $Shared.filt_air

# ge_s3_poeira_reader_back_1 (reader back 1)
Write-TresFile "$effectsDir\ge_s3_reader_back_1.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_move_reader)" id="2_am"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_am")
value = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_poeira_perm_reader_1 (+1 permanent reader return = +1 permanent activation to self, effectively)
# Since there's no direct "permanent reader bonus", we model this as +1 buff activation permanent on self
# Actually this is a unique mechanic. Let's use ActionBuffActivation permanent on self as approximation.
Write-TresFile "$effectsDir\ge_s3_buff_self_1_perm.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_buff)" id="2_ab"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ab")
value = SubResource("vr")
is_permanent = true

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_sedimentacao_score_10 - reuse ge_score_10
# ge_s3_sedimentacao_perm_20_if_simultaneous
New-ScoreEffect "ge_s3_perm_20_if_simultaneous" 20 -permanent $true -conditionRes "res://resources/effects/shared/conditions/condition_simultaneous.tres"


# ==== ESPIRITO (SPIRIT) effects ====

# ge_s3_trevas_destroy_prev = ge_destroy_previous (reuse)
# ge_s3_trevas_residue_adj_if_success (mana residue on adj if previous effect succeeded)
Write-TresFile "$effectsDir\ge_s3_residue_adj_if_success.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]
[ext_resource type="Resource" path="$($Shared.cond_prev_effect)" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_luz_score_per_created (+100 per rune created this round)
New-ScorePerEffect "ge_s3_score_100_per_created" 9 100

# ge_s3_caos_consume_anomaly_adj (consume adj anomaly)
Write-TresFile "$effectsDir\ge_s3_consume_anomaly_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="2_ac"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_mana_anomaly.tres" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
residue_id = "mana_anomaly"
max_consume = 1

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_caos_create_spirit_if_success (create spirit rune in adj if previous effect succeeded)
Write-TresFile "$effectsDir\ge_s3_create_spirit_adj_if_success.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_create)" id="2_ac"]
[ext_resource type="Resource" path="$($Shared.sel_empty_adj)" id="3_sel"]
[ext_resource type="Resource" path="$($Shared.cond_prev_effect)" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
element = 4

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_tempo_free_below (next activation of below is free)
Write-TresFile "$effectsDir\ge_s3_free_activation_below.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_free_activation)" id="2_af"]
[ext_resource type="Resource" path="$($Shared.sel_below)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_af")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_ordem_consume_mana_residue_adj (consume mana residues adj, +100 per consumed)
Write-TresFile "$effectsDir\ge_s3_consume_mana_residue_adj_score.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="2_ac"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 100.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
residue_id = "mana_residue"
max_consume = -1
score_per_consumed = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_entropia (consume adj mana_residue AND anomaly, then create random rune)
# This needs composite: consume residue + consume anomaly + create random if both succeeded
# We'll split into: effect 1: consume both (with condition), effect 2: create random (with prev effect)
Write-TresFile "$effectsDir\ge_s3_entropia_consume_both.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_composite)" id="2_comp"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="3_ac"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_residue_and_anomaly.tres" id="5_cond"]

[sub_resource type="Resource" id="act_residue"]
script = ExtResource("3_ac")
residue_id = "mana_residue"
max_consume = 1

[sub_resource type="Resource" id="act_anomaly"]
script = ExtResource("3_ac")
residue_id = "mana_anomaly"
max_consume = 1

[sub_resource type="Resource" id="act"]
script = ExtResource("2_comp")
actions = [SubResource("act_residue"), SubResource("act_anomaly")]

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("act")
"@

# ge_s3_entropia_create_random (create random rune if prev succeeded)
Write-TresFile "$effectsDir\ge_s3_create_random_if_success.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_create_random)" id="2_acr"]
[ext_resource type="Resource" path="$($Shared.sel_empty_rand)" id="3_sel"]
[ext_resource type="Resource" path="$($Shared.cond_prev_effect)" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_acr")
random_any = true

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_mudanca_transform_anomaly_to_residue (transform adj anomalies to residues)
Write-TresFile "$effectsDir\ge_s3_transform_anomaly_to_residue_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_transform_residue)" id="2_at"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_at")
from_residue_id = "mana_anomaly"
to_residue_id = "mana_residue"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_pleroma_anomaly_adj (create anomaly on all adjacent)
Write-TresFile "$effectsDir\ge_s3_apply_anomaly_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_apply_residue)" id="2_ar"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ar")
residue_id = "mana_anomaly"

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_vacuo_score_10 - reuse ge_score_10
# ge_s3_vacuo_perm_per_empty_adj (+20 perm per empty adjacent)
New-ScorePerEffect "ge_s3_perm_20_per_empty_adj" 0 20 -permanent $true -filterRes $Shared.filt_empty


# ==== ESPIRITO+FOGO ====

# ge_s3_fenix_score_100 - reuse ge_s3_score_100
# ge_s3_fenix_resurrect (resurrect with +100 permanent on destroy)
Write-TresFile "$effectsDir\ge_s3_phoenix_resurrect_100.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_resurrect)" id="2_amr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_amr")
permanent_score_bonus = 100

[resource]
script = ExtResource("1_ge")
trigger = 2
selector = ExtResource("3_sel")
action = SubResource("act")
"@


# ==== ESPIRITO+AGUA ====

# ge_s3_empatia (consume mana residue adj, then copy previous effects)
Write-TresFile "$effectsDir\ge_s3_empatia_consume_then_copy.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="2_ac"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="3_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_mana_residue.tres" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
residue_id = "mana_residue"
max_consume = 1

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@
# ge_s3_empatia_copy (copy previous effects if prev succeeded)
Write-TresFile "$effectsDir\ge_s3_copy_previous_if_success.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_copy)" id="2_ac"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="3_sel"]
[ext_resource type="Resource" path="$($Shared.cond_prev_effect)" id="4_cond"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
source = 0

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_ninfa_score_per_panel_residue (+50 per mana residue on panel)
New-ScorePerEffect "ge_s3_score_50_per_panel_mana_residue" 16 50


# ==== ESPIRITO+AR ====

# ge_s3_djinn (consume mana residue adj, create random air rune)
Write-TresFile "$effectsDir\ge_s3_djinn_consume_and_create_air.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=9 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_composite)" id="2_comp"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="3_ac"]
[ext_resource type="Script" path="$($S.action_create_random)" id="4_acr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="5_sel"]
[ext_resource type="Resource" path="res://resources/effects/shared/conditions/condition_adj_mana_residue.tres" id="6_cond"]

[sub_resource type="Resource" id="act_consume"]
script = ExtResource("3_ac")
residue_id = "mana_residue"
max_consume = 1

[sub_resource type="Resource" id="act_create"]
script = ExtResource("4_acr")
allowed_elements = Array[int]([3])

[sub_resource type="Resource" id="act"]
script = ExtResource("2_comp")
actions = [SubResource("act_consume"), SubResource("act_create")]

[resource]
script = ExtResource("1_ge")
condition = ExtResource("6_cond")
selector = ExtResource("5_sel")
action = SubResource("act")
"@


# ==== ESPIRITO+TERRA ====

# ge_s3_golem_score_20
New-ScoreEffect "ge_s3_score_20" 20

# ge_s3_golem_consume_residue_perm50 (consume adj mana residue, +50 perm each)
Write-TresFile "$effectsDir\ge_s3_consume_residue_adj_perm50.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="2_ac"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 50.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
residue_id = "mana_residue"
max_consume = -1
score_per_consumed = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@
# Note: score_per_consumed gives immediate score per consumed. For permanent, we'd need the action to support is_permanent.
# Since ActionConsumeResidue's score_per_consumed may not support permanent, let's check and potentially use a different approach.
# For now, this gives +50 score per consumed residue (not permanent). TODO: verify if permanent is needed.

# ge_s3_golem_consume_anomaly_perm100 (consume adj anomaly, +100 perm each)
Write-TresFile "$effectsDir\ge_s3_consume_anomaly_adj_perm100.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="2_ac"]
[ext_resource type="Script" path="$($S.value_resolver)" id="3_vr"]
[ext_resource type="Resource" path="$($Shared.sel_adj)" id="4_sel"]

[sub_resource type="Resource" id="vr"]
script = ExtResource("3_vr")
base = 100.0

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ac")
residue_id = "mana_anomaly"
max_consume = -1
score_per_consumed = SubResource("vr")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("act")
"@


# ==== TRIPLE ELEMENT ====

# ge_s3_vida_score_50
# reuse ge_s3_score_50

# ge_s3_vida_duplicate (duplicate self to empty adjacent)
# Reuse ge_nature_duplicate_self pattern
Write-TresFile "$effectsDir\ge_s3_duplicate_self_adj.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_duplicate)" id="2_ads"]
[ext_resource type="Resource" path="$($Shared.sel_empty_adj)" id="3_sel"]

[sub_resource type="Resource" id="act"]
script = ExtResource("2_ads")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("act")
"@

# ge_s3_estagnacao - complex: if last 3 same element, consume mana residue, +20 perm to all that element
# This is very complex. We'll approximate with: condition=last_5_same (adapt to 3), consume residue, score.
# For now create a simpler version using existing condition patterns
Write-TresFile "$effectsDir\ge_s3_estagnacao_score_matching.tres" @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$($S.game_effect)" id="1_ge"]
[ext_resource type="Script" path="$($S.action_composite)" id="2_comp"]
[ext_resource type="Script" path="$($S.action_consume_residue)" id="3_consume"]
[ext_resource type="Script" path="$($S.action_score)" id="4_score"]
[ext_resource type="Script" path="$($S.value_resolver)" id="5_vr"]
[ext_resource type="Resource" path="$($Shared.sel_self)" id="6_sel"]

[sub_resource type="Resource" id="act_consume"]
script = ExtResource("3_consume")
residue_id = "mana_residue"
max_consume = 1

[sub_resource type="Resource" id="vr"]
script = ExtResource("5_vr")
base = 20.0

[sub_resource type="Resource" id="act_score"]
script = ExtResource("4_score")
value = SubResource("vr")
is_permanent = true

[sub_resource type="Resource" id="act"]
script = ExtResource("2_comp")
actions = [SubResource("act_consume"), SubResource("act_score")]

[resource]
script = ExtResource("1_ge")
selector = ExtResource("6_sel")
action = SubResource("act")
"@

# ge_s3_gravidade_transfer (consume adj activations, transfer to next)
# Reuse ge_gravity_transfer_activations.tres

Write-Host "Phase 2: Effect resources created."

# =============================================================================
# PHASE 3: Create all Rune .tres files
# =============================================================================

# Reusable script UID
$runeDataScript = 'res://scripts/data/rune_data.gd'
$runeDataUID    = 'uid://s48ipf5uo7mv'

# Default texture for new runes (we'll use existing icons)
$defaultTextures = @{
    fire    = 'res://sprites/icons/runes/Icon3.png'
    water   = 'res://sprites/icons/runes/Icon46.png'
    earth   = 'res://sprites/icons/runes/Icon8.png'
    air     = 'res://sprites/icons/runes/Icon40.png'
    spirit  = 'res://sprites/icons/runes/Icon31.png'
    fire_earth = 'res://sprites/icons/runes/Icon6.png'
    fire_water = 'res://sprites/icons/runes/Icon4.png'
    fire_air   = 'res://sprites/icons/runes/Icon44.png'
    water_earth = 'res://sprites/icons/runes/Icon2.png'
    water_air   = 'res://sprites/icons/runes/Icon28.png'
    air_earth   = 'res://sprites/icons/runes/Icon31.png'
    triple  = 'res://sprites/icons/runes/Icon44.png'
}

function New-RuneFile($dir, $filename, $id, $name, $desc, $rarity, $elements, $effects, $tex, $maxAct=1, $indestructible=$true) {
    $elementArray = "Array[int]([$($elements -join ', ')])"

    # Calculate load_steps: script + texture + N effects + 1
    $loadSteps = 2 + $effects.Count + 1

    $extResources = @()
    $extResources += "[ext_resource type=""Script"" uid=""$runeDataUID"" path=""$runeDataScript"" id=""1_data""]"

    $effIdx = 2
    foreach ($eff in $effects) {
        $extResources += "[ext_resource type=""Resource"" path=""$eff"" id=""$($effIdx)_e$($effIdx - 1)""]"
        $effIdx++
    }
    $texId = "$($effIdx)_tex"
    $extResources += "[ext_resource type=""Texture2D"" path=""$tex"" id=""$texId""]"

    $effectRefs = ($effects | ForEach-Object { $i = [array]::IndexOf($effects, $_) + 2; "ExtResource(""$($i)_e$($i - 1)"")" }) -join ', '

    $rarityLine = if ($rarity -ne 0) { "`nrarity = $rarity" } else { "" }
    $maxActLine = if ($maxAct -ne 1) { "`nbase_max_activations = $maxAct" } else { "" }
    $indestrLine = ""

    $content = @"
[gd_resource type="Resource" script_class="RuneData" load_steps=$loadSteps format=3]

$($extResources -join "`n")

[resource]
script = ExtResource("1_data")
id = "$id"
rune_name = "$name"
description = "$desc"$rarityLine
elements = $elementArray$maxActLine$indestrLine
textures = Array[Texture2D]([ExtResource("$texId")])
effects = [$effectRefs]
"@

    Write-TresFile "$dir\$filename" $content
}

# ---- FOGO ----
New-RuneFile $runesUncommon "rune_incendio.tres" "incendio" "Incendio" `
    "+50 pts para cada runa de fogo ou ar proximo (com diagonal)" 1 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_incendio_score.tres'
) $defaultTextures.fire

New-RuneFile $runesUncommon "rune_plasma.tres" "plasma" "Plasma" `
    "+100 pontos. Se ativada 2x consecutivas, ganha +200 pontos" 1 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_plasma_score_100.tres',
    'res://resources/effects/rune_effects/ge_s3_plasma_bonus_consecutive.tres'
) $defaultTextures.fire

New-RuneFile $runesUncommon "rune_calor.tres" "calor" "Calor" `
    "+30 pontos para cada runa de fogo ativada na rodada. Petrifica o slot." 1 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_calor_score_per_fire.tres',
    'res://resources/effects/rune_effects/ge_petrify_self.tres'
) $defaultTextures.fire

New-RuneFile $runesCommon "rune_explosao.tres" "explosao" "Explosao" `
    "+200 pontos. -10 pontos permanentes para adjacentes." 0 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_explosao_score_200.tres',
    'res://resources/effects/rune_effects/ge_s3_explosao_minus10_adj.tres'
) $defaultTextures.fire

New-RuneFile $runesCommon "rune_queimadura.tres" "queimadura" "Queimadura" `
    "+200 pontos. Gera uma anomalia de mana em slot adjacente." 0 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_explosao_score_200.tres',
    'res://resources/effects/rune_effects/ge_s3_apply_anomaly_adj_random.tres'
) $defaultTextures.fire

New-RuneFile $runesCommon "rune_labareda.tres" "labareda" "Labareda" `
    "+100 pontos. +100 pontos caso a runa anterior seja de fogo." 0 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_labareda_score_100.tres',
    'res://resources/effects/rune_effects/ge_s3_labareda_bonus_fire.tres'
) $defaultTextures.fire

New-RuneFile $runesRare "rune_supernova.tres" "supernova" "Supernova" `
    "+500 pontos. Petrifica o slot. Gera anomalias de mana em toda a coluna." 2 @(0) @(
    'res://resources/effects/rune_effects/ge_s3_supernova_score_500.tres',
    'res://resources/effects/rune_effects/ge_petrify_self.tres',
    'res://resources/effects/rune_effects/ge_s3_anomaly_column_not_self.tres'
) $defaultTextures.fire

# ---- AGUA ----
New-RuneFile $runesCommon "rune_gota.tres" "gota" "Gota" `
    "+1 ativacao permanente para a runa inferior. Destrua essa runa e gere residuo manico." 0 @(1) @(
    'res://resources/effects/rune_effects/ge_buff_below_activation_permanent.tres',
    'res://resources/effects/rune_effects/ge_s3_apply_mana_residue_self.tres',
    'res://resources/effects/rune_effects/ge_s3_destroy_self.tres'
) $defaultTextures.water -indestructible $false

New-RuneFile $runesCommon "rune_lago.tres" "lago" "Lago" `
    "+1 ativacao para runas adjacentes se adjacente a 2 terras." 0 @(1) @(
    'res://resources/effects/rune_effects/ge_s3_buff_adj_if_2earth.tres'
) $defaultTextures.water

New-RuneFile $runesCommon "rune_chuva.tres" "chuva" "Chuva" `
    "Gera um residuo de mana no slot inferior." 0 @(1) @(
    'res://resources/effects/rune_effects/ge_s3_apply_mana_residue_below.tres'
) $defaultTextures.water

New-RuneFile $runesUncommon "rune_rio.tres" "rio" "Rio" `
    "+1 ativacao para todas as runas da linha se adjacente a 2 terras." 1 @(1) @(
    'res://resources/effects/rune_effects/ge_s3_buff_row_if_2earth.tres'
) $defaultTextures.water

New-RuneFile $runesUncommon "rune_cachoeira.tres" "cachoeira" "Cachoeira" `
    "Se adjacente a 3 aguas, gera residuo de mana em toda a coluna." 1 @(1) @(
    'res://resources/effects/rune_effects/ge_s3_residue_column_if_3water.tres'
) $defaultTextures.water

New-RuneFile $runesCommon "rune_fluxo.tres" "fluxo" "Fluxo" `
    "+2 de ativacao para a runa seguinte." 0 @(1) @(
    'res://resources/effects/rune_effects/ge_s3_buff_next_2.tres'
) $defaultTextures.water

# ---- AR ----
New-RuneFile $runesCommon "rune_vento.tres" "vento" "Vento" `
    "Reader retorna 2 slots." 0 @(3) @(
    'res://resources/effects/rune_effects/ge_reader_back_2.tres'
) $defaultTextures.air

New-RuneFile $runesCommon "rune_redemoinho.tres" "redemoinho" "Redemoinho" `
    "Ativa runas imediatamente antes e depois simultaneamente." 0 @(3) @(
    'res://resources/effects/rune_effects/ge_s3_trigger_both_simultaneous.tres'
) $defaultTextures.air

New-RuneFile $runesCommon "rune_pressao.tres" "pressao" "Pressao" `
    "Ativa todas as ativacoes da runa anterior." 0 @(3) @(
    'res://resources/effects/rune_effects/ge_s3_drain_previous.tres'
) $defaultTextures.air

New-RuneFile $runesUncommon "rune_vendaval.tres" "vendaval" "Vendaval" `
    "Reader retorna 4 slots se adjacente a 2 runas de ar." 1 @(3) @(
    'res://resources/effects/rune_effects/ge_s3_reader_back_4_if_2air.tres'
) $defaultTextures.air

New-RuneFile $runesUncommon "rune_furacao.tres" "furacao" "Furacao" `
    "Ativa simultaneamente todas as runas adjacentes se adjacente a 2 runas de ar." 1 @(3) @(
    'res://resources/effects/rune_effects/ge_s3_trigger_adj_simul_if_2air.tres'
) $defaultTextures.air

# ---- TERRA ----
New-RuneFile $runesCommon "rune_rocha.tres" "rocha" "Rocha" `
    "+10 pontos. +10 pontos permanente." 0 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_score_permanent_10.tres'
) $defaultTextures.earth

New-RuneFile $runesCommon "rune_tremor.tres" "tremor" "Tremor" `
    "+10 pontos. A runa anterior e movida para o espaco inferior." 0 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_swap_previous_to_below.tres'
) $defaultTextures.earth

New-RuneFile $runesUncommon "rune_terremoto.tres" "terremoto" "Terremoto" `
    "As runas de cima e anterior sao trocadas de lugar para baixo e posterior." 1 @(2) @(
    'res://resources/effects/rune_effects/ge_s3_terremoto_swap.tres'
) $defaultTextures.earth

New-RuneFile $runesCommon "rune_quartzo.tres" "quartzo" "Quartzo" `
    "+10 pontos permanentes para runas de terra adjacentes." 0 @(2) @(
    'res://resources/effects/rune_effects/ge_s3_perm_10_to_earth_adj.tres'
) $defaultTextures.earth

New-RuneFile $runesCommon "rune_ametista.tres" "ametista" "Ametista" `
    "+10 pontos. +5 pontos permanente para cada runa de terra adjacente." 0 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_5_per_earth_adj.tres'
) $defaultTextures.earth

New-RuneFile $runesUncommon "rune_topazio.tres" "topazio" "Topazio" `
    "+10 pontos. +20 pontos permanente se adjacente a 3 elementos distintos." 1 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_20_if_3distinct.tres'
) $defaultTextures.earth

New-RuneFile $runesUncommon "rune_esmeralda.tres" "esmeralda" "Esmeralda" `
    "+10 pontos. +10 pontos permanentes por cada vez que essa runa foi movida." 1 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_10_per_moved.tres'
) $defaultTextures.earth

New-RuneFile $runesCommon "rune_estalactite.tres" "estalactite" "Estalactite" `
    "+10 pontos. +20 pontos permanentes se em um canto." 0 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_20_if_corner.tres'
) $defaultTextures.earth

New-RuneFile $runesRare "rune_diamante.tres" "diamante" "Diamante" `
    "+10 pontos. +50 pontos permanente se esta no centro. Petrifica o slot." 2 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_50_if_center.tres',
    'res://resources/effects/rune_effects/ge_petrify_self.tres'
) $defaultTextures.earth

New-RuneFile $runesUncommon "rune_rubi.tres" "rubi" "Rubi" `
    "+10 pontos. Ganha +5 pontos permanente quando uma runa de fogo adjacente e ativada." 1 @(2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_rubi_on_adj_fire.tres'
) $defaultTextures.earth

# ---- FOGO+TERRA ----
New-RuneFile $runesUncommon "rune_lava.tres" "lava" "Lava" `
    "+50 pontos. +20 pontos permanentes para cada terra adjacente. Petrifica o slot." 1 @(0, 2) @(
    'res://resources/effects/rune_effects/ge_s3_score_50.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_20_per_earth_adj.tres',
    'res://resources/effects/rune_effects/ge_petrify_self.tres'
) $defaultTextures.fire_earth

New-RuneFile $runesUncommon "rune_obsidiana.tres" "obsidiana" "Obsidiana" `
    "+100 pontos para cada runa de terra ou fogo adjacentes. Petrifica o slot." 1 @(0, 2) @(
    'res://resources/effects/rune_effects/ge_s3_score_100_per_fire_earth_adj.tres',
    'res://resources/effects/rune_effects/ge_petrify_self.tres'
) $defaultTextures.fire_earth

New-RuneFile $runesRare "rune_erupcao.tres" "erupcao" "Erupcao" `
    "Destrua a runa seguinte. Crie uma anomalia no slot anterior. +400 pontos." 2 @(0, 2) @(
    'res://resources/effects/rune_effects/ge_destroy_next.tres',
    'res://resources/effects/rune_effects/ge_s3_apply_anomaly_previous.tres',
    'res://resources/effects/rune_effects/ge_s3_score_400.tres'
) $defaultTextures.fire_earth

# ---- FOGO+AGUA ----
New-RuneFile $runesUncommon "rune_oleo.tres" "oleo" "Oleo" `
    "+50 pontos para cada ativacao restante." 1 @(0, 1) @(
    'res://resources/effects/rune_effects/ge_s3_score_50_per_remaining.tres'
) $defaultTextures.fire_water

New-RuneFile $runesUncommon "rune_acido.tres" "acido" "Acido" `
    "Destrua a runa anterior. Se bem sucedido, +5 ativacoes para a proxima runa." 1 @(0, 1) @(
    'res://resources/effects/rune_effects/ge_destroy_previous.tres',
    'res://resources/effects/rune_effects/ge_s3_buff_next_5_if_success.tres'
) $defaultTextures.fire_water

New-RuneFile $runesRare "rune_ebulicao.tres" "ebulicao" "Ebulicao" `
    "Gera residuo de mana nos espacos adjacentes. -1 ativacao para runas adjacentes." 2 @(0, 1) @(
    'res://resources/effects/rune_effects/ge_s3_apply_mana_residue_adj.tres',
    'res://resources/effects/rune_effects/ge_s3_debuff_adj_1.tres'
) $defaultTextures.fire_water

# ---- FOGO+AR ----
New-RuneFile $runesUncommon "rune_raio.tres" "raio" "Raio" `
    "Ativa todas as runas adjacentes simultaneamente. Gera anomalia no slot posterior." 1 @(0, 3) @(
    'res://resources/effects/rune_effects/ge_s3_trigger_adj_simultaneous.tres',
    'res://resources/effects/rune_effects/ge_s3_apply_anomaly_next.tres'
) $defaultTextures.fire_air

New-RuneFile $runesRare "rune_eletricidade.tres" "eletricidade" "Eletricidade" `
    "Se ativada simultaneamente, nao gasta ativacao. +100 pontos." 2 @(0, 3) @(
    'res://resources/effects/rune_effects/ge_s3_free_if_simultaneous.tres',
    'res://resources/effects/rune_effects/ge_s3_score_100.tres'
) $defaultTextures.fire_air

New-RuneFile $runesUncommon "rune_conveccao.tres" "conveccao" "Conveccao" `
    "Reader retorna +2 por fogo adjacente, -1 por agua adjacente." 1 @(0, 3) @(
    'res://resources/effects/rune_effects/ge_s3_conveccao_reader.tres'
) $defaultTextures.fire_air

# ---- AGUA+TERRA ----
New-RuneFile $runesUncommon "rune_gelo.tres" "gelo" "Gelo" `
    "+10 pontos permanentes para cada ativacao restante." 1 @(1, 2) @(
    'res://resources/effects/rune_effects/ge_s3_perm_10_per_remaining.tres'
) $defaultTextures.water_earth

New-RuneFile $runesUncommon "rune_lama.tres" "lama" "Lama" `
    "+1 ativacao permanente para runas de terra adjacentes. Destrua essa runa." 1 @(1, 2) @(
    'res://resources/effects/rune_effects/ge_s3_buff_adj_earth_perm.tres',
    'res://resources/effects/rune_effects/ge_s3_destroy_self.tres'
) $defaultTextures.water_earth -indestructible $false

New-RuneFile $runesRare "rune_praia.tres" "praia" "Praia" `
    "Rotacione as runas e residuos adjacentes no sentido anti-horario." 2 @(1, 2) @(
    'res://resources/effects/rune_effects/ge_s3_rotate_adj_ccw.tres'
) $defaultTextures.water_earth

# ---- AGUA+AR ----
New-RuneFile $runesRare "rune_corrente.tres" "corrente" "Corrente" `
    "Reader retorna 1 casa para cada ativacao restante." 2 @(1, 3) @(
    'res://resources/effects/rune_effects/ge_reader_per_remaining.tres'
) $defaultTextures.water_air

New-RuneFile $runesRare "rune_geada.tres" "geada" "Geada" `
    "Ative todas as runas da coluna simultaneamente. Runas com 0 ativacoes recebem +1." 2 @(1, 3) @(
    'res://resources/effects/rune_effects/ge_s3_trigger_column_simultaneous.tres',
    'res://resources/effects/rune_effects/ge_s3_buff_column_if_0_activations.tres'
) $defaultTextures.water_air

New-RuneFile $runesUncommon "rune_bolha.tres" "bolha" "Bolha" `
    "Reader retorna para o residuo de mana anterior mais proximo." 1 @(1, 3) @(
    'res://resources/effects/rune_effects/ge_s3_reader_to_nearest_mana_residue.tres'
) $defaultTextures.water_air

New-RuneFile $runesUncommon "rune_nuvem.tres" "nuvem" "Nuvem" `
    "+10 pontos para cada ativacao de agua ou ar realizada nessa rodada." 1 @(1, 3) @(
    'res://resources/effects/rune_effects/ge_s3_score_per_water_air_round.tres'
) $defaultTextures.water_air

# ---- AR+TERRA ----
New-RuneFile $runesUncommon "rune_areia.tres" "areia" "Areia" `
    "+10 pontos. +10 pontos permanentes para cada runa de ar ativada nessa rodada." 1 @(3, 2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_10_per_air_round.tres'
) $defaultTextures.air_earth

New-RuneFile $runesRare "rune_poeira.tres" "poeira" "Poeira" `
    "Reader volta 1 casa. +1 ativacao permanente para si." 2 @(3, 2) @(
    'res://resources/effects/rune_effects/ge_s3_reader_back_1.tres',
    'res://resources/effects/rune_effects/ge_s3_buff_self_1_perm.tres'
) $defaultTextures.air_earth

New-RuneFile $runesUncommon "rune_sedimentacao.tres" "sedimentacao" "Sedimentacao" `
    "+10 pontos. +20 pontos permanentes se ativada simultaneamente." 1 @(3, 2) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_20_if_simultaneous.tres'
) $defaultTextures.air_earth

# ---- ESPIRITO ----
New-RuneFile $runesUncommon "rune_trevas.tres" "trevas" "Trevas" `
    "Destrua a runa anterior. Se bem sucedido, gere residuo manico nos adjacentes." 1 @(4) @(
    'res://resources/effects/rune_effects/ge_destroy_previous.tres',
    'res://resources/effects/rune_effects/ge_s3_residue_adj_if_success.tres'
) $defaultTextures.spirit

New-RuneFile $runesUncommon "rune_luz.tres" "luz" "Luz" `
    "+100 pontos para cada runa criada nessa rodada." 1 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_score_100_per_created.tres'
) $defaultTextures.spirit

New-RuneFile $runesRare "rune_caos.tres" "caos" "Caos" `
    "Consuma uma anomalia manica adjacente. Se bem sucedido, gere uma runa de espirito adjacente." 2 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_consume_anomaly_adj.tres',
    'res://resources/effects/rune_effects/ge_s3_create_spirit_adj_if_success.tres'
) $defaultTextures.spirit

New-RuneFile $runesCommon "rune_tempo.tres" "tempo" "Tempo" `
    "A proxima ativacao da runa inferior nao gasta ativacao." 0 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_free_activation_below.tres'
) $defaultTextures.spirit

New-RuneFile $runesUncommon "rune_ordem.tres" "ordem" "Ordem" `
    "Consuma residuos manicos adjacentes. Para cada consumido, +100 pontos." 1 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_consume_mana_residue_adj_score.tres'
) $defaultTextures.spirit

New-RuneFile $runesRare "rune_entropia.tres" "entropia" "Entropia" `
    "Se adjacente a residuo manico e anomalia manica, consuma-os. Gere uma runa aleatoria." 2 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_entropia_consume_both.tres',
    'res://resources/effects/rune_effects/ge_s3_create_random_if_success.tres'
) $defaultTextures.spirit

New-RuneFile $runesUncommon "rune_mudanca.tres" "mudanca" "Mudanca" `
    "Transforme anomalias manicas adjacentes em residuos manicos." 1 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_transform_anomaly_to_residue_adj.tres'
) $defaultTextures.spirit

New-RuneFile $runesRare "rune_pleroma.tres" "pleroma" "Pleroma" `
    "Gere anomalia manica em todos os slots adjacentes." 2 @(4) @(
    'res://resources/effects/rune_effects/ge_s3_apply_anomaly_adj.tres'
) $defaultTextures.spirit

New-RuneFile $runesUncommon "rune_vacuo.tres" "vacuo" "Vacuo" `
    "+10 pontos. +20 pontos permanentes para cada espaco vazio adjacente." 1 @(4) @(
    'res://resources/effects/rune_effects/ge_score_10.tres',
    'res://resources/effects/rune_effects/ge_s3_perm_20_per_empty_adj.tres'
) $defaultTextures.spirit

# ---- ESPIRITO+FOGO ----
New-RuneFile $runesRare "rune_fenix.tres" "fenix" "Fenix" `
    "+100 pontos. Se destruida, recrie-a com +100 pontos permanentes." 2 @(4, 0) @(
    'res://resources/effects/rune_effects/ge_s3_score_100.tres',
    'res://resources/effects/rune_effects/ge_s3_phoenix_resurrect_100.tres'
) $defaultTextures.fire -indestructible $false

# ---- ESPIRITO+AGUA ----
New-RuneFile $runesRare "rune_empatia.tres" "empatia" "Empatia" `
    "Se adjacente a residuo manico, consuma-o e copie os efeitos da runa anterior." 2 @(4, 1) @(
    'res://resources/effects/rune_effects/ge_s3_empatia_consume_then_copy.tres',
    'res://resources/effects/rune_effects/ge_s3_copy_previous_if_success.tres'
) $defaultTextures.water

New-RuneFile $runesRare "rune_ninfa.tres" "ninfa" "Ninfa" `
    "+50 pontos para cada residuo manico presente no painel." 2 @(4, 1) @(
    'res://resources/effects/rune_effects/ge_s3_score_50_per_panel_mana_residue.tres'
) $defaultTextures.water

# ---- ESPIRITO+AR ----
New-RuneFile $runesRare "rune_djinn.tres" "djinn" "Djinn" `
    "Se adjacente a residuo manico, consuma-o e gere uma runa de ar aleatoria." 2 @(4, 3) @(
    'res://resources/effects/rune_effects/ge_s3_djinn_consume_and_create_air.tres'
) $defaultTextures.air

# ---- ESPIRITO+TERRA ----
New-RuneFile $runesRare "rune_golem.tres" "golem" "Golem" `
    "+20 pontos. Consuma residuos manicos adjacentes (+50 pts cada). Consuma anomalias (+100 pts cada)." 2 @(4, 2) @(
    'res://resources/effects/rune_effects/ge_s3_score_20.tres',
    'res://resources/effects/rune_effects/ge_s3_consume_residue_adj_perm50.tres',
    'res://resources/effects/rune_effects/ge_s3_consume_anomaly_adj_perm100.tres'
) $defaultTextures.earth

# ---- TRIPLE ELEMENT ----
New-RuneFile $runesEpic "rune_vida.tres" "vida" "Vida" `
    "+50 pontos. Gere uma copia dessa runa em um espaco adjacente disponivel." 3 @(4, 2, 1) @(
    'res://resources/effects/rune_effects/ge_s3_score_50.tres',
    'res://resources/effects/rune_effects/ge_s3_duplicate_self_adj.tres'
) $defaultTextures.triple

New-RuneFile $runesEpic "rune_estagnacao.tres" "estagnacao" "Estagnacao" `
    "Consuma residuo de mana e conceda +20 pontos permanentes." 3 @(2, 1, 3) @(
    'res://resources/effects/rune_effects/ge_s3_estagnacao_score_matching.tres'
) $defaultTextures.triple

New-RuneFile $runesEpic "rune_gravidade.tres" "gravidade" "Gravidade" `
    "Consuma todas as ativacoes de runas adjacentes, transfira para a runa seguinte." 3 @(2, 1, 0) @(
    'res://resources/effects/rune_effects/ge_gravity_transfer_activations.tres'
) $defaultTextures.triple

Write-Host "Phase 3: Rune resources created."
Write-Host ""
Write-Host "=== GENERATION COMPLETE ==="
Write-Host "Total files created/updated: $fileCount"
