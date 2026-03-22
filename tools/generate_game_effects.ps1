# Phase 8 GameEffect .tres migration generator
# Generates new GameEffect .tres files in resources/effects/rune_effects/

$base = "c:\Users\55119\Documents\runes\resources\effects\rune_effects"

# Script paths (res:// format for Godot)
$GE = "res://scripts/effects/game_effect.gd"
$AS = "res://scripts/effects/actions/action_score.gd"
$AB = "res://scripts/effects/actions/action_buff_activation.gd"
$AD = "res://scripts/effects/actions/action_destroy_rune.gd"
$AP = "res://scripts/effects/actions/action_petrify.gd"
$AC = "res://scripts/effects/actions/action_create_rune.gd"
$AM = "res://scripts/effects/actions/action_move_reader.gd"
$ADS = "res://scripts/effects/actions/action_duplicate_self.gd"
$AMR = "res://scripts/effects/actions/action_mark_resurrection.gd"
$AT = "res://scripts/effects/actions/action_trigger_activation.gd"
$ASW = "res://scripts/effects/actions/action_swap_position.gd"
$ACO = "res://scripts/effects/actions/action_composite.gd"
$VR = "res://scripts/effects/value_resolver.gd"
$VP = "res://scripts/effects/value_per.gd"
$SF = "res://scripts/effects/slot_filter.gd"

# Shared resource paths
$SEL_SELF = "res://resources/effects/shared/selectors/selector_self.tres"
$SEL_ADJ = "res://resources/effects/shared/selectors/selector_adjacent.tres"
$SEL_NEXT = "res://resources/effects/shared/selectors/selector_sequence_next.tres"
$SEL_PREV = "res://resources/effects/shared/selectors/selector_sequence_previous.tres"
$SEL_BELOW = "res://resources/effects/shared/selectors/selector_below.tres"
$SEL_EMPTY_ADJ = "res://resources/effects/shared/selectors/selector_empty_adjacent.tres"
$SEL_EMPTY_RND = "res://resources/effects/shared/selectors/selector_empty_random.tres"
$SEL_PANEL = "res://resources/effects/shared/selectors/selector_panel_all.tres"

# Shared conditions
$COND_CORNER = "res://resources/effects/shared/conditions/condition_corner.tres"
$COND_NO_NEIGH = "res://resources/effects/shared/conditions/condition_no_neighbors.tres"
$COND_3DIST = "res://resources/effects/shared/conditions/condition_3_distinct.tres"
$COND_4DIST = "res://resources/effects/shared/conditions/condition_4_distinct.tres"
$COND_5DIST = "res://resources/effects/shared/conditions/condition_5_distinct.tres"
$COND_LAST_FIRE = "res://resources/effects/shared/conditions/condition_last_fire.tres"
$COND_LAST_AIR = "res://resources/effects/shared/conditions/condition_last_air.tres"
$COND_LAST_SPIRIT = "res://resources/effects/shared/conditions/condition_last_spirit.tres"
$COND_NOT_ACT = "res://resources/effects/shared/conditions/condition_not_activated.tres"
$COND_WATER_ADJ = "res://resources/effects/shared/conditions/condition_water_adjacent.tres"
$COND_ADJ_ACT = "res://resources/effects/shared/conditions/condition_adjacent_activated.tres"
$COND_ADJ_FIRE = "res://resources/effects/shared/conditions/condition_adjacent_fire_activated.tres"
$COND_ADJ_SPIRIT = "res://resources/effects/shared/conditions/condition_adjacent_spirit_activated.tres"

# Shared filters
$FILT_EMPTY = "res://resources/effects/shared/filters/filter_empty.tres"
$FILT_EARTH = "res://resources/effects/shared/filters/filter_earth.tres"
$FILT_WATER = "res://resources/effects/shared/filters/filter_water.tres"

# Helper: Simple score effect (self, no condition)
function New-ScoreEffect($name, $score, $trigger = 0, $permanent = $false) {
    $isPerm = if ($permanent) { "is_permanent = true" } else { "" }
    $triggerLine = if ($trigger -ne 0) { "trigger = $trigger" } else { "" }
    @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AS" id="2_as"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_SELF" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = $($score).0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
$isPerm

[resource]
script = ExtResource("1_ge")
$triggerLine
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_$name.tres" -Encoding UTF8
}

# Helper: Score with condition
function New-ScoreCondEffect($name, $score, $condPath, $trigger = 0, $permanent = $false) {
    $isPerm = if ($permanent) { "is_permanent = true" } else { "" }
    $triggerLine = if ($trigger -ne 0) { "trigger = $trigger" } else { "" }
    @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AS" id="2_as"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_SELF" id="4_sel"]
[ext_resource type="Resource" path="$condPath" id="5_cond"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = $($score).0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_as")
value = SubResource("Resource_vr001")
$isPerm

[resource]
script = ExtResource("1_ge")
$triggerLine
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_$name.tres" -Encoding UTF8
}

# Helper: Score per remaining activations
function New-ScorePerRemaining($name, $perValue) {
    @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AS" id="2_as"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Script" path="$VP" id="4_vp"]
[ext_resource type="Resource" path="$SEL_SELF" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 4
per_value = $($perValue).0

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
"@ | Set-Content "$base\ge_$name.tres" -Encoding UTF8
}

# Helper: Score per adjacent element
function New-ScorePerAdjacentElement($name, $perValue, $filterPath) {
    @"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AS" id="2_as"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Script" path="$VP" id="4_vp"]
[ext_resource type="Resource" path="$SEL_SELF" id="5_sel"]
[ext_resource type="Resource" path="$filterPath" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = $($perValue).0
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
"@ | Set-Content "$base\ge_$name.tres" -Encoding UTF8
}

Write-Output "Generating GameEffect .tres files..."

# ========== SIMPLE SCORE EFFECTS ==========
New-ScoreEffect "score_10" 10
New-ScoreEffect "score_20" 20
New-ScoreEffect "score_30" 30
New-ScoreEffect "score_50" 50
New-ScoreEffect "score_100" 100
New-ScoreEffect "score_200" 200

# ========== CONDITIONAL SCORE EFFECTS ==========
New-ScoreCondEffect "score_50_if_corner" 50 $COND_CORNER
New-ScoreCondEffect "score_50_if_no_neighbors" 50 $COND_NO_NEIGH
New-ScoreCondEffect "score_20_if_3_distinct" 20 $COND_3DIST
New-ScoreCondEffect "score_30_if_4_distinct" 30 $COND_4DIST
New-ScoreCondEffect "score_20_if_last_fire" 20 $COND_LAST_FIRE
New-ScoreCondEffect "score_20_if_last_spirit" 20 $COND_LAST_SPIRIT
New-ScoreCondEffect "score_100_if_not_activated" 100 $COND_NOT_ACT 5

# ========== SCORE PER REMAINING ==========
New-ScorePerRemaining "score_10_per_remaining" 10
New-ScorePerRemaining "score_20_per_remaining" 20
New-ScorePerRemaining "score_30_per_remaining" 30

# ========== SCORE PER ADJACENT ELEMENT ==========
New-ScorePerAdjacentElement "score_per_earth_adjacent" 10 $FILT_EARTH
New-ScorePerAdjacentElement "score_per_water_adjacent" 10 $FILT_WATER

# ========== PERMANENT SCORE PER EMPTY ADJACENT ==========
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=7 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AS" id="2_as"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Script" path="$VP" id="4_vp"]
[ext_resource type="Resource" path="$SEL_SELF" id="5_sel"]
[ext_resource type="Resource" path="$FILT_EMPTY" id="6_filt"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 10.0
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
"@ | Set-Content "$base\ge_permanent_score_10_per_empty_adjacent.tres" -Encoding UTF8

# ========== TRIGGERED SCORE EFFECTS ==========
New-ScoreEffect "score_50_on_adjacent_activated" 50 3
New-ScoreCondEffect "score_10_on_adjacent_fire" 10 $COND_ADJ_FIRE 3
New-ScoreCondEffect "permanent_score_5_on_adjacent_activated" 5 $COND_ADJ_ACT 3 $true
New-ScoreCondEffect "permanent_score_minus20_on_adjacent_spirit" -20 $COND_ADJ_SPIRIT 3 $true
New-ScoreCondEffect "permanent_score_50_if_not_activated" 50 $COND_NOT_ACT 5 $true

# ========== BUFF EFFECTS ==========
# Buff adjacent +2 activation
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AB" id="2_ab"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_ADJ" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 2.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ab")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_buff_adjacent_activation.tres" -Encoding UTF8

# Buff next +1 activation
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AB" id="2_ab"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_NEXT" id="4_sel"]

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
"@ | Set-Content "$base\ge_buff_next_activation.tres" -Encoding UTF8

# Buff next +1 if water adjacent
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AB" id="2_ab"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_NEXT" id="4_sel"]
[ext_resource type="Resource" path="$COND_WATER_ADJ" id="5_cond"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 1.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ab")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_buff_next_if_water_adjacent.tres" -Encoding UTF8

# Buff adjacent +2 if 5 distinct
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AB" id="2_ab"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_ADJ" id="4_sel"]
[ext_resource type="Resource" path="$COND_5DIST" id="5_cond"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 2.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ab")
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
condition = ExtResource("5_cond")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_buff_2_if_5_distinct.tres" -Encoding UTF8

# ========== MOVEMENT EFFECTS ==========
# Reader back 2
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=5 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AM" id="2_am"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Resource" path="$SEL_SELF" id="4_sel"]

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
base = 2.0

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 0
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("4_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_reader_back_2.tres" -Encoding UTF8

# Reader per adjacent
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AM" id="2_am"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Script" path="$VP" id="4_vp"]
[ext_resource type="Resource" path="$SEL_SELF" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 0
per_value = 1.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 0
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_reader_per_adjacent.tres" -Encoding UTF8

# Reader per remaining (move reader back 1 per remaining activation)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=6 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AM" id="2_am"]
[ext_resource type="Script" path="$VR" id="3_vr"]
[ext_resource type="Script" path="$VP" id="4_vp"]
[ext_resource type="Resource" path="$SEL_SELF" id="5_sel"]

[sub_resource type="Resource" id="Resource_vp001"]
script = ExtResource("4_vp")
source = 4
per_value = 1.0

[sub_resource type="Resource" id="Resource_vr001"]
script = ExtResource("3_vr")
per = [SubResource("Resource_vp001")]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 0
value = SubResource("Resource_vr001")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("5_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_reader_per_remaining.tres" -Encoding UTF8

# Tempo jump to previous air
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AM" id="2_am"]
[ext_resource type="Resource" path="$SEL_SELF" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 1
target_element = 3

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_tempo_jump_previous_air.tres" -Encoding UTF8

# Mundo jump to start on destroy (trigger=2)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AM" id="2_am"]
[ext_resource type="Resource" path="$SEL_SELF" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_am")
mode = 3

[resource]
script = ExtResource("1_ge")
trigger = 2
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_mundo_jump_on_destroy.tres" -Encoding UTF8

# ========== DESTRUCTION EFFECTS ==========
# Destroy adjacent
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AD" id="2_ad"]
[ext_resource type="Resource" path="$SEL_ADJ" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ad")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_destroy_adjacent.tres" -Encoding UTF8

# Destroy below
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AD" id="2_ad"]
[ext_resource type="Resource" path="$SEL_BELOW" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ad")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_destroy_below.tres" -Encoding UTF8

# Destroy previous
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AD" id="2_ad"]
[ext_resource type="Resource" path="$SEL_PREV" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ad")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_destroy_previous.tres" -Encoding UTF8

# ========== PETRIFY EFFECTS ==========
# Petrify adjacent
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AP" id="2_ap"]
[ext_resource type="Resource" path="$SEL_ADJ" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ap")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_petrify_adjacent.tres" -Encoding UTF8

# Petrify below
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AP" id="2_ap"]
[ext_resource type="Resource" path="$SEL_BELOW" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ap")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_petrify_below.tres" -Encoding UTF8

# ========== CREATION EFFECTS ==========
# Djinn spawn air (condition: last air)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AC" id="2_ac"]
[ext_resource type="Resource" path="$SEL_EMPTY_RND" id="3_sel"]
[ext_resource type="Resource" path="$COND_LAST_AIR" id="4_cond"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ac")
element = 3
activation_bonus = 1

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_djinn_spawn_air.tres" -Encoding UTF8

# Golem create earth (condition: corner)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=4 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AC" id="2_ac"]
[ext_resource type="Resource" path="$SEL_EMPTY_RND" id="3_sel"]
[ext_resource type="Resource" path="$COND_CORNER" id="4_cond"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ac")
element = 2

[resource]
script = ExtResource("1_ge")
condition = ExtResource("4_cond")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_golem_create_earth.tres" -Encoding UTF8

# Nymph spawn water (target: below)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AC" id="2_ac"]
[ext_resource type="Resource" path="$SEL_BELOW" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ac")
element = 1

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_nymph_spawn_water.tres" -Encoding UTF8

# ========== SPECIAL EFFECTS ==========
# Duplicate self to empty adjacent
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$ADS" id="2_ads"]
[ext_resource type="Resource" path="$SEL_EMPTY_ADJ" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_ads")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_nature_duplicate_self.tres" -Encoding UTF8

# Phoenix resurrect (trigger: ON_DESTROY=2)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AMR" id="2_amr"]
[ext_resource type="Resource" path="$SEL_SELF" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_amr")
permanent_score_bonus = 50

[resource]
script = ExtResource("1_ge")
trigger = 2
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_phoenix_resurrect.tres" -Encoding UTF8

# Trigger next (activate next rune)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$AT" id="2_at"]
[ext_resource type="Resource" path="$SEL_NEXT" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_at")

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_trigger_next_twice.tres" -Encoding UTF8

# Swap to empty adjacent (random)
@"
[gd_resource type="Resource" script_class="GameEffect" load_steps=3 format=3]

[ext_resource type="Script" path="$GE" id="1_ge"]
[ext_resource type="Script" path="$ASW" id="2_asw"]
[ext_resource type="Resource" path="$SEL_EMPTY_ADJ" id="3_sel"]

[sub_resource type="Resource" id="Resource_act01"]
script = ExtResource("2_asw")
swap_mode = 1

[resource]
script = ExtResource("1_ge")
selector = ExtResource("3_sel")
action = SubResource("Resource_act01")
"@ | Set-Content "$base\ge_swap_to_empty_adjacent.tres" -Encoding UTF8

$count = (Get-ChildItem "$base\ge_*.tres").Count
Write-Output "Generated $count GameEffect .tres files in $base"
