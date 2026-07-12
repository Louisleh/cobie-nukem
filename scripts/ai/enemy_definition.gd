class_name EnemyDefinition
extends Resource

enum Archetype { MELEE, RANGED, SKIRMISHER, TANK, FLYING, SUPPORT, BOSS }

@export var id: StringName = &"enemy"
@export var display_name := "COMPLIANCE UNIT"
@export var archetype: Archetype = Archetype.MELEE
@export_multiline var warning_text := "VIOLATION DETECTED."
@export var max_health := 40.0
@export var move_speed := 3.0
@export var acceleration := 18.0
@export var detection_range := 22.0
@export var attack_range := 8.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.5
@export var telegraph_seconds := 0.45
@export var threat_weight := 0.5
@export_range(1, 20, 1) var threat_value := 1
@export var faction := &"animal_control"
@export_range(0.1, 4.0, 0.05) var navigation_radius := 0.45
@export var weak_point_multiplier := 1.0
@export var reaction_profile: DamageReactionProfile
@export var alert_sound := &"enemy_alert"
@export var attack_sound_set := &"enemy_attack"
@export var death_sound_set := &"enemy_death"
@export var allowed_encounter_tags: Array[StringName] = []
@export var score_value := 100
@export var drop_id: StringName = &""
@export_range(0.0, 20.0, 0.25) var preferred_distance := 0.0
@export_range(0.0, 20.0, 0.25) var retreat_distance := 0.0
