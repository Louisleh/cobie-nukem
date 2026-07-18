extends SceneTree

const MANIFEST := preload("res://resources/content/mount_hood_manifest.tres") as ContentManifest
const MISSION_SCENE := preload("res://scenes/levels/mount_hood_whiteout.tscn")
const CARD := preload("res://resources/level/mountain_card.tres") as LevelCardData
const EXPECTED_ZONES: Array[StringName] = [&"forest_pullout", &"mountain_road", &"snowbound_lodge", &"service_tunnels", &"summit"]
const EXPECTED_CHECKPOINTS: Array[StringName] = [&"checkpoint_forest_start", &"checkpoint_road_clear", &"checkpoint_lodge_power", &"checkpoint_lift_restored", &"checkpoint_summit_arrival"]

var failures: Array[String] = []


func _initialize() -> void:
	_check_manifest()
	_check_encounters()
	_check_route_soak()
	_check_surface_profiles()
	await _check_runtime_world()
	if failures.is_empty(): print("MOUNT HOOD BETA TESTS: PASS")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _check_manifest() -> void:
	_expect(MANIFEST != null, "Mount Hood manifest loads")
	if MANIFEST == null: return
	for error in MANIFEST.validate(): failures.append("Manifest: " + error)
	_expect(MANIFEST.level_id == &"mount_hood_whiteout", "Mount Hood keeps stable mission id")
	_expect(MANIFEST.route_definition.ordered_zone_ids() == EXPECTED_ZONES, "Mount Hood owns five canonical zones")
	_expect(MANIFEST.objectives.size() == 6, "Mount Hood has its complete six-step objective chain")
	_expect(MANIFEST.zone_presentations.size() == 5, "Every Mount Hood zone has presentation identity")
	_expect(CARD != null and CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Mount Hood is always-selectable public beta")
	_expect(CARD.release_badge == "BETA" and not CARD.scene_path.is_empty() and CARD.warmup_profile != null, "Mount Hood card carries beta notice, route, and warmup")
	var checkpoints: Array[StringName] = []
	for zone in MANIFEST.route_definition.zones: checkpoints.append_array(zone.checkpoint_ids)
	_expect(checkpoints == EXPECTED_CHECKPOINTS, "Mount Hood has the five authored checkpoint ids")
	for profile in MANIFEST.zone_presentations:
		_expect(profile.environment_identity_id != &"" and not profile.material_family_ids.is_empty(), "Zone %s has distinct materials and identity" % profile.zone_id)
		if profile.zone_id in [&"forest_pullout", &"mountain_road", &"summit"]:
			_expect(profile.weather == &"snow", "Exterior zone %s uses snow weather" % profile.zone_id)


func _check_encounters() -> void:
	var regular := 0
	var bosses := 0
	for encounter in MANIFEST.encounters:
		var zone := MANIFEST.route_definition.zone_for_id(encounter.zone_id)
		for wave in encounter.effective_waves():
			for spawn in wave.get("spawns", []):
				var position: Vector3 = spawn.get("position", Vector3.ZERO)
				_expect(zone.bounds.has_point(position), "Spawn %s remains inside %s bounds" % [position, encounter.zone_id])
				if StringName(spawn.get("completion_marker", "")) == EncounterDefinition.BOSS_COMPLETION_MARKER: bosses += 1
				else: regular += 1
	_expect(regular == 24, "Mount Hood authors exactly 24 regular enemies")
	_expect(bosses == 1, "Mount Hood authors exactly one completion boss")
	_expect(MANIFEST.encounters[-1].completion_policy == EncounterDefinition.CompletionPolicy.BOSS_DEFEATED, "Summit completion is boss-authoritative")


func _check_route_soak() -> void:
	for difficulty in [&"story", &"classic", &"mayhem"]:
		for run in 100:
			var runtime := MissionRouteRuntime.new(); root.add_child(runtime)
			_expect(runtime.configure(MANIFEST.route_definition), "Route configures on %s soak %d" % [difficulty, run])
			for zone in MANIFEST.route_definition.zones:
				runtime.submit_actor_position(zone.bounds.get_center())
			_expect(runtime.current_zone == &"summit", "Route reaches summit on %s soak %d" % [difficulty, run])
			runtime.free()


func _check_surface_profiles() -> void:
	var powder := load("res://resources/player/surface_powder.tres") as SurfaceMovementProfile
	var ice := load("res://resources/player/surface_ice_slush.tres") as SurfaceMovementProfile
	_expect(is_equal_approx(powder.scaled_multiplier(powder.speed_multiplier, "full"), 0.88), "Full powder applies bounded speed reduction")
	_expect(is_equal_approx(powder.scaled_multiplier(powder.speed_multiplier, "reduced"), 0.94), "Reduced powder halves deviation")
	_expect(is_equal_approx(ice.scaled_multiplier(ice.deceleration_multiplier, "off"), 1.0), "Off removes ice movement variation")


func _check_runtime_world() -> void:
	var mission := MISSION_SCENE.instantiate() as MountHoodWhiteout
	if mission == null:
		failures.append("Mount Hood mission scene instantiates")
		return
	mission.spawn_player = false; mission.setup_presentation = false; mission.build_navigation = true
	root.add_child(mission)
	for frame in 180:
		await process_frame
		if mission._world_builder != null and mission._world_builder.navigation_region != null and mission._world_builder.navigation_region.navigation_mesh.get_polygon_count() > 0:
			break
	_expect(mission._world_builder != null and mission._world_builder.golden_ball != null, "Mount Hood builds its authored world and gated Golden Ball")
	_expect(mission._world_builder.navigation_region.navigation_mesh.get_polygon_count() > 0, "Mount Hood bakes reachable production navigation")
	_expect(not mission._world_builder.golden_ball.enabled, "Golden Ball starts unavailable")
	var snowcat := load("res://scenes/enemies/municipal_snowcat.tscn") as PackedScene
	var snowcat_instance := snowcat.instantiate() as MunicipalSnowcat
	_expect(snowcat_instance != null and snowcat_instance.definition.max_health == 1000.0, "Snowcat owns the readable 1,000 HP boss baseline")
	_expect(snowcat_instance != null and snowcat_instance.combat_profile.summon_scene.resource_path.ends_with("avalanche_recon_drone.tscn"), "Snowcat summons the Mount Hood recon family")
	if snowcat_instance != null: snowcat_instance.free()
	var signs := mission.get_tree().get_nodes_in_group(&"authored_world_signs")
	_expect(signs.size() >= 4, "Mount Hood has authored route-facing signs")
	for sign in signs:
		for error in (sign as AuthoredWorldSign).validate_authored(): failures.append("Sign: " + error)
	var lift := mission._world_builder.chairlift
	_expect(lift != null, "Mount Hood has a reset-safe chairlift")
	if lift != null:
		var rider := CharacterBody3D.new()
		mission.add_child(rider)
		lift.set_enabled(true); lift.interact(rider)
		var rider_start := rider.global_position
		var lift_start := lift.position
		for frame in 30: await physics_frame
		_expect(lift.position.distance_to(lift_start) > 0.1, "Chairlift advances while riding")
		_expect(rider.global_position.distance_to(rider_start) > 0.1, "Chairlift carries its interacting rider")
		lift.reset_lift()
		for cycle in 100:
			lift.set_enabled(true); lift.interact(null); lift._physics_process(0.1); lift.reset_lift()
			_expect(not lift.riding and lift.position.is_equal_approx(lift.start_position), "Chairlift resets on cycle %d" % cycle)
	mission.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
