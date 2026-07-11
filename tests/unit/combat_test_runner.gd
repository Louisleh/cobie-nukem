extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_damage_and_armor()
	_test_healing_and_armor_caps()
	_test_auto_aim_modes()
	_test_weapon_ammo_and_cooldown()
	_test_visible_muzzle_flash()
	_test_enemy_hit_pop()
	_test_player_forwards_weapon_ammo()
	_test_instant_weapon_selection()
	_test_weapon_balance_and_fetch_bounce()
	_test_all_pickups_collect()
	_test_full_resource_pickups_collect()
	_test_access_collar_updates_hud()
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

func _test_player_forwards_weapon_ammo() -> void:
	var definition := WeaponDefinition.new()
	definition.display_name = "Barkshot"
	definition.ammo_type = "shells"
	definition.magazine_size = 40
	var barkshot := WeaponBase.new()
	barkshot.definition = definition
	barkshot.ammo = 12
	var player := CobiePlayer.new()
	player.weapons.append(barkshot)
	barkshot.ammo_changed.connect(player._on_weapon_ammo_changed.bind(barkshot))
	var reported_ammo := [-1]
	player.weapon_changed.connect(func(_name: String, ammo: int, _maximum: int) -> void: reported_ammo[0] = ammo)
	barkshot.ammo_changed.emit(11, 40)
	_expect(reported_ammo[0] == 11, "player forwards Barkshot ammo changes to the HUD")
	barkshot.free()
	player.free()

func _test_instant_weapon_selection() -> void:
	var player := CobiePlayer.new()
	var changes := [0]
	player.weapon_changed.connect(func(_name: String, _ammo: int, _maximum: int) -> void: changes[0] += 1)
	for name in ["Pawstol", "Barkshot", "Fetch Launcher"]:
		var weapon := WeaponBase.new()
		var definition := WeaponDefinition.new()
		definition.display_name = name
		definition.magazine_size = 20
		weapon.definition = definition
		weapon.unlocked = true
		player.weapons.append(weapon)
	_expect(player.select_weapon_slot(2), "number-key weapon slot selects an unlocked weapon")
	_expect(player.current_weapon_index == 2, "weapon slot changes synchronously")
	_expect(changes[0] == 1, "weapon HUD change emits in the same call")
	_expect(not player.select_weapon_slot(3), "out-of-range weapon slot is ignored")
	for weapon in player.weapons:
		weapon.free()
	player.weapons.clear()
	player.free()

func _test_weapon_balance_and_fetch_bounce() -> void:
	var pawstol := load("res://resources/weapons/pawstol.tres") as WeaponDefinition
	var barkshot := load("res://resources/weapons/barkshot.tres") as WeaponDefinition
	_expect(is_equal_approx(pawstol.knockback, 3.0), "Pawstol has readable knockback")
	_expect(barkshot.knockback * barkshot.pellets <= 5.0, "Barkshot pellet knockback is capped")
	var projectile := preload("res://scenes/weapons/fetch_projectile.tscn").instantiate() as FetchProjectile
	_expect(projectile.collision_mask == 5, "Fetch ball collides with world and enemy layers")
	_expect(projectile.collision_mask_for_blast == 4, "Fetch blast queries the enemy layer")
	projectile.velocity = Vector3(0.0, 0.0, -10.0)
	projectile._bounce(Vector3.BACK)
	_expect(projectile.velocity.z > 0.0 and projectile.velocity.y >= 2.4, "Fetch ball visibly rebounds after impact")
	projectile.free()

func _test_visible_muzzle_flash() -> void:
	var weapon := preload("res://scenes/weapons/pawstol.tscn").instantiate() as WeaponBase
	weapon.camera = Camera3D.new()
	weapon.add_child(weapon.camera)
	root.add_child(weapon)
	weapon.enabled = true
	_expect(weapon._begin_fire(false), "Pawstol begins firing")
	var burst := weapon.get_node_or_null("MuzzleBurst") as GeometryInstance3D
	_expect(burst != null and burst.visible, "firing shows a visible muzzle burst")
	weapon.free()

func _test_enemy_hit_pop() -> void:
	var weapon := WeaponBase.new()
	root.add_child(weapon)
	var pop := weapon._spawn_enemy_hit_pop(Vector3.ZERO, Vector3.UP, root)
	_expect(pop != null and pop.get_node_or_null("ContactFlash") != null, "enemy hit creates a bright contact flash")
	var sparks := pop.find_children("Spark*", "MeshInstance3D", false, false)
	_expect(sparks.size() == 6, "enemy hit creates six lightweight explosion fragments")
	pop.free()
	weapon.free()

func _test_all_pickups_collect() -> void:
	var collector := preload("res://tests/fixtures/pickup_collector.gd").new()
	for path in [
		"res://scenes/pickups/access_collar.tscn",
		"res://scenes/pickups/barkshot_weapon.tscn",
		"res://scenes/pickups/fetch_launcher_weapon.tscn",
		"res://scenes/pickups/golden_tag.tscn",
		"res://scenes/pickups/leather_padding.tscn",
		"res://scenes/pickups/premium_treat.tscn",
		"res://scenes/pickups/shells.tscn",
		"res://scenes/pickups/squeaker.tscn",
		"res://scenes/pickups/tennis_balls.tscn",
		"res://scenes/pickups/treat.tscn",
		"res://scenes/pickups/water_bowl.tscn",
		"res://scenes/pickups/zoomies.tscn",
	]:
		var pickup := (load(path) as PackedScene).instantiate() as CombatPickup
		_expect(pickup.try_collect(collector), "pickup dispatch succeeds: " + path)
		pickup.free()
	var base := preload("res://scenes/pickups/pickup_base.tscn").instantiate() as CombatPickup
	base.position.y = 0.1
	base._ready()
	var shape := base.get_node("CollisionShape3D").shape as SphereShape3D
	_expect(shape.radius >= 1.0, "pickup collection radius is forgiving")
	base._process(0.1)
	_expect(base.position.y >= 0.6, "pickup remains visibly anchored above the floor")
	base.free()
	collector.free()

func _test_full_resource_pickups_collect() -> void:
	var collector := preload("res://tests/fixtures/full_collector.gd").new()
	for path in [
		"res://scenes/pickups/treat.tscn",
		"res://scenes/pickups/leather_padding.tscn",
		"res://scenes/pickups/shells.tscn",
		"res://scenes/pickups/barkshot_weapon.tscn",
	]:
		var pickup := (load(path) as PackedScene).instantiate() as CombatPickup
		_expect(pickup.try_collect(collector), "full-resource player still collects pickup: " + path)
		pickup.free()
	collector.free()

func _test_access_collar_updates_hud() -> void:
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as GameHUD
	var player := CobiePlayer.new()
	player.access_item_changed.connect(hud.set_access_item)
	_expect(player.receive_pickup_effect(PickupDefinition.Kind.ACCESS_COLLAR, 0.0), "access collar applies to player")
	_expect(hud.get_node("Root/BottomBar/AccessLabel").text == "ACCESS COLLAR", "access collar appears in HUD")
	hud.free()
	player.free()

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
