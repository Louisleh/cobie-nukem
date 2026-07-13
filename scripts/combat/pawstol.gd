class_name Pawstol
extends WeaponBase

var _bark_timer: Timer
var _bark_shots_remaining := 0


func _ready() -> void:
	super._ready()
	_bark_timer = Timer.new()
	_bark_timer.name = "BarkBurstTimer"
	_bark_timer.one_shot = true
	_bark_timer.wait_time = 0.055
	_bark_timer.timeout.connect(_fire_bark_shot)
	add_child(_bark_timer)

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
	_bark_shots_remaining = 3
	_fire_bark_shot()


func _fire_bark_shot() -> void:
	if _bark_shots_remaining <= 0 or not is_inside_tree() or not enabled:
		_bark_shots_remaining = 0
		return
	_hitscan(definition.secondary_damage, definition.range, 1.25, definition.knockback)
	_flash_muzzle()
	if feedback != null:
		feedback.kick(0.11, 0.12, 0.2, 0.05)
	_bark_shots_remaining -= 1
	if _bark_shots_remaining > 0:
		_bark_timer.start()
