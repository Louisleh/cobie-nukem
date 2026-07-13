class_name EnemyNavigator
extends Node

signal recovery_requested(reason: StringName, recovery_position: Vector3)

const TARGET_REFRESH_SECONDS := 0.25
const TARGET_MOVE_THRESHOLD_SQUARED := 0.64
const STUCK_SAMPLE_SECONDS := 0.35
const STUCK_DISTANCE_SQUARED := 0.0025
const REPATH_ATTEMPTS_BEFORE_RECOVERY := 3
const MAX_RECOVERY_DISTANCE := 3.0

var agent: NavigationAgent3D
var actor: CharacterBody3D
var enabled := false
var recovery_count := 0

var _target_refresh_remaining := 0.0
var _last_requested_target := Vector3.INF
var _sample_elapsed := 0.0
var _sample_origin := Vector3.ZERO
var _stuck_attempts := 0


func configure(owner: CharacterBody3D, navigation_radius: float, actor_height: float) -> void:
	actor = owner
	agent = NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.radius = maxf(navigation_radius, 0.1)
	agent.height = maxf(actor_height, 0.5)
	agent.path_desired_distance = maxf(navigation_radius * 0.6, 0.25)
	agent.target_desired_distance = maxf(navigation_radius, 0.45)
	agent.avoidance_enabled = false
	owner.add_child(agent)
	enabled = true
	_sample_origin = owner.global_position


func steering_destination(requested: Vector3, delta: float) -> Vector3:
	if not enabled or not is_instance_valid(agent) or not _navigation_ready():
		return requested
	_target_refresh_remaining -= delta
	if _target_refresh_remaining <= 0.0 or _last_requested_target == Vector3.INF or _last_requested_target.distance_squared_to(requested) >= TARGET_MOVE_THRESHOLD_SQUARED:
		agent.target_position = requested
		_last_requested_target = requested
		_target_refresh_remaining = TARGET_REFRESH_SECONDS
	if agent.is_navigation_finished():
		return requested
	var next_position := agent.get_next_path_position()
	return next_position if next_position.is_finite() else requested


func observe_motion(wants_motion: bool, delta: float) -> void:
	if not enabled or not is_instance_valid(actor) or not _navigation_ready():
		return
	_sample_elapsed += delta
	if _sample_elapsed < STUCK_SAMPLE_SECONDS:
		return
	var moved_squared := actor.global_position.distance_squared_to(_sample_origin)
	_sample_origin = actor.global_position
	_sample_elapsed = 0.0
	if not wants_motion or moved_squared > STUCK_DISTANCE_SQUARED:
		_stuck_attempts = 0
		return
	_stuck_attempts += 1
	# The first two failures force a fresh path. Only a persistent failure asks
	# the actor to perform a bounded recovery, keeping ordinary collision stalls
	# from turning into visible teleports.
	_target_refresh_remaining = 0.0
	if _stuck_attempts < REPATH_ATTEMPTS_BEFORE_RECOVERY:
		return
	_stuck_attempts = 0
	var closest := NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), actor.global_position)
	if not closest.is_finite() or actor.global_position.distance_to(closest) > MAX_RECOVERY_DISTANCE:
		recovery_requested.emit(&"path_unreachable", actor.global_position)
		return
	recovery_count += 1
	recovery_requested.emit(&"stuck_on_navigation", closest)


func reset_after_teleport() -> void:
	if not is_instance_valid(actor):
		return
	_sample_origin = actor.global_position
	_sample_elapsed = 0.0
	_stuck_attempts = 0
	_target_refresh_remaining = 0.0
	_last_requested_target = Vector3.INF


func _navigation_ready() -> bool:
	if agent.get_navigation_map() == RID():
		return false
	return NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0
