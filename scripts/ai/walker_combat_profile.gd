class_name WalkerCombatProfile
extends Resource

@export var phase_ids: Array[StringName] = []
@export var phase_transition_fractions: Array[float] = []
@export var phase_attack_kinds: Array[StringName] = []
@export var phase_attack_ranges: Array[float] = []
@export var phase_attack_cooldowns: Array[float] = []
@export var phase_telegraph_seconds: Array[float] = []
@export var phase_projectile_speeds: Array[float] = []
@export var phase_charge_speed_multipliers: Array[float] = []
@export var phase_damage_multipliers: Array[float] = []
@export var phase_weak_point_multipliers: Array[float] = []
@export var summon_scene: PackedScene
@export var summon_attack_interval := 3
@export_range(1, 24, 1) var max_live_summons := 3
@export_range(0.01, 2.0, 0.01) var followup_bolt_delay := 0.15


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if phase_ids.is_empty():
		errors.append("Walker combat profile must define phase IDs")
		return errors
	var expected := phase_ids.size()
	if expected < 2:
		errors.append("Walker phase profile must include at least one combat phase and DEFEATED")
	# Health thresholds exist for the three authored phase transitions. The final
	# vulnerability phase then runs continuously to zero health.
	if expected - 2 != phase_transition_fractions.size():
		errors.append("Transition fractions must cover authored combat transitions but exclude zero-health defeat")
	for idx in expected:
		if phase_attack_ranges.size() <= idx:
			errors.append("Walker phase %d missing attack range" % idx)
		if phase_attack_cooldowns.size() <= idx:
			errors.append("Walker phase %d missing attack cooldown" % idx)
		if phase_telegraph_seconds.size() <= idx:
			errors.append("Walker phase %d missing telegraph seconds" % idx)
		if phase_projectile_speeds.size() <= idx:
			errors.append("Walker phase %d missing projectile speed" % idx)
		if phase_charge_speed_multipliers.size() <= idx:
			errors.append("Walker phase %d missing charge speed multiplier" % idx)
		if phase_damage_multipliers.size() <= idx:
			errors.append("Walker phase %d missing phase damage multiplier" % idx)
		if phase_weak_point_multipliers.size() <= idx:
			errors.append("Walker phase %d missing weak-point multiplier" % idx)
		if phase_attack_kinds.size() <= idx:
			errors.append("Walker phase %d missing attack kind" % idx)
	if summon_attack_interval <= 0:
		errors.append("summon_attack_interval must be positive")
	if max_live_summons < 1:
		errors.append("max_live_summons must be at least 1")
	for i in phase_transition_fractions.size():
		var value := phase_transition_fractions[i]
		if value <= 0.0 or value >= 1.0:
			errors.append("Walker transition %d must be between 0 and 1 (exclusive), got %.3f" % [i, value])
		if i > 0 and not phase_transition_fractions[i] < phase_transition_fractions[i - 1]:
			errors.append("Walker transitions must be strictly descending, but transition %d is %.3f" % [i, value])
	for i in range(phase_attack_ranges.size()):
		if phase_attack_ranges[i] <= 0.0:
			errors.append("Walker phase %d attack range must be positive" % i)
	for i in range(phase_attack_cooldowns.size()):
		if i < expected - 1 and phase_attack_cooldowns[i] <= 0.0:
			errors.append("Walker combat phase %d attack cooldown must be positive" % i)
	for i in range(phase_telegraph_seconds.size()):
		if i < expected - 1 and phase_telegraph_seconds[i] <= 0.0:
			errors.append("Walker combat phase %d telegraph seconds must be positive" % i)
	for i in range(phase_projectile_speeds.size()):
		if i <= expected - 1 and phase_projectile_speeds[i] < 0.0:
			errors.append("Walker combat phase %d projectile speed must be non-negative" % i)
	for i in range(phase_charge_speed_multipliers.size()):
		if phase_charge_speed_multipliers[i] <= 0.0:
			errors.append("Walker combat phase %d charge speed multiplier must be positive" % i)
	for i in range(phase_damage_multipliers.size()):
		if phase_damage_multipliers[i] <= 0.0:
			errors.append("Walker phase %d damage multiplier must be positive" % i)
	return errors


func _phased_float(values: Array[float], phase: int, fallback: float) -> float:
	return fallback if phase < 0 or phase >= values.size() else values[phase]


func _phased_string(values: Array[StringName], phase: int, fallback: StringName) -> StringName:
	return fallback if phase < 0 or phase >= values.size() else values[phase]


func phase_transition_fraction(phase: int) -> float:
	return _phased_float(phase_transition_fractions, phase, 0.0)


func phase_attack_kind(phase: int) -> StringName:
	return _phased_string(phase_attack_kinds, phase, &"attack")


func phase_attack_range(phase: int) -> float:
	return _phased_float(phase_attack_ranges, phase, 0.0)


func phase_attack_cooldown(phase: int) -> float:
	return _phased_float(phase_attack_cooldowns, phase, 1.0)


func phase_telegraph_seconds_for_phase(phase: int) -> float:
	return _phased_float(phase_telegraph_seconds, phase, 0.0)


func phase_projectile_speed(phase: int) -> float:
	return _phased_float(phase_projectile_speeds, phase, 0.0)


func phase_charge_speed_multiplier(phase: int) -> float:
	return _phased_float(phase_charge_speed_multipliers, phase, 1.0)


func phase_damage_multiplier(phase: int) -> float:
	return _phased_float(phase_damage_multipliers, phase, 1.0)


func phase_weak_point_multiplier(phase: int) -> float:
	return _phased_float(phase_weak_point_multipliers, phase, 1.0)
