class_name TowmasterPhaseCombatDefinition
extends Resource

@export var schema_version: int = 1
@export var phase_id: StringName = &""
@export var attack_ids: Array[StringName] = []
@export var arena_state_id: StringName = &""
@export var cooldown_scale: float = 1.0
@export var telegraph_scale: float = 1.0
@export var damage_scale: float = 1.0
@export var warning_color: Color = Color("f3ab4d")
@export var warning_energy: float = 1.0


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if schema_version != 1:
		errors.append("TowmasterPhaseCombatDefinition %s has unsupported schema_version %d" % [phase_id, schema_version])

	if phase_id == &"":
		errors.append("TowmasterPhaseCombatDefinition has empty phase_id")

	if attack_ids.is_empty():
		errors.append("TowmasterPhaseCombatDefinition %s has no attack_ids" % phase_id)

	var seen_attack_ids: Dictionary = {}
	for index in range(attack_ids.size()):
		var attack_id: StringName = attack_ids[index]
		if attack_id == &"":
			errors.append("TowmasterPhaseCombatDefinition %s has empty attack_ids[%d]" % [phase_id, index])
			continue
		var key: String = String(attack_id)
		if seen_attack_ids.has(key):
			errors.append("TowmasterPhaseCombatDefinition %s has duplicate attack_id %s" % [phase_id, attack_id])
		else:
			seen_attack_ids[key] = true

	if arena_state_id == &"":
		errors.append("TowmasterPhaseCombatDefinition %s has empty arena_state_id" % phase_id)

	if not is_finite(cooldown_scale) or cooldown_scale <= 0.0:
		errors.append("TowmasterPhaseCombatDefinition %s has invalid cooldown_scale" % phase_id)

	if not is_finite(telegraph_scale) or telegraph_scale <= 0.0:
		errors.append("TowmasterPhaseCombatDefinition %s has invalid telegraph_scale" % phase_id)

	if not is_finite(damage_scale) or damage_scale <= 0.0:
		errors.append("TowmasterPhaseCombatDefinition %s has invalid damage_scale" % phase_id)

	if not _is_finite_color(warning_color):
		errors.append("TowmasterPhaseCombatDefinition %s has invalid warning_color" % phase_id)

	if not is_finite(warning_energy) or warning_energy <= 0.0:
		errors.append("TowmasterPhaseCombatDefinition %s has invalid warning_energy" % phase_id)

	return errors


func _is_finite_color(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)
