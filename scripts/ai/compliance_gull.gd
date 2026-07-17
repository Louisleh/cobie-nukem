class_name ComplianceGull
extends EnemyAgent

signal target_marked(target: Node3D, duration: float)
signal dive_interrupted()

@export_range(0.2, 8.0, 0.1) var mark_duration := 2.4
@export_range(1.0, 40.0, 0.5) var alert_radius := 15.0
@export_range(0.1, 4.0, 0.05) var recovery_window := 0.85

@onready var searchlight: GeometryInstance3D = get_node_or_null("Visual/Searchlight") as GeometryInstance3D

var _telegraph_active := false
var _recovering_until_msec := 0
var _searchlight_timer: Timer


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
	if global_position.distance_to(target.global_position) <= definition.attack_range * 1.2 and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)
	_recovering_until_msec = Time.get_ticks_msec() + roundi(recovery_window * 1000.0)
	_hide_searchlight()


func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	if state == State.ATTACK and not _attack_committed:
		_hide_searchlight()
		_recovering_until_msec = Time.get_ticks_msec() + roundi(recovery_window * 1000.0)
		dive_interrupted.emit()


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

