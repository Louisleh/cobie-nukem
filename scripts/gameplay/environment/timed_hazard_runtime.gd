class_name TimedHazardRuntime
extends Node3D

signal phase_changed(hazard_id: StringName, phase: Phase)
signal target_affected(hazard_id: StringName, target: Node, damage: float, impulse: Vector3)

enum Phase {
	IDLE,
	WARNING,
	ACTIVE,
	RECOVERY,
}

@export var definition: TimedHazardDefinition
@export var start_on_ready := true
@export var assist_enabled := false

var phase := Phase.IDLE
var _generation := 0
var _phase_generation := -1
var _tick_generation := -1
var _targets: Dictionary = {}
var _area: Area3D
var _phase_timer: Timer
var _tick_timer: Timer


func _ready() -> void:
	_setup_timers()
	_setup_area()
	if start_on_ready:
		start_hazard()


func _exit_tree() -> void:
	_generation += 1
	_targets.clear()
	if _phase_timer != null:
		_phase_timer.stop()
	if _tick_timer != null:
		_tick_timer.stop()


func configure(value: TimedHazardDefinition, should_start := true) -> void:
	definition = value
	start_on_ready = should_start
	if is_inside_tree():
		_setup_area()
		reset_hazard(should_start)


func start_hazard() -> void:
	_generation += 1
	_stop_timers()
	if definition == null or not definition.enabled or not definition.validate().is_empty():
		_set_phase(Phase.IDLE)
		return
	_enter_warning(_generation)


func reset_hazard(restart := false) -> void:
	_generation += 1
	_stop_timers()
	_prune_targets()
	_set_phase(Phase.IDLE)
	if restart and definition != null and definition.enabled and definition.validate().is_empty():
		_enter_warning(_generation)


func register_target(target: Node) -> void:
	if target == null or not is_instance_valid(target) or not _target_matches_policy(target):
		return
	_targets[target.get_instance_id()] = target


func unregister_target(target: Node) -> void:
	if target != null:
		_targets.erase(target.get_instance_id())


func apply_active_effects() -> int:
	if phase != Phase.ACTIVE or definition == null:
		return 0
	var intensity := definition.intensity_for_assist(assist_enabled)
	if intensity <= 0.0:
		return 0
	var affected := 0
	for instance_id in _targets.keys():
		var target := _targets.get(instance_id) as Node
		if target == null or not is_instance_valid(target) or not _target_matches_policy(target):
			_targets.erase(instance_id)
			continue
		var damage := clampf(definition.damage_per_tick * intensity, 0.0, TimedHazardDefinition.MAX_DAMAGE_PER_TICK)
		var impulse := _bounded_impulse(definition.environment_impulse * intensity)
		if damage > 0.0 and target.has_method("apply_damage"):
			target.call("apply_damage", damage, self, global_position)
		if not impulse.is_zero_approx() and target.has_method("apply_environment_impulse"):
			target.call("apply_environment_impulse", impulse, definition.horizontal_impulse_cap, definition.vertical_impulse_cap)
		target_affected.emit(definition.id, target, damage, impulse)
		affected += 1
	return affected


func _setup_timers() -> void:
	if _phase_timer == null:
		_phase_timer = Timer.new()
		_phase_timer.name = "PhaseTimer"
		_phase_timer.one_shot = true
		_phase_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		_phase_timer.timeout.connect(_on_phase_timeout)
		add_child(_phase_timer)
	if _tick_timer == null:
		_tick_timer = Timer.new()
		_tick_timer.name = "TickTimer"
		_tick_timer.one_shot = false
		_tick_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		_tick_timer.timeout.connect(_on_tick_timeout)
		add_child(_tick_timer)


func _setup_area() -> void:
	if _area == null:
		_area = Area3D.new()
		_area.name = "HazardArea"
		_area.collision_layer = 0
		_area.monitorable = false
		_area.body_entered.connect(register_target)
		_area.body_exited.connect(unregister_target)
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_shape.shape = BoxShape3D.new()
		_area.add_child(collision_shape)
		add_child(_area)
	if definition != null:
		_area.collision_mask = definition.collision_mask
		var shape := _area.get_node("CollisionShape3D") as CollisionShape3D
		if shape != null and shape.shape is BoxShape3D:
			(shape.shape as BoxShape3D).size = definition.volume_size


func _enter_warning(generation: int) -> void:
	if generation != _generation:
		return
	_set_phase(Phase.WARNING)
	_schedule_phase(definition.warning_seconds, generation)


func _enter_active(generation: int) -> void:
	if generation != _generation:
		return
	_set_phase(Phase.ACTIVE)
	apply_active_effects()
	_tick_generation = generation
	_tick_timer.wait_time = maxf(0.01, definition.tick_seconds)
	_tick_timer.start()
	_schedule_phase(definition.active_seconds, generation)


func _enter_recovery(generation: int) -> void:
	if generation != _generation:
		return
	_tick_timer.stop()
	_set_phase(Phase.RECOVERY)
	_schedule_phase(definition.recovery_seconds, generation)


func _schedule_phase(seconds: float, generation: int) -> void:
	_phase_generation = generation
	_phase_timer.wait_time = maxf(0.001, seconds)
	_phase_timer.start()


func _on_phase_timeout() -> void:
	if _phase_generation != _generation:
		return
	match phase:
		Phase.WARNING:
			_enter_active(_generation)
		Phase.ACTIVE:
			_enter_recovery(_generation)
		Phase.RECOVERY:
			if definition != null and definition.repeat_cycle:
				_enter_warning(_generation)
			else:
				_set_phase(Phase.IDLE)


func _on_tick_timeout() -> void:
	if _tick_generation != _generation or phase != Phase.ACTIVE:
		return
	apply_active_effects()


func _set_phase(value: Phase) -> void:
	if phase == value:
		return
	phase = value
	phase_changed.emit(definition.id if definition != null else &"", phase)


func _stop_timers() -> void:
	if _phase_timer != null:
		_phase_timer.stop()
	if _tick_timer != null:
		_tick_timer.stop()
	_phase_generation = -1
	_tick_generation = -1


func _target_matches_policy(target: Node) -> bool:
	if definition == null:
		return false
	match definition.target_policy:
		TimedHazardDefinition.TargetPolicy.PLAYER_ONLY:
			return target.is_in_group(&"player") or target.is_in_group(&"damageable_player")
		TimedHazardDefinition.TargetPolicy.DAMAGEABLES:
			return target.has_method("apply_damage") or target.has_method("apply_environment_impulse")
	return false


func _prune_targets() -> void:
	for instance_id in _targets.keys():
		var target := _targets.get(instance_id) as Node
		if target == null or not is_instance_valid(target) or not _target_matches_policy(target):
			_targets.erase(instance_id)


func _bounded_impulse(value: Vector3) -> Vector3:
	var horizontal := Vector2(value.x, value.z).limit_length(definition.horizontal_impulse_cap)
	return Vector3(horizontal.x, clampf(value.y, -definition.vertical_impulse_cap, definition.vertical_impulse_cap), horizontal.y)
