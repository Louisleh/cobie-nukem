extends SceneTree

const MANIFEST := preload("res://resources/content/ventura_manifest.tres") as ContentManifest
const ROUTE := preload("res://resources/routes/ventura_route_definition.tres") as MissionRouteDefinition
const PROFILE := preload("res://resources/biomes/ventura_profile.tres") as BiomeMissionProfile
const CARD := preload("res://resources/level/ventura_card.tres") as LevelCardData
const MISSION_SCENE := preload("res://scenes/levels/ventura_pier_pressure.tscn") as PackedScene
const MISSION_AUDIO_LIBRARY := preload("res://resources/audio/mission_audio_library.tres") as AudioCueLibrary
const EXPECTED_ZONES: Array[StringName] = [&"downtown_service_lane", &"surfers_point", &"marina_service_docks", &"ventura_pier", &"offshore_platform"]
const EXPECTED_CHECKPOINTS: Array[StringName] = [&"checkpoint_service_lane_entry", &"checkpoint_surfers_point", &"checkpoint_marina_service_docks", &"checkpoint_ventura_pier", &"checkpoint_offshore_platform"]

var failures: Array[String] = []


func _initialize() -> void:
	_check_level_card()
	_check_profile_and_route()
	_check_manifest()
	_check_encounters()
	await _check_scene_boot()
	if failures.is_empty():
		print("VENTURA MISSION CONTRACT TEST: PASS")
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_card() -> void:
	_expect(CARD != null, "Ventura card loads")
	if CARD == null: return
	_expect(CARD.level_id == &"ventura_pier_pressure", "Card keeps Ventura mission id")
	_expect(CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Card is public ALWAYS")
	_expect(CARD.release_badge == "BETA", "Card exposes BETA badge")
	_expect(not CARD.launch_notice.is_empty(), "Card start beta notice is present")
	_expect(CARD.warmup_profile != null, "Card includes warmup profile")
	_expect(CARD.secrets == 5, "Card declares five secrets")
	_expect(CARD.scene_path == "res://scenes/levels/ventura_pier_pressure.tscn", "Card routes to Ventura scene")


func _check_profile_and_route() -> void:
	_expect(PROFILE != null, "Ventura biome profile loads")
	if PROFILE == null: return
	for error in PROFILE.validate():
		failures.append("Biome profile: %s" % error)
	_expect(PROFILE.zones.size() == EXPECTED_ZONES.size(), "Profile includes exactly five authored zones")
	_expect(PROFILE.content_revision == 1, "Profile revision remains v1")
	_expect(PROFILE.campaign_unlock_ids.is_empty(), "Ventura finale profile does not add mission unlocks")
	_expect(PROFILE.permanent_upgrade_ids.size() == 1 and PROFILE.permanent_upgrade_ids[0] == &"new_game_plus", "Ventura finale profile records new_game_plus in campaign upgrades")
	_expect(ROUTE != null, "Ventura route loads")
	if ROUTE == null: return
	_expect(ROUTE.ordered_zone_ids() == EXPECTED_ZONES, "Route zone order matches expected sequence")
	_expect(ROUTE.ordered_zone_ids() == PROFILE.zones.map(func(zone: Dictionary) -> StringName: return StringName(zone.id)), "Route and profile zone sets align")
	_expect(MANIFEST != null and MANIFEST.objectives.size() == EXPECTED_ZONES.size() + 1, "Manifest includes one route checkpoint objective plus final boss and complete objectives")
	_expect(ROUTE.ordered_zone_ids().size() == 5, "Five-zone route is preserved")
	var checkpoint_ids: Array[StringName] = []
	for zone in ROUTE.zones:
		checkpoint_ids.append_array(zone.checkpoint_ids)
	_expect(checkpoint_ids == EXPECTED_CHECKPOINTS, "Checkpoint chain matches authored route")


func _check_manifest() -> void:
	_expect(MANIFEST != null, "Ventura manifest loads")
	if MANIFEST == null: return
	for error in MANIFEST.validate():
		failures.append("Manifest: %s" % error)
	_expect(MANIFEST.level_id == &"ventura_pier_pressure", "Manifest keeps stable Ventura level id")
	_expect(MANIFEST.level_scene == "res://scenes/levels/ventura_pier_pressure.tscn", "Manifest points to Ventura scene")
	_expect(MANIFEST.objectives.size() == 6, "Manifest authors six objectives")
	_expect(MANIFEST.encounters.size() == 5, "Manifest authors five encounters")
	var boss_ok := false
	var complete_ok := false
	for objective in MANIFEST.objectives:
		if objective.id == &"defeat_ventura_tidebreaker":
			boss_ok = objective.kind == ObjectiveDefinition.Kind.DEFEAT and objective.target_id == &"ventura_tidebreaker" and objective.prerequisite_ids.size() == 1
		if objective.id == &"complete_ventura_pier_pressure":
			complete_ok = objective.kind == ObjectiveDefinition.Kind.COMPLETE_LEVEL and objective.target_id == &"golden_tennis_ball" and objective.prerequisite_ids.size() == 1
	_expect(MANIFEST.objectives[3].id == &"marina_grid_controls", "Marina objective is the penultimate gate")
	for zone in EXPECTED_ZONES:
		for objective in MANIFEST.objectives:
			if objective.target_id == zone and objective.kind == ObjectiveDefinition.Kind.REACH_ZONE:
				pass
	_expect(boss_ok, "Boss objective references tidebreaker and is gated by Marina grid")
	_expect(complete_ok, "Final complete objective targets the golden ball")
	_expect(MANIFEST.audio_profile != null, "Manifest has mission audio profile")
	if MANIFEST.audio_profile != null:
		var errors := MANIFEST.audio_profile.validate()
		for error in errors:
			failures.append("Audio profile: %s" % error)


func _check_encounters() -> void:
	_expect(MANIFEST.route_definition == ROUTE, "Manifest route definition links Ventura route")
	if ROUTE == null: return
	if MANIFEST == null: return
	var zone_spawn_count: int = 0
	var boss_marker_count: int = 0
	var regular_count: int = 0
	for encounter in MANIFEST.encounters:
		_expect(ROUTE.ordered_zone_ids().has(encounter.zone_id), "Encounter zone belongs to route: %s" % encounter.zone_id)
		_expect(encounter.wave_progression == EncounterDefinition.WaveProgression.AUTO, "Encounter wave progression defaults to AUTO")
		_expect(encounter.maximum_simultaneous_attackers <= 4, "Max simultaneous attackers bounded by 4")
		var zone := ROUTE.zone_for_id(encounter.zone_id)
		for wave in encounter.waves:
			var spawns: Array = wave.get("spawns", [])
			for spawn in spawns:
				zone_spawn_count += 1
				if spawn.get("completion_marker", null) == EncounterDefinition.BOSS_COMPLETION_MARKER:
					boss_marker_count += 1
					continue
				regular_count += 1
				var point: Variant = spawn.get("position", Vector3.ZERO)
				_expect(zone != null and zone.bounds.has_point(point), "Spawn %s is inside %s" % [point, encounter.zone_id])
		for wave in encounter.waves:
			if encounter.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED and encounter.id == &"ventura_offshore_platform":
				var wave_count := encounter.waves.size()
				_expect(wave_count > 1, "Boss encounter uses multiple phases")
		_expect(encounter.completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED if encounter.id == &"ventura_offshore_platform" else true, "Boss zone uses boss completion policy")
	_expect(zone_spawn_count == 29, "Ventura authors exactly 29 encounter spawns total")
	_expect(regular_count == 28, "Ventura has approximately 28 regular enemies")
	_expect(boss_marker_count == 1, "Exactly one boss completion marker")


func _check_scene_boot() -> void:
	var mission_node := MISSION_SCENE.instantiate() as Node3D
	_expect(mission_node != null, "Ventura mission scene instantiates")
	if mission_node == null:
		quit(1)
		return
	mission_node.spawn_player = false
	mission_node.setup_presentation = false
	mission_node.build_navigation = true
	mission_node._restored_checkpoint = {
		"objective_snapshot": {},
		"encounter_snapshot": {"completed": [], "active": {"downtown_service_lane": {"wave": 0, "remaining": 1}}},
		"route_snapshot": {"route_id": "ventura_pier_pressure_route", "current_zone": "downtown_service_lane", "current_index": 0, "visited_zones": ["downtown_service_lane"], "checkpoint_id": "checkpoint_service_lane_entry"},
		"secrets": {},
	}
	root.add_child(mission_node)
	for frame in 120:
		await process_frame
		var controller := mission_node as BiomeMissionController
		if controller != null and controller._world_builder != null and controller._world_builder.navigation_region != null:
			if controller._world_builder.navigation_region.navigation_mesh.get_polygon_count() > 0:
				break
	var controller2 := mission_node as BiomeMissionController
	_expect(controller2 != null, "Scene root is a BiomeMissionController")
	if controller2 != null:
		_expect(controller2._world_builder != null, "World builder is constructed")
		_expect(controller2.content_manifest == MANIFEST, "Controller points at Ventura manifest")
		_expect(controller2.biome_profile == PROFILE, "Controller points at Ventura biome profile")
		_expect(controller2.metadata.level_id == &"ventura_pier_pressure", "Controller metadata uses Ventura level id")
		_expect(controller2._mission_runtime.encounters.active.has(&"downtown_service_lane"), "Ventura Continue reactivates its unfinished checkpoint encounter")
		if controller2._mission_runtime.encounters.active.has(&"downtown_service_lane"):
			var restored_state: Dictionary = controller2._mission_runtime.encounters.active[&"downtown_service_lane"]
			_expect(not (restored_state.get("actors", []) as Array).is_empty(), "Ventura Continue rebuilds live actors")
		controller2._on_golden_ball_claimed(null)
		_expect(not controller2._completion_started, "A premature Golden Ball claim cannot bypass Tidebreaker")
		var cue_ids: Array[StringName] = MISSION_AUDIO_LIBRARY.cue_ids()
		_expect(cue_ids.has(MANIFEST.audio_profile.exploration_ambience_cue_id), "Exploration cue resolves in mission audio library")
	mission_node.queue_free()
	await process_frame
	if failures.is_empty():
		print("VENTURA_MISSION_RUNTIME_BOOT: PASS")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
