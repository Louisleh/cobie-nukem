class_name DirectionalShieldComponent
extends Node

signal shield_hit(owner_body: Node3D, hit_position: Vector3, incoming_damage: float, damage_multiplier: float, remaining_shield_health: float)
signal shield_broken
signal shield_reset
signal shield_guard_state_changed(guarding: bool, permanently_broken: bool)

@export_range(0.0, 9999.0, 0.01) var maximum_shield_health := 70.0
@export_range(0.0, 360.0, 0.1) var shield_arc_degrees := 162.74
@export_range(0.0, 5.0, 0.01) var blocked_damage_multiplier := 0.25
@export_range(0.0, 5.0, 0.01) var break_damage_multiplier := 1.35
@export_range(0.0, 9999.0, 0.01) var shield_hit_cost := 35.0
@export var visual_target_path := NodePath("Visual/Shield")

var shield_active := true
var current_shield_health := 0.0
var shield_is_broken := false
var _guarding_requested := true

var _configured_owner: Node3D
var _shield_visual: Node3D
var _arc_cos_threshold := 0.0
var _configured_guarding := true


func _ready() -> void:
	configure(
		get_parent() as Node3D,
		maximum_shield_health,
		shield_arc_degrees,
		blocked_damage_multiplier,
		break_damage_multiplier,
		shield_hit_cost,
		visual_target_path
	)


func configure(
	owner_body: Node3D,
	max_health: float = 70.0,
	arc_degrees: float = 162.74,
	blocked_multiplier: float = 0.25,
	break_multiplier: float = 1.35,
	hit_cost: float = 35.0,
	target_path: NodePath = NodePath("Visual/Shield"),
	guarding_enabled: bool = true,
) -> void:
	_configured_owner = owner_body
	maximum_shield_health = maxf(0.0, _finite_or_fallback(max_health, 70.0))
	shield_arc_degrees = clampf(_finite_or_fallback(arc_degrees, 162.74), 0.0, 360.0)
	blocked_damage_multiplier = maxf(0.0, _finite_or_fallback(blocked_multiplier, 0.25))
	break_damage_multiplier = maxf(0.0, _finite_or_fallback(break_multiplier, 1.35))
	shield_hit_cost = maxf(0.0, _finite_or_fallback(hit_cost, 35.0))
	_configured_guarding = guarding_enabled
	_guarding_requested = guarding_enabled and maximum_shield_health > 0.0
	visual_target_path = target_path
	_shield_visual = _configured_owner.get_node_or_null(visual_target_path) if _configured_owner != null else null
	_arc_cos_threshold = cos(deg_to_rad(shield_arc_degrees * 0.5))
	reset()


func _finite_or_fallback(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback


func reset() -> void:
	current_shield_health = maximum_shield_health
	shield_is_broken = false
	_guarding_requested = _configured_guarding and maximum_shield_health > 0.0
	shield_active = _guarding_requested and not shield_is_broken
	_apply_visual()
	shield_reset.emit()
	shield_guard_state_changed.emit(shield_active, shield_is_broken)


func set_guarding(enabled: bool) -> void:
	if shield_is_broken:
		enabled = false
	_guarding_requested = enabled and _configured_guarding and maximum_shield_health > 0.0
	if shield_active == _guarding_requested:
		return
	shield_active = _guarding_requested
	_apply_visual()
	shield_guard_state_changed.emit(shield_active, shield_is_broken)


func is_guarding() -> bool:
	return shield_active and not shield_is_broken


func is_permanently_broken() -> bool:
	return shield_is_broken


func get_health_fraction() -> float:
	if maximum_shield_health <= 0.0:
		return 0.0
	return clampf(current_shield_health / maximum_shield_health, 0.0, 1.0)


func apply_stagger_multiplier(multiplier: float) -> bool:
	if not is_guarding() or multiplier <= 1.0:
		return false
	current_shield_health = maxf(0.0, current_shield_health - shield_hit_cost * (multiplier - 1.0))
	if current_shield_health > 0.0:
		return true
	shield_active = false
	shield_is_broken = true
	_guarding_requested = false
	_apply_visual()
	shield_guard_state_changed.emit(false, true)
	shield_broken.emit()
	return true


func damage_multiplier(owner_body: Node3D, hit_position: Vector3, _incoming_damage: float = 0.0) -> float:
	var body := owner_body if owner_body != null else _configured_owner
	if body == null or hit_position == Vector3.ZERO or maximum_shield_health <= 0.0:
		return 1.0
	if shield_hit_cost <= 0.0:
		return 1.0 if not shield_active else break_damage_multiplier
	if not shield_active:
		return 1.0
	if _is_shield_hit(body, hit_position):
		current_shield_health = maxf(0.0, current_shield_health - shield_hit_cost)
		shield_hit.emit(owner_body, hit_position, _incoming_damage, blocked_damage_multiplier, current_shield_health)
		if current_shield_health <= 0.0 and not shield_is_broken:
			shield_active = false
			shield_is_broken = true
			if _shield_visual != null:
				_shield_visual.visible = false
			shield_guard_state_changed.emit(shield_active, shield_is_broken)
			shield_broken.emit()
		return blocked_damage_multiplier
	return break_damage_multiplier


func _is_shield_hit(owner_body: Node3D, hit_position: Vector3) -> bool:
	var local_hit := owner_body.to_local(hit_position)
	var flat := Vector3(local_hit.x, 0.0, local_hit.z)
	var flat_len := flat.length()
	if flat_len <= 0.000001:
		return false
	var normal := flat / flat_len
	return normal.dot(Vector3.FORWARD) >= _arc_cos_threshold


func _apply_visual() -> void:
	if _shield_visual != null:
		_shield_visual.visible = shield_active
