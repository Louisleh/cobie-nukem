class_name FetchLauncher
extends WeaponBase

const PROJECTILE_SCENE := preload("res://scenes/weapons/fetch_projectile.tscn")

var latest_projectile: FetchProjectile
var recall_speed_multiplier := 1.0
var recall_stagger_multiplier := 1.0
var mod_recall_speed_multiplier := 1.0
var mod_bounce_bonus := 0
var golden_trail_enabled := false
var _municipal_recall_enabled := false
var _latest_projectile_shot_id := 0
var _projectile_shot_id := 0

func fire_primary() -> bool:
	if not _begin_fire(false):
		return false
	var owner_node := _find_player()
	var pool := get_node_or_null("/root/ProjectilePool")
	var projectile := pool.acquire(PROJECTILE_SCENE) as FetchProjectile if pool != null else null
	if projectile == null:
		projectile = PROJECTILE_SCENE.instantiate() as FetchProjectile
		if projectile == null:
			return false
	if not is_instance_valid(projectile):
			return false
	if projectile.get_parent() == null:
		var parent := get_tree().current_scene
		if parent == null:
			parent = get_tree().root
		parent.add_child(projectile)
	if not projectile.shot_resolved.is_connected(_on_projectile_resolved):
		projectile.shot_resolved.connect(_on_projectile_resolved)
	_projectile_shot_id += 1
	projectile.speed = definition.projectile_speed
	projectile.fuse_seconds = definition.projectile_fuse
	projectile.damage = definition.primary_damage
	projectile.recall_speed_multiplier = recall_speed_multiplier
	projectile.recall_stagger_multiplier = recall_stagger_multiplier
	projectile.begin_shot(_projectile_shot_id, owner_node, maxi(0, mod_bounce_bonus))
	projectile.set_golden_trail(golden_trail_enabled)
	projectile.launch(camera.global_position + _aim_direction(definition.range) * 0.7, _aim_direction(definition.range), owner_node)
	latest_projectile = projectile
	_latest_projectile_shot_id = _projectile_shot_id
	if feedback != null:
		feedback.kick(0.3, 0.2, 0.38, 0.1)
	return true


func apply_municipal_recall_override() -> void:
	_municipal_recall_enabled = true
	refresh_recall_multipliers()
	recall_stagger_multiplier = 2.0
	if is_instance_valid(latest_projectile) and latest_projectile.can_recall(_latest_projectile_shot_id):
		latest_projectile.recall_speed_multiplier = recall_speed_multiplier
		latest_projectile.recall_stagger_multiplier = recall_stagger_multiplier


func refresh_recall_multipliers() -> void:
	recall_speed_multiplier = minf(1.75, mod_recall_speed_multiplier * (1.35 if _municipal_recall_enabled else 1.0))
	if is_instance_valid(latest_projectile) and latest_projectile.can_recall(_latest_projectile_shot_id):
		latest_projectile.recall_speed_multiplier = recall_speed_multiplier


func fire_secondary() -> bool:
	if not enabled or not is_instance_valid(latest_projectile) or _latest_projectile_shot_id <= 0:
		dry_fired.emit(self)
		return false
	if not latest_projectile.can_recall(_latest_projectile_shot_id):
		dry_fired.emit(self)
		return false
	latest_projectile.recall()
	if feedback != null:
		feedback.kick(0.2, 0.25, 0.1, 0.12)
	return true


func _find_player() -> Node3D:
	var node := get_parent()
	while node != null:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null


func _on_projectile_resolved(kind: StringName, position_value: Vector3) -> void:
	shot_resolved.emit(kind, position_value)
	if kind == &"enemy" or kind == &"world":
		_spawn_impact_marker(position_value, Vector3.UP, kind)
