extends SceneTree

const Presentation := preload("res://scripts/ai/enemy_sprite_presentation.gd")
const REGULAR_SCENES := [
	"res://scenes/enemies/leash_enforcement_drone.tscn",
	"res://scenes/enemies/mutant_groundskeeper.tscn",
	"res://scenes/enemies/squirrel_trooper.tscn",
]
const ELITE_BOSS_SCENES := [
	"res://scenes/enemies/compliance_hound.tscn",
	"res://scenes/enemies/animal_control_walker.tscn",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_direction_quantization()
	_test_state_frame_vocabulary()
	for scene_path in REGULAR_SCENES:
		await _test_scene(scene_path, true)
	for scene_path in ELITE_BOSS_SCENES:
		await _test_scene(scene_path, false)
	if failures.is_empty():
		print("PASS: authored enemy atlases, deterministic direction/state selection, elite/boss vocabulary")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_direction_quantization() -> void:
	var forward := Vector3.FORWARD
	_expect(Presentation.direction_index_from_vectors(forward, Vector3.FORWARD) == 0, "Front direction maps to octant 0")
	_expect(Presentation.direction_index_from_vectors(forward, Vector3.LEFT) == 2, "Left direction maps to octant 2")
	_expect(Presentation.direction_index_from_vectors(forward, Vector3.BACK) == 4, "Back direction maps to octant 4")
	_expect(Presentation.direction_index_from_vectors(forward, Vector3.RIGHT) == 6, "Right direction maps to octant 6")
	_expect(Presentation.direction_index_from_vectors(Vector3.ZERO, Vector3.RIGHT) == 0, "Degenerate direction has stable fallback")


func _test_state_frame_vocabulary() -> void:
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.IDLE, 0) == 0, "Idle uses authored front frame")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.CHASE, 2) == 2, "Chase uses authored side frame")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.ALERT, 7) == 4, "Alert uses explicit pose")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.ATTACK, 3) == 5, "Attack uses explicit pose")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.HURT, 0) == 6, "Hurt uses explicit pose")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.STUNNED, 0) == 6, "Stagger uses explicit pose")
	_expect(Presentation.atlas_frame_for(EnemyAgent.State.DEAD, 0) == 7, "Death uses explicit pose")


func _test_scene(scene_path: String, expects_atlas: bool) -> void:
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "Enemy scene loads: %s" % scene_path)
	if packed == null:
		return
	var enemy := packed.instantiate() as EnemyAgent
	root.add_child(enemy)
	await process_frame
	var presentation := enemy.get_node_or_null("EnemySpritePresentation") as EnemySpritePresentation
	_expect(presentation != null, "Presentation component exists: %s" % scene_path)
	if presentation != null:
		var sprite := enemy.get_node_or_null("Visual/DetailedSprite") as Sprite3D
		_expect(sprite != null, "Detailed sprite exists: %s" % scene_path)
		if expects_atlas and sprite != null:
			_expect(presentation.atlas_texture != null, "Regular archetype has authored atlas: %s" % scene_path)
			_expect(sprite.hframes == 4 and sprite.vframes == 2, "Atlas has bounded 4x2 runtime layout: %s" % scene_path)
			enemy._set_state(EnemyAgent.State.ALERT)
			_expect(presentation.debug_current_frame() == 4, "Alert state applies immediately: %s" % scene_path)
			enemy._set_state(EnemyAgent.State.ATTACK)
			_expect(presentation.debug_current_frame() == 5, "Attack state applies immediately: %s" % scene_path)
			enemy._set_state(EnemyAgent.State.STUNNED)
			_expect(presentation.debug_current_frame() == 6, "Stagger state applies immediately: %s" % scene_path)
			enemy._set_state(EnemyAgent.State.DEAD)
			_expect(presentation.debug_current_frame() == 7, "Death state applies immediately: %s" % scene_path)
		elif presentation != null:
			_expect(presentation.atlas_texture == null, "Elite/boss reuses canonical texture: %s" % scene_path)
			var before := sprite.modulate if sprite != null else Color.WHITE
			enemy._set_state(EnemyAgent.State.ATTACK)
			_expect(sprite != null and sprite.modulate != before, "Elite/boss attack vocabulary is visible: %s" % scene_path)
	enemy.free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
