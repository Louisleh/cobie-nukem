class_name EnemyNavigationRecovery
extends RefCounted

enum Result { IGNORED, RECOVERED, DEFEAT }
const MAX_TERMINAL_RECOVERY_DISTANCE := 8.0

static func resolve(actor: CharacterBody3D, navigator: EnemyNavigator, reason: StringName, recovery_position: Vector3) -> Result:
	if reason != &"stuck_on_navigation" and reason != &"path_unreachable":
		return Result.IGNORED
	if reason == &"path_unreachable" and (not recovery_position.is_finite() or actor.global_position.distance_to(recovery_position) > MAX_TERMINAL_RECOVERY_DISTANCE):
		return Result.DEFEAT
	actor.global_position = recovery_position + Vector3.UP * 0.05
	actor.velocity = Vector3.ZERO
	actor.reset_physics_interpolation()
	if navigator != null:
		navigator.reset_after_teleport()
	return Result.RECOVERED
