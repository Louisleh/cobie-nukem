class_name Pawstol
extends WeaponBase

func fire_primary() -> bool:
	if not _begin_fire(false):
		return false
	_hitscan(definition.primary_damage, definition.range, 0.35, definition.knockback)
	if feedback != null:
		feedback.kick(0.16, 0.1, 0.18, 0.06)
	return true

func fire_secondary() -> bool:
	if not _begin_fire(true):
		return false
	_bark_burst()
	return true

func _bark_burst() -> void:
	for shot in 3:
		if shot > 0:
			await get_tree().create_timer(0.055).timeout
		if not is_inside_tree() or not enabled:
			return
		_hitscan(definition.secondary_damage, definition.range, 1.25, definition.knockback)
		_flash_muzzle()
		if feedback != null:
			feedback.kick(0.11, 0.12, 0.2, 0.05)

