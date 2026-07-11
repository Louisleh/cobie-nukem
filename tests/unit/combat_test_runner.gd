extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_damage_and_armor()
	_test_healing_and_armor_caps()
	_test_auto_aim_modes()
	_test_weapon_ammo_and_cooldown()
	_test_required_scenes_load()
	if failures == 0:
		print("COMBAT TESTS: PASS")
	else:
		push_error("COMBAT TESTS: %d FAILURE(S)" % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func _test_damage_and_armor() -> void:
	var component := HealthArmor.new()
	component.health = 100.0
	component.armor = 50.0
	component.armor_absorption = 0.65
	root.add_child(component)
	component.apply_damage(20.0)
	_expect(is_equal_approx(component.armor, 37.0), "armor absorbs 65 percent")
	_expect(is_equal_approx(component.health, 93.0), "remaining damage reaches health")
	component.free()

func _test_healing_and_armor_caps() -> void:
	var component := HealthArmor.new()
	component.health = 95.0
	component.armor = 98.0
	root.add_child(component)
	_expect(is_equal_approx(component.heal(20.0), 5.0), "healing reports capped gain")
	_expect(is_equal_approx(component.add_armor(20.0), 2.0), "armor reports capped gain")
	component.free()

func _test_auto_aim_modes() -> void:
	var tuning := AutoAimTuning.new()
	tuning.mode = AutoAimTuning.Mode.OFF
	_expect(is_zero_approx(tuning.strength()), "off auto aim has zero strength")
	tuning.mode = AutoAimTuning.Mode.CLASSIC
	_expect(is_equal_approx(tuning.strength(), 0.7), "classic auto aim strength")
	tuning.mode = AutoAimTuning.Mode.HEAVY
	_expect(is_equal_approx(tuning.strength(), 1.0), "heavy auto aim strength")

func _test_weapon_ammo_and_cooldown() -> void:
	var definition := WeaponDefinition.new()
	definition.ammo_type = "shells"
	definition.magazine_size = 10
	definition.starting_ammo = 3
	definition.primary_cooldown = 0.5
	var weapon := WeaponBase.new()
	weapon.definition = definition
	weapon.camera = Camera3D.new()
	weapon.add_child(weapon.camera)
	root.add_child(weapon)
	weapon.enabled = true
	weapon.ammo = 3
	_expect(weapon.definition != null, "weapon has definition")
	_expect(weapon.camera != null, "weapon has camera")
	_expect(weapon.enabled and weapon.unlocked, "weapon is enabled and unlocked")
	_expect(weapon._has_ammo(1), "weapon recognizes available ammo")
	_expect(weapon._begin_fire(false), "weapon fires with ammo")
	_expect(weapon.ammo == 2, "weapon consumes ammo")
	_expect(not weapon.can_fire(false), "weapon cooldown blocks immediate refire")
	weapon.free()

func _test_required_scenes_load() -> void:
	for path in [
		"res://scenes/player/cobie_player.tscn",
		"res://scenes/weapons/pawstol.tscn",
		"res://scenes/weapons/barkshot.tscn",
		"res://scenes/weapons/fetch_launcher.tscn",
		"res://scenes/weapons/fetch_projectile.tscn",
		"res://scenes/pickups/treat.tscn",
	]:
		_expect(ResourceLoader.exists(path), "scene exists: " + path)
		var scene := load(path) as PackedScene
		var instance := scene.instantiate() if scene != null else null
		_expect(instance != null, "scene instantiates: " + path)
		if instance != null:
			instance.free()
