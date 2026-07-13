class_name EnemySpritePresentation
extends Node

## Low-frame-rate, deterministic presentation layer for billboard enemies.
## Authored atlases use four directional locomotion views plus four explicit
## reaction poses. Elite and boss sprites share the same state vocabulary even
## when an atlas is not assigned, without duplicating their large source texture.

const STATE_IDLE := 0
const STATE_ALERT := 1
const STATE_CHASE := 2
const STATE_ATTACK := 3
const STATE_HURT := 4
const STATE_STUNNED := 5
const STATE_DEAD := 6
const DIRECTION_FRAMES: Array[int] = [0, 1, 2, 3, 3, 3, 2, 1]

@export var sprite_path := NodePath("../Visual/DetailedSprite")
@export var atlas_texture: Texture2D
@export_range(6.0, 12.0, 1.0) var animation_fps := 8.0
@export_range(0.25, 1.5, 0.05) var motion_scale := 1.0
@export var attack_accent := Color("ffb12b")

var _actor: EnemyAgent
var _sprite: Sprite3D
var _base_position := Vector3.ZERO
var _base_scale := Vector3.ONE
var _base_rotation := Vector3.ZERO
var _base_modulate := Color.WHITE
var _state := STATE_IDLE
var _direction_index := 0
var _pose_step := 0
var _tick_accumulator := 0.0
var _hit_side := 1.0
var _accent_steps := 0


func _ready() -> void:
	_actor = get_parent() as EnemyAgent
	_sprite = get_node_or_null(sprite_path) as Sprite3D
	if _actor == null or _sprite == null:
		push_error("EnemySpritePresentation requires an EnemyAgent parent and Sprite3D: %s" % get_path())
		set_process(false)
		return
	_base_position = _sprite.position
	_base_scale = _sprite.scale
	_base_rotation = _sprite.rotation
	_base_modulate = _sprite.modulate
	_state = int(_actor.state)
	if atlas_texture != null:
		_sprite.texture = atlas_texture
		_sprite.hframes = 4
		_sprite.vframes = 2
		_sprite.frame = 0
	_actor.state_changed.connect(_on_state_changed)
	_actor.damaged.connect(_on_damaged)
	if _actor.has_signal(&"shield_broken"):
		_actor.connect(&"shield_broken", _on_elite_break)
	if _actor.has_signal(&"boss_phase_changed"):
		_actor.connect(&"boss_phase_changed", _on_boss_phase_changed)
	_apply_pose()


func _process(delta: float) -> void:
	_tick_accumulator += delta
	var tick_seconds := 1.0 / animation_fps
	if _tick_accumulator < tick_seconds:
		return
	var elapsed_ticks := maxi(1, floori(_tick_accumulator / tick_seconds))
	_tick_accumulator = fmod(_tick_accumulator, tick_seconds)
	_pose_step = wrapi(_pose_step + elapsed_ticks, 0, 4)
	_accent_steps = maxi(0, _accent_steps - elapsed_ticks)
	_direction_index = _direction_from_camera()
	_apply_pose()


static func direction_index_from_vectors(forward: Vector3, observer_direction: Vector3) -> int:
	var flat_forward := Vector3(forward.x, 0.0, forward.z)
	var flat_observer := Vector3(observer_direction.x, 0.0, observer_direction.z)
	if flat_forward.length_squared() <= 0.000001 or flat_observer.length_squared() <= 0.000001:
		return 0
	flat_forward = flat_forward.normalized()
	flat_observer = flat_observer.normalized()
	var signed_angle := atan2(flat_forward.cross(flat_observer).y, flat_forward.dot(flat_observer))
	return wrapi(roundi(signed_angle / (PI * 0.25)), 0, 8)


static func atlas_frame_for(state_value: int, direction_index: int) -> int:
	match state_value:
		STATE_ALERT:
			return 4
		STATE_ATTACK:
			return 5
		STATE_HURT, STATE_STUNNED:
			return 6
		STATE_DEAD:
			return 7
		_:
			return DIRECTION_FRAMES[wrapi(direction_index, 0, 8)]


func debug_direction_index() -> int:
	return _direction_index


func debug_current_frame() -> int:
	return _sprite.frame if _sprite != null else -1


func _direction_from_camera() -> int:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return _direction_index
	var forward := -_actor.global_basis.z
	var observer_direction := _actor.global_position.direction_to(camera.global_position)
	return direction_index_from_vectors(forward, observer_direction)


func _apply_pose() -> void:
	if _sprite == null:
		return
	if atlas_texture != null:
		_sprite.frame = atlas_frame_for(_state, _direction_index)
		_sprite.flip_h = _direction_index >= 5
	else:
		_sprite.flip_h = false
	var offset := Vector3.ZERO
	var pose_scale := Vector3.ONE
	var roll := 0.0
	var tint := _base_modulate
	match _state:
		STATE_IDLE:
			offset.y = (0.018 if _pose_step >= 2 else 0.0) * motion_scale
		STATE_ALERT:
			offset.y = (0.11 if _pose_step == 0 else 0.045) * motion_scale
			pose_scale = Vector3(1.06, 1.06, 1.0)
			tint = _base_modulate.lerp(attack_accent, 0.18)
		STATE_CHASE:
			var stride: float = [-1.0, 0.0, 1.0, 0.0][_pose_step]
			offset.y = absf(stride) * 0.045 * motion_scale
			roll = stride * 0.025 * motion_scale
		STATE_ATTACK:
			var attack_curve: float = [0.0, 0.06, 0.12, 0.035][_pose_step]
			offset.y = attack_curve * motion_scale
			pose_scale = Vector3(1.0 + attack_curve * 0.35, 1.0 + attack_curve * 0.2, 1.0)
			tint = _base_modulate.lerp(attack_accent, 0.24 if _pose_step < 2 else 0.1)
		STATE_HURT:
			offset.x = _hit_side * (0.085 if _pose_step == 0 else 0.035) * motion_scale
			roll = -_hit_side * 0.075 * motion_scale
			pose_scale = Vector3(1.06, 0.92, 1.0)
			tint = Color(1.0, 0.55, 0.43, _base_modulate.a)
		STATE_STUNNED:
			var shake: float = [-1.0, 1.0, -0.65, 0.65][_pose_step]
			offset.x = shake * 0.055 * motion_scale
			roll = shake * 0.055 * motion_scale
			tint = _base_modulate.lerp(Color("ffd166"), 0.32)
		STATE_DEAD:
			pose_scale = Vector3(1.04, 0.96, 1.0)
	if _accent_steps > 0:
		tint = tint.lerp(attack_accent, 0.34)
	_sprite.position = _base_position + offset
	_sprite.scale = _base_scale * pose_scale
	_sprite.rotation = _base_rotation + Vector3(0.0, 0.0, roll)
	_sprite.modulate = tint


func _on_state_changed(_previous: EnemyAgent.State, current: EnemyAgent.State) -> void:
	_state = int(current)
	_pose_step = 0
	_tick_accumulator = 0.0
	_apply_pose()


func _on_damaged(_amount: float, _source: Node, hit_position: Vector3) -> void:
	if hit_position != Vector3.ZERO:
		_hit_side = -1.0 if _actor.to_local(hit_position).x >= 0.0 else 1.0


func _on_elite_break() -> void:
	_accent_steps = 4
	attack_accent = Color("4ed9ff")
	_apply_pose()


func _on_boss_phase_changed(_previous: int, current: int) -> void:
	_accent_steps = 4
	match current:
		1:
			attack_accent = Color("ff7338")
		2:
			attack_accent = Color("ff2f1f")
		3:
			attack_accent = Color("ffd33d")
		_:
			attack_accent = Color("ffb12b")
	_apply_pose()
