class_name MutantGroundskeeper
extends EnemyAgent

const CHARGE_SECONDS := 0.46
const CONTACT_RANGE := 1.15

var _charging := false
var _charge_elapsed := 0.0
var _charge_direction := Vector3.ZERO
var _charge_hit := false

func _ready() -> void:
	super._ready()
	attack_kind = &"mower_charge"

func _physics_process(delta: float) -> void:
	if not _charging or state != State.ATTACK or is_dead:
		_charging = false
		super._physics_process(delta)
		return
	if not _target_valid():
		_finish_charge()
		return
	_charge_elapsed += delta
	_stabilize_ground_height()
	if is_dead:
		return
	_update_locomotion_presentation()
	_health_label_time = maxf(0.0, _health_label_time - delta)
	_update_health_bar_presentation()
	velocity.x = _charge_direction.x * definition.move_speed * _speed_scale * 3.0
	velocity.z = _charge_direction.z * definition.move_speed * _speed_scale * 3.0
	if uses_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	_stabilize_ground_height()
	if is_dead:
		return
	if not _charge_hit and _can_damage_target(CONTACT_RANGE) and target.has_method("apply_damage"):
		_charge_hit = true
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)
	if _charge_elapsed >= CHARGE_SECONDS:
		_finish_charge()

func _begin_attack() -> void:
	super._begin_attack()
	if state == State.ATTACK and _target_valid():
		var direction := global_position.direction_to(target.global_position)
		_charge_direction = Vector3(direction.x, 0.0, direction.z).normalized()

func _face_target(delta: float) -> void:
	if state == State.ATTACK and _charge_direction.length_squared() > 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(-_charge_direction.x, -_charge_direction.z), minf(1.0, delta * 12.0))
		return
	super._face_target(delta)

func _perform_attack() -> void:
	if not _target_valid():
		return
	_charge_elapsed = 0.0
	_charge_hit = false
	_charging = true

func _finish_charge() -> void:
	_charging = false
	velocity.x = 0.0
	velocity.z = 0.0
	_cooldown = definition.attack_cooldown / maxf(_aggression_scale, 0.1)
	_set_state(State.CHASE)

func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	_charging = false
