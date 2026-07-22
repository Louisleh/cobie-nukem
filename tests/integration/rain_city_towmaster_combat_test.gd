extends SceneTree

class ProbeTarget extends Node3D:
	var damage_events: Array[Dictionary] = []
	var total_damage := 0.0

	func apply_damage(amount: float, _source: Node = null, _hit_position := Vector3.ZERO) -> float:
		damage_events.append({
			"amount": amount,
			"position": _hit_position,
		})
		total_damage += amount
		return amount

	func clear() -> void:
		damage_events.clear()
		total_damage = 0.0

const CONVOY_SCENE := preload("res://scenes/set_pieces/citation_convoy.tscn") as PackedScene
const COMBAT_PROFILE := preload("res://resources/set_pieces/towmaster_combat_profile.tres") as TowmasterCombatProfile

const COMBAT_ADVANCE_STEP := 0.1

const ATTACK_IDS: Array[StringName] = [
	&"citation_barrage",
	&"tow_sweep",
	&"impound_pulse",
]

const ATTACK_SHAPES: Array[TowmasterAttackDefinition.AttackShape] = [
	TowmasterAttackDefinition.AttackShape.TARGET_ZONE,
	TowmasterAttackDefinition.AttackShape.LANE,
	TowmasterAttackDefinition.AttackShape.RING,
]

const PHASE_IDS: Array[StringName] = [
	&"appeal_filed",
	&"appeal_denied",
	&"final_notice",
	&"case_closed",
]

const ARENA_SEQUENCE: Array[StringName] = [
	CitationConvoyActor.PHASE_OPEN_DOCK,
	CitationConvoyActor.PHASE_CITATION_LANES,
	CitationConvoyActor.PHASE_IMPOUND_FIELD,
	CitationConvoyActor.PHASE_IMPOUND_FIELD,
]

const MODULE_PATHS := {
	&"citation_drive_left": "CitationDriveLeft",
	&"citation_signal_dish": "CitationSignalDish",
	&"citation_drive_right": "CitationDriveRight",
	&"citation_core": "CitationCore",
}

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _validate_static_contract()
	if failures.is_empty():
		await _run_phase0_deterministic()
	if failures.is_empty():
		await _run_phase1_and_phase2_cycles()
	if failures.is_empty():
		await _run_arena_state_and_visual_checks()
	if failures.is_empty():
		await _run_defeat_sequence()
	if failures.is_empty():
		await _run_reset_soak()

	if failures.is_empty():
		print("RAIN CITY TOWMASTER COMBAT TEST: PASS (3 attacks, 4 phases, 2 arena changes, 100 reset cycles, 10.2s defeat)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_static_contract() -> void:
	_expect(COMBAT_PROFILE != null, "towmaster combat profile loads")
	if COMBAT_PROFILE == null:
		return
	var validation := COMBAT_PROFILE.validate()
	_expect(validation.is_empty(), "towmaster combat profile validates")
	if not validation.is_empty():
		for entry in validation:
			failures.append(entry)

	_expect(COMBAT_PROFILE.attacks.size() == ATTACK_IDS.size(), "towmaster profile defines exactly 3 attacks")
	var seen_attack_ids: Dictionary = {}
	for index in range(ATTACK_IDS.size()):
		var attack := COMBAT_PROFILE.attack_for_id(ATTACK_IDS[index])
		_expect(attack != null, "towmaster profile defines required attack %s" % ATTACK_IDS[index])
		if attack == null:
			continue
		var id_key := String(attack.id)
		_seen_duplicate_assert(id_key, seen_attack_ids, "towmaster profile attack id %s is unique" % attack.id)
		seen_attack_ids[id_key] = true
		_expect(attack.shape == ATTACK_SHAPES[index], "towmaster attack %s has expected shape" % attack.id)

	var shape_values: Dictionary = {}
	for attack in COMBAT_PROFILE.attacks:
		if attack != null:
			shape_values[str(int(attack.shape))] = true
	_expect(shape_values.size() == 3, "towmaster profile attack shapes are distinct")

	_expect(COMBAT_PROFILE.phases.size() == PHASE_IDS.size(), "towmaster profile defines 4 phases")
	var seen_phase_ids: Dictionary = {}
	var arena_states: Array[StringName] = []
	for index in range(PHASE_IDS.size()):
		var phase := COMBAT_PROFILE.phase_at(index)
		_expect(phase != null, "towmaster profile defines phase %d" % index)
		if phase == null:
			continue
		_expect(phase.phase_id == PHASE_IDS[index], "towmaster phase id at %d is canonical" % index)
		var phase_key := String(phase.phase_id)
		_seen_duplicate_assert(phase_key, seen_phase_ids, "towmaster phase ids are unique")
		arena_states.append(phase.arena_state_id)

	_expect(arena_states.size() == ARENA_SEQUENCE.size(), "phase arenas are all authored")
	if arena_states.size() == ARENA_SEQUENCE.size():
		for index in range(ARENA_SEQUENCE.size()):
			_expect(arena_states[index] == ARENA_SEQUENCE[index], "towmaster phase %d arena is canonical" % index)

	_expect(COMBAT_PROFILE.max_temp_visuals <= 6, "towmaster profile max temp visuals is <= 6")
	_expect(COMBAT_PROFILE.max_defeat_particles <= 48, "towmaster profile max defeat particles is <= 48")
	_expect(COMBAT_PROFILE.defeat_duration >= 10.0 and COMBAT_PROFILE.defeat_duration <= 11.0, "towmaster defeat duration is in [10,11]")

	var actor := CONVOY_SCENE.instantiate() as CitationConvoyActor
	_expect(actor != null, "citation convoy scene instantiates")
	if actor == null:
		return
	root.add_child(actor)
	actor.set_physics_process(false)
	await process_frame

	var lane_parent := actor.get_node_or_null("ArenaStates/CitationLanes")
	var lane_mesh_count := 0
	if lane_parent != null:
		for child in lane_parent.get_children():
			if child is MeshInstance3D:
				lane_mesh_count += 1
	_expect(lane_mesh_count == 2, "scene has 2 citation-lane mesh instances")
	var lane_left := actor.get_node_or_null("ArenaStates/CitationLanes/LaneLeft")
	var lane_right := actor.get_node_or_null("ArenaStates/CitationLanes/LaneRight")
	_expect(lane_left is MeshInstance3D and lane_right is MeshInstance3D, "scene exposes both lane meshes")

	var impound_ring := actor.get_node_or_null("ArenaStates/ImpoundField/ImpoundRing")
	_expect(impound_ring is MeshInstance3D, "scene exposes impound field mesh")

	var warning_parent := actor.get_node_or_null("WarningLights")
	var warning_light_count := 0
	if warning_parent != null:
		for child in warning_parent.get_children():
			if child is OmniLight3D:
				warning_light_count += 1
				_expect(not (child as OmniLight3D).shadow_enabled, "warning lights do not cast shadows")
	_expect(warning_light_count == 2, "scene has exactly 2 warning lights")

	for module_id in MODULE_PATHS.keys():
		var module_path := MODULE_PATHS[module_id] as String
		var module_node := actor.get_node_or_null(module_path)
		_expect(module_node is WorldInteraction, "module path exists: %s" % module_path)
		if module_node is WorldInteraction:
			var module_interaction := module_node as WorldInteraction
			var expected_definition: StringName = module_id
			if module_interaction.definition != null:
				_expect(module_interaction.definition.id == expected_definition, "module %s has canonical module id" % module_path)
			else:
				_expect(false, "module %s has definition" % module_path)

	var ticket_debris := actor.get_node_or_null("TicketDebris") as CPUParticles3D
	var defeat_sparks := actor.get_node_or_null("DefeatSparks") as CPUParticles3D
	var total_particles := 0
	if ticket_debris != null:
		total_particles += int(ticket_debris.amount)
	if defeat_sparks != null:
		total_particles += int(defeat_sparks.amount)
	_expect(total_particles <= COMBAT_PROFILE.max_defeat_particles, "profile particle cap bounds scene particle emission")

	actor.queue_free()
	await process_frame

func _run_phase0_deterministic() -> void:
	var actor := _spawn_actor()
	var target := _spawn_target(Vector3(0.5, 0.0, 0.0))
	actor.set_target(target)
	var attack_events: Array[Dictionary] = []
	var telegraph_events: Array[Dictionary] = []
	_connect_attack_signals(actor, attack_events, telegraph_events)

	actor.set_active_phase(0)
	actor.set_combat_enabled(true)

	var first_telegraph := _wait_for_telegraph(actor, telegraph_events, ATTACK_IDS[0])
	_expect(not first_telegraph.is_empty(), "phase0 emits first barrage telegraph")
	if not first_telegraph.is_empty():
		_expect(first_telegraph["attack_id"] == ATTACK_IDS[0], "phase0 first telegraph is citation_barrage")

	target.global_position = Vector3(8.0, 0.0, 8.0)
	var first_resolve := _wait_for_resolve(actor, attack_events)
	_expect(not first_resolve.is_empty(), "phase0 emits barrage resolve")
	_expect(first_resolve["attack_id"] == ATTACK_IDS[0], "phase0 resolve uses citation_barrage")
	_expect(first_resolve["phase"] == 0, "phase0 barrage resolves in phase 0")
	_expect(first_resolve["hit"] == false, "phase0 first barrage misses at out-of-radius lock")
	_expect(is_zero_approx(first_resolve["damage"]), "phase0 first barrage reports zero damage")
	_expect(telegraph_events.size() == 1, "phase0 first barrage emits one telegraph")
	_expect(actor.active_temp_visual_count() == 0, "phase0 resolves stale attack visuals")

	target.global_position = Vector3(0.5, 0.0, 0.0)
	var second_telegraph := _wait_for_telegraph(actor, telegraph_events, ATTACK_IDS[0], 1)
	_expect(not second_telegraph.is_empty(), "phase0 emits second barrage telegraph")
	if not second_telegraph.is_empty():
		_expect(second_telegraph["attack_id"] == ATTACK_IDS[0], "phase0 second telegraph is citation_barrage")
	var second_resolve := _wait_for_resolve(actor, attack_events)
	_expect(not second_resolve.is_empty(), "phase0 emits second barrage resolve")
	_expect(second_resolve["attack_id"] == ATTACK_IDS[0], "phase0 second resolve remains citation_barrage")
	_expect(second_resolve["phase"] == 0, "phase0 second barrage resolves in phase 0")
	_expect(second_resolve["hit"] == true, "phase0 second barrage hits locked target")
	var expected_second_damage := _scaled_attack_damage(ATTACK_IDS[0], 0)
	_expect(is_equal_approx(second_resolve["damage"], expected_second_damage), "phase0 second barrage damage matches profile scaling")
	_expect(actor.active_temp_visual_count() == 0, "phase0 second resolve clears hazard visuals")

	actor.set_combat_enabled(false)
	await _defer_cleanup(actor, target)

func _run_phase1_and_phase2_cycles() -> void:
	var actor := _spawn_actor()
	var target := _spawn_target(Vector3(0.0, 0.0, -10.0))
	actor.set_target(target)
	var attack_events: Array[Dictionary] = []
	var telegraph_events: Array[Dictionary] = []
	_connect_attack_signals(actor, attack_events, telegraph_events)

	actor.set_active_phase(1)
	actor.set_combat_enabled(true)

	var phase1_first := _wait_for_resolve(actor, attack_events)
	_expect(not phase1_first.is_empty(), "phase1 emits first barrage")
	_expect(phase1_first["attack_id"] == ATTACK_IDS[0], "phase1 starts with citation_barrage")
	_expect(phase1_first["phase"] == 1, "phase1 first resolve in phase 1")

	target.global_position = Vector3(0.0, 0.0, -10.0)
	var phase1_second := _wait_for_resolve(actor, attack_events)
	_expect(not phase1_second.is_empty(), "phase1 emits second resolve")
	_expect(phase1_second["attack_id"] == ATTACK_IDS[1], "phase1 second resolve is tow_sweep")
	_expect(phase1_second["phase"] == 1, "phase1 second resolve in phase 1")
	_expect(phase1_second["hit"] == true, "phase1 initial tow_sweep hits after lane lock")
	var expected_hit := _scaled_attack_damage(ATTACK_IDS[1], 1)
	_expect(is_equal_approx(phase1_second["damage"], expected_hit), "phase1 initial tow_sweep damage matches profile")

	var phase1_repeat_barrage := _wait_for_resolve(actor, attack_events)
	_expect(not phase1_repeat_barrage.is_empty(), "phase1 repeat emits burst barrage")
	_expect(phase1_repeat_barrage["attack_id"] == ATTACK_IDS[0], "phase1 repeat starts with citation_barrage")
	target.global_position = Vector3(0.0, 0.0, -10.0)

	var phase1_miss_telegraph := _wait_for_telegraph(actor, telegraph_events, ATTACK_IDS[1], 2)
	_expect(not phase1_miss_telegraph.is_empty(), "phase1 repeat emits sweep telegraph")
	target.global_position = Vector3(6.0, 0.0, 1.4)
	var phase1_miss_second := _wait_for_resolve(actor, attack_events)
	_expect(not phase1_miss_second.is_empty(), "phase1 repeat emits tow_sweep resolve")
	_expect(phase1_miss_second["attack_id"] == ATTACK_IDS[1], "phase1 repeat second attack is tow_sweep")
	_expect(phase1_miss_second["phase"] == 1, "phase1 repeat tow_sweep remains in phase 1")
	_expect(phase1_miss_second["hit"] == false, "phase1 repeated tow_sweep misses when target shifts beyond lane width")
	_expect(phase1_miss_second["damage"] == 0.0, "phase1 repeated tow_sweep applies zero damage outside lane width")

	actor.set_active_phase(2)
	target.global_position = Vector3(1.0, 0.0, 0.0)
	var phase2_first := _wait_for_resolve(actor, attack_events)
	_expect(not phase2_first.is_empty(), "phase2 emits first resolve")
	_expect(phase2_first["attack_id"] == ATTACK_IDS[1], "phase2 starts with tow_sweep")
	_expect(phase2_first["phase"] == 2, "phase2 first resolve in phase 2")

	var phase2_impulse := _wait_for_resolve(actor, attack_events)
	_expect(not phase2_impulse.is_empty(), "phase2 emits second resolve")
	_expect(phase2_impulse["attack_id"] == ATTACK_IDS[2], "phase2 second attack is impound_pulse")
	_expect(phase2_impulse["phase"] == 2, "phase2 impound_pulse resolve in phase 2")
	_expect(phase2_impulse["hit"] == true, "phase2 impound_pulse hits near target")
	var expected_impulse_damage := _scaled_attack_damage(ATTACK_IDS[2], 2)
	_expect(phase2_impulse["damage"] > 0.0 and is_equal_approx(phase2_impulse["damage"], expected_impulse_damage), "phase2 impound_pulse damage is positive and canonical")

	target.global_position = Vector3(8.0, 0.0, 0.0)
	var phase2_repeat_first := _wait_for_resolve(actor, attack_events)
	_expect(phase2_repeat_first["attack_id"] == ATTACK_IDS[1], "phase2 repeat starts with tow_sweep")
	var phase2_miss_impulse := _wait_for_resolve(actor, attack_events)
	_expect(phase2_miss_impulse["attack_id"] == ATTACK_IDS[2], "phase2 repeat second attack is impound_pulse")
	_expect(phase2_miss_impulse["phase"] == 2, "phase2 repeat impound_pulse in phase 2")
	_expect(phase2_miss_impulse["hit"] == false, "phase2 repeated impound_pulse misses when target leaves impound radius")
	_expect(is_zero_approx(phase2_miss_impulse["damage"]), "phase2 repeated impound_pulse applies zero damage outside radius")

	actor.set_combat_enabled(false)
	await _defer_cleanup(actor, target)

func _run_arena_state_and_visual_checks() -> void:
	var actor := _spawn_actor()
	var target := _spawn_target(Vector3(0.0, 0.0, 0.0))
	actor.set_target(target)

	var telegraph_events: Array[Dictionary] = []
	var attack_events: Array[Dictionary] = []
	var arena_events: Array[Dictionary] = []
	var arena_state_events: Array[Dictionary] = []
	_connect_attack_signals(actor, attack_events, telegraph_events)
	_connect_arena_signals(actor, arena_events, arena_state_events)

	var lane_node := actor.get_node_or_null("ArenaStates/CitationLanes")
	var impound_node := actor.get_node_or_null("ArenaStates/ImpoundField")

	actor.set_active_phase(1)
	actor.set_combat_enabled(true)
	if lane_node != null and impound_node != null:
		_expect(lane_node.visible, "combat-enabled phase 1 shows citation lanes")
		_expect(!impound_node.visible, "phase 1 hides impound field")

	target.global_position = Vector3(3.5, 0.0, 0.0)
	arena_events.clear()
	target.clear()
	_advance_for(actor, 4.0)
	_expect(_arena_hit_recorded(arena_events, CitationConvoyActor.PHASE_CITATION_LANES, true), "citation lanes produce a hit at local x 3.5")
	_expect(not _arena_hit_recorded(arena_events, CitationConvoyActor.PHASE_CITATION_LANES, false), "citation lanes are not required to miss when positioned in lane")
	_expect(target.damage_events.size() > 0, "target receives damage when citation lanes hit")

	arena_events.clear()
	target.clear()
	target.global_position = Vector3(0.0, 0.0, 0.0)
	_advance_for(actor, 4.0)
	_expect(_arena_hit_recorded(arena_events, CitationConvoyActor.PHASE_CITATION_LANES, false), "citation lanes miss at local center")

	actor.set_active_phase(2)
	_advance_for(actor, 0.3)
	if lane_node != null and impound_node != null:
		_expect(!lane_node.visible, "phase 2 hides citation lanes")
		_expect(impound_node.visible, "phase 2 shows impound field")

	target.global_position = Vector3(4.0, 0.0, 0.0)
	arena_events.clear()
	target.clear()
	_advance_for(actor, 4.0)
	_expect(_arena_hit_recorded(arena_events, CitationConvoyActor.PHASE_IMPOUND_FIELD, true), "impound field hits target within 4.5")

	arena_events.clear()
	target.clear()
	target.global_position = Vector3(7.0, 0.0, 0.0)
	_advance_for(actor, 4.0)
	_expect(_arena_hit_recorded(arena_events, CitationConvoyActor.PHASE_IMPOUND_FIELD, false), "impound field misses target beyond radius")

	actor.set_combat_enabled(false)
	if lane_node != null and impound_node != null:
		_expect(!lane_node.visible, "combat disabled hides arena lanes")
		_expect(!impound_node.visible, "combat disabled hides arena impound")

	actor.set_combat_enabled(true)
	await _defer_cleanup(actor, target)

func _run_defeat_sequence() -> void:
	var actor := _spawn_actor()
	var target := _spawn_target(Vector3.ZERO)
	actor.set_target(target)
	actor.set_active_phase(3)
	actor.set_combat_enabled(true)

	var milestone_events: Array[Dictionary] = []
	var finish_events: Array[float] = []
	actor.defeat_milestone_reached.connect(func(milestone_id: StringName, elapsed: float) -> void:
		milestone_events.append({"id": milestone_id, "elapsed": elapsed})
	)
	actor.defeat_sequence_finished.connect(func(duration: float) -> void:
		finish_events.append(duration)
	)

	var played_once := actor.play_defeat_sequence()
	_expect(played_once, "towmaster defeat sequence starts")
	_expect(actor.play_defeat_sequence() == false, "towmaster defeat sequence rejects duplicate start")
	var profile_milestones := COMBAT_PROFILE.defeat_milestones
	_expect(not profile_milestones.is_empty(), "profile provides defeat milestones")
	if profile_milestones.is_empty():
		actor.set_combat_enabled(false)
		await _defer_cleanup(actor, target)
		return

	var configured_duration := COMBAT_PROFILE.defeat_duration
	actor._physics_process(configured_duration)
	_expect(actor.defeat_started(), "combat actor is flagged as defeated")
	_expect(is_equal_approx(actor.defeat_elapsed(), configured_duration), "defeat timeline reaches profile duration")
	_expect(finish_events.size() == 1, "defeat emits sequence finished exactly once")
	if finish_events.size() > 0:
		_expect(is_equal_approx(finish_events[0], configured_duration), "defeat finish duration matches profile")

	_expect(milestone_events.size() == profile_milestones.size(), "defeat milestone event count is canonical")
	for index in range(profile_milestones.size()):
		var expected_milestone := profile_milestones[index] as Dictionary
		if expected_milestone.is_empty():
			_expect(false, "profile milestone %d is well-formed" % index)
			continue
		if index >= milestone_events.size():
			break
		var emitted := milestone_events[index]
		_expect(emitted["id"] == expected_milestone.get(TowmasterCombatProfile.MILESTONE_ID_KEY, &""), "defeat milestone id is canonical at index %d" % index)
		_expect(
			is_equal_approx(
				float(emitted["elapsed"]),
				float(expected_milestone.get(TowmasterCombatProfile.MILESTONE_TIME_KEY, -1.0))
			),
			"defeat milestone time is canonical at index %d" % index
		)

	var panel := actor.get_node_or_null("LeadCitationPanel")
	_expect(panel != null and panel.visible, "defeat reveals lead citation panel")
	_expect(actor.active_temp_visual_count() == 0, "defeat disables temporary combat visuals")

	for module_id in MODULE_PATHS.keys():
		var node_path := MODULE_PATHS[module_id] as String
		var interaction := actor.get_node_or_null(node_path) as WorldInteraction
		_expect(interaction != null, "defeat checks module exists: %s" % node_path)
		if interaction == null:
			continue
		_expect(!interaction.visible, "defeat disables module visibility: %s" % node_path)
		_expect(interaction.collision_layer == 0, "defeat disables module collision: %s" % node_path)
		_expect(interaction.definition != null and interaction.definition.enabled == false, "defeat disables module definition: %s" % node_path)

	var ticket_debris := actor.get_node_or_null("TicketDebris") as CPUParticles3D
	var defeat_sparks := actor.get_node_or_null("DefeatSparks") as CPUParticles3D
	var total_particles := 0
	if ticket_debris != null:
		total_particles += int(ticket_debris.amount)
	if defeat_sparks != null:
		total_particles += int(defeat_sparks.amount)
	_expect(total_particles <= COMBAT_PROFILE.max_defeat_particles, "defeat particle total is capped by profile")

	actor.set_combat_enabled(false)
	await _defer_cleanup(actor, target)

func _run_reset_soak() -> void:
	for cycle in range(100):
		var actor := _spawn_actor()
		var target := _spawn_target(Vector3(0.0, 0.0, 0.0))
		var attack_events: Array[Dictionary] = []
		var telegraph_events: Array[Dictionary] = []
		_connect_attack_signals(actor, attack_events, telegraph_events)
		actor.set_target(target)
		actor.set_active_phase(0)
		actor.set_combat_enabled(true)
		actor.advance_combat(0.1)
		var telegraph := _wait_for_telegraph(actor, telegraph_events, ATTACK_IDS[0], 0, 240)
		_expect(not telegraph.is_empty(), "reset soak cycle %d starts with one telegraph" % cycle)
		await process_frame
		_expect(actor.active_temp_visual_count() == 1, "reset soak cycle %d starts with one visual" % cycle)
		var temp_cap: int = get_nodes_in_group(&"towmaster_temp_visual").size()
		_expect(temp_cap <= COMBAT_PROFILE.max_temp_visuals, "reset soak cycle %d respects temp visual cap" % cycle)
		actor.free()
		target.free()
		for _index in range(4):
			await process_frame
			var remaining: int = get_nodes_in_group(&"towmaster_temp_visual").size()
			if remaining == 0:
				break
		_expect(get_nodes_in_group(&"towmaster_temp_visual").size() == 0, "reset soak cycle %d clears temp visuals" % cycle)

func _spawn_actor() -> CitationConvoyActor:
	var actor := CONVOY_SCENE.instantiate() as CitationConvoyActor
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.set_combat_enabled(false)
	return actor

func _spawn_target(position: Vector3) -> ProbeTarget:
	var target := ProbeTarget.new()
	root.add_child(target)
	target.global_position = position
	return target

func _connect_attack_signals(actor: CitationConvoyActor, resolved_events: Array[Dictionary], telegraph_events: Array[Dictionary]) -> void:
	actor.attack_telegraphed.connect(func(attack_id: StringName, phase_index: int, locked_position: Vector3, seconds: float) -> void:
		telegraph_events.append({
			"attack_id": attack_id,
			"phase": phase_index,
			"locked_position": locked_position,
			"seconds": seconds,
		})
	)
	actor.attack_resolved.connect(func(attack_id: StringName, phase_index: int, hit: bool, damage: float) -> void:
		resolved_events.append({
			"attack_id": attack_id,
			"phase": phase_index,
			"hit": hit,
			"damage": damage,
		})
	)

func _connect_arena_signals(actor: CitationConvoyActor, hazard_events: Array[Dictionary], arena_state_events: Array[Dictionary]) -> void:
	actor.arena_hazard_pulsed.connect(func(state: StringName, hit: bool, damage: float) -> void:
		hazard_events.append({
			"state": state,
			"hit": hit,
			"damage": damage,
		})
	)
	actor.arena_state_changed.connect(func(state: StringName, phase_index: int) -> void:
		arena_state_events.append({"state": state, "phase": phase_index})
	)

func _wait_for_resolve(actor: CitationConvoyActor, resolved_events: Array[Dictionary], max_steps: int = 400) -> Dictionary:
	var base := resolved_events.size()
	for _i in range(max_steps):
		actor.advance_combat(COMBAT_ADVANCE_STEP)
		if resolved_events.size() > base:
			return resolved_events[resolved_events.size() - 1]
	return {}

func _wait_for_telegraph(actor: CitationConvoyActor, telegraphs: Array[Dictionary], attack_id: StringName, min_index := 0, max_steps: int = 200) -> Dictionary:
	var check_index: int = max(min_index, telegraphs.size())
	for _i in range(max_steps):
		actor.advance_combat(COMBAT_ADVANCE_STEP)
		while check_index < telegraphs.size():
			var candidate: Dictionary = telegraphs[check_index]
			check_index += 1
			if candidate.get("attack_id", &"") == attack_id:
				return candidate
	return {}

func _advance_for(actor: CitationConvoyActor, seconds: float) -> void:
	var remaining := maxf(0.0, seconds)
	var steps := int(ceil(remaining / COMBAT_ADVANCE_STEP))
	for _i in range(steps):
		actor.advance_combat(COMBAT_ADVANCE_STEP)

func _arena_hit_recorded(events: Array[Dictionary], state_id: StringName, expect_hit: bool) -> bool:
	for event in events:
		if event.get("state", &"") == state_id and bool(event.get("hit", false)) == expect_hit:
			return true
	return false

func _defer_cleanup(actor: CitationConvoyActor, target: ProbeTarget) -> void:
	actor.queue_free()
	target.queue_free()
	await process_frame

func _scaled_attack_damage(attack_id: StringName, phase_index: int) -> float:
	if COMBAT_PROFILE == null:
		return 0.0
	var attack := COMBAT_PROFILE.attack_for_id(attack_id)
	var phase := COMBAT_PROFILE.phase_at(phase_index)
	if attack == null or phase == null:
		return 0.0
	var raw := float(attack.base_damage) * float(phase.damage_scale)
	var game_state: Node = get_root().get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("get_difficulty_profile"):
		return raw
	var difficulty_profile := game_state.get_difficulty_profile() as DifficultyProfile
	if difficulty_profile == null:
		return raw
	return difficulty_profile.scaled_enemy_damage(raw)

func _seen_duplicate_assert(key: String, seen: Dictionary, message: String) -> void:
	if seen.has(key):
		failures.append(message)
	else:
		seen[key] = true

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
