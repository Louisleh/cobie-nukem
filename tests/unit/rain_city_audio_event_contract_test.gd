extends SceneTree

const VANCOUVER_MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres")
const GULL_SCENE := preload("res://scenes/enemies/compliance_gull.tscn")
const ENFORCER_SCENE := preload("res://scenes/enemies/umbrella_shield_enforcer.tscn")
const CONVOY_SCENE := preload("res://scenes/set_pieces/citation_convoy.tscn")


class FakeLevel extends Node:
	signal zone_entered(zone_id: StringName, title: String)
	signal narrative_message(text: String, duration: float)
	signal objective_changed(text: String)
	signal secret_found(secret_id: StringName, title: String, found: int, total: int)


class RecordingRouter extends MissionEnemyCueRouter:
	var events: Array[Dictionary] = []

	func play_at(cue_id: StringName, world_position: Vector3) -> bool:
		events.append({"cue_id": cue_id, "position": world_position})
		return true


class RecordingPresentation extends MissionPresentation:
	var spatial_cues: Array[StringName] = []

	func play_spatial_cue(cue_id: StringName, _world_position: Vector3) -> bool:
		spatial_cues.append(cue_id)
		return true


class RecordingMissionRuntime extends MissionRuntime:
	var objective_ids: Array[StringName] = []
	var checkpoint_ids: Array[StringName] = []

	func record_objective(_kind: ObjectiveDefinition.Kind, target_id: StringName, _amount := 1) -> Array[StringName]:
		objective_ids.append(target_id)
		return []

	func activate_checkpoint(checkpoint_id: StringName) -> bool:
		checkpoint_ids.append(checkpoint_id)
		return true


var failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_mission_state_and_ambience_routes()
	await _test_hero_enemy_cue_routes()
	await _test_convoy_cue_routes()
	if failures.is_empty():
		print("RAIN CITY AUDIO EVENT CONTRACT TEST: PASS")
		await _finish(0)
	else:
		for failure in failures:
			push_error(failure)
		await _finish(1)


func _test_mission_state_and_ambience_routes() -> void:
	var level := FakeLevel.new()
	var actors := Node.new()
	actors.name = "Actors"
	level.add_child(actors)
	root.add_child(level)
	var presentation := MissionPresentation.new()
	root.add_child(presentation)
	presentation._create_presentation_nodes()
	presentation.get_audio_director().playback_enabled = false
	_expect(presentation.configure(
		level,
		VANCOUVER_MANIFEST,
		actors,
		null,
		null,
		null,
		null,
		&"downtown_alley",
		&"harbour_pier"
	), "Vancouver mission presentation configures with its authored content manifest")
	var director := presentation.get_audio_director()
	_expect(director.current_state() == &"exploration", "Vancouver mission initializes exploration state")
	_expect(director.current_music_cue() == &"vancouver_music_exploration", "exploration event resolves to Vancouver exploration music")
	_expect(director.current_ambience_cue() == &"vancouver_ambience_dock", "downtown route resolves to Vancouver dock ambience")

	presentation.on_zone_entered(&"terminal_service", "RAINLINE TERMINAL")
	_expect(director.current_ambience_cue() == &"vancouver_ambience_terminal", "terminal zone event resolves to Vancouver terminal ambience")
	var terminal_encounter := _definition(&"terminal_service")
	presentation.on_encounter_started(terminal_encounter)
	_expect(director.current_state() == &"tension" and director.current_music_cue() == &"vancouver_music_tension", "encounter start resolves to Vancouver tension music")
	var enemy := Node.new()
	presentation.on_actor_spawned(enemy, terminal_encounter)
	_expect(director.current_state() == &"combat" and director.current_music_cue() == &"vancouver_music_combat", "active current-zone actor resolves to Vancouver combat music")
	presentation.on_encounter_completed(terminal_encounter)
	_expect(director.current_state() == &"exploration" and director.current_music_cue() == &"vancouver_music_exploration", "encounter completion restores Vancouver exploration music")
	var boss_encounter := _definition(&"harbour_pier")
	presentation.on_encounter_started(boss_encounter)
	_expect(director.current_state() == &"boss" and director.current_music_cue() == &"vancouver_music_boss", "harbour boss event resolves to Vancouver boss music")
	presentation.on_level_completed({})
	_expect(director.current_state() == &"victory" and director.current_music_cue() == &"vancouver_music_victory", "mission completion resolves to Vancouver victory music")

	enemy.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_hero_enemy_cue_routes() -> void:
	var router := RecordingRouter.new()
	root.add_child(router)
	var target := Node3D.new()
	root.add_child(target)
	var gull := GULL_SCENE.instantiate() as ComplianceGull
	var enforcer := ENFORCER_SCENE.instantiate() as UmbrellaShieldEnforcer
	gull.process_mode = Node.PROCESS_MODE_DISABLED
	enforcer.process_mode = Node.PROCESS_MODE_DISABLED
	gull.position = Vector3(3.0, 4.0, 5.0)
	enforcer.position = Vector3(-3.0, 1.0, -5.0)
	root.add_child(gull)
	root.add_child(enforcer)
	await process_frame
	router.bind_enemy(gull)
	router.bind_enemy(enforcer)
	_expect(router.bound_enemy_count() == 2, "Rain City cue router binds both hero enemy implementations")

	gull.target_marked.emit(target, gull.mark_duration)
	gull.attack_fired.emit(&"gull_mark_dive")
	gull.dive_interrupted.emit()
	gull.died.emit(gull, null)
	enforcer.guard_state_changed.emit(UmbrellaShieldEnforcer.GuardState.DISABLED, UmbrellaShieldEnforcer.GuardState.GUARDING)
	enforcer.guard_state_changed.emit(UmbrellaShieldEnforcer.GuardState.GUARDING, UmbrellaShieldEnforcer.GuardState.OPENING)
	enforcer.guard_state_changed.emit(UmbrellaShieldEnforcer.GuardState.OPENING, UmbrellaShieldEnforcer.GuardState.BROKEN)
	var observed: Array[StringName] = []
	for event: Dictionary in router.events:
		observed.append(event["cue_id"] as StringName)
	_expect(observed == [
		&"rain_city_gull_mark",
		&"rain_city_gull_dive",
		&"rain_city_gull_dive",
		&"rain_city_gull_death",
		&"rain_city_shield_brace",
		&"rain_city_shield_open",
		&"rain_city_shield_break",
	], "hero enemy runtime signals resolve to the complete Rain City authored cue sequence")
	_expect(router.events[0]["position"] == gull.global_position, "Gull authored cues retain the live enemy position")
	_expect(router.events[-1]["position"] == enforcer.global_position, "Umbrella authored cues retain the live enemy position")

	gull.free()
	enforcer.free()
	target.free()
	router.queue_free()
	await process_frame


func _test_convoy_cue_routes() -> void:
	var runtime := MovingSetPieceRuntime.new()
	runtime._generation = 7
	root.add_child(runtime)
	var mission_runtime := RecordingMissionRuntime.new()
	root.add_child(mission_runtime)
	var recorder := RecordingPresentation.new()
	root.add_child(recorder)
	var convoy := CONVOY_SCENE.instantiate() as CitationConvoyActor
	convoy.process_mode = Node.PROCESS_MODE_DISABLED
	convoy.position = Vector3(8.0, 0.0, -12.0)
	root.add_child(convoy)
	await process_frame
	var presentation := RainCityConvoyPresentation.new()
	root.add_child(presentation)
	presentation._runtime = runtime
	presentation._mission_runtime = mission_runtime
	presentation._presentation = recorder
	presentation._active_actor = convoy
	presentation._actor_generation = runtime.generation()
	var generation := runtime.generation()

	presentation._on_actor_attack_telegraphed(&"citation_barrage", 0, Vector3.ZERO, 0.8, convoy, generation)
	presentation._on_actor_attack_telegraphed(&"impound_pulse", 1, Vector3.ZERO, 0.8, convoy, generation)
	presentation._on_actor_attack_telegraphed(&"tow_sweep", 2, Vector3.ZERO, 0.8, convoy, generation)
	presentation._on_actor_module_destroyed(&"citation_drive_left", convoy, generation)
	presentation._on_actor_defeat_milestone_reached(&"tickets", 0.0, convoy, generation)
	presentation._on_completed(&"citation_convoy_stopped", generation)
	_expect(recorder.spatial_cues == [
		&"rain_city_convoy_move",
		&"rain_city_convoy_move",
		&"rain_city_module_break",
		&"rain_city_module_break",
		&"rain_city_module_break",
		&"rain_city_convoy_defeat",
	], "convoy attack, module, milestone, and completion events resolve to authored Rain City cues")
	_expect(mission_runtime.objective_ids == [&"citation_convoy"], "convoy cue completion path still records its canonical objective")
	_expect(mission_runtime.checkpoint_ids == [&"checkpoint_harbour_clear"], "convoy cue completion path still activates its canonical checkpoint")

	presentation.queue_free()
	convoy.free()
	recorder.queue_free()
	mission_runtime.queue_free()
	runtime.queue_free()
	await process_frame


func _definition(zone_id: StringName) -> EncounterDefinition:
	var definition := EncounterDefinition.new()
	definition.id = zone_id
	definition.zone_id = zone_id
	return definition


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(exit_code: int) -> void:
	await process_frame
	await process_frame
	quit(exit_code)
