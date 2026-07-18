class_name TimedHazardDefinition
extends Resource

enum TargetPolicy {
	PLAYER_ONLY,
	DAMAGEABLES,
}

enum AssistPolicy {
	UNCHANGED,
	REDUCED,
	DISABLED,
}

const MAX_DAMAGE_PER_TICK := 100.0
const MAX_HORIZONTAL_IMPULSE := 24.0
const MAX_VERTICAL_IMPULSE := 16.0

@export var id: StringName = &"timed_hazard"
@export var enabled := true
@export_range(0.0, 30.0, 0.01) var warning_seconds := 1.0
@export_range(0.01, 30.0, 0.01) var active_seconds := 2.0
@export_range(0.0, 30.0, 0.01) var recovery_seconds := 1.0
@export var repeat_cycle := true
@export_range(0.01, 5.0, 0.01) var tick_seconds := 0.25
@export_range(0.0, MAX_DAMAGE_PER_TICK, 0.5) var damage_per_tick := 8.0
@export var environment_impulse := Vector3.ZERO
@export_range(0.0, MAX_HORIZONTAL_IMPULSE, 0.5) var horizontal_impulse_cap := 14.0
@export_range(0.0, MAX_VERTICAL_IMPULSE, 0.5) var vertical_impulse_cap := 9.0
@export var target_policy := TargetPolicy.PLAYER_ONLY
@export var assist_policy := AssistPolicy.REDUCED
@export_range(0.0, 1.0, 0.05) var assisted_intensity := 0.5
@export var volume_size := Vector3(4.0, 2.0, 4.0)
@export_flags_3d_physics var collision_mask := 2


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("timed hazard id is empty")
	if active_seconds <= 0.0:
		errors.append("timed hazard %s requires active_seconds > 0" % id)
	if tick_seconds <= 0.0:
		errors.append("timed hazard %s requires tick_seconds > 0" % id)
	if warning_seconds < 0.0 or recovery_seconds < 0.0:
		errors.append("timed hazard %s phase durations cannot be negative" % id)
	if damage_per_tick < 0.0 or damage_per_tick > MAX_DAMAGE_PER_TICK:
		errors.append("timed hazard %s damage is outside the bounded range" % id)
	if horizontal_impulse_cap < 0.0 or horizontal_impulse_cap > MAX_HORIZONTAL_IMPULSE:
		errors.append("timed hazard %s horizontal impulse cap is invalid" % id)
	if vertical_impulse_cap < 0.0 or vertical_impulse_cap > MAX_VERTICAL_IMPULSE:
		errors.append("timed hazard %s vertical impulse cap is invalid" % id)
	if not _vector_is_finite(environment_impulse):
		errors.append("timed hazard %s impulse must be finite" % id)
	if volume_size.x <= 0.0 or volume_size.y <= 0.0 or volume_size.z <= 0.0:
		errors.append("timed hazard %s volume size must be positive" % id)
	if collision_mask <= 0:
		errors.append("timed hazard %s requires a collision mask" % id)
	if assist_policy == AssistPolicy.REDUCED and (assisted_intensity < 0.0 or assisted_intensity > 1.0):
		errors.append("timed hazard %s assisted intensity must be between zero and one" % id)
	if damage_per_tick <= 0.0 and environment_impulse.is_zero_approx():
		errors.append("timed hazard %s has no damage or impulse effect" % id)
	return errors


func intensity_for_assist(assist_enabled: bool) -> float:
	if not assist_enabled:
		return 1.0
	match assist_policy:
		AssistPolicy.DISABLED:
			return 0.0
		AssistPolicy.REDUCED:
			return clampf(assisted_intensity, 0.0, 1.0)
		_:
			return 1.0


func _vector_is_finite(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
