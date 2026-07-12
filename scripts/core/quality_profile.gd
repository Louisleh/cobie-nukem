class_name QualityProfile
extends Resource

@export var id := &"web"
@export var display_name := "WEB / IPAD"
@export_range(0.25, 1.0, 0.05) var render_scale := 1.0
@export_range(0, 2000, 10) var particle_budget := 500
@export_range(0, 256, 1) var decal_budget := 48
@export_range(0, 64, 1) var audio_voice_budget := 20
@export_range(5.0, 200.0, 1.0) var visibility_distance := 55.0
@export_range(0, 8, 1) var dynamic_light_budget := 2
@export_range(1, 8, 1) var maximum_attackers := 3
@export var distant_animation_hz := 12.0
@export var target_fps := 30
