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
	if walker.has_signal("golden_ball_enabled"):
		walker.golden_ball_enabled.connect(_on_golden_ball_enabled)
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


func _on_golden_ball_enabled(target: Node) -> void:
	_golden_ball.enable_for_boss(target)
	objective_changed.emit("FETCH THE GOLDEN TENNIS BALL")


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
