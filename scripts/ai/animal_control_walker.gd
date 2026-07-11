class_name AnimalControlWalker
extends EnemyAgent

signal boss_phase_changed(previous: BossPhase, current: BossPhase)
signal armor_panels_broken
signal golden_ball_enabled(boss: AnimalControlWalker)
signal walker_defeated

enum BossPhase { CANNONS, EXPOSED_CORE, CHARGE, GOLDEN_BALL, DEFEATED }

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const DRONE := preload("res://scenes/enemies/leash_enforcement_drone.tscn")

var boss_phase := BossPhase.CANNONS
var _attack_count := 0
var _finishing_with_ball := false

func _ready() -> void:
	if definition != null:
		definition = definition.duplicate(true)
	super._ready()
	attack_kind = &"walker_cannons"
	auto_aim_threat = 2.0

func apply_damage(amount: float, source: Node = null, hit_position := Vector3.ZERO) -> float:
	if boss_phase == BossPhase.GOLDEN_BALL and not _finishing_with_ball:
		return 0.0
	var applied := super.apply_damage(amount, source, hit_position)
	_update_phase()
	return applied

func strike_with_golden_ball(source: Node = null) -> void:
	if boss_phase != BossPhase.GOLDEN_BALL or is_dead:
		return
	_finishing_with_ball = true
	super.apply_damage(maxf(health, 1.0), source, get_auto_aim_position())
	_finishing_with_ball = false

func _damage_multiplier(_hit_position: Vector3) -> float:
	return 0.62 if boss_phase == BossPhase.CANNONS else 1.0

func _perform_attack() -> void:
	_attack_count += 1
	match boss_phase:
		BossPhase.CANNONS:
			_spawn_projectile(BOLT, 12.0)
			if _attack_count % 3 == 0:
				_spawn_drone()
		BossPhase.EXPOSED_CORE:
			_spawn_projectile(BOLT, 14.0, 1.5)
			get_tree().create_timer(0.15).timeout.connect(func() -> void:
				if not is_dead:
					_spawn_projectile(BOLT, 14.0, 1.5)
			)
		BossPhase.CHARGE:
			if _target_valid():
				var direction := global_position.direction_to(target.global_position)
				velocity = Vector3(direction.x, 0.0, direction.z).normalized() * definition.move_speed * 4.5
				move_and_slide()
				if global_position.distance_to(target.global_position) < definition.attack_range * 2.0 and target.has_method("apply_damage"):
					target.apply_damage(definition.attack_damage * 1.4, self, target.global_position)

func _update_phase() -> void:
	if is_dead:
		_set_boss_phase(BossPhase.DEFEATED)
		return
	var fraction := health_fraction()
	if fraction <= 0.15:
		health = maxf(health, definition.max_health * 0.1)
		_set_boss_phase(BossPhase.GOLDEN_BALL)
	elif fraction <= 0.45:
		_set_boss_phase(BossPhase.CHARGE)
	elif fraction <= 0.75:
		_set_boss_phase(BossPhase.EXPOSED_CORE)

func _set_boss_phase(next: BossPhase) -> void:
	if boss_phase == next:
		return
	var previous := boss_phase
	boss_phase = next
	match boss_phase:
		BossPhase.EXPOSED_CORE:
			attack_kind = &"core_barrage"
			definition.attack_cooldown = 1.25
			armor_panels_broken.emit()
			for panel_name in ["PanelLeft", "PanelRight"]:
				var panel := get_node_or_null("Visual/%s" % panel_name) as Node3D
				if panel != null:
					panel.visible = false
		BossPhase.CHARGE:
			attack_kind = &"walker_charge"
			definition.attack_range = 5.0
			definition.telegraph_seconds = 0.8
		BossPhase.GOLDEN_BALL:
			attack_kind = &"final_vulnerability"
			velocity = Vector3.ZERO
			golden_ball_enabled.emit(self)
		BossPhase.DEFEATED:
			walker_defeated.emit()
	boss_phase_changed.emit(previous, boss_phase)

func _spawn_drone() -> void:
	if not is_inside_tree():
		return
	var drone := DRONE.instantiate() as EnemyAgent
	get_tree().current_scene.add_child(drone)
	drone.global_position = global_position + global_basis.x * (2.5 if _attack_count % 2 == 0 else -2.5) + Vector3.UP * 1.0
	drone.set_target(target)
