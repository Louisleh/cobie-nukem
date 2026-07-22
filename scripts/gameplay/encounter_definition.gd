class_name EncounterDefinition
extends Resource

enum CompletionPolicy { ALL_DEFEATED, BOSS_DEFEATED, FIRE_AND_FORGET }
enum WaveProgression { AUTO, EXTERNAL }
const BOSS_COMPLETION_MARKER := &"boss"

@export var id: StringName = &"encounter"
@export var zone_id: StringName = &"zone"
@export var display_name := "ENCOUNTER"
@export var completion_policy: CompletionPolicy = CompletionPolicy.ALL_DEFEATED
@export_range(0.0, 30.0, 0.1) var activation_delay := 0.0
@export_range(0.0, 30.0, 0.1) var opening_grace_seconds := 0.0
@export var spawns: Array[Dictionary] = [] # v1 compatibility
@export var schema_version := 2
@export var choreography_profile: EncounterChoreographyProfile
@export var waves: Array[Dictionary] = []
@export_range(1, 100, 1) var enemy_budget := 12
@export_range(1, 8, 1) var maximum_simultaneous_attackers := 3
@export var spawn_tags: Array[StringName] = []
@export var entry_lock_id: StringName = &""
@export var exit_lock_id: StringName = &""
@export var recovery_policy: StringName = &"restart_wave"
@export var wave_progression: WaveProgression = WaveProgression.AUTO
@export_range(0.0, 1.0, 0.05) var music_intensity := 0.5
@export var reward_policy: StringName = &"authored"


func effective_waves() -> Array[Dictionary]:
	if not waves.is_empty(): return waves
	var result: Array[Dictionary] = []
	if not spawns.is_empty(): result.append({"delay_seconds": activation_delay, "spawns": spawns})
	return result


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("encounter id is empty")
	if zone_id == &"": errors.append("encounter %s has no zone_id" % id)
	if wave_progression < WaveProgression.AUTO or wave_progression > WaveProgression.EXTERNAL:
		errors.append("encounter %s has invalid wave progression" % id)
	var all_waves: Array[Dictionary] = effective_waves()
	if all_waves.is_empty(): errors.append("encounter %s has no waves or spawns" % id)
	var requires_choreography := schema_version >= 3
	var completion_marker_count := 0
	var authored_count := 0
	var used_roles := {}
	var used_approaches := {}
	for wave_index: int in all_waves.size():
		var wave: Dictionary = all_waves[wave_index]
		var wave_spawns_value: Variant = wave.get("spawns", [])
		if wave_spawns_value is not Array:
			errors.append("encounter %s wave %d has no spawns" % [id, wave_index])
			continue
		var wave_spawns: Array = wave_spawns_value
		if wave_spawns.is_empty():
			errors.append("encounter %s wave %d has no spawns" % [id, wave_index])
			continue
		for index in wave_spawns.size():
			authored_count += 1
			var spawn_value: Variant = wave_spawns[index]
			if not (spawn_value is Dictionary):
				errors.append("encounter %s wave %d spawn %d is not a Dictionary" % [id, wave_index, index])
				continue
			var spawn: Dictionary = spawn_value
			errors.append_array(_validate_spawn(spawn, wave_index, index))
			if requires_choreography:
				errors.append_array(_validate_choreography_spawn(spawn, wave_index, index, used_roles, used_approaches))
			var marker: Variant = spawn.get("completion_marker", null)
			if marker != null:
				if marker is String or marker is StringName:
					if StringName(marker) == BOSS_COMPLETION_MARKER:
						completion_marker_count += 1
					else:
						errors.append("encounter %s wave %d spawn %d has invalid completion marker: %s" % [id, wave_index, index, String(marker)])
				else:
					errors.append("encounter %s wave %d spawn %d has invalid completion marker type: %s" % [id, wave_index, index, typeof(marker)])
	if requires_choreography:
		if choreography_profile == null:
			errors.append("encounter %s requires choreography_profile for schema_version >= 3" % id)
		else:
			errors.append_array(choreography_profile.validate(int(all_waves.size())))
			var declared_roles := _unique_nonempty_ids(choreography_profile.role_ids)
			for role_id: Variant in declared_roles:
				if not used_roles.has(role_id):
					errors.append("encounter %s wave spawns do not use declared role_id %s" % [id, role_id])
			var declared_approaches := _unique_nonempty_ids(choreography_profile.approach_ids)
			for approach_id: Variant in declared_approaches:
				if not used_approaches.has(approach_id):
					errors.append("encounter %s wave spawns do not use declared approach_id %s" % [id, approach_id])
	if completion_policy == CompletionPolicy.BOSS_DEFEATED:
		if completion_marker_count == 0:
			errors.append("encounter %s with BOSS_DEFEATED must specify exactly one completion_marker=%s" % [id, BOSS_COMPLETION_MARKER])
		elif completion_marker_count > 1:
			errors.append("encounter %s with BOSS_DEFEATED has more than one completion_marker=%s" % [id, BOSS_COMPLETION_MARKER])
	elif completion_marker_count > 0:
		errors.append("encounter %s has a completion_marker but policy is %s" % [id, CompletionPolicy.keys()[completion_policy]])
	if authored_count > enemy_budget:
		errors.append("encounter %s authors %d enemies above budget %d" % [id, authored_count, enemy_budget])
	return errors


func _validate_choreography_spawn(spawn: Dictionary, wave_index: int, index: int, used_roles: Dictionary, used_approaches: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if choreography_profile == null:
		return errors

	var role_value: Variant = spawn.get("role_id", null)
	if not (role_value is String or role_value is StringName):
		errors.append("encounter %s wave %d spawn %d missing or invalid role_id" % [id, wave_index, index])
	else:
		var role_id := StringName(role_value)
		if role_id == &"":
			errors.append("encounter %s wave %d spawn %d has empty role_id" % [id, wave_index, index])
		else:
			used_roles[role_id] = true
			if not choreography_profile.role_ids.has(role_id):
				errors.append("encounter %s wave %d spawn %d uses undeclared role_id %s" % [id, wave_index, index, role_id])

	var approach_value: Variant = spawn.get("approach_id", null)
	if not (approach_value is String or approach_value is StringName):
		errors.append("encounter %s wave %d spawn %d missing or invalid approach_id" % [id, wave_index, index])
	else:
		var approach_id := StringName(approach_value)
		if approach_id == &"":
			errors.append("encounter %s wave %d spawn %d has empty approach_id" % [id, wave_index, index])
		else:
			used_approaches[approach_id] = true
			if not choreography_profile.approach_ids.has(approach_id):
				errors.append("encounter %s wave %d spawn %d uses undeclared approach_id %s" % [id, wave_index, index, approach_id])
	return errors


func _unique_nonempty_ids(values: Array[StringName]) -> Dictionary:
	var normalized: Dictionary = {}
	for value in values:
		if value == &"":
			continue
		normalized[value] = true
	return normalized


func _validate_spawn(spawn: Dictionary, wave_index: int, index: int) -> PackedStringArray:
	var errors := PackedStringArray()
	var path := String(spawn.get("scene", ""))
	if path.is_empty(): errors.append("encounter %s wave %d spawn %d has no scene" % [id, wave_index, index])
	elif not ResourceLoader.exists(path): errors.append("encounter %s wave %d spawn %d scene missing: %s" % [id, wave_index, index, path])
	else:
		var packed := load(path) as PackedScene
		if packed == null:
			errors.append("encounter %s wave %d spawn %d is not a PackedScene: %s" % [id, wave_index, index, path])
		else:
			var instance := packed.instantiate()
			if not instance.has_method("set_target") or not instance.has_signal("died"):
				errors.append("encounter %s wave %d spawn %d lacks enemy contract set_target+died: %s" % [id, wave_index, index, path])
			instance.free()
	var position: Variant = spawn.get("position")
	if not position is Vector3 or not position.is_finite():
		errors.append("encounter %s wave %d spawn %d has invalid finite Vector3 position" % [id, wave_index, index])
	return errors
