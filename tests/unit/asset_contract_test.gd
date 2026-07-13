extends SceneTree

const BALL_RETURN_SCENE := preload("res://scenes/interactables/ball_return_secret.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	await _test_ball_return_production_asset()
	if failures.is_empty():
		print("ASSET CONTRACT TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_ball_return_production_asset() -> void:
	var machine := BALL_RETURN_SCENE.instantiate() as BallReturnSecret
	get_root().add_child(machine)
	await process_frame
	var production_model := machine.get_node_or_null("ProductionModel")
	_expect(production_model != null, "ball return instantiates its authored production model")
	if production_model != null:
		var meshes := production_model.find_children("*", "MeshInstance3D", true, false)
		_expect(meshes.size() >= 9, "ball return retains its authored mesh-part vocabulary")
		_expect(not production_model.find_children("*", "StaticBody3D", true, false).is_empty(), "ball return import retains physical collision")
		_expect(is_equal_approx((production_model as Node3D).position.y, -1.4), "ball return model sits on the authored level ground plane")
	var trigger := machine.get_node_or_null("ProjectileTrigger") as CollisionShape3D
	_expect(trigger != null and trigger.shape != null, "ball return has a dedicated projectile trigger")
	var activations := [0]
	machine.secret_requested.connect(func(_id: StringName, _title: String) -> void: activations[0] += 1)
	var ordinary_body := Node3D.new()
	machine._on_body_entered(ordinary_body)
	_expect(activations[0] == 0, "ordinary actors cannot bypass the projectile puzzle")
	var fetch_body := Node3D.new()
	fetch_body.add_to_group(&"fetch_projectiles")
	machine._on_body_entered(fetch_body)
	machine._on_body_entered(fetch_body)
	_expect(activations[0] == 1 and machine.activated, "fetch projectile activates the secret exactly once")
	ordinary_body.free()
	fetch_body.free()
	machine.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
