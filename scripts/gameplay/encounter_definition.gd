class_name EncounterDefinition
extends Resource

enum CompletionPolicy { ALL_DEFEATED, BOSS_DEFEATED, FIRE_AND_FORGET }

@export var id: StringName = &"encounter"
@export var zone_id: StringName = &"zone"
@export var display_name := "ENCOUNTER"
@export var completion_policy: CompletionPolicy = CompletionPolicy.ALL_DEFEATED
@export_range(0.0, 30.0, 0.1) var activation_delay := 0.0
@export_range(0.0, 30.0, 0.1) var opening_grace_seconds := 0.0
@export var spawns: Array[Dictionary] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("encounter id is empty")
	if zone_id == &"": errors.append("encounter %s has no zone_id" % id)
	if spawns.is_empty(): errors.append("encounter %s has no spawns" % id)
	for index in spawns.size():
		var spawn: Dictionary = spawns[index]
		var path := String(spawn.get("scene", ""))
		if path.is_empty(): errors.append("encounter %s spawn %d has no scene" % [id, index])
		elif not ResourceLoader.exists(path): errors.append("encounter %s spawn %d scene missing: %s" % [id, index, path])
		var position = spawn.get("position")
		if not position is Vector3: errors.append("encounter %s spawn %d has invalid position" % [id, index])
	return errors
