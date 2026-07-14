extends SceneTree

const MANIFEST := preload("res://resources/content/salmon_creek_manifest.tres")
const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")

class FakeLevel extends Node:
	signal zone_entered(zone_id: StringName, title: String)
	signal narrative_message(text: String, duration: float)
	signal objective_changed(text: String)
	signal secret_found(secret_id: StringName, title: String, found: int, total: int)


class FakeEnemy extends Node:
	signal telegraph_started(kind: StringName, duration: float)


var failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_duplicate_configuration()
	await _test_null_player()
	await _test_ui_and_audio_ownership()
	await _test_enemy_binding_current_and_future()
	await _test_state_and_zone_transitions()
	await _test_checkpoint_reset()
	await _test_death_touch_release_and_pause_suppression()
	await _test_teardown_without_leaks()
	if failures.is_empty():
		print("MISSION PRESENTATION TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _make_level() -> FakeLevel:
	var level := FakeLevel.new()
	level.name = "MissionPresentationTestLevel"
	root.add_child(level)
	return level


func _make_presentation(level: FakeLevel, actors: Node, player: Node3D = null) -> MissionPresentation:
	var presentation := MissionPresentation.new()
	presentation.name = "MissionPresentationTestPresentation"
	root.add_child(presentation)
	_expect(presentation.configure(level, MANIFEST, actors, null, null, player, root.get_node_or_null("GameState"), &"forbidden_field", &"walker_arena", {
		&"forbidden_field": &"salmon_ambience_exterior",
		&"equipment_shed": &"salmon_ambience_exterior",
		&"maintenance_tunnels": &"salmon_ambience_tunnel",
		&"compliance_lab": &"salmon_ambience_lab",
		&"walker_arena": &"salmon_ambience_arena",
	}), "presentation configures with mission-owned presentation data")
	return presentation


func _definition(zone_id: StringName) -> EncounterDefinition:
	var definition := EncounterDefinition.new()
	definition.id = zone_id
	definition.zone_id = zone_id
	return definition


func _count_playing_audio(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			if child.playing:
				total += 1
	return total


func _test_duplicate_configuration() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	var existing_enemy := FakeEnemy.new(); actors.add_child(existing_enemy)
	await process_frame
	var presentation := _make_presentation(level, actors)
	_expect(presentation.bound_enemy_count() == 1, "first configure binds existing actor warnings")
	_expect(presentation.configure(level, MANIFEST, actors), "duplicate configure remains true")
	_expect(presentation.bound_enemy_count() == 1, "duplicate configure avoids duplicate actor warning bindings")
	_expect(presentation.is_enemy_bound(existing_enemy), "existing actor remains warning-bound")
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_null_player() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	await process_frame
	var presentation := _make_presentation(level, actors)
	var player := PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	presentation.set_player(player)
	_expect(presentation.get_mobile_controls().player == player, "set_player binds mobile controls")
	presentation.set_player(null)
	_expect(presentation.get_mobile_controls().player == null, "set_player(null) safely unbinds controls")
	presentation.set_player(null)
	_expect(true, "idempotent null player setting does not crash")
	player.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_ui_and_audio_ownership() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	await process_frame
	var presentation := _make_presentation(level, actors)
	_expect(presentation.get_hud() != null, "mission presentation exposes HUD node")
	_expect(presentation.get_pause_menu() != null, "mission presentation exposes pause menu node")
	_expect(presentation.get_death_screen() != null, "mission presentation exposes death screen node")
	_expect(presentation.get_victory_screen() != null, "mission presentation exposes victory screen node")
	_expect(presentation.get_combat_audio_bridge() != null, "mission presentation exposes combat audio bridge")
	_expect(presentation.get_audio_director() != null, "mission presentation exposes mission audio director")
	_expect(presentation.get_mobile_controls() != null, "mission presentation exposes mobile controls")
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_enemy_binding_current_and_future() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	var existing_enemy := FakeEnemy.new(); actors.add_child(existing_enemy)
	await process_frame
	var presentation := _make_presentation(level, actors)
	_expect(presentation.is_enemy_bound(existing_enemy), "existing enemy is warning-bound on presentation setup")
	var future_enemy := FakeEnemy.new()
	presentation.bind_warning_enemy(future_enemy)
	_expect(presentation.bound_enemy_count() == 2, "future enemy can be warning-bound once")
	actors.add_child(future_enemy)
	var scripted_enemy := FakeEnemy.new()
	presentation.on_actor_spawned(scripted_enemy, _definition(&"maintenance_tunnels"))
	_expect(presentation.bound_enemy_count() == 3, "spawn callback warnings bind future actor")
	actors.add_child(scripted_enemy)
	for actor: Node in actors.get_children():
		actor.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_state_and_zone_transitions() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	await process_frame
	var presentation := _make_presentation(level, actors)
	var director := presentation.get_audio_director()
	_expect(director.current_state() == &"exploration", "presentation initializes mission music state to exploration")
	presentation.on_zone_entered(&"equipment_shed", "EQUIPMENT SHED")
	_expect(director.current_ambience_cue() == &"salmon_ambience_exterior", "zone ambience tracks Salmon shed as exterior")
	var regular_enemy := FakeEnemy.new()
	presentation.on_actor_spawned(regular_enemy, _definition(&"equipment_shed"))
	await process_frame
	_expect(director.current_state() == &"combat", "combat cue activates for active non-boss wave in current zone")
	presentation.on_actor_defeated(regular_enemy, _definition(&"equipment_shed"))
	await process_frame
	_expect(director.current_state() == &"tension", "combat resolves to tension when zone threat ends")
	var boss_enemy := FakeEnemy.new()
	presentation.on_actor_spawned(boss_enemy, _definition(&"walker_arena"))
	await process_frame
	_expect(director.current_state() == &"boss", "boss cue activates for walker zone")
	presentation.on_level_completed({})
	await process_frame
	_expect(director.current_state() == &"victory", "victory event sets victory music")
	regular_enemy.free()
	boss_enemy.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_checkpoint_reset() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	var player := PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	var presentation := _make_presentation(level, actors, player)
	var audio := presentation.get_combat_audio_bridge()
	if audio.sounds != null:
		audio.sounds.play(ProceduralAudio.Cue.PAWSTOL)
	presentation.on_player_died(player)
	presentation.reset_for_checkpoint()
	await process_frame
	_expect(not presentation.is_pause_suppressed(), "checkpoint reset clears pause suppression")
	_expect(presentation.get_death_screen().visible == false, "checkpoint reset hides death UI")
	_expect(_count_playing_audio(audio.sounds) == 0, "checkpoint reset stops procedural combat audio")
	if audio.samples != null:
		_expect(audio.samples.total_voice_count() == 0, "checkpoint reset stops sample combat audio")
	player.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_death_touch_release_and_pause_suppression() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	var player := PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	var presentation := _make_presentation(level, actors, player)
	var controls := presentation.get_mobile_controls()
	controls.force_visible = true
	controls.set_deferred("size", Vector2(320, 180))
	await process_frame
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.pressed = true
	press.position = controls._from_design(Vector2(292, 111))
	controls._handle_touch(press)
	Input.flush_buffered_events()
	await process_frame
	_expect(Input.is_action_pressed(&"fire_primary"), "mobile touch input drives death-path release verification")
	presentation.on_player_died(player)
	Input.flush_buffered_events()
	await process_frame
	_expect(not Input.is_action_pressed(&"fire_primary"), "player death releases all held mobile inputs")
	_expect(presentation.is_pause_suppressed(), "player death suppresses pause menu and focus-open reentry")
	player.free()
	presentation.queue_free()
	level.queue_free()
	await process_frame


func _test_teardown_without_leaks() -> void:
	var level := _make_level()
	var actors := Node.new(); actors.name = "Actors"; level.add_child(actors)
	await process_frame
	var presentation := _make_presentation(level, actors)
	var director := presentation.get_audio_director()
	var bridge := presentation.get_combat_audio_bridge()
	var mobile := presentation.get_mobile_controls()
	presentation.queue_free()
	await process_frame
	_expect(not is_instance_valid(director), "mission presentation frees mission audio director")
	_expect(not is_instance_valid(bridge), "mission presentation frees combat audio bridge")
	_expect(not is_instance_valid(mobile), "mission presentation frees mobile controls")
	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
