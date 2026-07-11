extends SceneTree

const ENEMY_SCENES := [
	"res://scenes/enemies/leash_enforcement_drone.tscn",
	"res://scenes/enemies/mutant_groundskeeper.tscn",
	"res://scenes/enemies/squirrel_trooper.tscn",
	"res://scenes/enemies/compliance_hound.tscn",
	"res://scenes/enemies/animal_control_walker.tscn",
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in ENEMY_SCENES:
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "Scene loads: %s" % scene_path)
		if packed == null:
			continue
		var enemy := packed.instantiate() as EnemyAgent
		_expect(enemy != null, "Scene root is EnemyAgent: %s" % scene_path)
		if enemy == null:
			continue
		root.add_child(enemy)
		await process_frame
		_expect(enemy.definition != null, "Definition assigned: %s" % scene_path)
		_expect(enemy.is_in_group(&"enemies"), "Enemy group: %s" % scene_path)
		_expect(enemy.is_in_group(&"auto_aim_targets"), "Auto-aim group: %s" % scene_path)
		_expect(enemy.get_auto_aim_position().is_finite(), "Finite aim point: %s" % scene_path)
		var before := enemy.health
		var applied := enemy.apply_damage(5.0, null, enemy.global_position)
		_expect(applied > 0.0, "Damage hook applies: %s" % scene_path)
		_expect(enemy.health < before, "Health decreases: %s" % scene_path)
		enemy.free()
	_test_hound_shield()
	_test_walker_phases()
	if failures.is_empty():
		print("PASS: enemy contracts, damage hooks, shield, and boss phases")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_hound_shield() -> void:
	var hound := preload("res://scenes/enemies/compliance_hound.tscn").instantiate() as ComplianceHound
	root.add_child(hound)
	await process_frame
	var front_damage := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var back_damage := hound.apply_damage(20.0, null, hound.global_position + Vector3.BACK)
	_expect(back_damage > front_damage, "Hound rear weak point bypasses shield")
	hound.free()

func _test_walker_phases() -> void:
	var walker := preload("res://scenes/enemies/animal_control_walker.tscn").instantiate() as AnimalControlWalker
	root.add_child(walker)
	await process_frame
	walker.apply_damage(400.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.EXPOSED_CORE, "Walker exposes core below 75%")
	walker.apply_damage(300.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.CHARGE, "Walker charges below 45%")
	walker.apply_damage(300.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.GOLDEN_BALL, "Walker requires Golden Ball below 15%")
	var protected_health := walker.health
	walker.apply_damage(999.0)
	_expect(is_equal_approx(walker.health, protected_health), "Regular damage cannot finish Walker")
	walker.strike_with_golden_ball()
	_expect(walker.is_dead, "Golden Ball finishes Walker")
	walker.free()

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

