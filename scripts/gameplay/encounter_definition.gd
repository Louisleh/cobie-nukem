class_name EncounterDefinition
extends Resource

enum CompletionPolicy { ALL_DEFEATED, BOSS_DEFEATED, FIRE_AND_FORGET }
const BOSS_COMPLETION_MARKER := &"boss"

@export var id: StringName = &"encounter"
@export var zone_id: StringName = &"zone"
@export var display_name := "ENCOUNTER"
@export var completion_policy: CompletionPolicy = CompletionPolicy.ALL_DEFEATED
@export_range(0.0, 30.0, 0.1) var activation_delay := 0.0
@export_range(0.0, 30.0, 0.1) var opening_grace_seconds := 0.0
@export var spawns: Array[Dictionary] = [] # v1 compatibility
@export var schema_version := 2
@export var waves: Array[Dictionary] = []
@export_range(1, 100, 1) var enemy_budget := 12
@export_range(1, 8, 1) var maximum_simultaneous_attackers := 3
@export var spawn_tags: Array[StringName] = []
@export var entry_lock_id: StringName = &""
@export var exit_lock_id: StringName = &""
@export var recovery_policy: StringName = &"restart_wave"
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
	var all_waves: Array[Dictionary] = effective_waves()
	if all_waves.is_empty(): errors.append("encounter %s has no waves or spawns" % id)
	var completion_marker_count := 0
	var authored_count := 0
	for wave_index in all_waves.size():
		var wave: Dictionary = all_waves[wave_index]
		var wave_spawns: Variant = wave.get("spawns", [])
		if wave_spawns is not Array or wave_spawns.is_empty():
			errors.append("encounter %s wave %d has no spawns" % [id, wave_index])
			continue
		for index in wave_spawns.size():
			authored_count += 1
			errors.append_array(_validate_spawn(wave_spawns[index], wave_index, index))
			var marker: Variant = (wave_spawns[index] as Dictionary).get("completion_marker", null)
			if marker != null:
				if marker is String or marker is StringName:
					if StringName(marker) == BOSS_COMPLETION_MARKER:
						completion_marker_count += 1
					else:
						errors.append("encounter %s wave %d spawn %d has invalid completion marker: %s" % [id, wave_index, index, String(marker)])
				else:
					errors.append("encounter %s wave %d spawn %d has invalid completion marker type: %s" % [id, wave_index, index, typeof(marker)])
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
