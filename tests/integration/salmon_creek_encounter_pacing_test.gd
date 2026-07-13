extends SceneTree

const LevelScene := preload("res://scenes/levels/episode_1_level_1.tscn")
const Pacing := preload("res://resources/encounters/salmon_walker_pacing.tres")

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_authored_pacing_contract()
	await _test_complete_route_spawns_every_wave()
	await _test_checkpoint_reset_cancels_pending_reinforcement()
	await _test_walker_pressure_phases_summons_and_recovery()
	if failures.is_empty():
		print("SALMON CREEK ENCOUNTER PACING: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("ENCOUNTER PACING: " + failure)
		quit(1)


func _test_authored_pacing_contract() -> void:
	var manifest := load("res://resources/content/salmon_creek_manifest.tres") as ContentManifest
	_expect(manifest != null, "Salmon Creek manifest loads")
	if manifest == null:
		return
	var expected_waves := {
		&"forbidden_field": 1,
		&"equipment_shed": 2,
		&"maintenance_tunnels": 2,
		&"compliance_lab": 2,
		&"walker_arena": 1,
	}
	var previous_intensity := -1.0
	var total_authored := 0
	for definition in manifest.encounters:
		_expect(definition.schema_version == 2, "%s uses encounter schema v2" % definition.id)
		_expect(definition.spawns.is_empty(), "%s has no duplicate legacy spawn table" % definition.id)
		_expect(definition.waves.size() == expected_waves.get(definition.zone_id, 0), "%s has its intended wave count" % definition.id)
		_expect(definition.validate().is_empty(), "%s passes typed encounter validation" % definition.id)
		_expect(definition.music_intensity > previous_intensity, "%s raises route music intensity" % definition.id)
		previous_intensity = definition.music_intensity
		for wave in definition.waves:
			total_authored += (wave.get("spawns", []) as Array).size()
	_expect(total_authored == 17, "The complete authored route contains 17 required actors")
	var opening := manifest.encounters[0] as EncounterDefinition
	_expect(opening.opening_grace_seconds == 12.0, "Opening retains the family-safe 12-second grace window")
	_expect(opening.maximum_simultaneous_attackers == 1, "Opening limits simultaneous pressure to one attacker")
	_expect(Pacing.validate().is_empty(), "Walker phase pacing resource validates")
	_expect(Pacing.summon_attack_interval == 3, "Walker telegraphs a reinforcement every third cannon attack")


func _test_complete_route_spawns_every_wave() -> void:
	var level := _make_level()
	await process_frame
	var expected_first_wave := {
		&"forbidden_field": 3,
		&"equipment_shed": 2,
		&"maintenance_tunnels": 3,
		&"compliance_lab": 3,
	}
	var expected_reinforcement := {
		&"equipment_shed": 1,
		&"maintenance_tunnels": 2,
		&"compliance_lab": 2,
	}
	for zone_id: StringName in expected_first_wave:
		if zone_id != &"forbidden_field":
			level._enter_zone(zone_id, String(zone_id), null)
		var definition := level._encounter_runner.definitions[zone_id] as EncounterDefinition
		var pressure := root.get_node_or_null("CombatPressure")
		if pressure != null:
			_expect(pressure.maximum_attackers == mini(level._baseline_attack_budget, definition.maximum_simultaneous_attackers), "%s consumes its authored attack-token budget" % zone_id)
		var first_actors := _active_actors(level, zone_id)
		_expect(first_actors.size() == expected_first_wave[zone_id], "%s starts with its intended role composition" % zone_id)
		_defeat(first_actors)
		if expected_reinforcement.has(zone_id):
			await create_timer(1.05).timeout
			var reinforcement := _active_actors(level, zone_id)
			_expect(reinforcement.size() == expected_reinforcement[zone_id], "%s reinforcement appears after the authored delay" % zone_id)
			_expect(int(level._encounter_runner.active.get(zone_id, {}).get("wave", -1)) == 1, "%s advances to wave two" % zone_id)
			_defeat(reinforcement)
		_expect(level._encounter_runner.completed.has(zone_id), "%s completes only after every required wave" % zone_id)
	_expect(level.enemies_total == 16, "Normal pre-boss route spawns all 16 regular/elite actors")
	level.free()
	await process_frame


func _test_checkpoint_reset_cancels_pending_reinforcement() -> void:
	var level := _make_level()
	await process_frame
	level._enter_zone(&"maintenance_tunnels", "MAINTENANCE TUNNELS", null)
	_defeat(_active_actors(level, &"maintenance_tunnels"))
	level._last_combat_zone = &"maintenance_tunnels"
	level._reset_active_encounter_for_checkpoint()
	await create_timer(0.7).timeout
	var reset_wave := _active_actors(level, &"maintenance_tunnels")
	_expect(reset_wave.size() == 3, "Checkpoint reset restores exactly the tunnel opening wave")
	_expect(int(level._encounter_runner.active.get(&"maintenance_tunnels", {}).get("wave", -1)) == 0, "Cancelled reinforcement timer cannot advance the reset encounter")
	level.enemies_defeated = level.enemies_total
	_defeat(reset_wave)
	_expect(level.enemies_defeated == level.enemies_total, "Replayed checkpoint kills cannot exceed the authored enemy total")
	await create_timer(0.65).timeout
	_expect(_active_actors(level, &"maintenance_tunnels").size() == 2, "A fresh clear schedules exactly one fresh tunnel reinforcement")
	level.free()
	await process_frame


func _test_walker_pressure_phases_summons_and_recovery() -> void:
	var level := _make_level()
	var target := CharacterBody3D.new()
	target.name = "WalkerPressureTarget"
	level.add_child(target)
	target.global_position = Vector3(0.0, 0.0, -130.0)
	level.player = target
	await process_frame
	level._enter_zone(&"walker_arena", "ANIMAL CONTROL WALKER", target)
	var walker := level._walker as AnimalControlWalker
	_expect(walker != null, "Walker encounter spawns its boss")
	if walker == null:
		level.free()
		await process_frame
		return
	var initial_distance := walker.global_position.distance_to(target.global_position)
	var minimum_distance := initial_distance
	for frame in 360:
		await physics_frame
		minimum_distance = minf(minimum_distance, walker.global_position.distance_to(target.global_position))
	var settled_distance := walker.global_position.distance_to(target.global_position)
	print("WALKER PRESSURE EVIDENCE: initial=%.3f minimum=%.3f settled=%.3f state=%s cooldown=%.3f attack_range=%.3f authored=%s" % [initial_distance, minimum_distance, settled_distance, walker.state, walker._cooldown, walker.definition.attack_range, Pacing.pressure_distance])
	_expect(initial_distance > Pacing.pressure_distance.y, "Walker begins outside its pressure band")
	_expect(walker.summon_attack_interval == Pacing.summon_attack_interval, "Walker consumes the authored summon cadence")
	_expect(minimum_distance <= Pacing.pressure_distance.y, "Walker actively closes into the authored pressure band")
	_expect(settled_distance >= Pacing.pressure_distance.x and settled_distance <= Pacing.pressure_distance.y, "Walker settles at a readable pressure distance")

	var narrative: Array[String] = []
	var phase_ids: Array[StringName] = []
	level.narrative_message.connect(func(text: String, _duration: float) -> void: narrative.append(text))
	level.boss_state_changed.connect(func(id: StringName, _fraction: float) -> void: phase_ids.append(id))
	var pickups_before := _count_pickups(level)
	walker.apply_damage(450.0)
	_expect(phase_ids == [&"exposed_core"], "First threshold communicates the exposed-core phase")
	_expect(_count_pickups(level) == pickups_before + 1, "Exposed core deploys one authored health recovery")
	walker.apply_damage(300.0)
	_expect(phase_ids == [&"exposed_core", &"charge"], "Second threshold communicates the charge phase")
	_expect(_count_pickups(level) == pickups_before + 2, "Charge phase deploys one authored ammunition recovery")
	walker.apply_damage(300.0)
	_expect(phase_ids == [&"exposed_core", &"charge", &"golden_ball"], "Final threshold communicates the Golden Ball vulnerability")
	_expect(narrative.any(func(text: String) -> bool: return "EXPOSED CORE" in text), "Weak-point phase has an explicit player cue")

	# Recreate the cannon phase for an isolated public-behavior summon cadence check.
	walker.boss_phase = AnimalControlWalker.BossPhase.CANNONS
	current_scene = level
	var summons_before := get_nodes_in_group(&"boss_summons").size()
	for attack in Pacing.summon_attack_interval:
		walker._perform_attack()
		walker.attack_fired.emit(&"walker_cannons")
	_expect(get_nodes_in_group(&"boss_summons").size() == summons_before + 1, "Every third cannon attack creates exactly one drone reinforcement")
	_expect(narrative.any(func(text: String) -> bool: return "REINFORCEMENT DEPLOYED" in text), "The summon cadence communicates the deployed pressure actor")

	level._last_combat_zone = &"walker_arena"
	level._reset_active_encounter_for_checkpoint()
	await process_frame
	_expect(level._walker != walker and is_instance_valid(level._walker), "Boss reset replaces the Walker with a clean instance")
	_expect(level._walker_phase_rewards.is_empty(), "Boss reset clears phase-reward cadence state")
	_expect(_count_pickups(level) == pickups_before, "Boss reset removes uncollected phase recovery without duplicating it")
	_expect(get_nodes_in_group(&"boss_summons").is_empty(), "Boss reset clears all summoned pressure actors")
	_expect(level.enemies_defeated <= level.enemies_total, "Checkpoint replay never reports more credited defeats than authored enemies")
	level.free()
	current_scene = null
	await process_frame


func _make_level() -> EpisodeOneLevel:
	var level := LevelScene.instantiate() as EpisodeOneLevel
	level.spawn_player = false
	level.start_run_automatically = false
	level.setup_presentation = false
	root.add_child(level)
	return level


func _active_actors(level: EpisodeOneLevel, zone_id: StringName) -> Array:
	return level._encounter_runner.active.get(zone_id, {}).get("actors", []).duplicate()


func _defeat(actors: Array) -> void:
	for actor in actors:
		if is_instance_valid(actor) and actor.has_method("apply_damage"):
			actor.apply_damage(1000000.0)


func _count_pickups(level: EpisodeOneLevel) -> int:
	var count := 0
	for actor in level.get_node("Actors").get_children():
		if actor is CombatPickup:
			count += 1
	return count


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
