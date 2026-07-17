class_name FetchLauncher
extends WeaponBase

const PROJECTILE_SCENE := preload("res://scenes/weapons/fetch_projectile.tscn")

var latest_projectile: FetchProjectile
var recall_speed_multiplier := 1.0
var recall_stagger_multiplier := 1.0

func fire_primary() -> bool:
	if not _begin_fire(false):
		return false
	var projectile := PROJECTILE_SCENE.instantiate() as FetchProjectile
	get_tree().current_scene.add_child(projectile)
	var owner_node := _find_player()
	projectile.speed = definition.projectile_speed
	projectile.fuse_seconds = definition.projectile_fuse
	projectile.damage = definition.primary_damage
	projectile.recall_speed_multiplier = recall_speed_multiplier
	projectile.recall_stagger_multiplier = recall_stagger_multiplier
	projectile.shot_resolved.connect(_on_projectile_resolved)
	projectile.launch(camera.global_position + _aim_direction(definition.range) * 0.7, _aim_direction(definition.range), owner_node)
	latest_projectile = projectile
	if feedback != null:
		feedback.kick(0.3, 0.2, 0.38, 0.1)
	return true


func apply_municipal_recall_override() -> void:
	recall_speed_multiplier = 1.35
	recall_stagger_multiplier = 2.0
	if is_instance_valid(latest_projectile):
		latest_projectile.recall_speed_multiplier = recall_speed_multiplier
		latest_projectile.recall_stagger_multiplier = recall_stagger_multiplier

func fire_secondary() -> bool:
	if not enabled or not is_instance_valid(latest_projectile):
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
