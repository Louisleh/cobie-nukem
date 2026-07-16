class_name WeaponBase
extends Node3D

signal fired(weapon: WeaponBase, secondary: bool)
signal ammo_changed(current: int, maximum: int)
signal ammo_state_changed(loaded: int, magazine_capacity: int, reserve: int, infinite_reserve: bool)
signal dry_fired(weapon: WeaponBase)
signal reload_started(weapon: WeaponBase, duration: float)
signal reload_step(weapon: WeaponBase)
signal reload_finished(weapon: WeaponBase)
signal reload_cancelled(weapon: WeaponBase)
signal hit_confirmed(target: Node, damage: float)
signal shot_resolved(kind: StringName, position: Vector3)
signal feedback_resolved(event: CombatFeedbackEvent)

enum LifecycleState { HOLSTERED, RAISING, READY, FIRING, RECOVERING, RELOADING, LOWERING }

@export var definition: WeaponDefinition
@export var camera: Camera3D
@export var auto_aim: AutoAimComponent
@export var feedback: TactileFeedback
@export var muzzle_flash: Light3D
@export var unlocked := true

var ammo := 0
var reserve_ammo := 0
var is_reloading := false
var _enabled := false
@export var enabled := false:
	get:
		return _enabled
	set(value):
		if _enabled == value:
			return
		_enabled = value
		if value:
			if lifecycle_state == LifecycleState.HOLSTERED or lifecycle_state == LifecycleState.LOWERING:
				_start_lifecycle(LifecycleState.RAISING)
		elif lifecycle_state == LifecycleState.HOLSTERED:
			visible = false
		else:
			_start_lifecycle(LifecycleState.LOWERING)
var _cooldown_remaining := 0.0
var _muzzle_flash_generation := 0
var _reload_remaining := 0.0
var _reload_origin := Vector3.ZERO
var _lifecycle_remaining := 0.0
var lifecycle_state := LifecycleState.HOLSTERED
var _shot_sequence := 0
var _muzzle_timer: Timer

func _ready() -> void:
	_muzzle_timer = Timer.new()
	_muzzle_timer.name = "MuzzleTimer"
	_muzzle_timer.one_shot = true
	_muzzle_timer.wait_time = 0.09
	_muzzle_timer.timeout.connect(_hide_muzzle_flash)
	add_child(_muzzle_timer)
	if definition != null:
		ammo = definition.starting_ammo
		reserve_ammo = definition.starting_reserve
	_reload_origin = position
	if muzzle_flash != null:
		muzzle_flash.visible = false
	var burst := get_node_or_null("MuzzleBurst") as GeometryInstance3D
	if burst != null:
		burst.visible = false
	if enabled:
		_start_lifecycle(LifecycleState.RAISING)
	else:
		lifecycle_state = LifecycleState.HOLSTERED
		visible = false

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if lifecycle_state == LifecycleState.RAISING:
		_lifecycle_remaining = maxf(0.0, _lifecycle_remaining - delta)
		if _lifecycle_remaining <= 0.0:
			lifecycle_state = LifecycleState.READY
			visible = true
	elif lifecycle_state == LifecycleState.LOWERING:
		_lifecycle_remaining = maxf(0.0, _lifecycle_remaining - delta)
		if _lifecycle_remaining <= 0.0:
			lifecycle_state = LifecycleState.HOLSTERED
			visible = false
	elif lifecycle_state == LifecycleState.FIRING:
		lifecycle_state = LifecycleState.RECOVERING
	elif lifecycle_state == LifecycleState.RECOVERING and _cooldown_remaining <= 0.0:
		lifecycle_state = LifecycleState.READY
	if is_reloading:
		_reload_remaining -= delta
		var duration := maxf(definition.reload_seconds, 0.01)
		var phase := clampf(1.0 - _reload_remaining / duration, 0.0, 1.0)
		position = _reload_origin + Vector3(0.0, -sin(phase * PI) * 0.16, sin(phase * PI) * 0.08)
		if _reload_remaining <= 0.0:
			_complete_reload_step()

func configure(aim_camera: Camera3D, aim_component: AutoAimComponent, tactile: TactileFeedback) -> void:
	camera = aim_camera
	auto_aim = aim_component
	feedback = tactile

func can_fire(secondary := false) -> bool:
	if not unlocked or not enabled or definition == null or camera == null or lifecycle_state != LifecycleState.READY or is_reloading:
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
	if definition == null or amount <= 0 or definition.magazine_size <= 0 or definition.infinite_reserve:
		return 0
	var previous := reserve_ammo
	reserve_ammo = mini(definition.reserve_capacity, reserve_ammo + amount)
	_emit_ammo_state()
	return reserve_ammo - previous

func request_reload() -> bool:
	if definition == null or is_reloading or ammo >= definition.magazine_size or definition.magazine_size <= 0:
		return false
	if not definition.infinite_reserve and reserve_ammo <= 0:
		return false
	is_reloading = true
	lifecycle_state = LifecycleState.RELOADING
	_reload_remaining = definition.reload_seconds
	_reload_origin = position
	reload_started.emit(self, definition.reload_seconds)
	return true

func cancel_reload() -> bool:
	if not is_reloading:
		return false
	is_reloading = false
	lifecycle_state = LifecycleState.READY if enabled else LifecycleState.HOLSTERED
	_reload_remaining = 0.0
	position = _reload_origin
	reload_cancelled.emit(self)
	return true

func _complete_reload_step() -> void:
	var needed := definition.magazine_size - ammo
	var amount := 1 if definition.reload_per_round else needed
	if not definition.infinite_reserve:
		amount = mini(amount, reserve_ammo)
	ammo += amount
	if not definition.infinite_reserve:
		reserve_ammo -= amount
	reload_step.emit(self)
	_emit_ammo_state()
	if definition.reload_per_round and ammo < definition.magazine_size and (definition.infinite_reserve or reserve_ammo > 0):
		_reload_remaining = definition.reload_seconds
		return
	is_reloading = false
	lifecycle_state = LifecycleState.READY if enabled else LifecycleState.HOLSTERED
	position = _reload_origin
	reload_finished.emit(self)

func _begin_fire(secondary: bool) -> bool:
	if not can_fire(secondary):
		if enabled and _cooldown_remaining <= 0.0:
			dry_fired.emit(self)
			if not is_reloading and definition != null and ammo <= 0:
				request_reload()
		return false
	var cost := definition.ammo_per_secondary if secondary else definition.ammo_per_primary
	if definition.ammo_type != "none":
		ammo -= cost
		_emit_ammo_state()
	_cooldown_remaining = definition.secondary_cooldown if secondary else definition.primary_cooldown
	lifecycle_state = LifecycleState.FIRING
	fired.emit(self, secondary)
	_flash_muzzle()
	return true

func _has_ammo(cost: int) -> bool:
	return ammo >= cost

func _emit_ammo_state() -> void:
	ammo_changed.emit(ammo, definition.magazine_size)
	ammo_state_changed.emit(ammo, definition.magazine_size, reserve_ammo, definition.infinite_reserve)

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
	_shot_sequence += 1
	var event := CombatFeedbackEvent.new()
	event.shot_id = _shot_sequence
	event.weapon_id = definition.id
	event.origin = from
	event.damage = damage
	if hit.is_empty():
		event.destination = from + direction * range_limit
		event.hit_type = CombatFeedbackEvent.HitType.MISS
		_emit_feedback(event)
		return hit
	var impact_position: Vector3 = hit.get("position", from + direction * range_limit)
	var impact_normal: Vector3 = hit.get("normal", -direction)
	var target := _find_damage_receiver(hit.get("collider"))
	event.destination = impact_position
	event.surface_type = _surface_type(hit.get("collider"))
	event.target = target
	if target != null:
		var destructible := not target.is_in_group(&"enemies") and target.get("is_dead") == null
		if target.has_method("apply_damage"):
			target.apply_damage(damage, get_parent(), hit.get("position", Vector3.ZERO))
		elif target.has_method("damage"):
			target.damage(damage)
		hit_confirmed.emit(target, damage)
		event.hit_type = CombatFeedbackEvent.HitType.DESTRUCTIBLE if destructible else CombatFeedbackEvent.HitType.ENEMY
		event.killed = target.get("is_dead") == true
		_emit_feedback(event)
		_spawn_impact_marker(impact_position, impact_normal, event.legacy_kind())
		if knockback > 0.0 and target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
	else:
		event.hit_type = CombatFeedbackEvent.HitType.WORLD
		_emit_feedback(event)
		_spawn_impact_marker(impact_position, impact_normal, &"world")
	return hit


func _emit_feedback(event: CombatFeedbackEvent) -> void:
	feedback_resolved.emit(event)
	shot_resolved.emit(event.legacy_kind(), event.destination)


func request_raise() -> void:
	if not enabled:
		enabled = true


func request_lower() -> void:
	if enabled:
		enabled = false


func _start_lifecycle(state: LifecycleState) -> void:
	match state:
		LifecycleState.RAISING:
			_lifecycle_remaining = _feel_raise_seconds()
			if _lifecycle_remaining <= 0.0:
				lifecycle_state = LifecycleState.READY
				visible = true
			else:
				lifecycle_state = LifecycleState.RAISING
				visible = true
		LifecycleState.LOWERING:
			_lifecycle_remaining = _feel_lower_seconds()
			if _lifecycle_remaining <= 0.0:
				lifecycle_state = LifecycleState.HOLSTERED
				visible = false
			else:
				lifecycle_state = LifecycleState.LOWERING
				visible = true
		_:
			return


func _feel_raise_seconds() -> float:
	if definition == null or definition.feel == null:
		return 0.0
	return maxf(definition.feel.raise_seconds, 0.0)


func _feel_lower_seconds() -> float:
	if definition == null or definition.feel == null:
		return 0.0
	return maxf(definition.feel.lower_seconds, 0.0)


func _surface_type(collider: Variant) -> StringName:
	var node := collider as Node
	while node != null:
		if node.has_meta(&"surface_type"): return StringName(String(node.get_meta(&"surface_type")))
		for type in [&"metal", &"wood", &"glass", &"water", &"soil", &"concrete", &"shield"]:
			if node.is_in_group(type): return type
		node = node.get_parent()
	return &"flesh" if collider is Node and (collider as Node).is_in_group(&"enemies") else &"concrete"

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
	if muzzle_flash != null and not _reduced_flashes():
		muzzle_flash.visible = true
	if burst != null:
		burst.visible = true
		burst.scale = Vector3.ONE * randf_range(0.85, 1.2)
		burst.rotation.z = randf_range(0.0, TAU)
	if _muzzle_timer != null:
		_muzzle_timer.start()


func _hide_muzzle_flash() -> void:
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
	var burst := get_node_or_null("MuzzleBurst") as GeometryInstance3D
	if burst != null:
		burst.visible = false

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
	var quality := get_node_or_null("/root/QualityManager") if is_inside_tree() else null
	if quality != null: quality.claim_temporary_effect(marker)
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
	var quality := get_node_or_null("/root/QualityManager") if is_inside_tree() else null
	if quality != null: quality.claim_temporary_effect(pop)
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

	var spark_count := 3 if _reduced_flashes() else 6
	for index in spark_count:
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
		var cleanup := Timer.new()
		cleanup.name = "CleanupTimer"
		cleanup.one_shot = true
		cleanup.wait_time = 0.27
		cleanup.timeout.connect(pop.queue_free)
		pop.add_child(cleanup)
		cleanup.start()
	return pop


func _reduced_flashes() -> bool:
	if not is_inside_tree(): return false
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"video", &"reduced_flashes", false))


func _impact_pop_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
