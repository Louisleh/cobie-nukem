extends SceneTree

const EXPECTED_ZONE_IDS: Array[StringName] = [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
	&"harbour_pier",
]
const EXPECTED_CHECKPOINT_IDS: Array[StringName] = [
	&"checkpoint_downtown_alley",
	&"checkpoint_ruse_block",
	&"checkpoint_waterfront_seawall",
	&"checkpoint_terminal_service",
	&"checkpoint_harbour_pier",
	&"checkpoint_harbour_clear",
]
const MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres") as ContentManifest
const MISSION_AUDIO_LIBRARY := preload("res://resources/audio/mission_audio_library.tres") as AudioCueLibrary
const LEVEL_CARD := preload("res://resources/level/rain_city_card.tres") as LevelCardData
const COMPLIANCE_GULL_SCENE := preload("res://scenes/enemies/compliance_gull.tscn")
const UMBRELLA_ENFORCER_SCENE := preload("res://scenes/enemies/umbrella_shield_enforcer.tscn")
const MAX_READABLE_FOG_DENSITY := 0.018

var failures: Array[String] = []


func _initialize() -> void:
	_test_public_beta_contract()
	_test_manifest_and_stable_identity()
	_test_presentation_readability_contract()
	_test_route_geometry_contract()
	_test_encounter_spawn_contract()
	_test_hero_enemy_identity_contract()
	_test_audio_reference_contract()
	_finish()


func _test_public_beta_contract() -> void:
	_expect(LEVEL_CARD != null, "Rain City mission card loads")
	if LEVEL_CARD == null:
		return
	_expect(LEVEL_CARD.level_id == &"episode_1_vancouver_waterfront", "Mission card keeps stable level id")
	_expect(LEVEL_CARD.title == "RAIN CITY RUN", "Mission card uses the canonical Rain City Run title")
	_expect(LEVEL_CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Vancouver public BETA is always available")
	_expect(LEVEL_CARD.prerequisite_mission_id == &"", "Vancouver public BETA has no campaign prerequisite")
	_expect(LEVEL_CARD.scene_path == "res://scenes/levels/episode_1_vancouver_waterfront.tscn", "Vancouver beta card routes to the production preview scene")
	_expect(LEVEL_CARD.release_badge == "BETA", "Vancouver is explicitly labeled BETA while human gates remain open")
	_expect(not LEVEL_CARD.launch_notice.strip_edges().is_empty(), "Vancouver beta declares its work-in-progress status")


func _test_manifest_and_stable_identity() -> void:
	_expect(MANIFEST != null, "Vancouver content manifest loads")
	if MANIFEST == null:
		return
	var errors: PackedStringArray = MANIFEST.validate()
	_expect(errors.is_empty(), "Vancouver manifest validates: %s" % [errors])
	_expect(MANIFEST.level_id == &"episode_1_vancouver_waterfront", "Manifest keeps stable level id")
	_expect(MANIFEST.route_definition != null, "Manifest owns a typed route definition")
	if MANIFEST.route_definition == null:
		return
	_expect(MANIFEST.route_definition.ordered_zone_ids() == EXPECTED_ZONE_IDS, "Route keeps five canonical stable zone ids")
	var slice_zone: MissionRouteZone = MANIFEST.route_definition.zone_for_id(&"ruse_block")
	_expect(slice_zone != null, "Stable ruse_block zone id remains resolvable")
	if slice_zone != null:
		_expect(slice_zone.zone_title == "RAIN CITY SLICE", "Stable ruse_block id presents fictionalized Rain City Slice copy")


func _test_presentation_readability_contract() -> void:
	if MANIFEST == null:
		return
	_expect(MANIFEST.zone_presentations.size() == EXPECTED_ZONE_IDS.size(), "Every Rain City route zone owns one presentation profile")
	for profile: ZonePresentationProfile in MANIFEST.zone_presentations:
		_expect(profile != null, "Rain City presentation profile is non-null")
		if profile == null:
			continue
		_expect(profile.fog_density <= MAX_READABLE_FOG_DENSITY, "%s fog remains restrained enough to preserve route and landmark value separation" % profile.zone_id)


func _test_route_geometry_contract() -> void:
	if MANIFEST == null or MANIFEST.route_definition == null:
		return
	var route: MissionRouteDefinition = MANIFEST.route_definition
	var checkpoint_ids: Array[StringName] = []
	for zone_index in range(route.zones.size()):
		var zone: MissionRouteZone = route.zones[zone_index]
		_expect(zone != null, "Route zone %d is non-null" % zone_index)
		if zone == null:
			continue
		for volume_index in range(zone.spawn_volumes.size()):
			var volume: AABB = zone.spawn_volumes[volume_index]
			_expect(_aabb_contains_aabb(zone.bounds, volume), "%s spawn volume %d stays inside authored zone bounds" % [zone.zone_id, volume_index])
		for path_index in range(zone.patrol_paths.size()):
			var path: Array = zone.patrol_paths[path_index] as Array
			for point_index in range(path.size()):
				var point: Variant = path[point_index]
				_expect(point is Vector3 and _aabb_contains_point(zone.bounds, point as Vector3), "%s patrol point %d:%d stays inside authored zone bounds" % [zone.zone_id, path_index, point_index])
		checkpoint_ids.append_array(zone.checkpoint_ids)
		if zone_index + 1 < route.zones.size():
			var next_zone: MissionRouteZone = route.zones[zone_index + 1]
			if next_zone != null:
				var current_exit_z: float = zone.bounds.position.z
				var next_entry_z: float = next_zone.bounds.position.z + next_zone.bounds.size.z
				_expect(is_equal_approx(current_exit_z, next_entry_z), "%s connects continuously to %s without a route gap" % [zone.zone_id, next_zone.zone_id])
	_expect(checkpoint_ids == EXPECTED_CHECKPOINT_IDS, "Checkpoint rail remains uniquely ordered from downtown through post-convoy harbour clear")


func _test_encounter_spawn_contract() -> void:
	if MANIFEST == null or MANIFEST.route_definition == null:
		return
	var encounter_zones: Array[StringName] = []
	for encounter: EncounterDefinition in MANIFEST.encounters:
		_expect(encounter != null, "Vancouver encounter is non-null")
		if encounter == null:
			continue
		encounter_zones.append(encounter.zone_id)
		var zone: MissionRouteZone = MANIFEST.route_definition.zone_for_id(encounter.zone_id)
		_expect(zone != null, "Encounter %s resolves its route zone" % encounter.id)
		if zone == null:
			continue
		for wave_index in range(encounter.waves.size()):
			var wave: Dictionary = encounter.waves[wave_index]
			var spawns: Array = wave.get("spawns", []) as Array
			for spawn_index in range(spawns.size()):
				var spawn: Dictionary = spawns[spawn_index] as Dictionary
				var point: Variant = spawn.get("position")
				_expect(point is Vector3 and _point_in_spawn_volume(point as Vector3, zone), "%s wave %d spawn %d is inside a bounded authored spawn volume" % [encounter.id, wave_index, spawn_index])
	_expect(encounter_zones == EXPECTED_ZONE_IDS, "Encounter ordering follows the canonical route")
	var harbour: EncounterDefinition = _encounter_for_zone(&"harbour_pier")
	_expect(harbour != null, "Harbour convoy encounter exists")
	if harbour != null:
		_expect(harbour.waves.size() == 4, "Citation convoy owns one bounded reinforcement wave per boss phase")
		_expect(harbour.wave_progression == EncounterDefinition.WaveProgression.EXTERNAL, "Citation convoy waves advance only through the moving-set-piece coordinator")
	var authored_total := 0
	for encounter: EncounterDefinition in MANIFEST.encounters:
		for wave: Dictionary in encounter.effective_waves():
			authored_total += (wave.get("spawns", []) as Array).size()
	_expect(authored_total == 26, "Rain City authors the approved 26-enemy mission budget")


func _test_hero_enemy_identity_contract() -> void:
	var mission_scene_paths: Dictionary = {}
	for encounter: EncounterDefinition in MANIFEST.encounters:
		for wave: Dictionary in encounter.effective_waves():
			for spawn: Dictionary in wave.get("spawns", []):
				mission_scene_paths[String(spawn.get("scene", ""))] = true
	_expect(mission_scene_paths.has("res://scenes/enemies/compliance_gull.tscn"), "Rain City encounter roster includes the authored Compliance Gull")
	_expect(mission_scene_paths.has("res://scenes/enemies/umbrella_shield_enforcer.tscn"), "Rain City encounter roster includes the authored Umbrella Shield Enforcer")

	var gull := COMPLIANCE_GULL_SCENE.instantiate() as ComplianceGull
	var enforcer := UMBRELLA_ENFORCER_SCENE.instantiate() as UmbrellaShieldEnforcer
	_expect(gull != null and gull.get_script() != EnemyAgent, "Compliance Gull is a dedicated behavior class, not a renamed base enemy")
	_expect(gull != null and gull.has_signal("target_marked") and gull.has_signal("dive_started") and gull.has_node("Visual/Searchlight"), "Compliance Gull owns a mark/dive/searchlight silhouette contract")
	_expect(gull != null and gull.has_node("Visual/WingLeft") and gull.has_node("Visual/WingRight"), "Compliance Gull owns a distinct aerial silhouette")
	_expect(enforcer != null and enforcer.get_script() != EnemyAgent, "Umbrella Shield Enforcer is a dedicated behavior class, not a renamed base enemy")
	_expect(enforcer != null and enforcer.has_signal("guard_state_changed") and enforcer.has_node("DirectionalShieldComponent"), "Umbrella Shield Enforcer owns a directional guard/break contract")
	var detailed_sprite := enforcer.get_node_or_null("Visual/DetailedSprite") as Sprite3D if enforcer != null else null
	_expect(detailed_sprite != null and detailed_sprite.texture != null, "Umbrella Shield Enforcer owns a production directional atlas")
	if gull != null:
		gull.free()
	if enforcer != null:
		enforcer.free()


func _test_audio_reference_contract() -> void:
	_expect(MISSION_AUDIO_LIBRARY != null, "Mission audio library loads")
	_expect(MANIFEST != null and MANIFEST.audio_profile != null, "Vancouver audio profile is present")
	if MISSION_AUDIO_LIBRARY == null or MANIFEST == null or MANIFEST.audio_profile == null:
		return
	var library_ids: Array[StringName] = MISSION_AUDIO_LIBRARY.cue_ids()
	var profile: MissionAudioProfile = MANIFEST.audio_profile
	var state_cues: Array[StringName] = [
		profile.exploration_ambience_cue_id,
		profile.tension_ambience_cue_id,
		profile.combat_ambience_cue_id,
		profile.boss_ambience_cue_id,
		profile.victory_ambience_cue_id,
	]
	for cue_id in state_cues:
		_expect(cue_id in library_ids, "Vancouver adaptive state cue resolves in imported mission audio library: %s" % cue_id)
	for zone_profile: ZonePresentationProfile in MANIFEST.zone_presentations:
		_expect(zone_profile != null, "Vancouver zone presentation is non-null")
		if zone_profile == null:
			continue
		_expect(zone_profile.ambience_cue_id in profile.ambience_cue_ids, "%s ambience belongs to the Vancouver mission profile" % zone_profile.zone_id)
		_expect(zone_profile.ambience_cue_id in library_ids, "%s ambience resolves in imported mission audio library" % zone_profile.zone_id)


func _encounter_for_zone(zone_id: StringName) -> EncounterDefinition:
	for encounter: EncounterDefinition in MANIFEST.encounters:
		if encounter != null and encounter.zone_id == zone_id:
			return encounter
	return null


func _point_in_spawn_volume(point: Vector3, zone: MissionRouteZone) -> bool:
	for volume: AABB in zone.spawn_volumes:
		if _aabb_contains_point(volume, point):
			return true
	return false


func _aabb_contains_aabb(container: AABB, candidate: AABB) -> bool:
	return _aabb_contains_point(container, candidate.position) and _aabb_contains_point(container, candidate.position + candidate.size)


func _aabb_contains_point(bounds: AABB, point: Vector3) -> bool:
	var maximum: Vector3 = bounds.position + bounds.size
	return point.x >= bounds.position.x and point.y >= bounds.position.y and point.z >= bounds.position.z and point.x <= maximum.x and point.y <= maximum.y and point.z <= maximum.z


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VANCOUVER CONTENT CONTRACT TEST: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
