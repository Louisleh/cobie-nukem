class_name SalmonCreekBossRuntime
extends Node

signal boss_state_changed(state: StringName, fraction: float)
signal narrative_message(text: String, duration: float)
signal objective_changed(text: String)
signal phase_caption(text: String, duration: float)

var walker: Node
var phase_rewards: Dictionary = {}
var phase_pickups: Array[Node] = []

var _pacing: SalmonCreekPacingProfile
var _golden_ball: GoldenBallFinale
var _objectives: ObjectiveTracker
var _spawn_pickup: Callable
var _cannon_attacks := 0
var _reward_timer: Timer


func configure(pacing: SalmonCreekPacingProfile, golden_ball: GoldenBallFinale, objectives: ObjectiveTracker, spawn_pickup: Callable) -> bool:
	if pacing == null or golden_ball == null or objectives == null or not spawn_pickup.is_valid():
		return false
	_pacing = pacing
	_golden_ball = golden_ball
	_objectives = objectives
	_spawn_pickup = spawn_pickup
	return true


func bind_walker(value: Node) -> bool:
	if value == null or value == walker:
		return false
	reset(false)
	walker = value
	if walker is EnemyAgent and walker.definition != null:
		walker.definition.preferred_distance = walker.definition.attack_range
		walker.definition.retreat_distance = _pacing.pressure_distance.x
		boss_state_changed.emit(_pacing.phase_id(0), walker.health_fraction())
		narrative_message.emit(_pacing.phase_cue(0), 2.5)
	if walker.has_signal("boss_phase_changed"):
		walker.boss_phase_changed.connect(_on_phase_changed)
	if walker.has_signal("attack_fired"):
		walker.attack_fired.connect(_on_attack_fired)
	if walker.has_signal("walker_defeated"):
		walker.walker_defeated.connect(_on_walker_defeated)
	return true


func has_active_walker() -> bool:
	return is_instance_valid(walker) and not bool(walker.get("is_dead"))


func reset(clear_summons := true) -> void:
	_cancel_reward_timer()
	if _golden_ball != null:
		_golden_ball.reset_reward()
	walker = null
	phase_rewards.clear()
	_cannon_attacks = 0
	for pickup in phase_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	phase_pickups.clear()
	if clear_summons and is_inside_tree():
		for summon in get_tree().get_nodes_in_group(&"boss_summons"):
			summon.queue_free()

func _on_phase_changed(_previous: int, phase: int) -> void:
	if not is_instance_valid(walker):
		return
	boss_state_changed.emit(_pacing.phase_id(phase), walker.health_fraction())
	var cue := _pacing.phase_cue(phase)
	if not cue.is_empty():
		phase_caption.emit(cue, 3.0)
		narrative_message.emit(cue, 3.0)
	if phase_rewards.has(phase):
		return
	var recovery := _pacing.recovery_drop(phase)
	if recovery.is_empty():
		return
	phase_rewards[phase] = true
	var pickup: Node = _spawn_pickup.call(String(recovery.scene), recovery.position)
	if pickup != null:
		phase_pickups.append(pickup)
	narrative_message.emit("ARENA RECOVERY DROP DEPLOYED", 2.0)


func _on_attack_fired(_kind: StringName) -> void:
	if not is_instance_valid(walker) or int(walker.get("boss_phase")) != 0:
		return
	_cannon_attacks += 1
	var summon_interval := int(walker.get("summon_attack_interval"))
	if summon_interval > 0 and _cannon_attacks % summon_interval == 0:
		narrative_message.emit("DRONE REINFORCEMENT DEPLOYED", 2.0)


func _on_walker_defeated() -> void:
	boss_state_changed.emit(&"defeated", 0.0)
	_objectives.record(ObjectiveDefinition.Kind.DEFEAT, &"animal_control_walker")
	_clear_boss_summons()
	_schedule_finale_reward()


func _schedule_finale_reward() -> void:
	_cancel_reward_timer()
	_reward_timer = Timer.new()
	_reward_timer.name = "FinaleRewardTimer"
	_reward_timer.one_shot = true
	# The ball is a victory reward, not a concurrent boss mechanic. Wait through
	# the Walker's complete authored collapse and every summoned enemy's pop.
	var linger := float(walker.get("death_linger_seconds")) if is_instance_valid(walker) else 2.8
	_reward_timer.wait_time = maxf(linger + 0.08, 0.1)
	_reward_timer.timeout.connect(_reveal_finale_reward)
	_reward_timer.timeout.connect(_reward_timer.queue_free)
	add_child(_reward_timer)
	_reward_timer.start()


func _reveal_finale_reward() -> void:
	_reward_timer = null
	_clear_boss_summons()
	_golden_ball.enable_as_reward()
	objective_changed.emit("RECOVER THE GOLDEN TENNIS BALL")
	narrative_message.emit("WALKER DESTROYED — GOLDEN BALL RELEASED.", 3.0)


func _clear_boss_summons() -> void:
	if not is_inside_tree():
		return
	for summon in get_tree().get_nodes_in_group(&"boss_summons"):
		if not is_instance_valid(summon):
			continue
		if summon is EnemyAgent and not summon.is_dead:
			summon.apply_damage(1000000.0, walker, summon.global_position)
		elif not summon is EnemyAgent:
			summon.queue_free()


func _cancel_reward_timer() -> void:
	if _reward_timer != null and is_instance_valid(_reward_timer):
		_reward_timer.queue_free()
	_reward_timer = null
