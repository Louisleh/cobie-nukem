extends SceneTree

class SoakEnemy extends Node3D:
	signal died(enemy: Node, source: Node)

	func set_target(_value: Node3D) -> void:
		pass


const MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres")
const PRE_BOSS_ROUTE: Array[StringName] = [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
]
const EXPECTED_ROLE_BY_SCENE := {
	"res://scenes/enemies/squirrel_trooper.tscn": &"skirmisher",
	"res://scenes/enemies/leash_enforcement_drone.tscn": &"aerial_harrier",
	"res://scenes/enemies/compliance_gull.tscn": &"dive_support",
	"res://scenes/enemies/umbrella_shield_enforcer.tscn": &"shield_anchor",
	"res://scenes/enemies/compliance_hound.tscn": &"melee_pursuer",
	"res://scenes/enemies/mutant_groundskeeper.tscn": &"space_denial",
}
const EXPECTED_ATTACKER_CAPS := {
	&"downtown_alley": 4,
	&"ruse_block": 4,
	&"waterfront_seawall": 4,
	&"terminal_service": 4,
	&"harbour_pier": 3,
}

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_authored_contract()
	_run_route_reset_cycles(100)
	await _check_delayed_reinforcement_reset()
	if failures.is_empty():
		print("RAIN CITY ENCOUNTER CHOREOGRAPHY TEST: PASS (5 profiles, 6 roles, 26 actors, 100 pre-boss route/reset cycles)")
		quit(0)
	else:
		for failure in failures:
			push_error("RAIN CITY ENCOUNTER CHOREOGRAPHY: " + failure)
		quit(1)


func _check_authored_contract() -> void:
	var mission_roles: Dictionary = {}
	var mission_actor_count := 0
	var pre_boss_actor_count := 0
	for definition in MANIFEST.encounters:
		_expect(definition.schema_version == 3, "%s uses schema version 3" % definition.zone_id)
		_expect(definition.validate().is_empty(), "%s definition validates" % definition.zone_id)
		_expect(definition.choreography_profile != null, "%s has a choreography profile" % definition.zone_id)
		if definition.choreography_profile == null:
			continue
		var profile := definition.choreography_profile
		_expect(profile.role_ids.size() >= 3, "%s declares at least three roles" % definition.zone_id)
		_expect(profile.approach_ids.size() >= 2, "%s declares at least two approaches" % definition.zone_id)
		_expect(not profile.environment_choice_ids.is_empty(), "%s declares an environment choice" % definition.zone_id)
		_expect(not profile.counterplay_ids.is_empty(), "%s declares counterplay" % definition.zone_id)
		_expect(profile.wave_transition_ids.size() == definition.effective_waves().size(), "%s declares one transition per wave" % definition.zone_id)
		_expect(int(EXPECTED_ATTACKER_CAPS.get(definition.zone_id, -1)) == definition.maximum_simultaneous_attackers, "%s preserves its attacker cap" % definition.zone_id)
		var route_zone := MANIFEST.route_definition.zone_for_id(definition.zone_id)
		_expect(route_zone != null, "%s has an authored route zone" % definition.zone_id)
		if route_zone != null:
			_expect(route_zone.bounds.has_point(profile.recovery_position), "%s recovery position remains inside route bounds" % definition.zone_id)
		var used_roles: Dictionary = {}
		var used_approaches: Dictionary = {}
		for wave_index in range(definition.effective_waves().size()):
			var wave: Dictionary = definition.effective_waves()[wave_index]
			var transition_id := profile.wave_transition_ids[wave_index]
			_expect(transition_id != &"", "%s wave %d has a transition id" % [definition.zone_id, wave_index])
			for spawn_value in wave.get("spawns", []):
				var spawn := spawn_value as Dictionary
				var scene_path := String(spawn.get("scene", ""))
				var role_id := StringName(spawn.get("role_id", &""))
				var approach_id := StringName(spawn.get("approach_id", &""))
				mission_actor_count += 1
				if definition.zone_id in PRE_BOSS_ROUTE:
					pre_boss_actor_count += 1
				mission_roles[role_id] = true
				used_roles[role_id] = true
				used_approaches[approach_id] = true
				_expect(EXPECTED_ROLE_BY_SCENE.has(scene_path), "%s uses a known Rain City enemy scene" % definition.zone_id)
				if EXPECTED_ROLE_BY_SCENE.has(scene_path):
					_expect(EXPECTED_ROLE_BY_SCENE[scene_path] == role_id, "%s maps %s to its real combat role" % [definition.zone_id, scene_path])
		_expect(used_roles.size() >= 3, "%s runs at least three distinct roles" % definition.zone_id)
		_expect(used_approaches.size() >= 2, "%s runs at least two approach directions" % definition.zone_id)
	_expect(mission_roles.size() == 6, "Rain City uses exactly six existing combat roles")
	_expect(mission_actor_count == 26, "Rain City preserves the 26-enemy mission budget")
	_expect(pre_boss_actor_count == 18, "Rain City preserves 18 pre-boss enemies")
	var harbour := _definition_for_zone(&"harbour_pier")
	_expect(harbour != null and harbour.effective_waves().size() == 4, "harbour preserves four external waves")
	if harbour != null:
		_expect(harbour.wave_progression == EncounterDefinition.WaveProgression.EXTERNAL, "harbour remains externally progressed")


func _run_route_reset_cycles(count: int) -> void:
	for cycle in count:
		var runner := EncounterRunner.new()
		runner.name = "RainCityEncounterCycle%d" % cycle
		runner.log_failures = false
		root.add_child(runner)
		var pending: Array[SoakEnemy] = []
		var spawned: Array[SoakEnemy] = []
		var definitions := _zero_delay_pre_boss_definitions()
		runner.configure(definitions, func(_path: String, position: Vector3) -> Node:
			var enemy := SoakEnemy.new()
			enemy.position = position
			root.add_child(enemy)
			spawned.append(enemy)
			return enemy
		)
		runner.actor_spawned.connect(func(actor: Node, definition: EncounterDefinition) -> void:
			pending.append(actor as SoakEnemy)
			_check_runtime_metadata(actor, definition, runner)
		)
		for zone_id in PRE_BOSS_ROUTE:
			pending.clear()
			runner.activate_zone(zone_id)
			var safety := 0
			while not pending.is_empty() and safety < 64:
				var actor: SoakEnemy = pending.pop_front()
				actor.died.emit(actor, null)
				safety += 1
			_expect(safety < 64, "cycle %d zone %s remains inside its bounded wave budget" % [cycle, zone_id])
			_expect(runner.completed.has(zone_id), "cycle %d completes zone %s" % [cycle, zone_id])
		_expect(spawned.size() == 18, "cycle %d spawns exactly 18 pre-boss actors" % cycle)
		_expect(runner.completed.size() == PRE_BOSS_ROUTE.size(), "cycle %d completes the full pre-boss route" % cycle)
		for zone_id in PRE_BOSS_ROUTE:
			_expect(runner.reset_zone(zone_id), "cycle %d resets completed zone %s" % [cycle, zone_id])
		_expect(runner.completed.is_empty() and runner.active.is_empty(), "cycle %d clears completed and active state" % cycle)
		var active_retry := runner.activate_zone(PRE_BOSS_ROUTE[0])
		_expect(active_retry.size() == 3, "cycle %d retry reactivates downtown wave zero" % cycle)
		_expect(runner.reset_zone(PRE_BOSS_ROUTE[0]), "cycle %d resets an active retry" % cycle)
		_expect(runner.active.is_empty(), "cycle %d active retry reset leaves no runner state" % cycle)
		for actor in spawned:
			if is_instance_valid(actor):
				actor.free()
		runner.free()


func _check_delayed_reinforcement_reset() -> void:
	var source := _definition_for_zone(&"ruse_block")
	if source == null:
		_expect(false, "delayed reset fixture can load Ruse encounter")
		return
	var definition := source.duplicate(true) as EncounterDefinition
	var waves: Array[Dictionary] = definition.waves.duplicate(true)
	waves[1]["delay_seconds"] = 0.05
	definition.waves = waves
	var runner := EncounterRunner.new()
	runner.log_failures = false
	root.add_child(runner)
	var spawned: Array[SoakEnemy] = []
	runner.configure([definition], func(_path: String, position: Vector3) -> Node:
		var enemy := SoakEnemy.new()
		enemy.position = position
		root.add_child(enemy)
		spawned.append(enemy)
		return enemy
	)
	var opening := runner.activate_zone(&"ruse_block")
	for actor in opening:
		(actor as SoakEnemy).died.emit(actor, null)
	_expect(spawned.size() == 3, "delayed reset schedules rather than immediately spawning reinforcement")
	_expect(runner.reset_zone(&"ruse_block"), "delayed reset clears the scheduled Ruse reinforcement")
	await create_timer(0.08).timeout
	_expect(spawned.size() == 3, "reset generation prevents stale delayed reinforcement spawn")
	_expect(runner.active.is_empty() and runner.completed.is_empty(), "delayed reset leaves no active or completed state")
	for actor in spawned:
		if is_instance_valid(actor):
			actor.free()
	runner.free()


func _check_runtime_metadata(actor: Node, definition: EncounterDefinition, runner: EncounterRunner) -> void:
	var profile := definition.choreography_profile
	if profile == null:
		_expect(false, "%s runtime actor has a profile" % definition.zone_id)
		return
	var role_id := StringName(actor.get_meta(&"encounter_role_id", &""))
	var approach_id := StringName(actor.get_meta(&"encounter_approach_id", &""))
	var transition_id := StringName(actor.get_meta(&"encounter_transition_id", &""))
	var wave_index := int(runner.active.get(definition.zone_id, {}).get("wave", -1))
	_expect(role_id in profile.role_ids, "%s runtime actor role is declared" % definition.zone_id)
	_expect(approach_id in profile.approach_ids, "%s runtime actor approach is declared" % definition.zone_id)
	_expect(wave_index >= 0 and wave_index < profile.wave_transition_ids.size(), "%s runtime actor has a valid wave context" % definition.zone_id)
	if wave_index >= 0 and wave_index < profile.wave_transition_ids.size():
		_expect(transition_id == profile.wave_transition_ids[wave_index], "%s runtime actor carries its authored transition" % definition.zone_id)
	_expect(actor.get_meta(&"encounter_recovery_position", Vector3.INF) == profile.recovery_position, "%s runtime actor carries its recovery position" % definition.zone_id)
	_expect(not (actor.get_meta(&"encounter_environment_choice_ids", []) as Array).is_empty(), "%s runtime actor carries an environment choice" % definition.zone_id)


func _zero_delay_pre_boss_definitions() -> Array[EncounterDefinition]:
	var result: Array[EncounterDefinition] = []
	for zone_id in PRE_BOSS_ROUTE:
		var source := _definition_for_zone(zone_id)
		if source == null:
			continue
		var definition := source.duplicate(true) as EncounterDefinition
		var waves: Array[Dictionary] = []
		for source_wave in definition.effective_waves():
			var wave := source_wave.duplicate(true) as Dictionary
			wave["delay_seconds"] = 0.0
			waves.append(wave)
		definition.waves = waves
		result.append(definition)
	return result


func _definition_for_zone(zone_id: StringName) -> EncounterDefinition:
	for definition in MANIFEST.encounters:
		if definition != null and definition.zone_id == zone_id:
			return definition
	return null


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
