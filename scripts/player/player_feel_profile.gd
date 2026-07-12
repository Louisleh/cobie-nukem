class_name PlayerFeelProfile
extends Resource

@export_category("Locomotion")
@export var walk_speed := 6.0
@export var run_speed := 9.0
@export var ground_acceleration := 38.0
@export var ground_deceleration := 44.0
@export var air_acceleration := 8.0
@export var jump_velocity := 5.2
@export_range(0.0, 0.25, 0.01) var coyote_seconds := 0.10
@export var floor_snap := 0.35
@export var constant_slope_speed := true

@export_category("Camera")
@export var mouse_sensitivity := 0.0022
@export var touch_sensitivity_scale := 1.35
@export var max_look_degrees := 86.0
@export var head_bob_amount := 0.035
@export var head_bob_speed := 10.5
@export_range(0.0, 1.0, 0.05) var landing_response := 0.35
@export_range(0.0, 1.0, 0.05) var damage_response := 0.45
