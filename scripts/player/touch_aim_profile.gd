class_name TouchAimProfile
extends Resource

@export var id: StringName = &"balanced"
@export var display_name := "BALANCED"
@export_range(0.0, 0.3, 0.01) var dead_zone := 0.09
@export_range(0.5, 3.0, 0.05) var response_exponent := 1.55
@export_range(0.0, 0.15, 0.005) var smoothing_seconds := 0.04
@export_range(60.0, 420.0, 5.0) var yaw_degrees_per_second := 210.0
@export_range(45.0, 300.0, 5.0) var pitch_degrees_per_second := 150.0
@export_range(0.5, 1.0, 0.01) var boost_threshold := 0.82
@export_range(0.0, 0.5, 0.01) var boost_delay := 0.12
@export_range(1.0, 2.5, 0.05) var boost_multiplier := 1.45


func shape(raw: Vector2) -> Vector2:
	var magnitude := raw.length()
	if magnitude <= dead_zone:
		return Vector2.ZERO
	var normalized := clampf((magnitude - dead_zone) / maxf(1.0 - dead_zone, 0.001), 0.0, 1.0)
	return raw.normalized() * pow(normalized, response_exponent)


func smoothing_weight(delta: float) -> float:
	if smoothing_seconds <= 0.0:
		return 1.0
	return 1.0 - exp(-delta / smoothing_seconds)

static func friction_strength(value: String) -> float:
	return {"off": 0.0, "light": 0.16, "standard": 0.3, "strong": 0.45}.get(value.to_lower(), 0.3)
