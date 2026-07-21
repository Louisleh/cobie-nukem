class_name BiomeMissionController
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

@export var metadata: LevelMetadata
@export var content_manifest: ContentManifest
@export var biome_profile: BiomeMissionProfile
@export var spawn_player := true
@export var setup_presentation := true
@export var build_navigation := true
@export var opening_protection_seconds := 8.0

var player: Node3D
var current_zone: StringName = &""
var checkpoint_position := Vector3.ZERO
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
var _world_builder: BiomeMissionWorldBuilder
var _route_recovery_timer: Timer
var _completion_timer: Timer
var _last_combat_zone: StringName = &""
var _resetting_encounter := false
var _baseline_attack_budget := 3


func _ready() -> void:
	if not _validate_configuration(): return
	_run_started_ms = Time.get_ticks_msec()
	checkpoint_position = biome_profile.checkpoint_positions().get(biome_profile.first_checkpoint_id(), Vector3.ZERO)
	_initialize_runtime_and_player(get_node_or_null("/root/GameState"))
	narrative_message.emit(biome_profile.intro_message, 4.0); level_ready.emit(player)
	var announced := _mission_runtime.announce_available_objectives()
	if announced.is_empty(): objective_changed.emit(metadata.opening_objective)
	if is_instance_valid(player): _submit_route_position(player.global_position)


func _initialize_runtime_and_player(game_state: Node) -> void:
	_apply_requested_checkpoint()
	if game_state != null:
		_start_or_restore_progression(game_state)
	_setup_runtime()
	_build_world(); _restore_runtime_state()
	if spawn_player: _spawn_player()
	if setup_presentation: _setup_presentation()


func _start_or_restore_progression(game_state: Node) -> void:
	game_state.begin_run(metadata.level_id)
	RainCityCheckpointState.restore_progression_state(_restored_checkpoint, game_state)


func _validate_configuration() -> bool:
	if metadata == null or content_manifest == null or biome_profile == null:
		push_error("BiomeMissionController missing metadata, manifest, or profile"); return false
	var errors := biome_profile.validate(); errors.append_array(content_manifest.validate())
	if biome_profile.mission_id != metadata.level_id or content_manifest.level_id != metadata.level_id:
		errors.append("biome mission identity mismatch")
	if not errors.is_empty():
		for error in errors: push_error(error)
		return false
	return true


func _setup_runtime() -> void:
	var pressure := get_node_or_null("/root/CombatPressure"); var game_state := get_node_or_null("/root/GameState")
	var difficulty := StringName(game_state.difficulty_id) if game_state != null else &"classic"
	_baseline_attack_budget = 2 if difficulty == &"story" else (4 if difficulty == &"mayhem" else 3)
	if pressure != null: pressure.configure_limit(_baseline_attack_budget)
	var assembly := MissionRuntimeAssembly.create(self, content_manifest, _spawn_scene)
	_spawn_registry = assembly.registry; _mission_runtime = assembly.runtime; _route_recovery_timer = assembly.route_timer; _completion_timer = assembly.completion_timer
	_route_runtime = _mission_runtime.route
	if _route_runtime != null:
		_mission_runtime.zone_entered.connect(_on_route_zone_entered); _mission_runtime.checkpoint_available.connect(_on_route_checkpoint_available)


func _build_world() -> void:
	_world_builder = BiomeMissionWorldBuilder.new(); _world_builder.name = "BiomeMissionWorldBuilder"
	_world_builder.on_zone_entered = _on_world_zone_entered; _world_builder.on_checkpoint_activated = _on_world_checkpoint
	_world_builder.on_objective_action = _on_world_objective_action; _world_builder.on_narrative_message = narrative_message.emit
	_world_builder.on_golden_ball_claimed = _on_golden_ball_claimed; _world_builder.build_navigation = build_navigation; add_child(_world_builder)
	if not _world_builder.build(self, biome_profile): push_error("Biome mission world build failed"); return
	_spawn_registry.actor_parent = _world_builder.actors; _sync_route_gates()


func _spawn_player() -> void:
	player = _spawn_scene(PLAYER_SCENE, checkpoint_position) as Node3D
	if not player is CobiePlayer: return
	var cobie := player as CobiePlayer; cobie.health_armor.grant_invulnerability(opening_protection_seconds)
	cobie.configure_movement_environment(biome_profile.movement_environment)
	if metadata.mission_loadout != null: cobie.apply_mission_loadout(metadata.mission_loadout, _restored_checkpoint)
	RainCityCheckpointState.restore_player_state(cobie, _restored_checkpoint)
	for weapon in cobie.weapons:
		if weapon is FetchLauncher: (weapon as FetchLauncher).apply_municipal_recall_override()
	cobie.died.connect(_on_player_died); cobie.restart_requested.connect(restart_from_checkpoint)


func _setup_presentation() -> void:
	_mission_presentation = MissionPresentation.new(); _mission_presentation.name = "MissionPresentation"; add_child(_mission_presentation)
	_mission_presentation.configure(self, content_manifest, _world_builder.actors, _mission_runtime.encounters, _mission_runtime, player, get_node_or_null("/root/GameState"), biome_profile.starting_zone_id, biome_profile.boss_zone_id, {}, biome_profile.boss_display_name)
	_mission_presentation.bind_restart_requests(restart_from_checkpoint)


func _apply_requested_checkpoint() -> void:
	var restored := RainCityCheckpointState.consume_requested(metadata, biome_profile.content_revision, biome_profile.checkpoint_positions(), get_node_or_null("/root/GameState"), get_node_or_null("/root/SaveManager"))
	if restored.is_empty(): return
	_restored_checkpoint = restored.payload; checkpoint_position = restored.position


func _restore_runtime_state() -> void:
	var restored := RainCityCheckpointState.restore(_restored_checkpoint, _mission_runtime, _route_runtime, content_manifest.route_definition)
	if restored.is_empty(): return
	secrets = restored.secrets; current_zone = restored.current_zone
	_sync_route_gates()
	# Active encounter snapshots carry deterministic progress markers, not live
	# nodes. Rebuild the current unfinished encounter exactly once after restore.
	if current_zone != &"" and not _mission_runtime.encounters.completed.has(current_zone):
		_last_combat_zone = current_zone
		_mission_runtime.reset_zone(current_zone)
		if current_zone != biome_profile.boss_zone_id or _mission_runtime.objectives.completed.has(_boss_prerequisite_objective_id()):
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
	if zone_id != biome_profile.boss_zone_id or _mission_runtime.objectives.completed.has(_boss_prerequisite_objective_id()):
		_activate_zone_encounter(zone_id)


func _boss_prerequisite_objective_id() -> StringName:
	for definition in content_manifest.objectives:
		if definition.kind == ObjectiveDefinition.Kind.DEFEAT and definition.target_id == biome_profile.boss_enemy_id and not definition.prerequisite_ids.is_empty():
			return definition.prerequisite_ids[-1]
	return &""


func _activate_zone_encounter(zone_id: StringName) -> void:
	if _mission_runtime.encounters == null or not _mission_runtime.encounters.definitions.has(zone_id): return
	if _mission_runtime.encounters.completed.has(zone_id) or _mission_runtime.encounters.active.has(zone_id): return
	_world_builder.set_route_gate_open(zone_id, false); _last_combat_zone = zone_id
	var definition := _mission_runtime.encounters.definitions[zone_id] as EncounterDefinition; var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null: pressure.configure_limit(mini(_baseline_attack_budget, definition.maximum_simultaneous_attackers))
	_spawn_registry.prepare_encounter(definition, _resetting_encounter); _mission_runtime.activate_zone(zone_id, player); _spawn_registry.mark_zone_spawned(zone_id)


func _on_route_checkpoint_available(id: StringName, _zone: StringName) -> void:
	_save_checkpoint(id, biome_profile.checkpoint_positions().get(id, checkpoint_position))
func _on_world_checkpoint(id: StringName, respawn: Vector3) -> void:
	if not _mission_runtime.activate_checkpoint(id) and id == _route_runtime.current_checkpoint_id: checkpoint_position = respawn


func _save_checkpoint(id: StringName, at: Vector3, announce := true) -> Error:
	var boss_active := _mission_runtime != null and _mission_runtime.encounters != null and _mission_runtime.encounters.active.has(biome_profile.boss_zone_id)
	if not RainCityCheckpointState.checkpoint_write_allowed(boss_active): return ERR_BUSY
	var manager := get_node_or_null("/root/SaveManager"); if manager == null: return ERR_UNCONFIGURED
	var game_state := get_node_or_null("/root/GameState"); var runtime_snapshot := _mission_runtime.snapshot()
	var loadout: Dictionary = player.mission_loadout_snapshot(metadata.level_id, biome_profile.permanent_upgrade_ids) if player is CobiePlayer else {}
	var player_state := {"health": player.health_armor.health, "armor": player.health_armor.armor} if player is CobiePlayer else {}
	var payload := RainCityCheckpointState.build_payload(metadata.replay_scene, metadata, id, biome_profile.content_revision, at, game_state.difficulty_id if game_state != null else &"classic", runtime_snapshot, _route_runtime.snapshot(), secrets, loadout, player_state)
	var error: Error = manager.save_slot(&"checkpoint", payload); if error != OK: return error
	checkpoint_position = at
	if announce:
		checkpoint_activated.emit(id, at); narrative_message.emit("CHECKPOINT SECURED.", 2.0)
		if _mission_presentation != null: _mission_presentation.on_checkpoint_caption("CHECKPOINT SECURED.")
	return OK


func restart_from_checkpoint() -> void:
	if _mission_presentation != null: _mission_presentation.reset_for_checkpoint()
	get_tree().call_group(&"boss_summons", &"queue_free")
	if _last_combat_zone != &"":
		_spawn_registry.clear_zone(_last_combat_zone); _resetting_encounter = true; _mission_runtime.reset_zone(_last_combat_zone); _activate_zone_encounter(_last_combat_zone); _resetting_encounter = false
	if player is CobiePlayer: (player as CobiePlayer).respawn(checkpoint_position, opening_protection_seconds)


func _on_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	_spawn_registry.register_encounter_actor(enemy, definition, _resetting_encounter); enemy_spawned.emit(enemy, definition.zone_id); enemies_total = _spawn_registry.enemies_total
	if enemy is AnimalControlWalker:
		var boss := enemy as AnimalControlWalker; boss.damaged.connect(_on_boss_damaged.bind(boss)); boss.boss_phase_changed.connect(_on_boss_phase_changed)
	if _mission_presentation != null: _mission_presentation.bind_warning_enemy(enemy)


func _on_actor_defeated(enemy: Node, definition: EncounterDefinition) -> void:
	enemies_defeated = _spawn_registry.record_enemy_defeat(); enemy_defeated.emit(enemy, definition.zone_id)
	if enemy is AnimalControlWalker and definition.zone_id == biome_profile.boss_zone_id:
		_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, biome_profile.boss_enemy_id)
		return
	if enemy is EnemyAgent and (enemy as EnemyAgent).definition != null:
		_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, (enemy as EnemyAgent).definition.id)


func _on_boss_damaged(_amount: float, _source: Node, _hit: Vector3, boss: AnimalControlWalker) -> void:
	boss_state_changed.emit(_boss_phase_label(boss.boss_phase), boss.health_fraction())
func _on_boss_phase_changed(_previous: AnimalControlWalker.BossPhase, current: AnimalControlWalker.BossPhase) -> void:
	var label := _boss_phase_label(current); boss_phase_caption.emit(label, 2.4); boss_state_changed.emit(label, 0.0 if current == AnimalControlWalker.BossPhase.DEFEATED else 1.0)
func _boss_phase_label(phase: AnimalControlWalker.BossPhase) -> String:
	var labels: Array = _profile_phase_labels()
	return String(labels[clampi(int(phase), 0, labels.size() - 1)])
func _profile_phase_labels() -> Array:
	return biome_profile.environment.get("boss_phase_labels", ["PHASE ONE", "PHASE TWO", "PHASE THREE", "FINAL CORE", "DESTROYED"])


func _on_encounter_completed(definition: EncounterDefinition) -> void:
	_spawn_registry.finish_encounter(definition.zone_id); _world_builder.set_route_gate_open(definition.zone_id, true)
	if definition.zone_id == biome_profile.boss_zone_id:
		_last_combat_zone = &""; get_tree().call_group(&"boss_summons", &"queue_free"); _finish_boss_defeat.call_deferred()
func _finish_boss_defeat() -> void:
	if _completion_started or _world_builder == null: return
	_world_builder.enable_golden_ball(); boss_state_changed.emit("DESTROYED", 0.0); narrative_message.emit("%s DESTROYED // GOLDEN BALL RELEASED" % biome_profile.boss_display_name, 3.2)
func _on_encounter_failed(definition: EncounterDefinition, reason: String) -> void:
	_spawn_registry.finish_encounter(definition.zone_id); _spawn_registry.clear_zone(definition.zone_id)
	_world_builder.set_route_gate_open(definition.zone_id, false)
	narrative_message.emit("ENCOUNTER DEPLOYMENT FAILED // RETRY CHECKPOINT (%s)" % reason, 4.0)


func _sync_route_gates() -> void:
	for zone in biome_profile.zones.slice(0, biome_profile.zones.size() - 1):
		_world_builder.set_route_gate_open(StringName(zone.id), _mission_runtime.encounters.completed.has(StringName(zone.id)))


func _on_world_objective_action(kind: ObjectiveDefinition.Kind, id: StringName) -> void:
	if String(id).begins_with("secret_"): _record_secret(id); return
	_mission_runtime.record_objective(kind, id)
	if id == biome_profile.final_activation_target and _mission_runtime.objectives.completed.has(_boss_prerequisite_objective_id()): _activate_zone_encounter(biome_profile.boss_zone_id)
func _on_objective_activated(definition: ObjectiveDefinition) -> void: objective_changed.emit(definition.title)
func _on_objective_completed(definition: ObjectiveDefinition) -> void:
	if definition.kind == ObjectiveDefinition.Kind.ACTIVATE:
		var checkpoint_id := _route_runtime.current_checkpoint_id if _route_runtime != null else biome_profile.first_checkpoint_id()
		_save_checkpoint(checkpoint_id, biome_profile.checkpoint_positions().get(checkpoint_id, checkpoint_position))
	if definition.kind == ObjectiveDefinition.Kind.COMPLETE_LEVEL: _begin_completion()


func _record_secret(id: StringName) -> void:
	if secrets.has(id): return
	var title := biome_profile.secret_title(id); secrets[id] = title
	if player is CobiePlayer: (player as CobiePlayer).heal(35.0); (player as CobiePlayer).add_armor(20.0); (player as CobiePlayer).add_ammo("fetch", 2)
	secret_found.emit(id, title, secrets.size(), metadata.total_secrets); narrative_message.emit("SECRET FOUND: %s (%d/%d)" % [title, secrets.size(), metadata.total_secrets], 3.0)


func _on_golden_ball_claimed(_actor: Node) -> void:
	if _world_builder == null or _world_builder.golden_ball == null or not _world_builder.golden_ball.enabled:
		narrative_message.emit("GOLDEN BALL CONTAINMENT ACTIVE // BOSS STILL ONLINE", 2.0)
		return
	var boss_objective := &""
	for definition in content_manifest.objectives:
		if definition.kind == ObjectiveDefinition.Kind.DEFEAT and definition.target_id == biome_profile.boss_enemy_id:
			boss_objective = definition.id
			break
	if boss_objective == &"" or not _mission_runtime.objectives.completed.has(boss_objective):
		narrative_message.emit("GOLDEN BALL CONTAINMENT ACTIVE // BOSS STILL ONLINE", 2.0)
		return
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.COMPLETE_LEVEL, &"golden_tennis_ball")


func _begin_completion() -> void:
	if _completion_started: return
	_completion_started = true; _completion_summary = get_level_summary()
	var manager := get_node_or_null("/root/SaveManager"); var game_state := get_node_or_null("/root/GameState")
	var difficulty: StringName = game_state.difficulty_id if game_state != null else &"classic"
	var error := _mission_runtime.record_campaign_completion(metadata.level_id, _completion_summary, manager, difficulty, biome_profile.campaign_unlock_ids, biome_profile.permanent_upgrade_ids)
	if error != OK: _completion_started = false; narrative_message.emit("CAMPAIGN SAVE FAILED // FETCH BALL TO RETRY", 4.0); return
	var checkpoint_error: Error = manager.delete_slot(&"checkpoint")
	if checkpoint_error != OK: push_error("Checkpoint cleanup failed: %s" % error_string(checkpoint_error))
	narrative_message.emit(biome_profile.victory_line, 4.0); _completion_timer.start()


func _finalize_completion() -> void:
	level_completed.emit(_completion_summary); var game_state := get_node_or_null("/root/GameState"); if game_state != null: game_state.finish_run(_completion_summary)
func _on_player_died(_source: Node) -> void: narrative_message.emit("GOOD DOG DOWN // FIRE TO RETRY", 3.0)
func _on_pickup_collected(message: String) -> void: narrative_message.emit(message, 2.0)
func _spawn_scene(path: String, at: Vector3) -> Node: return _spawn_registry.spawn_scene(path, at)
func get_level_summary() -> Dictionary:
	return {"level_id": metadata.level_id, "title": metadata.title, "completion_time_msec": Time.get_ticks_msec() - _run_started_ms, "enemies_defeated": enemies_defeated, "enemies_total": enemies_total, "secrets_found": secrets.size(), "secrets_total": metadata.total_secrets, "victory_line": biome_profile.victory_line}
func _exit_tree() -> void:
	if _route_recovery_timer != null: _route_recovery_timer.stop()
	if _completion_timer != null: _completion_timer.stop()
	get_tree().call_group(&"boss_summons", &"queue_free")
