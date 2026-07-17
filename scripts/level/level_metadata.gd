class_name LevelMetadata
extends Resource

@export var level_id: StringName = &"episode_1_level_1"
@export var title := "NO DOGS ALLOWED"
@export var subtitle := "The Salmon Creek Incident"
@export var target_minutes_min := 12
@export var target_minutes_max := 20
@export var total_secrets := 3
@export var opening_objective := "RECOVER THE GOLDEN TENNIS BALL"
@export_file("*.tscn") var replay_scene := "res://scenes/levels/episode_1_level_1.tscn"
@export var next_mission_id: StringName = &""
@export_file("*.tscn") var next_mission_scene := ""
@export var next_mission_title := ""
@export_file("*.tres") var loadout_reference := ""
@export var zones: Array[Dictionary] = []

func has_next_mission() -> bool:
	return next_mission_id != &"" and not next_mission_scene.is_empty()
