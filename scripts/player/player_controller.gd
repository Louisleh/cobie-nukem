class_name CobiePlayer
extends CharacterBody3D

signal died(source: Node)
signal restart_requested
signal interaction_available(label: String)
signal interacted(target: Node)
signal weapon_changed(display_name: String, ammo: int, maximum_ammo: int)
signal pickup_message(message: String)
signal temporary_effect_started(effect: StringName, duration: float)

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
var is_dead := false
var _head_bob_time := 0.0
var _head_base_position := Vector3.ZERO
var _zoomies_remaining := 0.0

func _ready() -> void:
	_head_base_position = head.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_armor.died.connect(_on_died)
	health_armor.damaged.connect(_on_damaged)
	for child in weapon_mount.get_children():
		if child is WeaponBase:
			weapons.append(child)
			child.configure(camera, auto_aim, feedback)
	if not weapons.is_empty():
		select_weapon(0)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if event.is_action_pressed("fire_primary") or event.is_action_pressed("jump") or event.is_action_pressed("use"):
			restart_requested.emit()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-max_look_degrees), deg_to_rad(max_look_degrees))
	if event.is_action_pressed("fire_primary"):
		_current_weapon_fire(false)
	elif event.is_action_pressed("fire_secondary"):
		_current_weapon_fire(true)
	elif event.is_action_pressed("weapon_next"):
		select_weapon(current_weapon_index + 1)
	elif event.is_action_pressed("weapon_previous"):
		select_weapon(current_weapon_index - 1)
	elif event.is_action_pressed("use"):
		_try_interact()

func _physics_process(delta: float) -> void:
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
	var wish_direction := (global_basis * Vector3(input.x, 0.0, input.y)).normalized()
	var running := Input.is_action_pressed("run")
	var target_speed := run_speed if running else walk_speed
	if _zoomies_remaining > 0.0:
		target_speed *= 1.35
	var target_velocity := wish_direction * target_speed
	var acceleration := air_acceleration if not is_on_floor() else (ground_acceleration if input.length_squared() > 0.0 else ground_deceleration)
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	_apply_keyboard_look(delta)
	move_and_slide()
	_update_head_bob(delta, input.length())
	_update_interaction_prompt()

func apply_damage(amount: float, source: Node = null, _hit_position := Vector3.ZERO) -> float:
	return health_armor.apply_damage(amount, source)

func heal(amount: float) -> float:
	return health_armor.heal(amount)

func add_armor(amount: float) -> float:
	return health_armor.add_armor(amount)

func restore_full() -> void:
	health_armor.restore_full()

func respawn(at_position: Vector3) -> void:
	global_position = at_position
	velocity = Vector3.ZERO
	is_dead = false
	health_armor.restore_full()
	collision_shape.set_deferred("disabled", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	current_weapon_index = candidate
	for weapon_index in weapons.size():
		weapons[weapon_index].enabled = weapon_index == current_weapon_index
	var current := weapons[current_weapon_index]
	weapon_changed.emit(current.definition.display_name, current.ammo, current.definition.magazine_size)

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

func _update_interaction_prompt() -> void:
	var hit := _interaction_hit()
	var target := hit.get("collider") as Node
	if target != null and target.has_method("get_interaction_label"):
		interaction_available.emit(target.get_interaction_label())
	else:
		interaction_available.emit("")

func _try_interact() -> void:
	var hit := _interaction_hit()
	var target := hit.get("collider") as Node
	if target != null and target.has_method("interact"):
		target.interact(self)
		interacted.emit(target)

func _on_damaged(_amount: float, _health_damage: float, _armor_damage: float, _source: Node) -> void:
	feedback.kick(0.35, 0.22, 0.46, 0.12)

func _on_died(source: Node) -> void:
	is_dead = true
	collision_shape.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	died.emit(source)
