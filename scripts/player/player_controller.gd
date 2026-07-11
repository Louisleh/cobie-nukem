class_name CobiePlayer
extends CharacterBody3D

signal died(source: Node)
signal restart_requested
signal interaction_available(label: String)
signal interacted(target: Node)
signal weapon_changed(display_name: String, ammo: int, maximum_ammo: int)
signal weapon_ammo_state_changed(display_name: String, loaded: int, magazine_capacity: int, reserve: int, infinite_reserve: bool)
signal pickup_message(message: String)
signal temporary_effect_started(effect: StringName, duration: float)
signal shot_resolved(kind: StringName, position: Vector3)
signal access_item_changed(label: String)
signal footstep(running: bool)

@export_category("Movement")
@export var walk_speed := 6.0
@export var run_speed := 9.0
@export var ground_acceleration := 38.0
@export var ground_deceleration := 44.0
@export var air_acceleration := 8.0
@export var jump_velocity := 5.2
@export var gravity_scale := 1.0
@export var mouse_sensitivity := 0.0022
@export var max_look_degrees := 86.0
@export var head_bob_amount := 0.035
@export var head_bob_speed := 10.5
@export var out_of_bounds_y := -8.0

@export_category("Interaction")
@export var interaction_range := 3.0
@export var interaction_mask := 1

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_armor: HealthArmor = $HealthArmor
@onready var auto_aim: AutoAimComponent = $AutoAim
@onready var feedback: TactileFeedback = $TactileFeedback
@onready var weapon_mount: Node3D = $Head/Camera/WeaponMount

var weapons: Array[WeaponBase] = []
var current_weapon_index := 0
var _weapon_selection_initialized := false
var is_dead := false
var _head_bob_time := 0.0
var _head_base_position := Vector3.ZERO
var _zoomies_remaining := 0.0
var _wheel_switch_time_ms := -1000
var _run_toggled := false
var _touch_move := Vector2.ZERO
var _step_distance := 0.0
var _last_step_position := Vector3.ZERO

func _ready() -> void:
	# Level zones key progression off this stable identity. Keeping it in code
	# prevents a scene metadata omission from silently disabling every later wave.
	add_to_group(&"player")
	add_to_group(&"damageable_player")
	_head_base_position = head.position
	_last_step_position = global_position
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_value"):
		mouse_sensitivity *= clampf(float(settings.call("get_value", &"gameplay", &"mouse_sensitivity", 1.0)), 0.25, 3.0)
		camera.fov = clampf(float(settings.call("get_value", &"video", &"fov", 90.0)), 70.0, 110.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if MobileControls.touchscreen_expected() else Input.MOUSE_MODE_CAPTURED
	health_armor.died.connect(_on_died)
	health_armor.damaged.connect(_on_damaged)
	for child in weapon_mount.get_children():
		if child is WeaponBase:
			var weapon := child as WeaponBase
			weapons.append(weapon)
			weapon.configure(camera, auto_aim, feedback)
			weapon.ammo_changed.connect(_on_weapon_ammo_changed.bind(weapon))
			weapon.ammo_state_changed.connect(_on_weapon_ammo_state_changed.bind(weapon))
			weapon.shot_resolved.connect(_on_shot_resolved)
	if not weapons.is_empty():
		select_weapon(0)


func _input(event: InputEvent) -> void:
	if is_dead or get_tree().paused:
		return
	# Arrow keys replace momentum-heavy trackpad scrolling. Ignore key repeat so
	# one physical press always produces exactly one visible weapon change.
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP:
				select_weapon(current_weapon_index - 1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				select_weapon(current_weapon_index + 1)
				get_viewport().set_input_as_handled()
			KEY_1:
				select_weapon_slot(0)
				get_viewport().set_input_as_handled()
			KEY_2:
				select_weapon_slot(1)
				get_viewport().set_input_as_handled()
			KEY_3:
				select_weapon_slot(2)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var now := Time.get_ticks_msec()
		if now - _wheel_switch_time_ms >= 180:
			select_weapon(current_weapon_index - 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else current_weapon_index + 1)
			_wheel_switch_time_ms = now
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("weapon_next"):
		select_weapon(current_weapon_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("weapon_previous"):
		select_weapon(current_weapon_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reload"):
		request_reload()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if event.is_action_pressed("fire_primary") or event.is_action_pressed("jump") or event.is_action_pressed("use"):
			restart_requested.emit()
		return
	# Browsers can release pointer lock when focus changes. A fresh click is the
	# user gesture required to reacquire it; consume that click so it cannot fire.
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var relative: Vector2 = event.relative.limit_length(180.0)
		rotate_y(-relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - relative.y * mouse_sensitivity, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))
	if event.is_action_pressed("fire_primary"):
		_current_weapon_fire(false)
	elif event.is_action_pressed("fire_secondary"):
		_current_weapon_fire(true)
	elif event.is_action_pressed("use"):
		_try_interact()

func _physics_process(delta: float) -> void:
	if _check_out_of_bounds():
		return
	if is_dead:
		velocity = velocity.move_toward(Vector3.ZERO, ground_deceleration * delta)
		move_and_slide()
		return
	_zoomies_remaining = maxf(0.0, _zoomies_remaining - delta)
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	var input := Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_backward")
	if _touch_move.length_squared() > input.length_squared(): input = _touch_move
	var wish_direction := (global_basis * Vector3(input.x, 0.0, input.y)).normalized()
	var run_mode := "hold"
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_value"):
		run_mode = String(settings.call("get_value", &"gameplay", &"run_mode", "hold"))
	if run_mode == "toggle" and Input.is_action_just_pressed("run"):
		_run_toggled = not _run_toggled
	var running := _run_toggled if run_mode == "toggle" else Input.is_action_pressed("run")
	var target_speed := run_speed if running else walk_speed
	if _zoomies_remaining > 0.0:
		target_speed *= 1.35
	var target_velocity := wish_direction * target_speed
	var acceleration := air_acceleration if not is_on_floor() else (ground_acceleration if input.length_squared() > 0.0 else ground_deceleration)
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	_apply_keyboard_look(delta)
	move_and_slide()
	_update_footsteps(running)
	_update_head_bob(delta, input.length())
	_update_interaction_prompt()


func _check_out_of_bounds() -> bool:
	if is_dead or global_position.y >= out_of_bounds_y:
		return false
	# Route through the normal damage/death signals so the existing death screen,
	# quip, input release, and checkpoint retry behavior all remain consistent.
	health_armor.apply_damage(health_armor.max_health + health_armor.max_armor + 1000.0, self)
	return true

func apply_damage(amount: float, source: Node = null, _hit_position := Vector3.ZERO) -> float:
	return health_armor.apply_damage(amount, source)


func set_touch_move(value: Vector2) -> void:
	_touch_move = value.limit_length(1.0)


func apply_touch_look(relative: Vector2) -> void:
	if is_dead: return
	rotate_y(-relative.x * mouse_sensitivity * 1.35)
	head.rotation.x = clampf(head.rotation.x - relative.y * mouse_sensitivity * 1.35, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))

func heal(amount: float) -> float:
	return health_armor.heal(amount)

func add_armor(amount: float) -> float:
	return health_armor.add_armor(amount)

func restore_full() -> void:
	health_armor.restore_full()

func respawn(at_position: Vector3, protection_seconds := 1.5) -> void:
	global_position = at_position
	velocity = Vector3.ZERO
	_touch_move = Vector2.ZERO
	is_dead = false
	health_armor.restore_full()
	health_armor.grant_invulnerability(protection_seconds)
	collision_shape.set_deferred("disabled", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if MobileControls.touchscreen_expected() else Input.MOUSE_MODE_CAPTURED

func add_ammo(ammo_type: String, amount: int) -> int:
	var added := 0
	for weapon in weapons:
		if weapon.definition != null and weapon.definition.ammo_type == ammo_type:
			added += weapon.add_ammo(amount)
	return added

func receive_pickup_effect(kind: PickupDefinition.Kind, amount: float) -> bool:
	match kind:
		PickupDefinition.Kind.ZOOMIES:
			_zoomies_remaining = maxf(_zoomies_remaining, amount)
			temporary_effect_started.emit(&"zoomies", amount)
			pickup_message.emit("ZOOMIES ACTIVATED.")
			return true
		PickupDefinition.Kind.SQUEAKER:
			get_tree().call_group(&"enemies", "distract", global_position, amount)
			temporary_effect_started.emit(&"squeaker", amount)
			pickup_message.emit("TACTICAL SQUEAKER ACQUIRED.")
			return true
		PickupDefinition.Kind.GOLDEN_TAG:
			pickup_message.emit("GOLDEN TAG. VERY SHINY.")
			return true
		PickupDefinition.Kind.ACCESS_COLLAR:
			add_to_group(&"has_access_collar")
			access_item_changed.emit("ACCESS COLLAR")
			pickup_message.emit("ACCESS COLLAR ACQUIRED.")
			return true
	return false

func select_weapon(index: int) -> void:
	if weapons.is_empty():
		return
	var direction := 1 if index >= current_weapon_index else -1
	var candidate := posmod(index, weapons.size())
	for attempt in weapons.size():
		if weapons[candidate].unlocked:
			break
		candidate = posmod(candidate + direction, weapons.size())
	if _weapon_selection_initialized and candidate == current_weapon_index:
		return
	if _weapon_selection_initialized:
		weapons[current_weapon_index].cancel_reload()
		weapons[current_weapon_index].enabled = false
	else:
		for weapon in weapons:
			weapon.enabled = false
	current_weapon_index = candidate
	weapons[current_weapon_index].enabled = true
	_weapon_selection_initialized = true
	var current := weapons[current_weapon_index]
	weapon_changed.emit(current.definition.display_name, current.ammo, current.definition.magazine_size)
	weapon_ammo_state_changed.emit(current.definition.display_name, current.ammo, current.definition.magazine_size, current.reserve_ammo, current.definition.infinite_reserve)


func select_weapon_slot(index: int) -> bool:
	if index < 0 or index >= weapons.size() or not weapons[index].unlocked:
		return false
	select_weapon(index)
	return true

func unlock_weapon(display_name: String) -> bool:
	for index in weapons.size():
		if weapons[index].definition != null and weapons[index].definition.display_name == display_name:
			weapons[index].unlocked = true
			select_weapon(index)
			return true
	return false

func _current_weapon_fire(secondary: bool) -> void:
	if weapons.is_empty():
		return
	var weapon := weapons[current_weapon_index]
	if secondary:
		weapon.fire_secondary()
	else:
		weapon.fire_primary()

func request_reload() -> bool:
	if weapons.is_empty() or is_dead:
		return false
	return weapons[current_weapon_index].request_reload()

func _update_footsteps(running: bool) -> void:
	var horizontal_delta := Vector2(global_position.x - _last_step_position.x, global_position.z - _last_step_position.z).length()
	_last_step_position = global_position
	if not should_play_footsteps(is_on_floor(), Vector2(velocity.x, velocity.z).length(), is_dead, get_tree().paused):
		_step_distance = 0.0
		return
	_step_distance += horizontal_delta
	var stride := 1.35 if running else 1.65
	if _step_distance >= stride:
		_step_distance = fmod(_step_distance, stride)
		footstep.emit(running)

static func should_play_footsteps(grounded: bool, horizontal_speed: float, dead: bool, paused: bool) -> bool:
	return grounded and horizontal_speed >= 0.8 and not dead and not paused

func _apply_keyboard_look(delta: float) -> void:
	var yaw := Input.get_axis("look_left", "look_right")
	var pitch := Input.get_axis("look_up", "look_down")
	rotate_y(-yaw * 2.2 * delta)
	head.rotation.x = clampf(head.rotation.x - pitch * 1.65 * delta, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))

func _update_head_bob(delta: float, input_amount: float) -> void:
	if is_on_floor() and input_amount > 0.05 and head_bob_amount > 0.0:
		_head_bob_time += delta * head_bob_speed * (velocity.length() / walk_speed)
		head.position.y = _head_base_position.y + sin(_head_bob_time) * head_bob_amount
	else:
		head.position.y = move_toward(head.position.y, _head_base_position.y, delta * 0.3)

func _interaction_hit() -> Dictionary:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * interaction_range, interaction_mask)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _nearby_interactable() -> Node:
	var best: Node
	var best_score := INF
	for node in get_tree().get_nodes_in_group(&"interactables"):
		if not node is Node3D or not node.has_method("interact"):
			continue
		var offset := (node as Node3D).global_position - camera.global_position
		var distance := offset.length()
		if distance > interaction_range + 0.8:
			continue
		var facing := (-camera.global_basis.z).dot(offset.normalized())
		if facing < 0.45:
			continue
		var score := distance - facing
		if score < best_score:
			best = node
			best_score = score
	return best

func _update_interaction_prompt() -> void:
	var hit := _interaction_hit()
	var target := hit.get("collider") as Node
	if target == null or not target.has_method("get_interaction_label"):
		target = _nearby_interactable()
	if target != null and target.has_method("get_interaction_label"):
		interaction_available.emit(target.get_interaction_label())
	else:
		interaction_available.emit("")

func _try_interact() -> void:
	var hit := _interaction_hit()
	var target := hit.get("collider") as Node
	if target == null or not target.has_method("interact"):
		target = _nearby_interactable()
	if target != null and target.has_method("interact"):
		target.interact(self)
		interacted.emit(target)

func _on_damaged(_amount: float, _health_damage: float, _armor_damage: float, _source: Node) -> void:
	feedback.kick(0.35, 0.22, 0.46, 0.12)

func _on_weapon_ammo_changed(current: int, maximum: int, weapon: WeaponBase) -> void:
	if weapons.is_empty() or weapon != weapons[current_weapon_index]:
		return
	weapon_changed.emit(weapon.definition.display_name, current, maximum)

func _on_weapon_ammo_state_changed(loaded: int, capacity: int, reserve: int, infinite: bool, weapon: WeaponBase) -> void:
	if weapons.is_empty() or weapon != weapons[current_weapon_index]:
		return
	weapon_ammo_state_changed.emit(weapon.definition.display_name, loaded, capacity, reserve, infinite)

func _on_shot_resolved(kind: StringName, position_value: Vector3) -> void:
	shot_resolved.emit(kind, position_value)

func _on_died(source: Node) -> void:
	is_dead = true
	collision_shape.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	died.emit(source)
