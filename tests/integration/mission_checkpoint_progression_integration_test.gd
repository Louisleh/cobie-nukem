extends SceneTree

const CHECKPOINT_PENDING_TAGS := 9
const CHECKPOINT_RUN_MODE := &"off_leash"
const CHECKPOINT_HEALTH := 72.0
const CHECKPOINT_ARMOR := 9.0
const CHECKPOINT_WEAPON_ID := &"pawstol"
const CHECKPOINT_LOADOUT_WEAPONS: Array[StringName] = [&"pawstol", &"barkshot", &"fetch_launcher"]
const RESTORE_CYCLES := 100

const MOUNT_SCENE := preload("res://scenes/levels/mount_hood_whiteout.tscn")
const MOUNT_MANIFEST := preload("res://resources/content/mount_hood_manifest.tres") as ContentManifest
const MOUNT_METADATA := preload("res://resources/level/mount_hood_whiteout.tres") as LevelMetadata
const MOUNT_CHECKPOINTS: Dictionary[StringName, Vector3] = {
	&"checkpoint_forest_start": Vector3(0.0, 1.1, 8.0),
	&"checkpoint_road_clear": Vector3(0.0, 1.1, -23.0),
	&"checkpoint_lodge_power": Vector3(0.0, 1.1, -61.0),
	&"checkpoint_lift_restored": Vector3(0.0, 1.1, -100.0),
	&"checkpoint_summit_arrival": Vector3(0.0, 1.1, -139.0),
}
const MOON_SCENE := preload("res://scenes/levels/dark_side_fetch.tscn")
const MOON_MANIFEST := preload("res://resources/content/moon_manifest.tres") as ContentManifest
const MOON_METADATA := preload("res://resources/level/dark_side_fetch.tres") as LevelMetadata
const MOON_PROFILE := preload("res://resources/biomes/moon_profile.tres") as BiomeMissionProfile
const MOON_ACTIVE_ZONE := &"lunar_landing_pad"
const MOON_CHECKPOINT_ID := &"checkpoint_landing_pad"
const VENTURA_SCENE := preload("res://scenes/levels/ventura_pier_pressure.tscn")
const VENTURA_MANIFEST := preload("res://resources/content/ventura_manifest.tres") as ContentManifest
const VENTURA_METADATA := preload("res://resources/level/ventura_pier_pressure.tres") as LevelMetadata
const VENTURA_PROFILE := preload("res://resources/biomes/ventura_profile.tres") as BiomeMissionProfile
const VENTURA_ACTIVE_ZONE := &"downtown_service_lane"
const VENTURA_CHECKPOINT_ID := &"checkpoint_service_lane_entry"

var failures: Array[String] = []
var _game_state: GameState
var _run_stats_backup: Dictionary = {}
var _local_metrics_backup: Dictionary = {}
var _continue_requested_backup := false
var _requested_run_mode_backup := "standard"
var _difficulty_id_backup: StringName = &"classic"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_state = root.get_node_or_null("/root/GameState")
	if _game_state == null:
		failures.append("GameState autoload is required for checkpoint progression tests")
		quit(1)
		return
	_backup_game_state()

	_check_progression_restore_cycles("Mount Hood", MOUNT_METADATA.level_id)
	_check_progression_restore_cycles("Moon", MOON_METADATA.level_id)
	_check_progression_restore_cycles("Ventura", VENTURA_METADATA.level_id)
	await _check_mount_hood_checkpoint_restore()
	await _check_moon_checkpoint_restore()
	await _check_ventura_checkpoint_restore()

	_restore_game_state()
	if failures.is_empty():
		print("MISSION CHECKPOINT PROGRESSION TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_mount_hood_checkpoint_restore() -> void:
	await _check_checkpoint_restore(
		"Mount Hood",
		MOUNT_SCENE,
		MOUNT_MANIFEST,
		MOUNT_METADATA,
		MOUNT_CHECKPOINTS,
		&"forest_pullout",
		&"checkpoint_forest_start"
	)


func _check_moon_checkpoint_restore() -> void:
	await _check_checkpoint_restore(
		"Moon",
		MOON_SCENE,
		MOON_MANIFEST,
		MOON_METADATA,
		MOON_PROFILE.checkpoint_positions(),
		MOON_ACTIVE_ZONE,
		MOON_CHECKPOINT_ID
	)


func _check_ventura_checkpoint_restore() -> void:
	await _check_checkpoint_restore(
		"Ventura",
		VENTURA_SCENE,
		VENTURA_MANIFEST,
		VENTURA_METADATA,
		VENTURA_PROFILE.checkpoint_positions(),
		VENTURA_ACTIVE_ZONE,
		VENTURA_CHECKPOINT_ID
	)


func _check_checkpoint_restore(label: String, mission_scene: PackedScene, manifest: ContentManifest, metadata: LevelMetadata, checkpoint_positions: Dictionary, checkpoint_zone: StringName, checkpoint_id: StringName) -> void:
	_set_game_state_for_checkpoint()
	var route_definition: MissionRouteDefinition = manifest.route_definition
	var objective_id: StringName = manifest.objectives[0].id if manifest.objectives.size() > 0 else &""
	if objective_id == &"":
		_restore_game_state()
		failures.append("%s manifest has no objective entries" % label)
		return
	var ordered: Array[StringName] = route_definition.ordered_zone_ids()
	var index := ordered.find(checkpoint_zone)
	if index < 0:
		_restore_game_state()
		failures.append("%s checkpoint zone %s is not in manifest route" % [label, checkpoint_zone])
		return
	var visited: Array[String] = []
	for zone_index in index + 1:
		visited.append(String(ordered[zone_index]))
	var checkpoint_position: Vector3 = checkpoint_positions.get(checkpoint_id, Vector3.ZERO) as Vector3
	var payload := _build_checkpoint_payload(
		metadata,
		objective_id,
		checkpoint_zone,
		checkpoint_id,
		checkpoint_position,
		route_definition,
		index,
		visited,
		{"checkpoint_proof": "integration"}
	)
	var mission := mission_scene.instantiate() as Node
	mission.spawn_player = false
	mission.setup_presentation = false
	mission.build_navigation = false
	mission.set("_restored_checkpoint", payload)
	mission.set("checkpoint_position", checkpoint_position)
	root.add_child(mission)
	for _frame in 10:
		await process_frame

	var run_stats := _game_state.run_stats if _game_state != null else {}
	_expect(int(run_stats.get("pending_compliance_tags", -1)) == CHECKPOINT_PENDING_TAGS, "%s restores pending compliance tags after begin_run" % label)
	_expect(String(run_stats.get("run_mode", "standard")) == String(CHECKPOINT_RUN_MODE), "%s restores run mode from checkpoint after begin_run" % label)

	var mission_runtime := mission.get("_mission_runtime") as MissionRuntime
	var route_runtime := mission.get("_route_runtime") as MissionRouteRuntime
	var mission_secrets := mission.get("secrets") as Dictionary
	var route_snapshot := route_runtime.snapshot() if route_runtime != null else {}
	var objective_snapshot := mission_runtime.objectives.snapshot() if mission_runtime != null else {}
	var encounter_snapshot := mission_runtime.encounters.snapshot() if mission_runtime != null else {}
	_expect(route_snapshot.get("current_zone", "") == String(checkpoint_zone), "%s restores route current zone" % label)
	_expect(route_snapshot.get("checkpoint_id", "") == String(checkpoint_id), "%s restores route checkpoint id" % label)
	_expect((route_snapshot.get("visited_zones", []) as Array).has(String(checkpoint_zone)), "%s restores visited zone set" % label)
	_expect((objective_snapshot.get("completed", []) as Array).has(String(objective_id)), "%s restores objective completion" % label)
	_expect((encounter_snapshot.get("active", {}) as Dictionary).has(String(checkpoint_zone)), "%s restores encounter active state" % label)
	_expect((encounter_snapshot.get("active", {}) as Dictionary).size() == 1, "%s restore keeps exactly one active encounter snapshot" % label)
	_expect((mission_secrets.get("checkpoint_proof", "") == "integration"), "%s restores checkpoint-secrets" % label)

	mission.call("_spawn_player")
	for _frame in 6:
		await process_frame
	var player := mission.get("player") as CobiePlayer
	_expect(player != null and player.health_armor != null, "%s spawns checkpointed player" % label)
	if player != null and player.health_armor != null:
		_expect(is_equal_approx(player.health_armor.health, CHECKPOINT_HEALTH), "%s restores checkpoint player health" % label)
		_expect(is_equal_approx(player.health_armor.armor, CHECKPOINT_ARMOR), "%s restores checkpoint player armor" % label)
		_expect(player.current_weapon_index >= 0 and player.current_weapon_index < player.weapons.size(), "%s restores a valid selected weapon index" % label)
		var selected := &""
		if player.current_weapon_index >= 0 and player.current_weapon_index < player.weapons.size() and player.weapons[player.current_weapon_index].definition != null:
			selected = player.weapons[player.current_weapon_index].definition.id
		_expect(selected == CHECKPOINT_WEAPON_ID, "%s restores loadout selected weapon" % label)
		var ammo := _get_weapon_ammo(player, CHECKPOINT_WEAPON_ID)
		var expected_ammo := _expected_weapon_ammo_for(_expected_active_loadout(String(metadata.level_id), CHECKPOINT_LOADOUT_WEAPONS), CHECKPOINT_WEAPON_ID)
		_expect(int(ammo.get("magazine", -1)) == int(expected_ammo.get("magazine", -1)) and int(ammo.get("reserve", -1)) == int(expected_ammo.get("reserve", -1)), "%s restores loadout ammo from checkpoint" % label)

	mission.queue_free()
	await process_frame
	_restore_game_state()


func _check_progression_restore_cycles(label: String, level_id: StringName) -> void:
	for cycle in RESTORE_CYCLES:
		var expected_tags := cycle + 1
		var expected_mode := "off_leash" if cycle % 2 == 0 else "standard"
		_game_state.begin_run(level_id)
		RainCityCheckpointState.restore_progression_state({
			"pending_compliance_tags": expected_tags,
			"run_mode": expected_mode,
		}, _game_state)
		_expect(int(_game_state.run_stats.get("pending_compliance_tags", -1)) == expected_tags, "%s progression cycle %d restores pending tags after begin_run" % [label, cycle])
		_expect(String(_game_state.run_stats.get("run_mode", "")) == expected_mode, "%s progression cycle %d restores run mode after begin_run" % [label, cycle])


func _build_checkpoint_payload(metadata: LevelMetadata, objective_id: StringName, zone_id: StringName, checkpoint_id: StringName, checkpoint_position: Vector3, route_definition: MissionRouteDefinition, zone_index: int, visited_zones: Array[String], secrets: Dictionary) -> Dictionary:
	return {
		"scene_path": metadata.replay_scene,
		"level_id": String(metadata.level_id),
		"checkpoint_id": String(checkpoint_id),
		"content_revision": 1,
		"position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z],
		"difficulty_id": "classic",
		"objective_snapshot": {
			"progress": {String(objective_id): 1},
			"completed": [String(objective_id)],
		},
		"encounter_snapshot": {
			"completed": [],
			"active": {String(zone_id): {"wave": 0, "remaining": 1}},
		},
		"route_snapshot": {
			"route_id": String(route_definition.route_id),
			"current_zone": String(zone_id),
			"current_index": zone_index,
			"visited_zones": visited_zones,
			"checkpoint_id": String(checkpoint_id),
		},
		"secrets": secrets,
		"unlocked_weapons": CHECKPOINT_LOADOUT_WEAPONS,
		"active_mission_upgrades": _expected_active_loadout(String(metadata.level_id), CHECKPOINT_LOADOUT_WEAPONS),
		"player_state": {"health": CHECKPOINT_HEALTH, "armor": CHECKPOINT_ARMOR},
		"pending_compliance_tags": CHECKPOINT_PENDING_TAGS,
		"run_mode": String(CHECKPOINT_RUN_MODE),
		"equipped_weapon_mods": {},
	}


func _expected_active_loadout(mission_id: String, unlocked_weapons: Array[StringName]) -> Dictionary:
	return {
		"mission_id": mission_id,
		"selected_weapon": CHECKPOINT_WEAPON_ID,
		"unlocked_weapons": unlocked_weapons,
		"weapon_ammo": {
			"pawstol": {"magazine": 15, "reserve": 0},
			"barkshot": {"magazine": 5, "reserve": 11},
			"fetch_launcher": {"magazine": 2, "reserve": 6},
		},
	}


func _get_weapon_ammo(player: CobiePlayer, weapon_id: StringName) -> Dictionary:
	var result := {"magazine": -1, "reserve": -1}
	if player == null:
		return result
	for weapon in player.weapons:
		if weapon.definition == null or weapon.definition.id != weapon_id:
			continue
		result["magazine"] = weapon.ammo
		result["reserve"] = weapon.reserve_ammo
		break
	return result


func _expected_weapon_ammo_for(loadout: Dictionary, weapon_id: StringName) -> Dictionary:
	var weapon_ammo := loadout.get("weapon_ammo", {}) as Dictionary
	var entry := weapon_ammo.get(String(weapon_id), {}) as Dictionary
	return entry if not entry.is_empty() else {"magazine": -1, "reserve": -1}


func _set_game_state_for_checkpoint() -> void:
	if _game_state == null:
		return
	_game_state.continue_requested = false
	_game_state.run_stats = {}
	_game_state.requested_run_mode = "standard"
	_game_state.difficulty_id = &"classic"


func _backup_game_state() -> void:
	if _game_state == null:
		return
	_run_stats_backup = _game_state.run_stats.duplicate(true)
	_local_metrics_backup = _game_state.local_metrics.duplicate(true) if _game_state.local_metrics is Dictionary else {}
	_continue_requested_backup = bool(_game_state.continue_requested)
	_requested_run_mode_backup = String(_game_state.requested_run_mode)
	_difficulty_id_backup = _game_state.difficulty_id


func _restore_game_state() -> void:
	if _game_state == null:
		return
	_game_state.run_stats = _run_stats_backup.duplicate(true)
	_game_state.local_metrics = _local_metrics_backup.duplicate(true) if _game_state.local_metrics is Dictionary else _local_metrics_backup.duplicate(true)
	_game_state.continue_requested = _continue_requested_backup
	_game_state.requested_run_mode = _requested_run_mode_backup
	_game_state.difficulty_id = _difficulty_id_backup


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
