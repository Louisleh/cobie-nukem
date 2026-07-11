class_name EnemyDefinition
extends Resource

@export var id: StringName = &"enemy"
@export var display_name := "COMPLIANCE UNIT"
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
@export var score_value := 100
@export var drop_id: StringName = &""

