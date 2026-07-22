class_name EncounterRunner
extends Node

signal encounter_started(definition: EncounterDefinition)
signal actor_spawned(actor: Node, definition: EncounterDefinition)
signal actor_defeated(actor: Node, definition: EncounterDefinition)
signal encounter_completed(definition: EncounterDefinition)
signal encounter_failed(definition: EncounterDefinition, reason: String)
signal wave_started(definition: EncounterDefinition, wave_index: int)
signal wave_completed(definition: EncounterDefinition, wave_index: int)

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var failed: Dictionary = {}
var spawn_callable: Callable
var log_failures := true
var _zone_generation: Dictionary = {}


func configure(values: Array[EncounterDefinition], spawner: Callable) -> void:
	for zone_id: Variant in active.keys():
		_clear_active_zone(zone_id)
	definitions.clear()
	active.clear()
	completed.clear()
	failed.clear()
	_zone_generation.clear()
	spawn_callable = spawner
	for definition in values:
		definitions[definition.zone_id] = definition


func activate_zone(zone_id: StringName, target: Node3D = null) -> Array[Node]:
	if completed.has(zone_id) or not definitions.has(zone_id):
		return []
	var starting_wave := 0
	if active.has(zone_id):
		if bool(active[zone_id].get("suspended", false)):
			starting_wave = maxi(0, int(active[zone_id].get("wave", 0)))
			_clear_active_zone(zone_id)
			active.erase(zone_id)
		else:
			return []
	var definition: EncounterDefinition = definitions[zone_id]
	active[zone_id] = {
		"remaining": 0,
		"actors": [],
		"wave": starting_wave,
		"target": target,
		"timer": null,
		"boss_target": null,
		"generation": _next_zone_generation(zone_id),
		"pending_external_advance": false,
		"next_wave": -1,
		"choreography_context": {},
		"suspended": false,
	}
	encounter_started.emit(definition)
	return _spawn_wave(definition, starting_wave, int(active[zone_id].generation))


func _spawn_wave(definition: EncounterDefinition, wave_index: int, expected_generation: int = -1) -> Array[Node]:
	if not active.has(definition.zone_id):
		return []
	var state: Dictionary = active[definition.zone_id]
	if expected_generation >= 0 and int(state.get("generation", 0)) != expected_generation:
		return []
	var waves := definition.effective_waves()
	if wave_index >= waves.size():
		_complete(definition)
		return []
	state.wave = wave_index
	state.pending_external_advance = false
	state.next_wave = -1
	state.actors = []
	state.remaining = 0
	state.target = state.get("target")
	var wave: Dictionary = waves[wave_index]
	var actors: Array[Node] = []
	var wave_spawns: Array = wave.get("spawns", [])
	var target: Node3D = state.get("target")
	var choreography_context := {}
	if definition.schema_version >= 3 and definition.choreography_profile != null:
		choreography_context = definition.choreography_profile.context_for_wave(wave_index)
	else:
		choreography_context = {
			"encounter_role_id": &"",
			"encounter_approach_id": &"",
			"encounter_transition_id": &"",
			"encounter_recovery_position": Vector3.ZERO,
			"encounter_environment_choice_ids": [],
			"encounter_counterplay_ids": [],
			"encounter_counterplay_id": &"",
		}
	state.choreography_context = choreography_context
	wave_started.emit(definition, wave_index)
	for spawn_index in wave_spawns.size():
		var spawn: Dictionary = wave_spawns[spawn_index]
		var actor: Node = spawn_callable.call(String(spawn.scene), spawn.position) if spawn_callable.is_valid() else null
		if actor == null:
			_fail(definition, "spawn returned null for %s" % String(spawn.get("scene", "<missing>")))
			return []
		if definition.completion_policy != EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET and not actor.has_signal("died"):
			actor.queue_free()
			_fail(definition, "spawned actor %s does not expose required died signal" % actor.name)
			return []
		actors.append(actor)
		actor.set_meta(&"encounter_role_id", StringName(spawn.get("role_id", "")))
		actor.set_meta(&"encounter_approach_id", StringName(spawn.get("approach_id", "")))
		actor.set_meta(&"encounter_transition_id", StringName(choreography_context.get("encounter_transition_id", "")))
		actor.set_meta(&"encounter_recovery_position", choreography_context.get("encounter_recovery_position", Vector3.ZERO))
		actor.set_meta(&"encounter_environment_choice_ids", _normalize_environment_choice_ids(choreography_context.get("encounter_environment_choice_ids", [])))
		actor.set_meta(&"encounter_counterplay_ids", _normalize_environment_choice_ids(choreography_context.get("encounter_counterplay_ids", [])))
		actor.set_meta(&"encounter_counterplay_id", StringName(choreography_context.get("encounter_counterplay_id", "")))
		actor.set_meta(&"encounter_spawn_slot", "%s:%d:%d" % [definition.id, wave_index, spawn_index])
		state.actors.append(actor)
		state.remaining = int(state.remaining) + 1
		if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED and _is_boss_target_spawn(spawn):
			if is_instance_valid(state.boss_target):
				_fail(definition, "encounter %s has multiple runtime boss targets" % definition.id)
				return []
			state.boss_target = actor
		if target != null and actor.has_method("set_target"):
			actor.set_target(target)
		if actor.has_signal("died"):
			actor.died.connect(func(dead_actor: Node, _source: Node) -> void: _on_actor_died(dead_actor, definition), CONNECT_ONE_SHOT)
		actor_spawned.emit(actor, definition)
	if definition.completion_policy == EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET:
		wave_completed.emit(definition, wave_index)
		_complete(definition)
	return actors


func reset_zone(zone_id: StringName) -> bool:
	if not definitions.has(zone_id):
		return false
	if active.has(zone_id):
		_invalidate_zone_generation(zone_id)
		_clear_active_zone(zone_id)
	active.erase(zone_id)
	completed.erase(zone_id)
	failed.erase(zone_id)
	return true


func snapshot() -> Dictionary:
	var ids: Array[String] = []
	for zone_id: Variant in completed:
		ids.append(String(zone_id))
	ids.sort()
	var active_states: Dictionary = {}
	for zone_id: Variant in active:
		var state: Dictionary = active[zone_id]
		active_states[String(zone_id)] = {
			"wave": int(state.get("wave", 0)),
			"remaining": int(state.get("remaining", 0)),
			"next_wave": int(state.get("next_wave", -1)),
			"pending_external_advance": bool(state.get("pending_external_advance", false)),
		}
	return {"completed": ids, "active": active_states}


func restore(data: Dictionary) -> void:
	for zone_id: Variant in active.keys():
		_clear_active_zone(zone_id)
	active.clear()
	failed.clear()
	completed.clear()
	# Restore only deterministic markers here. Active wave state is retained for
	# snapshot compatibility and deterministic reload order, but encounter actors
	# remain intentionally not replayed; checkpoint restore rebuilds live actors.
	for raw_id: Variant in data.get("completed", []):
		var zone_id := StringName(raw_id)
		if definitions.has(zone_id):
			completed[zone_id] = true
	for zone_id: Variant in definitions.keys():
		_invalidate_zone_generation(zone_id)
	var active_payload: Variant = data.get("active", {})
	if active_payload is Dictionary:
		for raw_id: Variant in active_payload:
			var zone_id := StringName(raw_id)
			if not definitions.has(zone_id):
				continue
			if not (active_payload[raw_id] is Dictionary):
				continue
			var state: Dictionary = active_payload[raw_id]
			var definition := definitions[zone_id] as EncounterDefinition
			var waves := definition.effective_waves()
			if waves.is_empty():
				continue
			var wave := int(state.get("wave", 0))
			var next_wave := int(state.get("next_wave", wave + 1))
			active[zone_id] = {
				"generation": _next_zone_generation(zone_id),
				"remaining": 0,
				"actors": [],
				"choreography_context": {},
				"wave": clamp(wave, 0, waves.size() - 1),
				"target": null,
				"timer": null,
				"boss_target": null,
				"pending_external_advance": false,
				"next_wave": clamp(next_wave, 0, waves.size()),
				"suspended": true,
			}


func advance_external_wave(zone_id: StringName) -> bool:
	if not definitions.has(zone_id) or not active.has(zone_id):
		return false
	if bool(active[zone_id].get("suspended", false)):
		return false
	var definition: EncounterDefinition = definitions[zone_id]
	if definition.wave_progression != EncounterDefinition.WaveProgression.EXTERNAL:
		return false
	var state: Dictionary = active[zone_id]
	if not bool(state.get("pending_external_advance", false)):
		return false
	var waves := definition.effective_waves()
	var next_wave := int(state.get("next_wave", int(state.get("wave", 0)) + 1))
	if next_wave < 0 or next_wave >= waves.size():
		return false
	state.pending_external_advance = false
	state.next_wave = -1
	state.actors = []
	state.remaining = 0
	state.wave = next_wave
	var delay := maxf(0.0, float(waves[next_wave].get("delay_seconds", 0.0)))
	var generation := int(state.get("generation", 0))
	_clear_active_wave_spawn_timer(zone_id, generation)
	if delay <= 0.0:
		_spawn_wave(definition, next_wave, generation)
	else:
		_schedule_wave_spawn(definition, next_wave, delay, generation)
	return true


func _on_actor_died(actor: Node, definition: EncounterDefinition) -> void:
	actor_defeated.emit(actor, definition)
	if not active.has(definition.zone_id):
		return
	var state: Dictionary = active[definition.zone_id]
	state.actors.erase(actor)
	state.remaining = maxi(0, int(state.remaining) - 1)
	if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED and is_instance_valid(state.get("boss_target")) and state.boss_target == actor:
		wave_completed.emit(definition, int(state.get("wave", 0)))
		_complete(definition, true)
		return
	if int(state.remaining) == 0:
		wave_completed.emit(definition, int(state.get("wave", 0)))
		_advance_or_complete(definition)


func _advance_or_complete(definition: EncounterDefinition) -> void:
	if not active.has(definition.zone_id):
		return
	var next_wave := int(active[definition.zone_id].wave) + 1
	var waves := definition.effective_waves()
	if next_wave >= waves.size():
		if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED:
			_fail(definition, "boss encounter exhausted its waves without defeating the completion target")
			return
		_complete(definition)
		return
	if definition.wave_progression == EncounterDefinition.WaveProgression.EXTERNAL:
		active[definition.zone_id].pending_external_advance = true
		active[definition.zone_id].next_wave = next_wave
		return
	var delay := maxf(0.0, float(waves[next_wave].get("delay_seconds", 0.0)))
	var generation := int(active[definition.zone_id].get("generation", 0))
	if delay <= 0.0:
		_spawn_wave(definition, next_wave, generation)
		return
	_schedule_wave_spawn(definition, next_wave, delay, generation)


func _complete(definition: EncounterDefinition, clear_runner_actors: bool = false) -> void:
	if completed.has(definition.zone_id):
		return
	if clear_runner_actors:
		_clear_active_zone(definition.zone_id)
	if active.has(definition.zone_id):
		active.erase(definition.zone_id)
	completed[definition.zone_id] = true
	encounter_completed.emit(definition)


func _fail(definition: EncounterDefinition, reason: String) -> void:
	if active.has(definition.zone_id):
		_clear_active_zone(definition.zone_id)
	active.erase(definition.zone_id)
	failed[definition.zone_id] = reason
	if log_failures:
		push_warning("Encounter %s failed: %s" % [definition.id, reason])
	encounter_failed.emit(definition, reason)


func _is_boss_target_spawn(spawn: Dictionary) -> bool:
	if not spawn.has("completion_marker"):
		return false
	var marker: Variant = spawn.get("completion_marker", null)
	return (marker is String or marker is StringName) and StringName(marker) == EncounterDefinition.BOSS_COMPLETION_MARKER


func _clear_active_zone(zone_id: StringName) -> void:
	if not active.has(zone_id):
		return
	var state: Dictionary = active[zone_id]
	var timer := state.get("timer") as Timer
	if is_instance_valid(timer):
		timer.queue_free()
	for actor in state.get("actors", []):
		if is_instance_valid(actor):
			actor.queue_free()
	state.timer = null
	state.actors.clear()


func _schedule_wave_spawn(definition: EncounterDefinition, wave_index: int, delay: float, expected_generation: int) -> void:
	if not active.has(definition.zone_id):
		return
	var zone_id := definition.zone_id
	var state: Dictionary = active[zone_id]
	var timer := Timer.new()
	timer.name = "EncounterWaveTimer_%s" % zone_id
	timer.one_shot = true
	timer.wait_time = delay
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		if not active.has(zone_id):
			return
		if expected_generation != int(active[zone_id].get("generation", 0)):
			return
		_spawn_wave(definition, wave_index, expected_generation)
		_clear_active_wave_spawn_timer(zone_id, expected_generation)
	)
	add_child(timer)
	_clear_active_wave_spawn_timer(zone_id, expected_generation)
	state.timer = timer


func _clear_active_wave_spawn_timer(zone_id: StringName, expected_generation: int) -> void:
	if not active.has(zone_id):
		return
	var state: Dictionary = active[zone_id]
	if int(state.get("generation", 0)) != expected_generation:
		return
	var timer := state.get("timer") as Timer
	if is_instance_valid(timer):
		timer.queue_free()
	state.timer = null


func _next_zone_generation(zone_id: StringName) -> int:
	var value: int = int(_zone_generation.get(zone_id, 0))
	value += 1
	_zone_generation[zone_id] = value
	return value


func _invalidate_zone_generation(zone_id: StringName) -> void:
	_next_zone_generation(zone_id)


func _normalize_environment_choice_ids(value: Variant) -> Array[StringName]:
	var normalized: Array[StringName] = []
	if value is Array:
		for item in value:
			if item is StringName or item is String:
				var entry := StringName(item)
				if entry != &"":
					normalized.append(entry)
	return normalized
