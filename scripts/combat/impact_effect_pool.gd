class_name ImpactEffectPool
extends RefCounted

const MARKER_POOL_CAPACITY := 12
const POP_POOL_CAPACITY := 8

const MARKER_OFFSET := 0.035
const POP_OFFSET := 0.055

const MARKER_EXPAND_DURATION := 0.06
const MARKER_SHRINK_DURATION := 0.24
const MARKER_EXPANDED_SCALE := 2.2
const MARKER_SHRUNK_SCALE := 0.05
const WORLD_MARKER_SCALE := 0.60

const FLASH_START_SCALE := 0.25
const FLASH_EXPAND_SCALE := 1.75
const FLASH_EXPAND_DURATION := 0.045
const FLASH_SHRINK_DURATION := 0.14

const SPARK_FULL_COUNT := 6
const SPARK_REDUCED_COUNT := 3
const SPARK_MOVE_DURATION := 0.22
const POP_TOTAL_DURATION := 0.27
const SPARK_MIN_DISTANCE := 0.20
const SPARK_MAX_DISTANCE := 0.36
const SPARK_PLANE_SPREAD := 0.85
const SPARK_VERTICAL_SPREAD := 0.85
const SPARK_VERTICAL_MIN := -0.55

const MARKER_MATERIAL_ENEMY := Color(1.0, 0.18, 0.06)
const MARKER_MATERIAL_WORLD := Color(1.0, 0.82, 0.28)
const FLASH_MATERIAL_COLOR := Color("fff1a8")
const FLASH_MATERIAL_ENERGY := 6.0
const SPARK_MATERIAL_A := Color("ff7a24")
const SPARK_MATERIAL_B := Color("ffd166")
const SPARK_MATERIAL_ENERGY := 4.5


class ImpactMarkerState extends RefCounted:
	var node: Node3D
	var mesh_instance: MeshInstance3D
	var age: float = 0.0
	var active: bool = false
	var is_enemy: bool = false
	var base_scale: float = 1.0


class EnemyPopState extends RefCounted:
	var node: Node3D
	var flash: MeshInstance3D
	var sparks: Array[MeshInstance3D] = []
	var spark_destinations: Array[Vector3] = []
	var age: float = 0.0
	var active: bool = false
	var spark_count: int = SPARK_FULL_COUNT


var _marker_mesh: SphereMesh
var _flash_mesh: SphereMesh
var _spark_mesh: SphereMesh
var _marker_material_enemy: StandardMaterial3D
var _marker_material_world: StandardMaterial3D
var _flash_material: StandardMaterial3D
var _spark_material_a: StandardMaterial3D
var _spark_material_b: StandardMaterial3D

var _active_markers: Array[ImpactMarkerState] = []
var _marker_pool: Array[ImpactMarkerState] = []
var _active_pops: Array[EnemyPopState] = []
var _pop_pool: Array[EnemyPopState] = []
var _prewarmed := false


func _init() -> void:
	_marker_mesh = SphereMesh.new()
	_marker_mesh.radius = 0.075
	_marker_mesh.height = 0.15

	_flash_mesh = SphereMesh.new()
	_flash_mesh.radius = 0.11
	_flash_mesh.height = 0.22

	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.025
	_spark_mesh.height = 0.05

	_marker_material_enemy = _create_unshaded_material(MARKER_MATERIAL_ENEMY, 4.0)
	_marker_material_world = _create_unshaded_material(MARKER_MATERIAL_WORLD, 4.0)
	_flash_material = _create_unshaded_material(FLASH_MATERIAL_COLOR, FLASH_MATERIAL_ENERGY)
	_spark_material_a = _create_unshaded_material(SPARK_MATERIAL_A, SPARK_MATERIAL_ENERGY)
	_spark_material_b = _create_unshaded_material(SPARK_MATERIAL_B, SPARK_MATERIAL_ENERGY)


func prewarm() -> void:
	if _prewarmed:
		return
	for index in MARKER_POOL_CAPACITY:
		_marker_pool.append(_create_marker(index % 2 == 0))
	for _index in POP_POOL_CAPACITY:
		_pop_pool.append(_create_pop())
	_prewarmed = true


func update(delta: float) -> void:
	_update_markers(delta)
	_update_pops(delta)


func active_count() -> int:
	return _active_markers.size() + _active_pops.size()


func max_active_count() -> int:
	return MARKER_POOL_CAPACITY + POP_POOL_CAPACITY


func allocated_count() -> int:
	return _marker_pool.size() + _active_markers.size() + _pop_pool.size() + _active_pops.size()


func allocated_node_count() -> int:
	# Marker: root + mesh. Pop: root + flash + all sparks.
	return MARKER_POOL_CAPACITY * 2 + POP_POOL_CAPACITY * (2 + SPARK_FULL_COUNT)


func allocated_resource_count() -> int:
	return 8 # Three shared meshes and five shared materials.


func spawn_marker(parent: Node, position: Vector3, normal: Vector3, is_enemy: bool) -> Node3D:
	if parent == null:
		return null
	prewarm()
	var marker := _acquire_marker(is_enemy)
	marker.age = 0.0
	marker.active = true
	marker.is_enemy = is_enemy
	var marker_scale := 1.0 if is_enemy else WORLD_MARKER_SCALE
	marker.base_scale = marker_scale
	marker.mesh_instance.material_override = _marker_material_enemy if is_enemy else _marker_material_world
	marker.node.name = "EnemyHit" if is_enemy else "SurfaceImpact"
	marker.node.scale = Vector3.ONE * marker_scale
	marker.node.visible = true
	_reparent_if_needed(marker.node, parent)
	marker.node.global_position = position + normal * MARKER_OFFSET
	_active_markers.append(marker)
	_update_marker(marker)
	return marker.node


func spawn_enemy_hit_pop(parent: Node, position: Vector3, normal: Vector3, reduced_flashes: bool) -> Node3D:
	if parent == null:
		return null
	prewarm()
	var pop := _acquire_pop()
	pop.age = 0.0
	pop.active = true
	pop.spark_count = SPARK_REDUCED_COUNT if reduced_flashes else SPARK_FULL_COUNT
	pop.node.name = "EnemyHitPop"
	pop.node.visible = true
	pop.flash.scale = Vector3.ONE * FLASH_START_SCALE
	pop.flash.visible = true
	for index in pop.sparks.size():
		var spark := pop.sparks[index]
		spark.visible = index < pop.spark_count
		spark.scale = Vector3.ONE
		spark.position = Vector3.ZERO
		spark.rotation = Vector3.ZERO
	for index in range(pop.spark_count):
		var spread := Vector3(
			randf_range(-SPARK_PLANE_SPREAD, SPARK_PLANE_SPREAD),
			randf_range(SPARK_VERTICAL_MIN, SPARK_VERTICAL_SPREAD),
			randf_range(-SPARK_PLANE_SPREAD, SPARK_PLANE_SPREAD),
		)
		var direction := (normal * 0.65 + spread).normalized()
		pop.spark_destinations[index] = direction * randf_range(SPARK_MIN_DISTANCE, SPARK_MAX_DISTANCE)
	for index in range(pop.spark_count, SPARK_FULL_COUNT):
		pop.spark_destinations[index] = Vector3.ZERO
	_reparent_if_needed(pop.node, parent)
	pop.node.global_position = position + normal * POP_OFFSET
	_active_pops.append(pop)
	_update_pop(pop)
	return pop.node


func clear() -> void:
	for entry in _active_markers:
		if is_instance_valid(entry.node):
			_remove_entry(entry.node)
	for entry in _marker_pool:
		if is_instance_valid(entry.node):
			_remove_entry(entry.node)
	for entry in _active_pops:
		if is_instance_valid(entry.node):
			_remove_entry(entry.node)
	for entry in _pop_pool:
		if is_instance_valid(entry.node):
			_remove_entry(entry.node)
	_active_markers.clear()
	_marker_pool.clear()
	_active_pops.clear()
	_pop_pool.clear()
	_prewarmed = false


func _acquire_marker(is_enemy: bool) -> ImpactMarkerState:
	var marker: ImpactMarkerState
	if not _marker_pool.is_empty():
		marker = _marker_pool.pop_back()
	else:
		marker = _active_markers.pop_front()
		marker.node.visible = false
		marker.age = 0.0
	marker.active = false
	return marker


func _acquire_pop() -> EnemyPopState:
	var pop: EnemyPopState
	if not _pop_pool.is_empty():
		pop = _pop_pool.pop_back()
	else:
		pop = _active_pops.pop_front()
		pop.node.visible = false
		pop.age = 0.0
	pop.active = false
	return pop


func _create_marker(is_enemy: bool) -> ImpactMarkerState:
	var data := ImpactMarkerState.new()
	data.node = Node3D.new()
	data.node.name = "EnemyHit" if is_enemy else "SurfaceImpact"
	data.mesh_instance = MeshInstance3D.new()
	data.mesh_instance.name = "MarkerMesh"
	data.mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	data.mesh_instance.mesh = _marker_mesh
	data.mesh_instance.material_override = _marker_material_enemy if is_enemy else _marker_material_world
	data.node.add_child(data.mesh_instance)
	data.node.visible = false
	data.node.scale = Vector3.ONE
	return data


func _create_pop() -> EnemyPopState:
	var data := EnemyPopState.new()
	data.node = Node3D.new()
	data.node.name = "EnemyHitPop"
	data.node.visible = false
	data.flash = MeshInstance3D.new()
	data.flash.name = "ContactFlash"
	data.flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	data.flash.mesh = _flash_mesh
	data.flash.material_override = _flash_material
	data.flash.scale = Vector3.ONE * FLASH_START_SCALE
	data.node.add_child(data.flash)

	for index in range(SPARK_FULL_COUNT):
		var spark := MeshInstance3D.new()
		spark.name = "Spark%02d" % index
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.mesh = _spark_mesh
		spark.material_override = _spark_material_a if index % 2 == 0 else _spark_material_b
		spark.scale = Vector3.ONE
		spark.visible = false
		data.sparks.append(spark)
		data.spark_destinations.append(Vector3.ZERO)
		data.node.add_child(spark)

	return data


func _update_markers(delta: float) -> void:
	var index := _active_markers.size() - 1
	while index >= 0:
		var marker := _active_markers[index]
		if not marker.active:
			index -= 1
			continue
		marker.age += delta
		_update_marker(marker)
		if marker.age >= MARKER_EXPAND_DURATION + MARKER_SHRINK_DURATION:
			_release_marker(index)
		index -= 1


func _update_marker(marker: ImpactMarkerState) -> void:
	if marker.age <= MARKER_EXPAND_DURATION:
		var ratio := clampf(marker.age / MARKER_EXPAND_DURATION, 0.0, 1.0)
		marker.node.scale = Vector3.ONE * (marker.base_scale * (1.0 + (MARKER_EXPANDED_SCALE - 1.0) * ratio))
	else:
		var ratio := clampf((marker.age - MARKER_EXPAND_DURATION) / MARKER_SHRINK_DURATION, 0.0, 1.0)
		marker.node.scale = Vector3.ONE * (marker.base_scale * (MARKER_EXPANDED_SCALE - (MARKER_EXPANDED_SCALE - MARKER_SHRUNK_SCALE) * ratio))


func _update_pops(delta: float) -> void:
	var index := _active_pops.size() - 1
	while index >= 0:
		var pop := _active_pops[index]
		if not pop.active:
			index -= 1
			continue
		pop.age += delta
		_update_pop(pop)
		if pop.age >= POP_TOTAL_DURATION:
			_release_pop(index)
		index -= 1


func _update_pop(pop: EnemyPopState) -> void:
	if pop.age <= FLASH_EXPAND_DURATION:
		var ratio := clampf(pop.age / FLASH_EXPAND_DURATION, 0.0, 1.0)
		pop.flash.scale = Vector3.ONE * lerpf(FLASH_START_SCALE, FLASH_EXPAND_SCALE, ratio)
	elif pop.age <= FLASH_EXPAND_DURATION + FLASH_SHRINK_DURATION:
		var ratio := clampf((pop.age - FLASH_EXPAND_DURATION) / FLASH_SHRINK_DURATION, 0.0, 1.0)
		pop.flash.scale = Vector3.ONE * lerpf(FLASH_EXPAND_SCALE, 0.0, ratio)
	else:
		pop.flash.scale = Vector3.ZERO
	var traveled := minf(pop.age / SPARK_MOVE_DURATION, 1.0)
	for index in range(pop.spark_count):
		var spark := pop.sparks[index]
		spark.position = pop.spark_destinations[index] * traveled
		var scale := 1.0 - traveled
		spark.scale = Vector3.ONE * maxf(0.0, scale)
func _release_marker(index: int) -> void:
	var marker := _active_markers[index]
	marker.active = false
	marker.node.visible = false
	marker.node.scale = Vector3.ONE
	_active_markers.remove_at(index)
	_marker_pool.append(marker)


func _release_pop(index: int) -> void:
	var pop := _active_pops[index]
	pop.active = false
	pop.node.visible = false
	pop.flash.scale = Vector3.ONE * FLASH_START_SCALE
	for spark in pop.sparks:
		spark.scale = Vector3.ZERO
		spark.visible = false
	for destination_index in pop.spark_destinations.size():
		pop.spark_destinations[destination_index] = Vector3.ZERO
	_pop_pool.append(pop)
	_active_pops.remove_at(index)


func _reparent_if_needed(node: Node, parent: Node) -> void:
	if node.get_parent() != parent:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		parent.add_child(node)


func _remove_entry(node: Node) -> void:
	if node == null or node.is_queued_for_deletion():
		return
	node.free()


func _create_unshaded_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
