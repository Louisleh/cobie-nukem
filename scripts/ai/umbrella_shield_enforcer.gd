class_name UmbrellaShieldEnforcer
extends EnemyAgent

signal guard_state_changed(previous_state: GuardState, current_state: GuardState)
signal shield_broken()

enum GuardState {
	GUARDING,
	OPENING,
	RECOVERING,
	BROKEN,
	DISABLED,
}

const DEFAULT_PROJECTILE := preload("res://scenes/enemies/explosive_acorn.tscn")

@export var projectile_scene: PackedScene = DEFAULT_PROJECTILE
@export_range(0.0, 9999.0, 0.01) var projectile_speed := 10.0
@export_range(0.0, 5.0, 0.01) var projectile_splash_radius := 0.0
@export_range(0.0, 3.0, 0.02) var base_opening_window_seconds := 0.28
@export_range(0.0, 3.0, 0.02) var base_recovery_window_seconds := 0.18

@onready var directional_shield := get_node_or_null("DirectionalShieldComponent") as DirectionalShieldComponent

var guard_state := GuardState.DISABLED
var _opening_window_seconds := 0.0
var _recovery_window_seconds := 0.0
var _is_recovering := false
var _timer_mode := _TimerMode.IDLE
var _guard_timer: Timer
var _guard_timer_generation := 0
var _active_guard_timer_generation := -1

enum _TimerMode { IDLE, OPENING, RECOVERY }


func _ready() -> void:
	super._ready()
	attack_kind = &"umbrella_bolt"
	_opening_window_seconds = maxf(0.05, base_opening_window_seconds)
	_recovery_window_seconds = maxf(0.05, base_recovery_window_seconds)
	_guard_timer = Timer.new()
	_guard_timer.name = "UmbrellaGuardTimer"
	_guard_timer.one_shot = true
	_guard_timer.timeout.connect(_on_guard_timer_timeout)
	add_child(_guard_timer)
	state_changed.connect(_on_state_changed)
	if directional_shield == null:
		push_error("UmbrellaShieldEnforcer requires a DirectionalShieldComponent: %s" % name)
	else:
		directional_shield.shield_broken.connect(_on_directional_shield_broken)
		directional_shield.shield_reset.connect(_on_directional_shield_reset)
	_refresh_guard_state()


func apply_difficulty(profile: DifficultyProfile) -> void:
	super.apply_difficulty(profile)
	if _aggression_scale <= 0.0001:
		return
	# Difficulty affects timing and aggression pressure without changing the base shield
	# behavior or requiring per-use timer allocation.
	_opening_window_seconds = maxf(0.05, base_opening_window_seconds / _aggression_scale)
	_recovery_window_seconds = maxf(0.05, base_recovery_window_seconds / _aggression_scale)
	_refresh_guard_state()


func _on_state_changed(_previous: State, next: State) -> void:
	if is_dead:
		_cancel_guard_timer()
		_set_guard_state(GuardState.DISABLED)
		_apply_guarding(false)
		return
	if _is_shield_broken():
		_cancel_guard_timer()
		_set_guard_state(GuardState.BROKEN)
		_apply_guarding(false)
		return
	match next:
		State.IDLE, State.CHASE, State.ALERT:
			if _is_recovering:
				_set_guard_state(GuardState.RECOVERING)
				_apply_guarding(false)
			else:
				_cancel_guard_timer()
				_set_guard_state(GuardState.GUARDING)
				_apply_guarding(true)
		State.ATTACK:
			_is_recovering = false
			_set_guard_state(GuardState.GUARDING)
			_apply_guarding(true)
			var open_delay := maxf(definition.telegraph_seconds - _opening_window_seconds, 0.0)
			if open_delay <= 0.0:
				_set_guard_state(GuardState.OPENING)
				_apply_guarding(false)
			else:
				_start_guard_timer(_TimerMode.OPENING, open_delay)
		_:
			_is_recovering = false
			_cancel_guard_timer()
			_set_guard_state(GuardState.DISABLED)
			_apply_guarding(false)


func _perform_attack() -> void:
	if not _target_valid():
		_start_guard_recovery()
		return
	_spawn_umbrella_projectile()
	_start_guard_recovery()


func _spawn_umbrella_projectile() -> Node3D:
	if projectile_scene == null:
		return null
	return _spawn_projectile(projectile_scene, projectile_speed, projectile_splash_radius)


func _on_directional_shield_broken() -> void:
	_is_recovering = false
	_cancel_guard_timer()
	_set_guard_state(GuardState.BROKEN)
	_apply_guarding(false)
	shield_broken.emit()


func _on_directional_shield_reset() -> void:
	_is_recovering = false
	_cancel_guard_timer()
	_refresh_guard_state()


func get_opening_window_seconds() -> float:
	return _opening_window_seconds


func get_recovery_window_seconds() -> float:
	return _recovery_window_seconds


func apply_recall_stagger(multiplier: float) -> void:
	if is_dead:
		return
	# The upgrade changes shield-control utility, never primary projectile damage.
	if directional_shield != null and directional_shield.is_guarding():
		directional_shield.apply_stagger_multiplier(multiplier)
	stun(0.7 * maxf(multiplier, 1.0))


func _start_guard_recovery() -> void:
	if is_dead or _is_shield_broken():
		_set_guard_state(GuardState.BROKEN if _is_shield_broken() else GuardState.DISABLED)
		_apply_guarding(false)
		return
	_is_recovering = true
	_set_guard_state(GuardState.RECOVERING)
	_apply_guarding(false)
	if _recovery_window_seconds <= 0.0:
		_complete_guard_recovery()
		return
	_start_guard_timer(_TimerMode.RECOVERY, _recovery_window_seconds)


func _complete_guard_recovery() -> void:
	_is_recovering = false
	_active_guard_timer_generation = -1
	_refresh_guard_state()


func _on_guard_timer_timeout() -> void:
	if _active_guard_timer_generation < 0 or _active_guard_timer_generation != _guard_timer_generation:
		return
	match _timer_mode:
		_TimerMode.OPENING:
			_active_guard_timer_generation = -1
			_set_guard_state(GuardState.OPENING)
			_apply_guarding(false)
			_timer_mode = _TimerMode.IDLE
		_TimerMode.RECOVERY:
			_active_guard_timer_generation = -1
			_timer_mode = _TimerMode.IDLE
			_complete_guard_recovery()
		_:
			_active_guard_timer_generation = -1
			_timer_mode = _TimerMode.IDLE


func _refresh_guard_state() -> void:
	if is_dead:
		_set_guard_state(GuardState.DISABLED)
		_apply_guarding(false)
		return
	if _is_shield_broken():
		_set_guard_state(GuardState.BROKEN)
		_apply_guarding(false)
		return
	if _is_recovering:
		_set_guard_state(GuardState.RECOVERING)
		_apply_guarding(false)
		return
	match state:
		State.IDLE, State.CHASE, State.ALERT:
			_set_guard_state(GuardState.GUARDING)
			_apply_guarding(true)
		State.ATTACK:
			_set_guard_state(GuardState.OPENING)
			_apply_guarding(false)
		_:
			_set_guard_state(GuardState.DISABLED)
			_apply_guarding(false)


func _start_guard_timer(mode: _TimerMode, wait_seconds: float) -> void:
	_guard_timer_generation += 1
	_active_guard_timer_generation = _guard_timer_generation
	_timer_mode = mode
	_guard_timer.stop()
	_guard_timer.wait_time = wait_seconds
	if wait_seconds <= 0.0:
		call_deferred("_on_guard_timer_timeout")
	else:
		_guard_timer.start()


func _cancel_guard_timer() -> void:
	if _guard_timer == null:
		return
	_guard_timer.stop()
	_active_guard_timer_generation = -1
	_guard_timer_generation += 1
	_timer_mode = _TimerMode.IDLE


func _apply_guarding(guarding: bool) -> void:
	if directional_shield == null:
		return
	directional_shield.set_guarding(guarding)


func _set_guard_state(next_state: GuardState) -> void:
	if guard_state == next_state:
		return
	var previous := guard_state
	guard_state = next_state
	guard_state_changed.emit(previous, guard_state)


func _is_shield_broken() -> bool:
	if directional_shield == null:
		return false
	return directional_shield.is_permanently_broken()
