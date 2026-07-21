class_name RainCityCheckpointState
extends RefCounted


static func consume_requested(metadata: LevelMetadata, content_revision: int, checkpoint_positions: Dictionary, game_state: Node, save_manager: Node) -> Dictionary:
	if game_state == null or not bool(game_state.get("continue_requested")):
		return {}
	var saved := CheckpointPayload.sanitize(save_manager.load_slot(&"checkpoint")) if save_manager != null else {}
	game_state.continue_requested = false
	if String(saved.get("level_id", "")) != String(metadata.level_id):
		return {}
	var checkpoint_id := StringName(saved.get("checkpoint_id", ""))
	var values: Array = saved.get("position", [])
	var revision_matches := int(saved.get("content_revision", 0)) == content_revision
	var position: Variant = null
	if revision_matches and values.size() == 3:
		position = Vector3(float(values[0]), float(values[1]), float(values[2]))
	elif checkpoint_positions.has(checkpoint_id):
		# Authored checkpoint anchors are authoritative whenever old content moved
		# or the persisted position is absent. Never invent Vector3.ZERO for a
		# structurally valid but incomplete checkpoint.
		position = checkpoint_positions[checkpoint_id]
	if position == null:
		return {}
	return {"payload": saved, "position": position}


static func restore_progression_state(payload: Dictionary, game_state: Node) -> void:
	if game_state == null or payload.is_empty():
		return
	if not game_state.has_method("restore_progression_checkpoint"):
		return
	game_state.restore_progression_checkpoint(int(payload.get("pending_compliance_tags", 0)), String(payload.get("run_mode", "standard")))


static func restore(payload: Dictionary, mission_runtime: MissionRuntime, route_runtime: MissionRouteRuntime, route_definition: MissionRouteDefinition) -> Dictionary:
	if payload.is_empty() or mission_runtime == null or route_runtime == null:
		return {}
	mission_runtime.restore(payload)
	var secrets: Dictionary = payload.get("secrets", {}).duplicate(true)
	var route_snapshot: Dictionary = payload.get("route_snapshot", {})
	if route_snapshot.is_empty() or not route_runtime.restore(route_snapshot):
		_restore_route_checkpoint(StringName(payload.get("checkpoint_id", "")), route_runtime, route_definition)
	return {"secrets": secrets, "current_zone": route_runtime.current_zone}


static func build_payload(scene_path: String, metadata: LevelMetadata, checkpoint_id: StringName, content_revision: int, position: Vector3, difficulty_id: StringName, runtime_snapshot: Dictionary, route_snapshot: Dictionary, secrets: Dictionary, active_loadout: Dictionary, player_state: Dictionary = {}) -> Dictionary:
	var payload := {
		"scene_path": scene_path,
		"level_id": String(metadata.level_id),
		"checkpoint_id": String(checkpoint_id),
		"content_revision": content_revision,
		"position": [position.x, position.y, position.z],
		"difficulty_id": String(difficulty_id),
		"objective_snapshot": runtime_snapshot.get("objective_snapshot", {}),
		"encounter_snapshot": runtime_snapshot.get("encounter_snapshot", {}),
		"route_snapshot": route_snapshot,
		"secrets": secrets.duplicate(true),
		"unlocked_weapons": active_loadout.get("unlocked_weapons", []),
		"active_mission_upgrades": active_loadout,
		"player_state": player_state.duplicate(true),
	}
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null("GameState") if tree != null else null
	if game_state != null:
		payload["pending_compliance_tags"] = int(game_state.run_stats.get("pending_compliance_tags", 0))
		payload["run_mode"] = String(game_state.run_stats.get("run_mode", "standard"))
	var progress := CampaignProgressRuntime.new()
	var save_manager: Node = tree.root.get_node_or_null("SaveManager") if tree != null else null
	if save_manager != null and progress.configure(save_manager):
		payload["equipped_weapon_mods"] = progress.load_progress().get("equipped_weapon_mods", {}).duplicate(true)
	progress.free()
	return payload


static func restore_player_state(player: CobiePlayer, checkpoint: Dictionary) -> void:
	if player == null or player.health_armor == null:
		return
	var state: Dictionary = checkpoint.get("player_state", {})
	if state.is_empty():
		return
	var health_armor := player.health_armor
	health_armor.is_dead = false
	health_armor.health = clampf(float(state.get("health", health_armor.health)), 0.0, health_armor.max_health)
	health_armor.armor = clampf(float(state.get("armor", health_armor.armor)), 0.0, health_armor.max_armor)
	health_armor.health_changed.emit(health_armor.health, health_armor.max_health)
	health_armor.armor_changed.emit(health_armor.armor, health_armor.max_armor)


static func _restore_route_checkpoint(checkpoint_id: StringName, route_runtime: MissionRouteRuntime, route_definition: MissionRouteDefinition) -> void:
	if route_definition == null:
		return
	var ordered := route_definition.ordered_zone_ids()
	var checkpoint_zone := &""
	for zone_id in ordered:
		var zone := route_definition.zone_for_id(zone_id)
		if zone != null and zone.checkpoint_ids.has(checkpoint_id):
			checkpoint_zone = zone_id
			break
	if checkpoint_zone == &"":
		return
	var target_index := ordered.find(checkpoint_zone)
	var visited: Array[String] = []
	for index in target_index + 1:
		visited.append(String(ordered[index]))
	route_runtime.restore({
		"route_id": String(route_definition.route_id),
		"current_zone": String(checkpoint_zone),
		"current_index": target_index,
		"visited_zones": visited,
		"checkpoint_id": String(checkpoint_id),
		"is_completed": target_index == ordered.size() - 1,
	})
