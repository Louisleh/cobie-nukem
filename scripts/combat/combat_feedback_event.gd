class_name CombatFeedbackEvent
extends RefCounted

enum HitType { MISS, WORLD, ENEMY, DESTRUCTIBLE, SHIELD }

var shot_id: int
var weapon_id: StringName
var origin: Vector3
var destination: Vector3
var hit_type: HitType
var surface_type: StringName
var damage: float
var critical := false
var killed := false
var target: Node


func legacy_kind() -> StringName:
	match hit_type:
		HitType.ENEMY, HitType.SHIELD: return &"enemy"
		HitType.DESTRUCTIBLE: return &"destructible"
		HitType.WORLD: return &"world"
	return &"miss"
