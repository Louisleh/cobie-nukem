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
	active[zone_id] = {"remaining": 0, "actors": [], "wave": 0, "target": target, "timer": null}
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
	var target: Node3D = active[definition.zone_id].target
	var actors: Array[Node] = []
	for spawn in wave.get("spawns", []):
		var actor: Node = spawn_callable.call(String(spawn.scene), spawn.position) if spawn_callable.is_valid() else null
		if actor == null:
			_fail(definition, "spawn returned null for %s" % String(spawn.get("scene", "<missing>")))
			return []
		if definition.completion_policy != EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET and not actor.has_signal("died"):
			actor.queue_free()
			_fail(definition, "spawned actor %s does not expose required died signal" % actor.name)
			return []
		actors.append(actor)
		active[definition.zone_id].actors.append(actor)
		active[definition.zone_id].remaining = int(active[definition.zone_id].remaining) + 1
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
		var timer := active[zone_id].get("timer") as Timer
		if is_instance_valid(timer): timer.queue_free()
		for actor in active[zone_id].get("actors", []):
			if is_instance_valid(actor): actor.queue_free()
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
	active[definition.zone_id].actors.erase(actor)
	active[definition.zone_id].remaining = maxi(0, int(active[definition.zone_id].remaining) - 1)
	if int(active[definition.zone_id].remaining) == 0: _advance_or_complete(definition)


func _advance_or_complete(definition: EncounterDefinition) -> void:
	var next_wave := int(active[definition.zone_id].wave) + 1
	var waves := definition.effective_waves()
	if next_wave >= waves.size():
		_complete(definition)
		return
	var delay := maxf(0.0, float(waves[next_wave].get("delay_seconds", 0.0)))
	if delay <= 0.0:
		_spawn_wave(definition, next_wave)
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	timer.timeout.connect(func() -> void:
		if active.has(definition.zone_id): _spawn_wave(definition, next_wave)
		if is_instance_valid(timer): timer.queue_free()
	)
	add_child(timer)
	active[definition.zone_id].timer = timer
	timer.start()


func _complete(definition: EncounterDefinition) -> void:
	active.erase(definition.zone_id)
	completed[definition.zone_id] = true
	encounter_completed.emit(definition)


func _fail(definition: EncounterDefinition, reason: String) -> void:
	if active.has(definition.zone_id):
		for actor in active[definition.zone_id].get("actors", []):
			if is_instance_valid(actor): actor.queue_free()
	active.erase(definition.zone_id)
	failed[definition.zone_id] = reason
	if log_failures: push_warning("Encounter %s failed: %s" % [definition.id, reason])
	encounter_failed.emit(definition, reason)
