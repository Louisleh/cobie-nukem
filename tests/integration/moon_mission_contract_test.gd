extends SceneTree

const WORK_ID := "moon-production"
const BASELINE := "423004e"
const MANIFEST := preload("res://resources/content/moon_manifest.tres") as ContentManifest
const PROFILE := preload("res://resources/biomes/moon_profile.tres") as BiomeMissionProfile
const CARD := preload("res://resources/level/moon_card.tres") as LevelCardData
const MISSION_METADATA := preload("res://resources/level/dark_side_fetch.tres") as LevelMetadata
const MISSION_SCENE := preload("res://scenes/levels/dark_side_fetch.tscn")
const EXPECTED_ZONES: Array[StringName] = [&"lunar_landing_pad", &"habitat_lab", &"crater_trench", &"satellite_array", &"leashmaster_crater"]
const EXPECTED_CHECKPOINTS: Array[StringName] = [&"checkpoint_landing_pad", &"checkpoint_habitat_airlock", &"checkpoint_crater_trench", &"checkpoint_satellite_array", &"checkpoint_leashmaster_crater"]
const EXPECTED_SECRETS: Array[StringName] = [&"secret_oxygen_canister", &"secret_pressure_log", &"secret_regolith_kit", &"secret_satellite_map", &"secret_orbit_passkey"]
const EXPECTED_OBJECTIVE_CHAIN: Array[StringName] = [&"moon_reach_landing_pad", &"moon_restore_airlock", &"moon_stabilize_crater_relay", &"moon_silence_satellite_array", &"moon_defeat_leashmaster", &"moon_complete_mission"]

var failures: Array[String] = []


func _initialize() -> void:
	_check_manifest_contract()
	_check_profile_contract()
	_check_encounter_contract()
	_check_runtime_boot()
	if failures.is_empty():
		print("MOON MISSION CONTRACT TEST: PASS (%s//%s)" % [WORK_ID, BASELINE])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_manifest_contract() -> void:
	_expect(MANIFEST != null, "Moon manifest loads")
	_expect(MANIFEST.level_id == &"dark_side_fetch", "Moon manifest keeps stable mission id")
	_expect(MANIFEST.level_scene == "res://scenes/levels/dark_side_fetch.tscn", "Moon manifest scene path targets mission production scene")
	_expect(MANIFEST.route_definition != null, "Moon manifest owns route definition")
	_expect(MANIFEST.audio_profile != null, "Moon manifest owns mission audio profile")
	_expect(MANIFEST.zone_presentations.size() == 5, "Moon manifest has all five zone presentations")
	for error in MANIFEST.validate():
		failures.append("Manifest: " + error)
	if MANIFEST == null or MANIFEST.route_definition == null:
		return
	_expect(MANIFEST.difficulty_profiles.size() == 3, "Moon manifest exports story/classic/mayhem difficulty profiles")
	_expect(MANIFEST.objectives.size() == 6, "Moon manifest has six objectives including final Golden Ball completion")
	_expect(MANIFEST.encounters.size() == 5, "Moon manifest has one encounter per zone")
	_expect(MANIFEST.route_definition.ordered_zone_ids() == EXPECTED_ZONES, "Moon route remains the five authored zones")

	var zone_ids: Array[StringName] = []
	for encounter in MANIFEST.encounters:
		zone_ids.append(encounter.zone_id)
		_expect(encounter.zone_id in EXPECTED_ZONES, "Moon encounter exists for recognized route zone %s" % encounter.zone_id)
		_expect(encounter.maximum_simultaneous_attackers <= 4, "Moon encounter %s respects attacker budget" % encounter.zone_id)
	_expect(zone_ids == EXPECTED_ZONES, "Moon encounter order follows route order")

	var objective_ids: Array[StringName] = []
	for objective in MANIFEST.objectives:
		objective_ids.append(objective.id)
	_expect(objective_ids == EXPECTED_OBJECTIVE_CHAIN, "Moon objective chain is ordered and ends in boss + Golden Ball")
	var final_objective: ObjectiveDefinition = MANIFEST.objectives[-1]
	_expect(final_objective.id == &"moon_complete_mission", "Final objective is Moon mission completion")
	_expect(final_objective.target_id == &"golden_tennis_ball", "Final objective target is Golden Ball")


func _check_profile_contract() -> void:
	_expect(PROFILE != null, "Moon biome profile loads")
	_expect(PROFILE.mission_id == &"dark_side_fetch", "Moon biome profile keeps stable mission id")
	_expect(PROFILE.zones.size() == 5, "Moon biome profile keeps five authored zones")
	_expect(PROFILE.objective_switches.size() == 3, "Moon profile owns three objective switches")
	_expect(PROFILE.secrets.size() == 5, "Moon profile owns five secrets")
	_expect(PROFILE.checkpoint_positions().size() == 5, "Moon profile owns five checkpoints")
	_expect(MISSION_METADATA != null and MISSION_METADATA.level_id == PROFILE.mission_id, "Moon level metadata targets the same mission id")
	_expect(CARD != null and CARD.level_id == PROFILE.mission_id, "Moon card targets the same mission id")
	_expect(CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Moon card remains public-BETA selectable")
	_expect(CARD.release_badge == "BETA", "Moon card is labeled BETA")
	_expect(CARD.launch_notice.contains("START BETA"), "Moon card preserves start-BETA notice")
	_expect(CARD.encounter == "LUNAR LEASHMASTER", "Moon card headline points at boss identity")

	for checkpoint in EXPECTED_CHECKPOINTS:
		var checkpoint_found := false
		for zone in PROFILE.zones:
			if StringName(zone.get("checkpoint_id", &"")) == checkpoint:
				checkpoint_found = true
				break
		_expect(checkpoint_found, "Moon profile owns checkpoint %s" % checkpoint)
	for secret_id in EXPECTED_SECRETS:
		var found := false
		for secret in PROFILE.secrets:
			if StringName(secret.get("id", &"")) == secret_id:
				found = true
				break
		_expect(found, "Moon profile owns secret %s" % secret_id)


func _check_encounter_contract() -> void:
	if MANIFEST == null or MANIFEST.route_definition == null:
		failures.append("Cannot verify spawn contract without manifest and route")
		return
	var regular := 0
	var bosses := 0
	for encounter in MANIFEST.encounters:
		var zone := MANIFEST.route_definition.zone_for_id(encounter.zone_id)
		_expect(zone != null, "Encounter %s resolves to an authored route zone" % encounter.zone_id)
		if zone == null:
			continue
		var waves := encounter.effective_waves()
		for wave in waves:
			var spawns := wave.get("spawns", []) as Array
			for spawn in spawns:
				var position: Vector3 = spawn.get("position", Vector3.ZERO)
				_expect(position is Vector3, "Spawn position is Vector3 in %s" % encounter.zone_id)
				_expect(zone.bounds.has_point(position), "Spawn position for %s stays inside %s bounds" % [encounter.id, encounter.zone_id])
				if StringName(spawn.get("completion_marker", "")) == EncounterDefinition.BOSS_COMPLETION_MARKER:
					bosses += 1
				else:
					regular += 1
		_expect(encounter.completion_policy != EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET, "Moon encounter %s uses a structured completion policy" % encounter.id)
		_expect(encounter.waves.size() <= 3, "Moon encounter %s keeps a compact staged wave budget" % encounter.id)
	_expect(MANIFEST.encounters[-1].completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED, "Boss zone uses boss-defeat completion policy")
	_expect(regular == 28, "Moon authors exactly 28 regular enemies")
	_expect(bosses == 1, "Moon authors exactly one boss marker")


func _check_runtime_boot() -> void:
	var mission := MISSION_SCENE.instantiate() as BiomeMissionController
	_expect(mission != null, "Moon production scene instantiates")
	if mission == null:
		return
	mission.spawn_player = false
	mission.setup_presentation = false
	mission.build_navigation = false
	mission._restored_checkpoint = {
		"objective_snapshot": {},
		"encounter_snapshot": {"completed": [], "active": {"lunar_landing_pad": {"wave": 0, "remaining": 1}}},
		"route_snapshot": {"route_id": "moon_dark_side_route", "current_zone": "lunar_landing_pad", "current_index": 0, "visited_zones": ["lunar_landing_pad"], "checkpoint_id": "checkpoint_landing_pad"},
		"secrets": {},
	}
	root.add_child(mission)
	for _idx in 6:
		await process_frame

	_expect(mission._mission_runtime != null, "Mission runtime attaches during instantiation")
	_expect(mission._route_runtime != null, "Mission route runtime attaches during instantiation")
	_expect(mission._world_builder != null, "Mission world builder attaches during instantiation")
	_expect(mission._world_builder.golden_ball != null, "Mission world builder spawns finale Golden Ball")
	if mission._world_builder != null:
		_expect(not mission._world_builder.golden_ball.enabled, "Golden Ball starts locked during Moon boss gating")
		mission._on_golden_ball_claimed(null)
		_expect(not mission._completion_started, "A premature Golden Ball claim cannot bypass the Moon boss")
	_expect(mission._mission_runtime.encounters.active.has(&"lunar_landing_pad"), "Moon Continue reactivates its unfinished checkpoint encounter")
	if mission._mission_runtime.encounters.active.has(&"lunar_landing_pad"):
		var restored_state: Dictionary = mission._mission_runtime.encounters.active[&"lunar_landing_pad"]
		_expect(not (restored_state.get("actors", []) as Array).is_empty(), "Moon Continue rebuilds live actors")
	var route := MANIFEST.route_definition
	if mission._route_runtime != null and route != null:
		for zone_id in EXPECTED_ZONES:
			var zone := route.zone_for_id(zone_id)
			_expect(zone != null, "Moon route resolves zone %s for boot-time progression" % zone_id)
			if zone == null:
				continue
			var center := zone.bounds.get_center()
			center.y = 1.0
			mission._submit_route_position(center)
			await process_frame
			_expect(mission._route_runtime.current_zone == zone_id, "Moon boot sweep reaches %s in deterministic order" % zone_id)
			if zone_id == &"leashmaster_crater":
				_expect(not mission._mission_runtime.encounters.active.has(zone_id), "Leashmaster zone does not auto-activate before objective gate")
			elif mission._mission_runtime != null:
				_expect(mission._mission_runtime.encounters.active.has(zone_id), "Non-final zone %s auto-activates encounter once entered" % zone_id)
	_expect(mission._route_runtime.current_zone == &"leashmaster_crater", "Mission route boots to boss zone at authored end")
	mission.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
