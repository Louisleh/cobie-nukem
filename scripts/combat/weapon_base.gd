class_name WeaponBase
extends Node3D

signal fired(weapon: WeaponBase, secondary: bool)
signal ammo_changed(current: int, maximum: int)
signal dry_fired(weapon: WeaponBase)
signal hit_confirmed(target: Node, damage: float)
signal shot_resolved(kind: StringName, position: Vector3)

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
var _muzzle_flash_generation := 0

func _ready() -> void:
	if definition != null:
		ammo = definition.starting_ammo
	if muzzle_flash != null:
		muzzle_flash.visible = false
	var burst := get_node_or_null("MuzzleBurst") as GeometryInstance3D
	if burst != null:
		burst.visible = false
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
		shot_resolved.emit(&"miss", from + direction * range_limit)
		return hit
	var impact_position: Vector3 = hit.get("position", from + direction * range_limit)
	var impact_normal: Vector3 = hit.get("normal", -direction)
	var target := _find_damage_receiver(hit.get("collider"))
	if target != null:
		if target.has_method("apply_damage"):
			target.apply_damage(damage, get_parent(), hit.get("position", Vector3.ZERO))
		elif target.has_method("damage"):
			target.damage(damage)
		hit_confirmed.emit(target, damage)
		shot_resolved.emit(&"enemy", impact_position)
		_spawn_impact_marker(impact_position, impact_normal, &"enemy")
		if knockback > 0.0 and target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
	else:
		shot_resolved.emit(&"world", impact_position)
		_spawn_impact_marker(impact_position, impact_normal, &"world")
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
	var burst := get_node_or_null("MuzzleBurst") as GeometryInstance3D
	if muzzle_flash == null and burst == null:
		return
	_muzzle_flash_generation += 1
	var generation := _muzzle_flash_generation
	if muzzle_flash != null:
		muzzle_flash.visible = true
	if burst != null:
		burst.visible = true
		burst.scale = Vector3.ONE * randf_range(0.85, 1.2)
		burst.rotation.z = randf_range(0.0, TAU)
	if not is_inside_tree():
		return
	get_tree().create_timer(0.09).timeout.connect(func() -> void:
		if generation != _muzzle_flash_generation:
			return
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
		if is_instance_valid(burst):
			burst.visible = false
	)

func _spawn_impact_marker(position_value: Vector3, normal: Vector3, kind: StringName) -> void:
	if not is_inside_tree():
		return
	var marker := MeshInstance3D.new()
	marker.name = "EnemyHit" if kind == &"enemy" else "SurfaceImpact"
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := SphereMesh.new()
	mesh.radius = 0.075 if kind == &"enemy" else 0.045
	mesh.height = mesh.radius * 2.0
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.18, 0.06) if kind == &"enemy" else Color(1.0, 0.82, 0.28)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 4.0
	marker.material_override = material
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(marker)
	marker.global_position = position_value + normal * 0.035
	if kind == &"enemy":
		_spawn_enemy_hit_pop(position_value, normal, parent)
	var tween := marker.create_tween()
	tween.tween_property(marker, "scale", Vector3.ONE * 2.2, 0.06)
	tween.tween_property(marker, "scale", Vector3.ONE * 0.05, 0.24)
	tween.tween_callback(marker.queue_free)


func _spawn_enemy_hit_pop(position_value: Vector3, normal: Vector3, parent: Node) -> Node3D:
	var pop := Node3D.new()
	pop.name = "EnemyHitPop"
	parent.add_child(pop)
	if pop.is_inside_tree():
		pop.global_position = position_value + normal * 0.055
	else:
		pop.position = position_value + normal * 0.055

	var flash := MeshInstance3D.new()
	flash.name = "ContactFlash"
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.11
	flash_mesh.height = 0.22
	flash.mesh = flash_mesh
	flash.material_override = _impact_pop_material(Color("fff1a8"), 6.0)
	flash.scale = Vector3.ONE * 0.25
	pop.add_child(flash)
	if pop.is_inside_tree():
		var flash_tween := flash.create_tween()
		flash_tween.tween_property(flash, "scale", Vector3.ONE * 1.75, 0.045)
		flash_tween.tween_property(flash, "scale", Vector3.ZERO, 0.14)

	for index in 6:
		var spark := MeshInstance3D.new()
		spark.name = "Spark%02d" % index
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.025
		spark_mesh.height = 0.05
		spark.mesh = spark_mesh
		spark.material_override = _impact_pop_material(Color("ff7a24") if index % 2 == 0 else Color("ffd166"), 4.5)
		pop.add_child(spark)
		var scatter := Vector3(randf_range(-0.85, 0.85), randf_range(-0.55, 0.85), randf_range(-0.85, 0.85))
		var direction := (normal * 0.65 + scatter).normalized()
		if pop.is_inside_tree():
			var spark_tween := spark.create_tween().set_parallel()
			spark_tween.tween_property(spark, "position", direction * randf_range(0.20, 0.36), 0.22)
			spark_tween.tween_property(spark, "scale", Vector3.ZERO, 0.22)

	if pop.is_inside_tree():
		get_tree().create_timer(0.27).timeout.connect(func() -> void:
			if is_instance_valid(pop):
				pop.queue_free()
		)
	return pop


func _impact_pop_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
