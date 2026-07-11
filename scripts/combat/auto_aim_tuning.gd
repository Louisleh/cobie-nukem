class_name AutoAimTuning
extends Resource

enum Mode { OFF, LIGHT, CLASSIC, HEAVY }

@export var mode: Mode = Mode.CLASSIC
@export_range(0.0, 60.0, 0.5) var horizontal_cone_degrees := 14.0
@export_range(0.0, 60.0, 0.5) var vertical_cone_degrees := 24.0
@export_range(0.0, 45.0, 0.25) var maximum_correction_degrees := 9.0
@export_range(0.0, 2.0, 0.05) var lock_persistence_seconds := 0.35
@export_range(0.0, 1.0, 0.01) var controller_multiplier := 1.0
@export_range(0.0, 2.0, 0.05) var reticle_weight := 1.0
@export_range(0.0, 2.0, 0.05) var distance_weight := 0.35
@export_range(0.0, 2.0, 0.05) var threat_weight := 0.2

func strength() -> float:
	match mode:
		Mode.LIGHT:
			return 0.35
		Mode.CLASSIC:
			return 0.7
		Mode.HEAVY:
			return 1.0
		_:
			return 0.0

