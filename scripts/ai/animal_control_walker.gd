class_name AnimalControlWalker
extends EnemyAgent

signal boss_phase_changed(previous: BossPhase, current: BossPhase)
signal armor_panels_broken
signal golden_ball_enabled(boss: AnimalControlWalker)
signal walker_defeated

enum BossPhase { CANNONS, EXPOSED_CORE, CHARGE, GOLDEN_BALL, DEFEATED }

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const DRONE := preload("res://scenes/enemies/leash_enforcement_drone.tscn")

@export var combat_profile: WalkerCombatProfile

var boss_phase := BossPhase.CANNONS
var _attack_count := 0
var _finishing_with_ball := false
var summon_attack_interval := 3


func _ready() -> void:
	if combat_profile == null:
		push_error("AnimalControlWalker requires a WalkerCombatProfile: %s" % name)
		combat_profile = WalkerCombatProfile.new()
	var errors: PackedStringArray = combat_profile.validate()
	if not errors.is_empty():
		for error in errors:
			push_error("Invalid WalkerCombatProfile for %s: %s" % [name, error])
	if definition != null:
		definition = definition.duplicate(true)
	super._ready()
	auto_aim_threat = 2.0
	summon_attack_interval = maxi(1, combat_profile.summon_attack_interval)
	attack_kind = combat_profile.phase_attack_kind(BossPhase.CANNONS)
	_apply_phase_tuning(BossPhase.CANNONS)


func apply_damage(amount: float, source: Node = null, hit_position := Vector3.ZERO) -> float:
	if boss_phase == BossPhase.GOLDEN_BALL and not _finishing_with_ball:
		return 0.0
	# A normal weapon hit may reach the next phase boundary but cannot kill the
	# Walker or consume several authored phases at once. This preserves each
	# telegraph and recovery window even under extreme damage or difficulty mods.
	var bounded_amount := amount
	if not _finishing_with_ball and boss_phase < BossPhase.GOLDEN_BALL:
		var floor_health := _max_health * combat_profile.phase_transition_fraction(boss_phase)
		var multiplier := maxf(_damage_multiplier(hit_position), 0.001)
		bounded_amount = minf(amount, maxf(0.0, health - floor_health) / multiplier)
	var applied := super.apply_damage(bounded_amount, source, hit_position)
	_update_phase()
	return applied


func strike_with_golden_ball(source: Node = null) -> void:
	if boss_phase != BossPhase.GOLDEN_BALL or is_dead:
		return
	_finishing_with_ball = true
	super.apply_damage(maxf(health, 1.0), source, get_auto_aim_position())
	_finishing_with_ball = false
	if is_dead:
		_set_boss_phase(BossPhase.DEFEATED)


func _damage_multiplier(hit_position: Vector3) -> float:
	var weak_point := super._damage_multiplier(hit_position)
	var exposed_bonus := combat_profile.phase_weak_point_multiplier(boss_phase) if weak_point > 1.0 else 1.0
	return weak_point * combat_profile.phase_damage_multiplier(boss_phase) * exposed_bonus


func _perform_attack() -> void:
	_attack_count += 1
	match boss_phase:
		BossPhase.CANNONS:
			_spawn_projectile(BOLT, combat_profile.phase_projectile_speed(boss_phase))
			if _attack_count % summon_attack_interval == 0 and _can_spawn_summon():
				_spawn_drone()
		BossPhase.EXPOSED_CORE:
			_spawn_projectile(BOLT, combat_profile.phase_projectile_speed(boss_phase))
			# Bound method rather than a lambda: the connection dies with the
			# walker instead of firing into a freed instance after a reset.
			var followup := Timer.new()
			followup.name = "FollowupBoltTimer"
			followup.one_shot = true
			followup.wait_time = combat_profile.followup_bolt_delay
			followup.timeout.connect(_fire_followup_bolt)
			followup.timeout.connect(followup.queue_free)
			add_child(followup)
			followup.start()
		BossPhase.CHARGE:
			if _target_valid():
				var direction := global_position.direction_to(target.global_position)
				velocity = Vector3(direction.x, 0.0, direction.z).normalized() * definition.move_speed * combat_profile.phase_charge_speed_multiplier(boss_phase)
				move_and_slide()
				if global_position.distance_to(target.global_position) < definition.attack_range * 2.0 and target.has_method("apply_damage"):
					target.apply_damage(definition.attack_damage * 1.4, self, target.global_position)


func _update_phase() -> void:
	if is_dead:
		_set_boss_phase(BossPhase.DEFEATED)
		return
	var fraction: float = health_fraction()
	if boss_phase == BossPhase.GOLDEN_BALL:
		return
	var next_phase := boss_phase + 1
	if next_phase < BossPhase.DEFEATED:
		var threshold: float = combat_profile.phase_transition_fraction(boss_phase)
		if fraction <= threshold:
			if next_phase == BossPhase.GOLDEN_BALL:
				health = maxf(health, definition.max_health * combat_profile.golden_ball_health_floor_fraction)
				_update_health_bar()
			_set_boss_phase(next_phase)


func _set_boss_phase(next: BossPhase) -> void:
	if boss_phase == next:
		return
	var previous := boss_phase
	boss_phase = next
	_apply_phase_tuning(next)
	match boss_phase:
		BossPhase.EXPOSED_CORE:
			armor_panels_broken.emit()
			for panel_name in ["PanelLeft", "PanelRight"]:
				var panel := get_node_or_null("Visual/%s" % panel_name) as Node3D
				if panel != null:
					panel.visible = false
		BossPhase.GOLDEN_BALL:
			health = maxf(health, definition.max_health * combat_profile.golden_ball_health_floor_fraction)
			_update_health_bar()
			velocity = Vector3.ZERO
			golden_ball_enabled.emit(self)
		BossPhase.DEFEATED:
			walker_defeated.emit()
		_:
			pass
	boss_phase_changed.emit(previous, boss_phase)


func _fire_followup_bolt() -> void:
	if not is_dead:
		_spawn_projectile(BOLT, combat_profile.phase_projectile_speed(BossPhase.EXPOSED_CORE), 1.5)


func _spawn_drone() -> void:
	if not is_inside_tree():
		return
	var summon_source: PackedScene = combat_profile.summon_scene if combat_profile.summon_scene != null else DRONE
	var drone := summon_source.instantiate() as EnemyAgent
	# Summons live outside the encounter runner's actor list; the group lets a
	# checkpoint reset clear them together with the walker.
	drone.add_to_group(&"boss_summons")
	drone.set_meta(&"walker_owner_id", get_instance_id())
	get_tree().current_scene.add_child(drone)
	drone.global_position = global_position + global_basis.x * (2.5 if _attack_count % 2 == 0 else -2.5) + Vector3.UP * 1.0
	drone.set_target(target)


func _can_spawn_summon() -> bool:
	var owned := 0
	for summon in get_tree().get_nodes_in_group(&"boss_summons"):
		if summon.get_meta(&"walker_owner_id", 0) == get_instance_id():
			owned += 1
	return owned < combat_profile.max_live_summons


func _apply_phase_tuning(phase: BossPhase) -> void:
	if definition == null:
		return
	definition.attack_range = combat_profile.phase_attack_range(phase)
	definition.attack_cooldown = combat_profile.phase_attack_cooldown(phase)
	definition.telegraph_seconds = combat_profile.phase_telegraph_seconds_for_phase(phase)
	attack_kind = combat_profile.phase_attack_kind(phase)
	if phase == BossPhase.GOLDEN_BALL:
		health = maxf(health, definition.max_health * combat_profile.golden_ball_health_floor_fraction)
		_update_health_bar()
