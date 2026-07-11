class_name WeaponBase
extends Node3D

signal fired(weapon: WeaponBase, secondary: bool)
signal ammo_changed(current: int, maximum: int)
signal dry_fired(weapon: WeaponBase)
signal hit_confirmed(target: Node, damage: float)

@export var definition: WeaponDefinition
@export var camera: Camera3D
@export var auto_aim: AutoAimComponent
@export var feedback: TactileFeedback
@export var muzzle_flash: Light3D
@export var unlocked := true

var ammo := 0
var enabled := false:
	set(value):
		enabled = value
		visible = value
var _cooldown_remaining := 0.0

func _ready() -> void:
	if definition != null:
		ammo = definition.starting_ammo
	if muzzle_flash != null:
		muzzle_flash.visible = false
	visible = enabled

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

func configure(aim_camera: Camera3D, aim_component: AutoAimComponent, tactile: TactileFeedback) -> void:
	camera = aim_camera
	auto_aim = aim_component
	feedback = tactile

func can_fire(secondary := false) -> bool:
	if not unlocked or not enabled or definition == null or camera == null or _cooldown_remaining > 0.0:
		return false
	var cost := definition.ammo_per_secondary if secondary else definition.ammo_per_primary
	return _has_ammo(cost)

func fire_primary() -> bool:
	if not _begin_fire(false):
		return false
	_hitscan(definition.primary_damage, definition.range, 0.0, definition.knockback)
	return true

func fire_secondary() -> bool:
	if not _begin_fire(true):
		return false
	_hitscan(definition.secondary_damage, definition.range, 0.0, definition.knockback)
	return true

func add_ammo(amount: int) -> int:
	if definition == null or amount <= 0 or definition.magazine_size <= 0:
		return 0
	var previous := ammo
	ammo = mini(definition.magazine_size, ammo + amount)
	ammo_changed.emit(ammo, definition.magazine_size)
	return ammo - previous

func _begin_fire(secondary: bool) -> bool:
	if not can_fire(secondary):
		if enabled and _cooldown_remaining <= 0.0:
			dry_fired.emit(self)
		return false
	var cost := definition.ammo_per_secondary if secondary else definition.ammo_per_primary
	if definition.ammo_type != "none":
		ammo -= cost
		ammo_changed.emit(ammo, definition.magazine_size)
	_cooldown_remaining = definition.secondary_cooldown if secondary else definition.primary_cooldown
	fired.emit(self, secondary)
	_flash_muzzle()
	return true

func _has_ammo(cost: int) -> bool:
	return definition.ammo_type == "none" or ammo >= cost

func _aim_direction(range_limit: float) -> Vector3:
	if auto_aim != null:
		return auto_aim.get_aim_direction(camera, range_limit)
	return -camera.global_basis.z.normalized()

func _hitscan(damage: float, range_limit: float, spread_degrees: float, knockback: float) -> Dictionary:
	var direction := _aim_direction(range_limit)
	if spread_degrees > 0.0:
		direction = _spread_direction(direction, spread_degrees)
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * range_limit)
	query.exclude = [_find_player_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return hit
	var target := _find_damage_receiver(hit.get("collider"))
	if target != null:
		if target.has_method("apply_damage"):
			target.apply_damage(damage, get_parent(), hit.get("position", Vector3.ZERO))
		elif target.has_method("damage"):
			target.damage(damage)
		hit_confirmed.emit(target, damage)
		if knockback > 0.0 and target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
	return hit

func _spread_direction(forward: Vector3, spread_degrees: float) -> Vector3:
	var cone := tan(deg_to_rad(spread_degrees))
	var right := camera.global_basis.x.normalized()
	var up := camera.global_basis.y.normalized()
	return (forward + right * randf_range(-cone, cone) + up * randf_range(-cone, cone)).normalized()

func _find_damage_receiver(value: Variant) -> Node:
	var node := value as Node
	while node != null:
		if node.has_method("apply_damage") or node.has_method("damage"):
			return node
		node = node.get_parent()
	return null

func _find_player_rid() -> RID:
	var node := get_parent()
	while node != null:
		if node is CollisionObject3D:
			return node.get_rid()
		node = node.get_parent()
	return RID()

func _flash_muzzle() -> void:
	if muzzle_flash == null:
		return
	muzzle_flash.visible = true
	get_tree().create_timer(0.045).timeout.connect(func() -> void:
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
	)
