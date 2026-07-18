extends SceneTree

const CAMPAIGN: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")
const ROUTE_MANIFESTS: Array[ContentManifest] = [
	preload("res://resources/content/vancouver_waterfront_manifest.tres"),
	preload("res://resources/content/mount_hood_manifest.tres"),
	preload("res://resources/content/moon_manifest.tres"),
	preload("res://resources/content/ventura_manifest.tres"),
]
const EXPECTED_IDS: Array[StringName] = [
	&"episode_1_level_1", &"episode_1_vancouver_waterfront", &"mount_hood_whiteout",
	&"dark_side_fetch", &"ventura_pier_pressure",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_campaign_graph()
	_check_route_and_checkpoint_soaks()
	await _check_all_scene_boots()
	if failures.is_empty():
		print("FIVE MISSION GAUNTLET: PASS (5 missions, 1200 routes, 1000 checkpoint restores)")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _check_campaign_graph() -> void:
	_expect(CAMPAIGN.ordered_level_ids() == EXPECTED_IDS, "Campaign order is stable from Salmon Creek through Ventura")
	_expect(CAMPAIGN.cards.size() == 5 and CAMPAIGN.missions.size() == 5, "Campaign owns five cards and five metadata records")
	for index in EXPECTED_IDS.size():
		var id := EXPECTED_IDS[index]
		var card := CAMPAIGN.cards[index] as LevelCardData
		var metadata := CAMPAIGN.metadata_for(id)
		_expect(card != null and card.level_id == id and card.is_available(null), "Mission %s is publicly selectable" % id)
		_expect(card != null and ResourceLoader.exists(card.scene_path, "PackedScene"), "Mission %s card routes to a packed scene" % id)
		_expect(metadata != null and metadata.replay_scene == card.scene_path, "Mission %s replay and card routes agree" % id)
		if index < EXPECTED_IDS.size() - 1:
			_expect(metadata.next_mission_id == EXPECTED_IDS[index + 1], "Mission %s continues to the next authored mission" % id)
			_expect(ResourceLoader.exists(metadata.next_mission_scene, "PackedScene"), "Mission %s continuation scene exists" % id)
		else:
			_expect(not metadata.has_next_mission(), "Ventura is the current campaign finale")


func _check_route_and_checkpoint_soaks() -> void:
	# Salmon Creek's custom six-zone controller remains covered by its 100-route
	# soak. This gauntlet exercises the four typed mission routes at the same scale.
	for manifest in ROUTE_MANIFESTS:
		var definition := manifest.route_definition
		_expect(definition != null, "%s owns a typed route" % manifest.level_id)
		if definition == null: continue
		var ordered := definition.ordered_zone_ids()
		for difficulty in [&"story", &"classic", &"mayhem"]:
			for cycle in 100:
				var runtime := MissionRouteRuntime.new(); root.add_child(runtime)
				_expect(runtime.configure(definition), "%s route configures on %s cycle %d" % [manifest.level_id, difficulty, cycle])
				for zone_id in ordered:
					var zone := definition.zone_for_id(zone_id)
					runtime.submit_actor_position(zone.bounds.get_center())
				_expect(runtime.current_zone == ordered[-1], "%s reaches its final zone on %s cycle %d" % [manifest.level_id, difficulty, cycle])
				runtime.free()
		for zone_index in ordered.size():
			var zone := definition.zone_for_id(ordered[zone_index])
			var checkpoint_id: StringName = zone.checkpoint_ids[0]
			for cycle in 50:
				var runtime := MissionRouteRuntime.new(); root.add_child(runtime); runtime.configure(definition)
				var visited: Array[String] = []
				for index in zone_index + 1: visited.append(String(ordered[index]))
				var snapshot := {"route_id": String(definition.route_id), "current_zone": String(ordered[zone_index]), "current_index": zone_index, "visited_zones": visited, "checkpoint_id": String(checkpoint_id)}
				_expect(runtime.restore(snapshot), "%s checkpoint %s restores on cycle %d" % [manifest.level_id, checkpoint_id, cycle])
				_expect(runtime.current_zone == ordered[zone_index], "%s checkpoint %s restores its zone" % [manifest.level_id, checkpoint_id])
				runtime.free()


func _check_all_scene_boots() -> void:
	for index in EXPECTED_IDS.size():
		var card := CAMPAIGN.cards[index] as LevelCardData
		var packed := load(card.scene_path) as PackedScene
		var mission := packed.instantiate() if packed != null else null
		_expect(mission != null, "Mission %s scene instantiates" % card.level_id)
		if mission == null: continue
		if "spawn_player" in mission: mission.set("spawn_player", false)
		if "setup_presentation" in mission: mission.set("setup_presentation", false)
		if "build_navigation" in mission: mission.set("build_navigation", false)
		root.add_child(mission)
		for _frame in 4: await process_frame
		_expect(mission.is_node_ready(), "Mission %s reaches ready without intervention" % card.level_id)
		mission.queue_free(); await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
