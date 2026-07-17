class_name ComplianceGull
extends EnemyAgent

signal target_marked(target: Node3D, duration: float)
signal dive_interrupted()
signal dive_started(target_position: Vector3)
signal dive_resolved(hit: bool)

enum DivePhase { NONE, DIVING, RECOVERING }

@export_range(0.2, 8.0, 0.1) var mark_duration := 2.4
@export_range(1.0, 40.0, 0.5) var alert_radius := 15.0
@export_range(0.1, 4.0, 0.05) var recovery_window := 0.85
@export_range(2.0, 30.0, 0.5) var dive_speed := 13.0
@export_range(0.1, 2.0, 0.05) var dive_hit_radius := 0.7
@export_range(0.2, 3.0, 0.05) var dive_timeout := 1.15
@export_range(2.0, 30.0, 0.5) var recovery_speed := 9.0

@onready var searchlight: GeometryInstance3D = get_node_or_null("Visual/Searchlight") as GeometryInstance3D

var _telegraph_active := false
var _recovering_until_msec := 0
var _searchlight_timer: Timer
var _dive_phase := DivePhase.NONE
var _dive_origin := Vector3.ZERO
var _dive_target_position := Vector3.ZERO
var _dive_elapsed := 0.0


func _ready() -> void:
	uses_gravity = false
	attack_kind = &"gull_mark_dive"
	super._ready()
	_searchlight_timer = Timer.new()
	_searchlight_timer.name = "SearchlightTimer"
	_searchlight_timer.one_shot = true
	_searchlight_timer.timeout.connect(_hide_searchlight)
	add_child(_searchlight_timer)
	telegraph_started.connect(_on_telegraph_started)
	state_changed.connect(_on_gull_state_changed)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_advance_dive(delta)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.rotation.z = lerp_angle(visual.rotation.z, clampf(-velocity.x * 0.045, -0.28, 0.28), minf(1.0, delta * 7.0))
		visual.position.y = 0.15 + sin(Time.get_ticks_msec() * 0.008) * 0.12


func _begin_attack() -> void:
	if Time.get_ticks_msec() < _recovering_until_msec:
		return
	super._begin_attack()


func _perform_attack() -> void:
	if not _target_valid():
		_hide_searchlight()
		return
	# Marking is communicated through the visible cone and caption signal. It only
	# alerts nearby enemies; it never applies an invisible damage or accuracy buff.
	target_marked.emit(target, mark_duration)
	get_tree().call_group(&"enemies", &"receive_alert", target, global_position, alert_radius)
	_dive_phase = DivePhase.DIVING
	_dive_origin = global_position
	# Lock the destination when the telegraph commits. A player who reacts and
	# leaves the marked spot avoids the hit; the dive never homes invisibly.
	_dive_target_position = target.global_position
	_dive_elapsed = 0.0
	dive_started.emit(_dive_target_position)
	_hide_searchlight()


func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	if (state == State.ATTACK and not _attack_committed) or _dive_phase == DivePhase.DIVING:
		_hide_searchlight()
		_dive_phase = DivePhase.NONE
		velocity = Vector3.ZERO
		_recovering_until_msec = Time.get_ticks_msec() + roundi(recovery_window * 1000.0)
		dive_interrupted.emit()


func _set_state(next: State) -> void:
	# EnemyAgent normally leaves ATTACK 0.2 seconds after firing. A Gull owns a
	# physical dive and readable return window, so hold that state until motion is
	# resolved. Damage/stun/death always interrupts immediately.
	if state == State.ATTACK and next == State.CHASE and _dive_phase != DivePhase.NONE:
		return
	if next == State.HURT or next == State.STUNNED or next == State.DEAD:
		_dive_phase = DivePhase.NONE
		velocity = Vector3.ZERO
	super._set_state(next)


func _advance_dive(delta: float) -> void:
	if _dive_phase == DivePhase.NONE or is_dead:
		return
	_dive_elapsed += delta
	if _dive_phase == DivePhase.DIVING:
		var remaining := global_position.distance_to(_dive_target_position)
		if remaining <= dive_hit_radius:
			_resolve_dive(_target_at_dive_point())
			return
		var step := minf(dive_speed * delta, remaining)
		var collision := move_and_collide(global_position.direction_to(_dive_target_position) * step)
		if collision != null:
			_resolve_dive(_collider_matches_target(collision.get_collider()))
			return
		if _dive_elapsed >= dive_timeout:
			_resolve_dive(false)
		return

	var return_distance := global_position.distance_to(_dive_origin)
	if return_distance <= 0.18 or _dive_elapsed >= dive_timeout + recovery_window:
		_finish_recovery()
		return
	var return_step := minf(recovery_speed * delta, return_distance)
	var return_collision := move_and_collide(global_position.direction_to(_dive_origin) * return_step)
	if return_collision != null:
		_finish_recovery()


func _resolve_dive(hit: bool) -> void:
	if _dive_phase != DivePhase.DIVING:
		return
	if hit and _target_valid() and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)
	dive_resolved.emit(hit)
	_dive_phase = DivePhase.RECOVERING
	_dive_elapsed = dive_timeout
	velocity = Vector3.ZERO


func _finish_recovery() -> void:
	_dive_phase = DivePhase.NONE
	_recovering_until_msec = Time.get_ticks_msec() + roundi(recovery_window * 1000.0)
	velocity = Vector3.ZERO
	super._set_state(State.CHASE)


func _target_at_dive_point() -> bool:
	return _target_valid() and target.global_position.distance_to(_dive_target_position) <= dive_hit_radius * 1.35


func _collider_matches_target(collider: Object) -> bool:
	if not _target_valid() or not collider is Node:
		return false
	var current := collider as Node
	while current != null:
		if current == target:
			return true
		current = current.get_parent()
	return false


func _on_telegraph_started(kind: StringName, duration: float) -> void:
	if kind != &"gull_mark_dive" or searchlight == null:
		return
	_telegraph_active = true
	searchlight.visible = true
	_searchlight_timer.stop()
	_searchlight_timer.wait_time = maxf(duration, 0.05)
	_searchlight_timer.start()


func _on_gull_state_changed(_previous: State, next: State) -> void:
	if next == State.STUNNED or next == State.HURT or next == State.DEAD:
		_hide_searchlight()


func _hide_searchlight() -> void:
	_telegraph_active = false
	if searchlight != null:
		searchlight.visible = false


func is_mark_telegraph_active() -> bool:
	return _telegraph_active


func is_dive_active() -> bool:
	return _dive_phase == DivePhase.DIVING


func is_dive_recovering() -> bool:
	return _dive_phase == DivePhase.RECOVERING
