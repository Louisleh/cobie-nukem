class_name Barkshot
extends WeaponBase

func fire_primary() -> bool:
	return _fire_shell(false)

func fire_secondary() -> bool:
	return _fire_shell(true)

func _fire_shell(secondary: bool) -> bool:
	if not _begin_fire(secondary):
		return false
	var pellet_count := definition.pellets + (2 if secondary else 0)
	var spread := definition.spread_degrees * (0.55 if secondary else 1.0)
	var damage := definition.secondary_damage if secondary else definition.primary_damage
	for pellet in pellet_count:
		_hitscan(damage, definition.range, spread, definition.knockback)
	if feedback != null:
		feedback.kick(0.72 if secondary else 0.48, 0.35, 0.75, 0.16)
	return true

