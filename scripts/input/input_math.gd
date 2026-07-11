class_name InputMath
extends RefCounted


static func normalize_calibrated_axis(
	value: float,
	minimum: float = -1.0,
	center: float = 0.0,
	maximum: float = 1.0
) -> float:
	var safe_minimum := minf(minimum, center - 0.0001)
	var safe_maximum := maxf(maximum, center + 0.0001)
	if value >= center:
		return clampf((value - center) / (safe_maximum - center), 0.0, 1.0)
	return clampf((value - center) / (center - safe_minimum), -1.0, 0.0)


static func apply_dead_zone(value: float, dead_zone: float) -> float:
	var safe_dead_zone := clampf(dead_zone, 0.0, 0.95)
	var magnitude := absf(value)
	if magnitude <= safe_dead_zone:
		return 0.0
	return signf(value) * ((magnitude - safe_dead_zone) / (1.0 - safe_dead_zone))


static func apply_response_curve(value: float, exponent: float) -> float:
	var safe_exponent := clampf(exponent, 0.1, 5.0)
	return signf(value) * pow(absf(value), safe_exponent)


static func process_axis(value: float, config: Dictionary) -> float:
	var calibrated := normalize_calibrated_axis(
		value,
		float(config.get("minimum", -1.0)),
		float(config.get("center", 0.0)),
		float(config.get("maximum", 1.0))
	)
	if bool(config.get("invert", false)):
		calibrated *= -1.0
	calibrated = apply_dead_zone(calibrated, float(config.get("dead_zone", 0.12)))
	calibrated = apply_response_curve(calibrated, float(config.get("curve", 1.0)))
	return clampf(calibrated * float(config.get("sensitivity", 1.0)), -1.0, 1.0)
