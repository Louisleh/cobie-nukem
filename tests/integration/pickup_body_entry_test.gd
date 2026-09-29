extends SceneTree

## A real PhysicsServer body-enter path, not a direct try_collect() call.
const PICKUP := preload("res://scenes/pickups/pickup_base.tscn")
const TREAT := preload("res://resources/pickups/treat.tres")

class Collector extends CharacterBody3D:
	var heal_count := 0
	func heal(amount: float) -> float:
		heal_count += 1
		return amount

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _run() -> void:
	var pickup := PICKUP.instantiate() as CombatPickup
	var definition := TREAT.duplicate(true) as PickupDefinition
	definition.respawns = true
	definition.respawn_seconds = 0.4
	pickup.definition = definition
	root.add_child(pickup)
	var collector := Collector.new()
	collector.collision_layer = 2
	collector.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	collector.add_child(shape)
	collector.position = Vector3(0, 0.75, 3)
	root.add_child(collector)
	var observed := {"entries": 0, "collections": 0}
	pickup.body_entered.connect(func(_body: Node3D) -> void: observed.entries += 1)
	pickup.collected.connect(func(_item: CombatPickup, _actor: Node, _message: String) -> void: observed.collections += 1)
	for index in 3: await physics_frame
	collector.global_position = Vector3(0, 0.75, 0)
	for index in 3: await physics_frame
	print("PICKUP FIRST: entries=%d collections=%d heals=%d monitoring=%s visible=%s" % [observed.entries, observed.collections, collector.heal_count, pickup.monitoring, pickup.visible])
	_check(observed.entries == 1 and observed.collections == 1 and collector.heal_count == 1, "first actual body entry collects exactly once")
	_check(not pickup.monitoring and not pickup.visible, "pickup stops monitoring once consumed inside body-enter callback")
	collector.global_position = Vector3(0, 0.75, 3)
	await create_timer(0.5).timeout
	print("PICKUP RESPAWN: entries=%d collections=%d heals=%d monitoring=%s visible=%s" % [observed.entries, observed.collections, collector.heal_count, pickup.monitoring, pickup.visible])
	_check(pickup.monitoring and pickup.visible and observed.collections == 1, "respawn reenables monitoring without duplicate collection")
	collector.global_position = Vector3(0, 0.75, 0)
	for index in 3: await physics_frame
	for index in 2: await process_frame
	print("PICKUP SECOND: entries=%d collections=%d heals=%d monitoring=%s visible=%s" % [observed.entries, observed.collections, collector.heal_count, pickup.monitoring, pickup.visible])
	_check(observed.entries == 2 and observed.collections == 2 and collector.heal_count == 2, "second entry collects exactly once after respawn")
	_check(not pickup.monitoring and not pickup.visible, "second consumption also stops monitoring")
	collector.queue_free()
	pickup.queue_free()
	for index in 4: await process_frame
	if failures.is_empty():
		print("PICKUP BODY ENTRY: PASS")
		quit(0)
	else:
		for failure in failures: push_error("PICKUP BODY ENTRY: " + failure)
		quit(1)
