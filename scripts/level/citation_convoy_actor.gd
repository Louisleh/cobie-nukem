class_name CitationConvoyActor
extends PhasedModuleActor

signal attack_telegraphed(attack_id: StringName, phase_index: int, locked_position: Vector3, seconds: float)
signal attack_resolved(attack_id: StringName, phase_index: int, hit: bool, damage: float)
signal arena_state_changed(arena_state_id: StringName, phase_index: int)
signal arena_hazard_pulsed(arena_state_id: StringName, hit: bool, damage: float)
signal defeat_milestone_reached(milestone_id: StringName, elapsed: float)
signal defeat_sequence_finished(duration: float)

@export var combat_profile: TowmasterCombatProfile

const FALLBACK_DEFEAT_DURATION: float = 10.2
const FALLBACK_MAX_DEFEAT_PARTICLES: int = 46
const FALLBACK_TICKET_PARTICLES: int = 28
const FALLBACK_SPARK_PARTICLES: int = 18
const FALLBACK_DEFEAT_MILESTONES: Array[Dictionary] = [
	{ TowmasterCombatProfile.MILESTONE_ID_KEY: &"shutdown", TowmasterCombatProfile.MILESTONE_TIME_KEY: 0.0 },
	{ TowmasterCombatProfile.MILESTONE_ID_KEY: &"tickets", TowmasterCombatProfile.MILESTONE_TIME_KEY: 2.2 },
	{ TowmasterCombatProfile.MILESTONE_ID_KEY: &"tow_arm", TowmasterCombatProfile.MILESTONE_TIME_KEY: 4.8 },
	{ TowmasterCombatProfile.MILESTONE_ID_KEY: &"core_discharge", TowmasterCombatProfile.MILESTONE_TIME_KEY: 7.2 },
	{ TowmasterCombatProfile.MILESTONE_ID_KEY: &"final_settle", TowmasterCombatProfile.MILESTONE_TIME_KEY: 10.2 },
]

const PHASE_OPEN_DOCK: StringName = &"open_dock"
const PHASE_CITATION_LANES: StringName = &"citation_lanes"
const PHASE_IMPOUND_FIELD: StringName = &"impound_field"
const MILESTONE_TICKETS: StringName = &"tickets"
const MILESTONE_TOW_ARM: StringName = &"tow_arm"
const MILESTONE_CORE_DISCHARGE: StringName = &"core_discharge"
const MILESTONE_FINAL_SETTLE: StringName = &"final_settle"
const BASE_ARENA_DAMAGE: float = 5.0

const TOW_ARM_TILT_RADIANS: float = 0.10471975511965978 # 6°
const ROOT_SETTLE_RADIANS: float = 0.06981317007977318 # 4°
const ARENA_PULSE_BASE: float = 2.5
const INVALID_FLOAT := -1.0

const TowmasterHazard := preload("res://scripts/level/towmaster_hazard_visual.gd")

@onready var _citation_lanes_node: Node3D = get_node_or_null("ArenaStates/CitationLanes")
@onready var _impound_field_node: Node3D = get_node_or_null("ArenaStates/ImpoundField")
@onready var _warning_lights_root: Node3D = get_node_or_null("WarningLights")
@onready var _lead_vehicle: Node3D = get_node_or_null("LeadVehicle")
@onready var _lead_panel: Node3D = get_node_or_null("LeadCitationPanel")
@onready var _escort_left: Node3D = get_node_or_null("EscortLeft")
@onready var _escort_right: Node3D = get_node_or_null("EscortRight")

var _combat_enabled := true
var _combat_profile_errors: PackedStringArray = PackedStringArray()
var _combat_phase_index := 0
var _arena_state_id: StringName = PHASE_OPEN_DOCK
var _arena_pulse_timer := 0.0
var _target: Node3D
var _warning_lights: Array[OmniLight3D] = []
var _temp_visuals: Array[TowmasterHazardVisual] = []
var _active_attack_visual: TowmasterHazardVisual
var _attack_cycle_index := 0
var _attack_cooldown := 0.0
var _attack_in_telegraph := false
var _telegraph_elapsed := 0.0
var _telegraph_duration := 0.0
var _active_attack: TowmasterAttackDefinition
var _active_attack_id := StringName()
var _locked_origin := Vector3.ZERO
var _locked_target := Vector3.ZERO
var _attack_direction := Vector3.ZERO
var _defeat_started := false
var _defeat_duration := FALLBACK_DEFEAT_DURATION
var _defeat_elapsed := 0.0
var _defeat_milestones: Array[Dictionary] = []
var _defeat_milestone_index := 0
var _defeat_emitted: PackedStringArray = PackedStringArray()
var _defeat_timeline_complete := false
var _defeat_reduced_flashes := false
var _defeat_reduced_motion := false
var _defeat_ticket_particles := 0
var _defeat_spark_particles := 0


func _ready() -> void:
	super._ready()
	_validate_profile()
	_collect_warning_lights()
	if not _combat_profile_valid():
		_combat_enabled = false
	_set_arena_state_from_profile()
	_apply_arena_state_visibility()
	if _lead_panel != null:
		_lead_panel.visible = false


func _physics_process(delta: float) -> void:
	if _defeat_started:
		_advance_defeat_sequence(delta)
		return

	var can_fight := _combat_enabled and _combat_profile_valid() and _target_valid() and _phase_is_valid(_combat_phase_index)
	if not can_fight:
		if _attack_in_telegraph:
			_cancel_active_attack()
		return
	advance_combat(delta)


func _validate_profile() -> void:
	if combat_profile == null:
		combat_profile = TowmasterCombatProfile.new()
	_combat_profile_errors = combat_profile.validate()
	if not _combat_profile_valid():
		_combat_enabled = false


func _combat_profile_valid() -> bool:
	return combat_profile != null and _combat_profile_errors.is_empty()


func _phase_is_valid(phase_index: int) -> bool:
	return _combat_profile_valid() and phase_index >= 0 and phase_index < combat_profile.phases.size()


func play_defeat_sequence() -> bool:
	if _defeat_started:
		return false
	_defeat_started = true
	_defeat_elapsed = 0.0
	_defeat_duration = FALLBACK_DEFEAT_DURATION
	_defeat_milestones = FALLBACK_DEFEAT_MILESTONES.duplicate(true)
	_defeat_milestone_index = 0
	_defeat_emitted.clear()
	_defeat_timeline_complete = false
	_defeat_reduced_flashes = _reduced_flashes()
	_defeat_reduced_motion = _reduced_motion()
	if _combat_profile_valid():
		_defeat_duration = combat_profile.defeat_duration
		if combat_profile.defeat_milestones.size() > 0:
			_defeat_milestones = combat_profile.defeat_milestones.duplicate(true)

	_combat_enabled = false
	_set_all_modules_enabled(false)
	_cancel_active_attack()
	_clear_temp_visuals()
	_set_warning_lights(false)
	_hide_arena_state_nodes()
	_configure_defeat_particles()
	if _lead_panel != null:
		_lead_panel.visible = true
	_advance_defeat_sequence(0.0)
	return true


func defeat_started() -> bool:
	return _defeat_started


func _advance_defeat_sequence(delta: float) -> void:
	if _defeat_timeline_complete:
		return
	_defeat_elapsed = minf(_defeat_elapsed + delta, _defeat_duration)
	while _defeat_milestone_index < _defeat_milestones.size():
		var raw := _defeat_milestones[_defeat_milestone_index]
		if raw == null or not (raw is Dictionary):
			_defeat_milestone_index += 1
			continue
		var dict := raw as Dictionary
		var id_raw: Variant = dict.get(TowmasterCombatProfile.MILESTONE_ID_KEY, "")
		var time_raw: Variant = dict.get(TowmasterCombatProfile.MILESTONE_TIME_KEY, INVALID_FLOAT)
		var milestone_id := StringName(id_raw)
		if String(milestone_id).is_empty() or not (time_raw is float or time_raw is int):
			_defeat_milestone_index += 1
			continue
		var milestone_time := float(time_raw)
		if not is_finite(milestone_time) or milestone_time > _defeat_elapsed + 0.000001:
			break
		var key := String(milestone_id)
		if not _defeat_emitted.has(key):
			_defeat_emitted.append(key)
			defeat_milestone_reached.emit(milestone_id, milestone_time)
			_apply_defeat_milestone(milestone_id)
		_defeat_milestone_index += 1

	if _defeat_elapsed >= _defeat_duration - 0.000001:
		_defeat_timeline_complete = true
		defeat_sequence_finished.emit(_defeat_duration)


func _apply_defeat_milestone(milestone_id: StringName) -> void:
	match milestone_id:
		&"shutdown":
			pass
		MILESTONE_TICKETS:
			var tickets := get_node_or_null("TicketDebris") as CPUParticles3D
			if tickets != null and _defeat_ticket_particles > 0:
				tickets.amount = _defeat_ticket_particles
				tickets.restart()
				tickets.emitting = true
		MILESTONE_TOW_ARM:
			if _defeat_reduced_motion:
				return
			if _lead_vehicle != null:
				_lead_vehicle.rotation = Vector3(_lead_vehicle.rotation.x, _lead_vehicle.rotation.y, TOW_ARM_TILT_RADIANS)
			if _escort_left != null:
				_escort_left.rotation = Vector3(_escort_left.rotation.x, _escort_left.rotation.y, -TOW_ARM_TILT_RADIANS)
			if _escort_right != null:
				_escort_right.rotation = Vector3(_escort_right.rotation.x, _escort_right.rotation.y, TOW_ARM_TILT_RADIANS)
		MILESTONE_CORE_DISCHARGE:
			if _defeat_reduced_flashes:
				return
			var sparks := get_node_or_null("DefeatSparks") as CPUParticles3D
			if sparks != null and _defeat_spark_particles > 0:
				sparks.amount = _defeat_spark_particles
				sparks.restart()
				sparks.emitting = true
		MILESTONE_FINAL_SETTLE:
			if _defeat_reduced_motion:
				return
			rotation = Vector3(rotation.x, rotation.y, clampf(rotation.z + ROOT_SETTLE_RADIANS, -ROOT_SETTLE_RADIANS, ROOT_SETTLE_RADIANS))


func set_target(value: Node3D) -> void:
	_target = value


func set_combat_enabled(value: bool) -> void:
	if not _combat_profile_valid():
		_combat_enabled = false
		return
	if _combat_enabled == value:
		return
	_combat_enabled = value
	_attack_cycle_index = 0
	_attack_cooldown = 0.0
	_cancel_active_attack()
	_clear_temp_visuals()
	if not value:
		_hide_arena_state_nodes()
		_set_warning_lights(false)
		return
	_set_arena_state_from_profile()
	_apply_arena_state_visibility()


func set_active_phase(index: int) -> void:
	super.set_active_phase(index)
	_combat_phase_index = index
	_attack_cycle_index = 0
	_attack_cooldown = 0.0
	_cancel_active_attack()
	_clear_temp_visuals()
	_set_arena_state_from_profile()
	_apply_arena_state_visibility()


func current_attack_id() -> StringName:
	return _active_attack_id


func current_arena_state_id() -> StringName:
	return _arena_state_id


func active_temp_visual_count() -> int:
	_prune_temp_visuals()
	return _temp_visuals.size()


func defeat_elapsed() -> float:
	return _defeat_elapsed


func emitted_defeat_milestones() -> PackedStringArray:
	return _defeat_emitted.duplicate()


func profile_validation_errors() -> PackedStringArray:
	return _combat_profile_errors.duplicate()


func advance_combat(delta: float) -> void:
	if not _combat_enabled or not _combat_profile_valid() or not _target_valid() or not _phase_is_valid(_combat_phase_index):
		return
	var phase := combat_profile.phase_at(_combat_phase_index)
	if phase == null:
		return
	if _attack_in_telegraph:
		_telegraph_elapsed += delta
		if _telegraph_elapsed >= _telegraph_duration:
			_resolve_attack(phase)
		return
	_apply_arena_pulse(phase, delta)
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
		return
	_start_next_attack(phase)


func _set_arena_state_from_profile() -> void:
	if _combat_profile_valid():
		var phase := combat_profile.phase_at(_combat_phase_index)
		if phase != null:
			_arena_state_id = phase.arena_state_id
			_arena_pulse_timer = ARENA_PULSE_BASE * phase.cooldown_scale
		else:
			_arena_state_id = PHASE_OPEN_DOCK
			_arena_pulse_timer = 0.0
	else:
		_arena_state_id = PHASE_OPEN_DOCK
		_arena_pulse_timer = 0.0
	arena_state_changed.emit(_arena_state_id, _combat_phase_index)


func _apply_arena_state_visibility() -> void:
	if _citation_lanes_node != null:
		_citation_lanes_node.visible = _combat_enabled && _arena_state_id == PHASE_CITATION_LANES
	if _impound_field_node != null:
		_impound_field_node.visible = _combat_enabled && _arena_state_id == PHASE_IMPOUND_FIELD
	_set_warning_lights(_combat_enabled)


func _hide_arena_state_nodes() -> void:
	if _citation_lanes_node != null:
		_citation_lanes_node.visible = false
	if _impound_field_node != null:
		_impound_field_node.visible = false


func _set_warning_lights(active: bool) -> void:
	if _warning_lights_root != null:
		_warning_lights_root.visible = active
	var phase := combat_profile.phase_at(_combat_phase_index) if _combat_profile_valid() else null
	for light in _warning_lights:
		if light != null:
			if phase != null:
				light.light_color = phase.warning_color
			light.light_energy = phase.warning_energy if active and phase != null else 0.0


func _start_next_attack(phase: TowmasterPhaseCombatDefinition) -> void:
	var phase_attacks := phase.attack_ids if phase != null else []
	if phase_attacks.is_empty():
		return
	if _attack_cycle_index >= phase_attacks.size():
		_attack_cycle_index = 0
	var attack_id := phase_attacks[_attack_cycle_index]
	_attack_cycle_index = (_attack_cycle_index + 1) % phase_attacks.size()
	var attack := combat_profile.attack_for_id(attack_id)
	if attack == null:
		return
	_active_attack = attack
	_active_attack_id = attack_id
	_locked_origin = global_position
	_locked_target = _target.global_position
	var dir := Vector3(_locked_target.x - _locked_origin.x, 0.0, _locked_target.z - _locked_origin.z)
	_attack_direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.FORWARD
	_telegraph_duration = attack.telegraph_seconds * phase.telegraph_scale
	_telegraph_elapsed = 0.0
	_attack_in_telegraph = true
	_spawn_attack_visual(attack)
	attack_telegraphed.emit(attack_id, _combat_phase_index, _locked_target, _telegraph_duration)
	if _telegraph_duration <= 0.0:
		_resolve_attack(phase)


func _resolve_attack(phase: TowmasterPhaseCombatDefinition) -> void:
	if phase == null or _active_attack == null:
		_cancel_active_attack()
		return
	_attack_in_telegraph = false
	_telegraph_elapsed = 0.0
	_telegraph_duration = 0.0
	var hit := _attack_hits_target()
	var damage := 0.0
	if hit:
		damage = _combat_profile_damage(_active_attack.base_damage * phase.damage_scale)
		if _target.has_method("apply_damage"):
			_target.call("apply_damage", damage, self, _target.global_position)
	attack_resolved.emit(_active_attack_id, _combat_phase_index, hit, damage)
	if _active_attack_visual != null:
		_active_attack_visual.expire()
		_temp_visuals.erase(_active_attack_visual)
		_active_attack_visual = null
	_attack_cooldown = _active_attack.cooldown_seconds * phase.cooldown_scale
	_active_attack = null
	_active_attack_id = StringName()


func _attack_hits_target() -> bool:
	if _active_attack == null or not _target_valid():
		return false
	var target_position := _target.global_position
	match _active_attack.shape:
		TowmasterAttackDefinition.AttackShape.TARGET_ZONE:
			if _active_attack.radius <= 0.0 or not is_finite(_active_attack.radius):
				return false
			var delta := Vector2(target_position.x - _locked_target.x, target_position.z - _locked_target.z)
			return delta.length() <= _active_attack.radius
		TowmasterAttackDefinition.AttackShape.LANE:
			if _active_attack.length <= 0.0 or _active_attack.width <= 0.0:
				return false
			if not is_finite(_active_attack.length) or not is_finite(_active_attack.width):
				return false
			var lane := Vector3(target_position.x - _locked_origin.x, 0.0, target_position.z - _locked_origin.z)
			var projection := lane.dot(_attack_direction)
			if projection < 0.0 or projection > _active_attack.length:
				return false
			return (lane - _attack_direction * projection).length() <= _active_attack.width * 0.5
		TowmasterAttackDefinition.AttackShape.RING:
			if _active_attack.radius <= 0.0 or not is_finite(_active_attack.radius):
				return false
			var origin_delta := Vector2(target_position.x - _locked_origin.x, target_position.z - _locked_origin.z)
			return origin_delta.length() <= _active_attack.radius
		_:
			return false


func _spawn_attack_visual(attack: TowmasterAttackDefinition) -> void:
	if attack == null:
		return
	_prune_temp_visuals()
	if _temp_visuals.size() >= max_temp_visuals():
		return
	if _active_attack_visual != null:
		_active_attack_visual.expire()
		_temp_visuals.erase(_active_attack_visual)
		_active_attack_visual = null
	var visual := TowmasterHazard.new() as TowmasterHazardVisual
	add_child(visual)
	if not visual.configure_from_attack(attack, _locked_origin, _locked_target):
		visual.queue_free()
		return
	_active_attack_visual = visual
	_temp_visuals.append(visual)


func _apply_arena_pulse(phase: TowmasterPhaseCombatDefinition, delta: float) -> void:
	if phase == null or not _target_valid():
		return
	if _arena_state_id == PHASE_OPEN_DOCK:
		return
	if _arena_pulse_timer > 0.0:
		_arena_pulse_timer = maxf(0.0, _arena_pulse_timer - delta)
		return
	var hit := false
	if _arena_state_id == PHASE_CITATION_LANES:
		var local := to_local(_target.global_position)
		var ax := absf(local.x)
		hit = ax >= 2.3 and ax <= 4.7 and absf(local.z) <= 8.0
	elif _arena_state_id == PHASE_IMPOUND_FIELD:
		var local := to_local(_target.global_position)
		hit = local.x * local.x + local.z * local.z <= 4.5 * 4.5
	var damage := 0.0
	if hit:
		damage = _combat_profile_damage(BASE_ARENA_DAMAGE * phase.damage_scale)
		if _target.has_method("apply_damage"):
			_target.call("apply_damage", damage, self, _target.global_position)
	arena_hazard_pulsed.emit(_arena_state_id, hit, damage)
	_arena_pulse_timer = ARENA_PULSE_BASE * phase.cooldown_scale


func _configure_defeat_particles() -> void:
	var max_particles := FALLBACK_MAX_DEFEAT_PARTICLES
	if _combat_profile_valid():
		max_particles = clampi(combat_profile.max_defeat_particles, 0, FALLBACK_MAX_DEFEAT_PARTICLES)
	var density := _particle_density()
	var tickets := maxi(0, roundi(float(FALLBACK_TICKET_PARTICLES) * density))
	var sparks := maxi(0, roundi(float(FALLBACK_SPARK_PARTICLES) * density))
	var total := tickets + sparks
	if total > max_particles:
		var ratio := float(max_particles) / float(maxi(total, 1))
		tickets = maxi(0, roundi(float(tickets) * ratio))
		sparks = maxi(0, roundi(float(sparks) * ratio))
		if tickets + sparks > max_particles:
			sparks = max(0, max_particles - tickets)
	_defeat_ticket_particles = clampi(tickets, 0, max_particles)
	_defeat_spark_particles = clampi(sparks, 0, max(0, max_particles - _defeat_ticket_particles))


func max_temp_visuals() -> int:
	if not _combat_profile_valid():
		return 0
	return clampi(combat_profile.max_temp_visuals, 1, 6)


func _combat_profile_damage(value: float) -> float:
	var base := value if is_finite(value) else 0.0
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("get_difficulty_profile"):
		return base
	var profile: DifficultyProfile = game_state.get_difficulty_profile() as DifficultyProfile
	if profile == null or not (profile is DifficultyProfile):
		return base
	return profile.scaled_enemy_damage(base)


func _clear_temp_visuals() -> void:
	for visual in _temp_visuals:
		if is_instance_valid(visual):
			visual.expire()
	_temp_visuals.clear()


func _prune_temp_visuals() -> void:
	var kept: Array[TowmasterHazardVisual] = []
	for visual in _temp_visuals:
		if is_instance_valid(visual):
			kept.append(visual)
	_temp_visuals = kept
	if _active_attack_visual != null and not is_instance_valid(_active_attack_visual):
		_active_attack_visual = null


func _cancel_active_attack() -> void:
	_attack_in_telegraph = false
	_attack_cooldown = 0.0
	_telegraph_elapsed = 0.0
	_telegraph_duration = 0.0
	_active_attack = null
	_active_attack_id = StringName()
	if _active_attack_visual != null:
		_active_attack_visual.expire()
		_temp_visuals.erase(_active_attack_visual)
		_active_attack_visual = null


func _collect_warning_lights() -> void:
	if _warning_lights_root == null:
		return
	for child in _warning_lights_root.get_children():
		var light := child as OmniLight3D
		if light == null:
			continue
		light.shadow_enabled = false
		_warning_lights.append(light)


func _particle_density() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return 1.0
	return clampf(float(settings.get_value(&"video", &"particle_density", 1.0)), 0.25, 1.0)


func _reduced_flashes() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"video", &"reduced_flashes", false))


func _reduced_motion() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"accessibility", &"reduced_motion", false))


func _target_valid() -> bool:
	return _target != null and is_instance_valid(_target)
