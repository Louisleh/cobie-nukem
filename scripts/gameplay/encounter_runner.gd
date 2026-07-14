class_name EncounterRunner
extends Node

signal encounter_started(definition: EncounterDefinition)
signal actor_spawned(actor: Node, definition: EncounterDefinition)
signal actor_defeated(actor: Node, definition: EncounterDefinition)
signal encounter_completed(definition: EncounterDefinition)
signal encounter_failed(definition: EncounterDefinition, reason: String)

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var failed: Dictionary = {}
var spawn_callable: Callable
var log_failures := true


func configure(values: Array[EncounterDefinition], spawner: Callable) -> void:
	definitions.clear()
	active.clear()
	completed.clear()
	failed.clear()
	spawn_callable = spawner
	for definition in values: definitions[definition.zone_id] = definition


func activate_zone(zone_id: StringName, target: Node3D = null) -> Array[Node]:
	if active.has(zone_id) or completed.has(zone_id) or not definitions.has(zone_id): return []
	var definition: EncounterDefinition = definitions[zone_id]
	active[zone_id] = {"remaining": 0, "actors": [], "wave": 0, "target": target, "timer": null, "boss_target": null}
	encounter_started.emit(definition)
	return _spawn_wave(definition, 0)


func _spawn_wave(definition: EncounterDefinition, wave_index: int) -> Array[Node]:
	if not active.has(definition.zone_id): return []
	var waves := definition.effective_waves()
	if wave_index >= waves.size():
		_complete(definition)
		return []
	active[definition.zone_id].wave = wave_index
	var wave: Dictionary = waves[wave_index]
	var state: Dictionary = active[definition.zone_id]
	var target: Node3D = state.target
	var actors: Array[Node] = []
	var wave_spawns: Array = wave.get("spawns", [])
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
		actor.set_meta(&"encounter_spawn_slot", "%s:%d:%d" % [definition.id, wave_index, spawn_index])
		state.actors.append(actor)
		state.remaining = int(state.remaining) + 1
		if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED and _is_boss_target_spawn(spawn):
			if is_instance_valid(state.boss_target):
				_fail(definition, "encounter %s has multiple runtime boss targets" % definition.id)
				return []
			state.boss_target = actor
		if target != null and actor.has_method("set_target"): actor.set_target(target)
		if actor.has_signal("died"):
			actor.died.connect(func(dead_actor: Node, _source: Node) -> void: _on_actor_died(dead_actor, definition), CONNECT_ONE_SHOT)
		actor_spawned.emit(actor, definition)
	if definition.completion_policy == EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET:
		_complete(definition)
	return actors


func reset_zone(zone_id: StringName) -> bool:
	if not definitions.has(zone_id): return false
	if active.has(zone_id):
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
	return {"completed": ids}


func restore(data: Dictionary) -> void:
	# Active encounters are never persisted: checkpoint restore rebuilds actors
	# from definitions and only suppresses encounters already completed.
	for state: Variant in active.values():
		for actor: Variant in state.get("actors", []):
			if is_instance_valid(actor): actor.queue_free()
	active.clear()
	failed.clear()
	completed.clear()
	for raw_id: Variant in data.get("completed", []):
		var zone_id := StringName(raw_id)
		if definitions.has(zone_id): completed[zone_id] = true


func _on_actor_died(actor: Node, definition: EncounterDefinition) -> void:
	actor_defeated.emit(actor, definition)
	if not active.has(definition.zone_id): return
	var state: Dictionary = active[definition.zone_id]
	state.actors.erase(actor)
	state.remaining = maxi(0, int(state.remaining) - 1)
	if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED and is_instance_valid(state.get("boss_target")) and state.boss_target == actor:
		_complete(definition, true)
		return
	if int(state.remaining) == 0:
		_advance_or_complete(definition)


func _advance_or_complete(definition: EncounterDefinition) -> void:
	if not active.has(definition.zone_id): return
	var next_wave := int(active[definition.zone_id].wave) + 1
	var waves := definition.effective_waves()
	if next_wave >= waves.size():
		if definition.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED:
			_fail(definition, "boss encounter exhausted its waves without defeating the completion target")
			return
		_complete(definition)
		return
	var delay := maxf(0.0, float(waves[next_wave].get("delay_seconds", 0.0)))
	if delay <= 0.0:
		_spawn_wave(definition, next_wave)
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		if active.has(definition.zone_id):
			_spawn_wave(definition, next_wave)
			active.get(definition.zone_id, {}).erase("timer")
		if is_instance_valid(timer): timer.queue_free()
	)
	add_child(timer)
	active[definition.zone_id].timer = timer


func _complete(definition: EncounterDefinition, clear_runner_actors: bool = false) -> void:
	if completed.has(definition.zone_id): return
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
	if log_failures: push_warning("Encounter %s failed: %s" % [definition.id, reason])
	encounter_failed.emit(definition, reason)


func _is_boss_target_spawn(spawn: Dictionary) -> bool:
	if not spawn.has("completion_marker"):
		return false
	var marker: Variant = spawn.get("completion_marker", null)
	return (marker is String or marker is StringName) and StringName(marker) == EncounterDefinition.BOSS_COMPLETION_MARKER


func _clear_active_zone(zone_id: StringName) -> void:
	if not active.has(zone_id): return
	var state: Dictionary = active[zone_id]
	var timer := state.get("timer") as Timer
	if is_instance_valid(timer):
		timer.queue_free()
	for actor in state.get("actors", []):
		if is_instance_valid(actor): actor.queue_free()
