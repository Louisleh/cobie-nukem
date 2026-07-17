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

enum OverrideType { NONE, TELEGRAPH, ATTACK, MILESTONE }

@export var sprite_path := NodePath("../Visual/DetailedSprite")
@export var atlas_texture: Texture2D
@export var animation_fps := 8.0
@export_range(0.25, 1.5, 0.05) var motion_scale := 1.0
@export var attack_accent := Color("ffb12b")
@export var presentation_profile: EnemyPresentationProfile
@export_range(12.0, 64.0, 0.5) var distant_distance := 28.0

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
var _active_profile: EnemyPresentationProfile
var _use_profile := false
var _override_type := OverrideType.NONE
var _override_until := -1.0
var _effective_hz := 0.0
var _near_hz := 0.0
var _distant_hz := 12.0
var _distant_frame_time := 0.0
var _current_pose_name := &"idle"


func _ready() -> void:
	_actor = get_parent() as EnemyAgent
	_sprite = get_node_or_null(sprite_path) as Sprite3D
	if _actor == null or _sprite == null:
		push_error("EnemySpritePresentation requires an EnemyAgent parent and Sprite3D: %s" % get_path())
		set_physics_process(false)
		return

	_active_profile = presentation_profile
	_use_profile = _is_valid_profile(_active_profile)
	if _active_profile != null and not _use_profile and _active_profile.has_method("validate"):
		var validation: PackedStringArray = _active_profile.validate()
		if validation is PackedStringArray:
			push_error("Invalid EnemyPresentationProfile on %s: %s" % [get_path(), str(validation)])

	_base_position = _sprite.position
	_base_scale = _sprite.scale
	_base_rotation = _sprite.rotation
	_base_modulate = _sprite.modulate
	var actor_state = _actor.get("state")
	_state = int(actor_state) if actor_state is int else STATE_IDLE
	if _use_profile:
		_sprite.texture = _active_profile.atlas_texture
		_sprite.hframes = EnemyPresentationProfile.HORIZONTAL_FRAMES
		_sprite.vframes = EnemyPresentationProfile.VERTICAL_FRAMES
		_near_hz = _active_profile.animation_fps
		_distant_hz = _active_profile.far_animation_fps
		distant_distance = _active_profile.far_distance
	elif atlas_texture != null:
		_sprite.texture = atlas_texture
		_sprite.hframes = 4
		_sprite.vframes = 2
		_near_hz = animation_fps
	else:
		# Elite/boss actors retain their canonical single image until an authored
		# profile atlas is assigned; code-driven motion and reaction tint remain live.
		_near_hz = animation_fps
	_effective_hz = maxf(1.0, _near_hz)

	var quality := get_node_or_null("/root/QualityManager")
	if quality != null and quality.has_signal(&"profile_changed"):
		quality.connect(&"profile_changed", _on_quality_profile_changed)
		if quality.current != null:
			_on_quality_profile_changed(quality.current)
	_actor.state_changed.connect(_on_state_changed)
	_actor.damaged.connect(_on_damaged)
	if _actor.has_signal(&"shield_broken"):
		_actor.connect(&"shield_broken", _on_elite_break)
	if _actor.has_signal(&"boss_phase_changed"):
		_actor.connect(&"boss_phase_changed", _on_boss_phase_changed)
	_actor.telegraph_started.connect(_on_telegraph_started)
	_actor.attack_fired.connect(_on_attack_fired)
	_apply_pose()


func _physics_process(delta: float) -> void:
	_tick_accumulator += delta
	_distant_frame_time += delta
	var tick_seconds := 1.0 / maxf(_effective_animation_hz(), 0.0001)
	if _tick_accumulator < tick_seconds:
		return
	var elapsed_ticks := maxi(1, floori(_tick_accumulator / tick_seconds))
	_tick_accumulator = fmod(_tick_accumulator, tick_seconds)
	_pose_step = wrapi(_pose_step + elapsed_ticks, 0, 4)
	_accent_steps = maxi(0, _accent_steps - elapsed_ticks)
	if _is_distant():
		_effective_hz = maxf(1.0, min(_near_hz, _distant_hz))
	else:
		_effective_hz = maxf(1.0, _near_hz)
	_direction_index = _direction_from_camera()
	_apply_pose()


func _effective_animation_hz() -> float:
	if _near_hz <= 0.001:
		return 1.0
	if _is_distant():
		return maxf(1.0, min(_near_hz, _distant_hz))
	return maxf(1.0, _near_hz)


func _is_valid_profile(profile: EnemyPresentationProfile) -> bool:
	if profile == null:
		return false
	var validation: PackedStringArray = profile.validate()
	return validation is PackedStringArray and validation.is_empty()


func _is_distant() -> bool:
	if distant_distance <= 0.0:
		return false

	if _actor == null:
		return false

	var registry := get_node_or_null("/root/WorldRegistry")
	var actor_point: Vector3 = _actor_position(_actor)
	var compare_point: Vector3 = actor_point
	if is_instance_valid(_actor.target) and _actor.target is Node3D:
		compare_point = _actor_position(_actor.target as Node3D)
	elif registry != null and registry.has_method(&"primary_player"):
		var player: Node3D = registry.primary_player()
		if player != null:
			compare_point = _actor_position(player)
	var distance := actor_point.distance_to(compare_point)
	return distance > distant_distance


func _actor_position(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	return node.position


func _on_quality_profile_changed(profile: Variant) -> void:
	if profile == null:
		_distant_hz = 12.0
	else:
		var distant_value := _read_profile_distant_hz(profile)
		_distant_hz = maxf(1.0, float(distant_value))
	if _active_profile != null:
		_near_hz = _active_profile.animation_fps
		_distant_hz = minf(_distant_hz, _active_profile.far_animation_fps)
	else:
		_near_hz = animation_fps
	_effective_hz = _effective_animation_hz()


func _read_profile_distant_hz(profile: Variant) -> float:
	var default_hz := 12.0
	if profile is Dictionary:
		if profile.has("distant_animation_hz"):
			return float(profile["distant_animation_hz"])
	if profile is Object:
		var value = profile.get("distant_animation_hz")
		if value != null:
			return float(value)
	return default_hz


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


static func atlas_frame_for_profile(profile: EnemyPresentationProfile, state_value: int, direction_index: int, pose_step: int = 0, override_type: int = OverrideType.NONE) -> int:
	if profile == null:
		return atlas_frame_for(state_value, direction_index)
	var clamped_direction := wrapi(direction_index, 0, 8)
	if override_type == OverrideType.TELEGRAPH:
		return profile.reaction_telegraph_frame()
	if override_type == OverrideType.ATTACK:
		return profile.reaction_attack_frame()
	if override_type == OverrideType.MILESTONE:
		return profile.reaction_milestone_frame()

	match state_value:
		STATE_IDLE:
			return profile.direction_frame(clamped_direction, profile.direction_row_idle())
		STATE_CHASE:
			var row: int = profile.direction_row_a() if (pose_step % 2 == 0) else profile.direction_row_b()
			return profile.direction_frame(clamped_direction, row)
		STATE_ALERT:
			return profile.reaction_alert_frame()
		STATE_ATTACK:
			return profile.reaction_attack_frame()
		STATE_HURT:
			return profile.reaction_hurt_frame()
		STATE_STUNNED:
			return profile.reaction_stagger_frame()
		STATE_DEAD:
			return profile.reaction_death_frame()
		_:
			return profile.reaction_alert_frame()


func debug_current_pose() -> StringName:
	return _current_pose_name


func debug_current_frame() -> int:
	return _sprite.frame if _sprite != null else -1


func debug_effective_fps() -> float:
	return _effective_hz


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

	var pose_frame: int
	var current_pose := &"unknown"
	if _use_profile:
		_sprite.flip_h = false
		if _override_type != OverrideType.NONE and _distant_frame_time < _override_until:
			pose_frame = atlas_frame_for_profile(_active_profile, STATE_ATTACK, _direction_index, _pose_step, _override_type)
			match _override_type:
				OverrideType.TELEGRAPH:
					current_pose = &"telegraph"
				OverrideType.ATTACK:
					current_pose = &"attack"
				OverrideType.MILESTONE:
					current_pose = &"milestone"
				_:
					current_pose = &"unknown"
		else:
			match _state:
				STATE_ALERT:
					pose_frame = atlas_frame_for_profile(_active_profile, _state, _direction_index, _pose_step)
					current_pose = &"alert"
				STATE_ATTACK:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_ATTACK, _direction_index, _pose_step)
					current_pose = &"attack"
				STATE_HURT:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_HURT, _direction_index, _pose_step)
					current_pose = &"hurt"
				STATE_STUNNED:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_STUNNED, _direction_index, _pose_step)
					current_pose = &"stagger"
				STATE_DEAD:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_DEAD, _direction_index, _pose_step)
					current_pose = &"death"
				STATE_CHASE:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_CHASE, _direction_index, _pose_step)
					current_pose = &"chase"
				_:
					pose_frame = atlas_frame_for_profile(_active_profile, STATE_IDLE, _direction_index, _pose_step)
					current_pose = &"idle"
	else:
		if _state == STATE_DEAD:
			_sprite.flip_h = false
		else:
			_sprite.flip_h = _direction_index >= 5
		pose_frame = atlas_frame_for(_state, _direction_index)
		match _state:
			STATE_IDLE:
				current_pose = &"idle"
			STATE_ALERT:
				current_pose = &"alert"
			STATE_CHASE:
				current_pose = &"chase"
			STATE_ATTACK:
				current_pose = &"attack"
			STATE_HURT:
				current_pose = &"hurt"
			STATE_STUNNED:
				current_pose = &"stagger"
			STATE_DEAD:
				current_pose = &"death"
			_:
				current_pose = &"idle"
	if _state != STATE_ALERT and _state != STATE_ATTACK and _state != STATE_HURT and _state != STATE_STUNNED and _state != STATE_DEAD and _state != STATE_CHASE:
		_pose_step = 0

	if pose_frame < 0:
		var profile_id := _active_profile.id if _active_profile != null else StringName("legacy")
		push_error("EnemySpritePresentation produced invalid frame index from profile %s: %d" % [profile_id, pose_frame])
		pose_frame = 0
	if _use_profile or atlas_texture != null:
		_sprite.frame = pose_frame
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
	_current_pose_name = current_pose


func _on_state_changed(_previous: int, current: int) -> void:
	_state = int(current)
	if _state == STATE_DEAD:
		_override_type = OverrideType.NONE
	_pose_step = 0
	_tick_accumulator = 0.0
	_apply_pose()


func _on_damaged(_amount: float, _source: Node, hit_position: Vector3) -> void:
	if hit_position != Vector3.ZERO:
		_hit_side = -1.0 if _actor.to_local(hit_position).x >= 0.0 else 1.0


func _on_elite_break() -> void:
	_accent_steps = 4
	attack_accent = Color("4ed9ff")
	_set_override(OverrideType.MILESTONE, _milestone_duration())
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
	_set_override(OverrideType.MILESTONE, _milestone_duration())
	_apply_pose()


func _on_telegraph_started(_kind: StringName, duration: float) -> void:
	_set_override(OverrideType.TELEGRAPH, maxf(duration, _active_profile.telegraph_hold_seconds if _active_profile != null else 0.24))
	_apply_pose()


func _on_attack_fired(_kind: StringName) -> void:
	_set_override(OverrideType.ATTACK, _active_profile.attack_hold_seconds if _active_profile != null else 0.16)
	_apply_pose()


func _set_override(type: OverrideType, hold_seconds: float) -> void:
	if hold_seconds <= 0.0:
		hold_seconds = 0.1
	_override_type = type
	_override_until = _distant_frame_time + hold_seconds


func _milestone_duration() -> float:
	if _active_profile != null:
		return _active_profile.milestone_hold_seconds
	return 0.22
