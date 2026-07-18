class_name MountHoodWhiteout
extends Node3D

signal level_ready(player: Node3D)
signal zone_entered(zone_id: StringName, title: String)
signal narrative_message(text: String, duration: float)
signal objective_changed(text: String)
signal secret_found(secret_id: StringName, title: String, found: int, total: int)
signal checkpoint_activated(checkpoint_id: StringName, respawn_position: Vector3)
signal enemy_spawned(enemy: Node, zone_id: StringName)
signal enemy_defeated(enemy: Node, zone_id: StringName)
signal boss_state_changed(state: StringName, fraction: float)
signal boss_phase_caption(text: String, duration: float)
signal level_completed(summary: Dictionary)

const PLAYER_SCENE := "res://scenes/player/cobie_player.tscn"
const CONTENT_REVISION := 1
const MUNICIPAL_RECALL_OVERRIDE := &"municipal_recall_override"
const CHECKPOINT_POSITIONS := {
	&"checkpoint_forest_start": Vector3(0, 1.1, 8),
	&"checkpoint_road_clear": Vector3(0, 1.1, -23),
	&"checkpoint_lodge_power": Vector3(0, 1.1, -61),
	&"checkpoint_lift_restored": Vector3(0, 1.1, -100),
	&"checkpoint_summit_arrival": Vector3(0, 1.1, -139),
}

@export var metadata: LevelMetadata = preload("res://resources/level/mount_hood_whiteout.tres")
@export var content_manifest: ContentManifest = preload("res://resources/content/mount_hood_manifest.tres")
@export var spawn_player := true
@export var setup_presentation := true
@export var build_navigation := true
@export var opening_protection_seconds := 8.0

var player: Node3D
var current_zone: StringName = &""
var checkpoint_position := CHECKPOINT_POSITIONS[&"checkpoint_forest_start"] as Vector3
var secrets: Dictionary = {}
var enemies_total := 0
var enemies_defeated := 0
var _run_started_ms := 0
var _completion_started := false
var _completion_summary: Dictionary = {}
var _restored_checkpoint: Dictionary = {}
var _mission_runtime: MissionRuntime
var _route_runtime: MissionRouteRuntime
var _spawn_registry: MissionSpawnRegistry
var _mission_presentation: MissionPresentation
var _world_builder: MountHoodWorldBuilder
var _route_recovery_timer: Timer
var _completion_timer: Timer
var _last_combat_zone: StringName = &""
var _resetting_encounter := false
var _baseline_attack_budget := 3


func _ready() -> void:
	_run_started_ms = Time.get_ticks_msec()
	_apply_requested_checkpoint()
	_setup_runtime()
	_build_world()
	_restore_runtime_state()
	if spawn_player: _spawn_player()
	if setup_presentation: _setup_presentation()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null: game_state.begin_run(metadata.level_id)
	narrative_message.emit("EPISODE 1, MISSION 3: MOUNT HOOD WHITEOUT\nPUBLIC BETA", 4.0)
	level_ready.emit(player)
	var announced := _mission_runtime.announce_available_objectives()
	if announced.is_empty(): objective_changed.emit(metadata.opening_objective)
	if is_instance_valid(player): _submit_route_position(player.global_position)


func _setup_runtime() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	var game_state := get_node_or_null("/root/GameState")
	var difficulty := StringName(game_state.difficulty_id) if game_state != null else &"classic"
	_baseline_attack_budget = 2 if difficulty == &"story" else (4 if difficulty == &"mayhem" else 3)
	if pressure != null: pressure.configure_limit(_baseline_attack_budget)
	var assembly := MissionRuntimeAssembly.create(self, content_manifest, _spawn_scene)
	_spawn_registry = assembly.registry
	_mission_runtime = assembly.runtime
	_route_recovery_timer = assembly.route_timer
	_completion_timer = assembly.completion_timer
	_route_runtime = _mission_runtime.route
	if _route_runtime != null:
		_mission_runtime.zone_entered.connect(_on_route_zone_entered)
		_mission_runtime.checkpoint_available.connect(_on_route_checkpoint_available)


func _build_world() -> void:
	_world_builder = MountHoodWorldBuilder.new(); _world_builder.name = "MountHoodWorldBuilder"
	_world_builder.on_zone_entered = _on_world_zone_entered
	_world_builder.on_checkpoint_activated = _on_world_checkpoint
	_world_builder.on_objective_action = _on_world_objective_action
	_world_builder.on_narrative_message = narrative_message.emit
	_world_builder.on_golden_ball_claimed = _on_golden_ball_claimed
	_world_builder.build_navigation = build_navigation
	add_child(_world_builder)
	if not _world_builder.build(self): push_error("Mount Hood world builder failed"); return
	_spawn_registry.actor_parent = _world_builder.actors
	_sync_route_gates()


func _spawn_player() -> void:
	player = _spawn_scene(PLAYER_SCENE, checkpoint_position) as Node3D
	if not player is CobiePlayer: return
	var cobie := player as CobiePlayer
	cobie.health_armor.grant_invulnerability(opening_protection_seconds)
	if metadata.mission_loadout != null: cobie.apply_mission_loadout(metadata.mission_loadout, _restored_checkpoint)
	RainCityCheckpointState.restore_player_state(cobie, _restored_checkpoint)
	for weapon in cobie.weapons:
		if weapon is FetchLauncher: (weapon as FetchLauncher).apply_municipal_recall_override()
	cobie.died.connect(_on_player_died)
	cobie.restart_requested.connect(restart_from_checkpoint)


func _setup_presentation() -> void:
	_mission_presentation = MissionPresentation.new(); _mission_presentation.name = "MissionPresentation"; add_child(_mission_presentation)
	_mission_presentation.configure(self, content_manifest, _world_builder.actors, _mission_runtime.encounters, _mission_runtime, player, get_node_or_null("/root/GameState"), &"forest_pullout", &"summit", {}, "MUNICIPAL SNOWCAT // OFF-LEASH SUMMIT")
	_mission_presentation.bind_restart_requests(restart_from_checkpoint)


func _apply_requested_checkpoint() -> void:
	var restored := RainCityCheckpointState.consume_requested(metadata, CONTENT_REVISION, CHECKPOINT_POSITIONS, get_node_or_null("/root/GameState"), get_node_or_null("/root/SaveManager"))
	if restored.is_empty(): return
	_restored_checkpoint = restored.payload
	checkpoint_position = restored.position


func _restore_runtime_state() -> void:
	var restored := RainCityCheckpointState.restore(_restored_checkpoint, _mission_runtime, _route_runtime, content_manifest.route_definition)
	if restored.is_empty(): return
	secrets = restored.secrets
	current_zone = restored.current_zone
	_sync_route_gates()
	if _mission_runtime.objectives.completed.has(&"restart_chairlift") and _world_builder.chairlift != null:
		_world_builder.chairlift.set_enabled(true)
	# Encounter snapshots intentionally do not resurrect actors. Convert any
	# restored in-progress marker back to a clean zone and activate it exactly once.
	if current_zone != &"" and not _mission_runtime.encounters.completed.has(current_zone):
		_last_combat_zone = current_zone
		_mission_runtime.reset_zone(current_zone)
		if current_zone != &"summit" or _mission_runtime.objectives.completed.has(&"disable_summit_relay"):
			_activate_zone_encounter(current_zone)


func _poll_route_position() -> void:
	if is_instance_valid(player): _submit_route_position(player.global_position)
func _submit_route_position(value: Vector3) -> void: _mission_runtime.submit_actor_position(value)
func _on_world_zone_entered(_id: StringName, _title: String, actor: Node) -> void:
	if actor is Node3D: _submit_route_position((actor as Node3D).global_position)


func _on_route_zone_entered(zone_id: StringName, title: String) -> void:
	if current_zone == zone_id: return
	current_zone = zone_id; zone_entered.emit(zone_id, title); narrative_message.emit(title, 2.0)
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.REACH_ZONE, zone_id)
	# The summit relay is an authored pre-boss objective. Delaying encounter
	# activation prevents the Snowcat from dying before its objective becomes
	# active, which would otherwise deadlock the mission.
	if zone_id != &"summit" or _mission_runtime.objectives.completed.has(&"disable_summit_relay"):
		_activate_zone_encounter(zone_id)


func _activate_zone_encounter(zone_id: StringName) -> void:
	if _mission_runtime.encounters == null or not _mission_runtime.encounters.definitions.has(zone_id): return
	if _mission_runtime.encounters.completed.has(zone_id) or _mission_runtime.encounters.active.has(zone_id): return
	_world_builder.set_route_gate_open(zone_id, false)
	_last_combat_zone = zone_id
	var definition := _mission_runtime.encounters.definitions[zone_id] as EncounterDefinition
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null: pressure.configure_limit(mini(_baseline_attack_budget, definition.maximum_simultaneous_attackers))
	_spawn_registry.prepare_encounter(definition, _resetting_encounter)
	_mission_runtime.activate_zone(zone_id, player)
	_spawn_registry.mark_zone_spawned(zone_id)


func _on_route_checkpoint_available(id: StringName, _zone: StringName) -> void:
	_save_checkpoint(id, CHECKPOINT_POSITIONS.get(id, checkpoint_position))
func _on_world_checkpoint(id: StringName, respawn: Vector3) -> void:
	if not _mission_runtime.activate_checkpoint(id) and id == _route_runtime.current_checkpoint_id: checkpoint_position = respawn


func _save_checkpoint(id: StringName, at: Vector3, announce := true) -> Error:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null: return ERR_UNCONFIGURED
	var runtime_snapshot := _mission_runtime.snapshot()
	var game_state := get_node_or_null("/root/GameState")
	var mission_upgrades: Array[StringName] = [MUNICIPAL_RECALL_OVERRIDE]
	var loadout: Dictionary = player.mission_loadout_snapshot(metadata.level_id, mission_upgrades) if player is CobiePlayer else {}
	var player_state := {"health": player.health_armor.health, "armor": player.health_armor.armor} if player is CobiePlayer else {}
	var payload := RainCityCheckpointState.build_payload("res://scenes/levels/mount_hood_whiteout.tscn", metadata, id, CONTENT_REVISION, at, game_state.difficulty_id if game_state != null else &"classic", runtime_snapshot, _route_runtime.snapshot(), secrets, loadout, player_state)
	var error: Error = manager.save_slot(&"checkpoint", payload)
	if error != OK: return error
	checkpoint_position = at
	if announce:
		checkpoint_activated.emit(id, at); narrative_message.emit("CHECKPOINT: PAWS WARMED.", 2.0)
		if _mission_presentation != null: _mission_presentation.on_checkpoint_caption("CHECKPOINT: PAWS WARMED.")
	return OK


func restart_from_checkpoint() -> void:
	if _mission_presentation != null: _mission_presentation.reset_for_checkpoint()
	get_tree().call_group(&"boss_summons", &"queue_free")
	if _world_builder != null: _world_builder.reset_chairlift()
	if _last_combat_zone != &"":
		_spawn_registry.clear_zone(_last_combat_zone); _resetting_encounter = true
		_mission_runtime.reset_zone(_last_combat_zone); _activate_zone_encounter(_last_combat_zone); _resetting_encounter = false
	if player is CobiePlayer: (player as CobiePlayer).respawn(checkpoint_position, opening_protection_seconds)


func _on_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	_spawn_registry.register_encounter_actor(enemy, definition, _resetting_encounter); enemy_spawned.emit(enemy, definition.zone_id)
	enemies_total = _spawn_registry.enemies_total
	if enemy is MunicipalSnowcat:
		var boss := enemy as MunicipalSnowcat
		boss.damaged.connect(_on_boss_damaged.bind(boss))
		boss.boss_phase_changed.connect(_on_boss_phase_changed)
	if _mission_presentation != null: _mission_presentation.bind_warning_enemy(enemy)


func _on_actor_defeated(enemy: Node, definition: EncounterDefinition) -> void:
	enemies_defeated = _spawn_registry.record_enemy_defeat(); enemy_defeated.emit(enemy, definition.zone_id)
	if enemy is EnemyAgent and (enemy as EnemyAgent).definition != null:
		_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, (enemy as EnemyAgent).definition.id)


func _on_boss_damaged(_amount: float, _source: Node, _hit: Vector3, boss: MunicipalSnowcat) -> void:
	boss_state_changed.emit(_boss_phase_label(boss.boss_phase), boss.health_fraction())
func _on_boss_phase_changed(_previous: AnimalControlWalker.BossPhase, current: AnimalControlWalker.BossPhase) -> void:
	var labels := ["ROAD CLOSED", "WHITEOUT WARNING", "CHAINS REQUIRED", "OFF-LEASH SUMMIT", "DESTROYED"]
	var label: String = labels[clampi(int(current), 0, labels.size() - 1)]
	boss_phase_caption.emit(label, 2.4); boss_state_changed.emit(label, 0.0 if current == AnimalControlWalker.BossPhase.DEFEATED else 1.0)
func _boss_phase_label(phase: AnimalControlWalker.BossPhase) -> String:
	return ["ROAD CLOSED", "WHITEOUT WARNING", "CHAINS REQUIRED", "OFF-LEASH SUMMIT", "DESTROYED"][clampi(int(phase), 0, 4)]


func _on_encounter_completed(definition: EncounterDefinition) -> void:
	_spawn_registry.finish_encounter(definition.zone_id); _world_builder.set_route_gate_open(definition.zone_id, true)
	if definition.zone_id == &"summit":
		_last_combat_zone = &""
		get_tree().call_group(&"boss_summons", &"queue_free")
		# Queue-free completes at the end of this frame. Release the reward on the
		# following frame so no living summon can overlap the post-boss objective.
		_finish_summit_defeat.call_deferred()


func _finish_summit_defeat() -> void:
	if _completion_started or _world_builder == null: return
	_world_builder.enable_golden_ball()
	boss_state_changed.emit("DESTROYED", 0.0)
	narrative_message.emit("SNOWCAT DESTROYED // GOLDEN BALL RELEASED", 3.2)
func _on_encounter_failed(definition: EncounterDefinition, reason: String) -> void:
	_spawn_registry.finish_encounter(definition.zone_id); _spawn_registry.clear_zone(definition.zone_id)
	_world_builder.set_route_gate_open(definition.zone_id, false)
	narrative_message.emit("ENCOUNTER DEPLOYMENT FAILED // RETRY CHECKPOINT (%s)" % reason, 4.0)


func _sync_route_gates() -> void:
	for id in [&"forest_pullout", &"mountain_road", &"snowbound_lodge", &"service_tunnels"]:
		_world_builder.set_route_gate_open(id, _mission_runtime.encounters.completed.has(id))


func _on_world_objective_action(kind: ObjectiveDefinition.Kind, id: StringName) -> void:
	if String(id).begins_with("secret_"):
		_record_secret(id); return
	_mission_runtime.record_objective(kind, id)
	if id == &"summit_relay" and _mission_runtime.objectives.completed.has(&"disable_summit_relay"):
		_activate_zone_encounter(&"summit")
func _on_objective_activated(definition: ObjectiveDefinition) -> void: objective_changed.emit(definition.title)
func _on_objective_completed(definition: ObjectiveDefinition) -> void:
	if definition.id in [&"restore_lodge_power", &"restart_chairlift", &"disable_summit_relay"]:
		var checkpoint_id := _route_runtime.current_checkpoint_id if _route_runtime != null else &"checkpoint_forest_start"
		_save_checkpoint(checkpoint_id, CHECKPOINT_POSITIONS.get(checkpoint_id, checkpoint_position))
	if definition.id == &"complete_mount_hood": _begin_completion()


func _record_secret(id: StringName) -> void:
	if secrets.has(id): return
	var titles := {&"secret_snowman_nose": "COLD NOSE CACHE", &"secret_treat_pantry": "TREAT PANTRY", &"secret_service_valves": "VALVE ZOOMIES", &"secret_good_dog_seat": "GOOD-DOG CHAIR"}
	var title: String = titles.get(id, "WHITEOUT SECRET")
	secrets[id] = title
	if player is CobiePlayer:
		(player as CobiePlayer).heal(35.0); (player as CobiePlayer).add_armor(20.0); (player as CobiePlayer).add_ammo("fetch", 2)
	secret_found.emit(id, title, secrets.size(), metadata.total_secrets); narrative_message.emit("SECRET FOUND: %s (%d/%d)" % [title, secrets.size(), metadata.total_secrets], 3.0)


func _on_golden_ball_claimed(_actor: Node) -> void:
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.COMPLETE_LEVEL, &"golden_tennis_ball")


func _begin_completion() -> void:
	if _completion_started: return
	_completion_started = true; _completion_summary = get_level_summary()
	var manager := get_node_or_null("/root/SaveManager")
	var game_state := get_node_or_null("/root/GameState")
	var difficulty: StringName = game_state.difficulty_id if game_state != null else &"classic"
	var error := _mission_runtime.record_campaign_completion(metadata.level_id, _completion_summary, manager, difficulty, [], [MUNICIPAL_RECALL_OVERRIDE])
	if error != OK: _completion_started = false; narrative_message.emit("CAMPAIGN SAVE FAILED // FETCH BALL TO RETRY", 4.0); return
	var checkpoint_error: Error = manager.delete_slot(&"checkpoint")
	if checkpoint_error != OK:
		# Campaign completion is already durable. Continue to victory rather than
		# trapping the player, but make the storage failure explicit and ensure the
		# stale checkpoint is never silently represented as a clean completion.
		_completion_summary["checkpoint_cleanup_error"] = checkpoint_error
		push_error("Mount Hood checkpoint cleanup failed: %s" % error_string(checkpoint_error))
		narrative_message.emit("RUN SECURED // CHECKPOINT CLEANUP FAILED", 4.0)
	else:
		narrative_message.emit("MOUNT HOOD: OFF-LEASH SUMMIT SECURED.", 4.0)
	_completion_timer.start()


func _finalize_completion() -> void:
	level_completed.emit(_completion_summary); var game_state := get_node_or_null("/root/GameState"); if game_state != null: game_state.finish_run(_completion_summary)
func _on_player_died(_source: Node) -> void: narrative_message.emit("GOOD DOG DOWN // FIRE TO RETRY", 3.0)
func _on_pickup_collected(message: String) -> void: narrative_message.emit(message, 2.0)
func _spawn_scene(path: String, at: Vector3) -> Node: return _spawn_registry.spawn_scene(path, at)


func get_level_summary() -> Dictionary:
	return {"level_id": metadata.level_id, "title": metadata.title, "completion_time_msec": Time.get_ticks_msec() - _run_started_ms, "enemies_defeated": enemies_defeated, "enemies_total": enemies_total, "secrets_found": secrets.size(), "secrets_total": metadata.total_secrets, "victory_line": "MOUNT HOOD: OFF-LEASH SUMMIT SECURED."}


func _exit_tree() -> void:
	if _route_recovery_timer != null: _route_recovery_timer.stop()
	if _completion_timer != null: _completion_timer.stop()
	get_tree().call_group(&"boss_summons", &"queue_free")
