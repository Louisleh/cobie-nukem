class_name CombatPickup
extends Area3D

signal collected(pickup: CombatPickup, collector: Node, message: String)

@export var definition: PickupDefinition
@export var spin_speed := 1.7
@export var bob_height := 0.12
@export var bob_speed := 2.4

var _anchor := Vector3.ZERO
var _time := 0.0
var _available := true

func _ready() -> void:
	_anchor = position
	# All current level floors meet at y=0. Keep a readable minimum even if an
	# authored spawn was accidentally placed inside the floor.
	_anchor.y = maxf(_anchor.y, 0.72)
	position = _anchor
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position = _anchor + Vector3.UP * sin(_time * bob_speed) * bob_height

func _physics_process(_delta: float) -> void:
	if not _available:
		return
	# Polling makes collection reliable when an Area begins overlapped, a frame is
	# dropped, or the player crosses the edge between body-enter notifications.
	for body in get_overlapping_bodies():
		if try_collect(body):
			return
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null and global_position.distance_to(player.global_position) <= 1.35:
		try_collect(player)

func try_collect(collector: Node) -> bool:
	if not _available or definition == null:
		return false
	var applied := false
	match definition.kind:
		PickupDefinition.Kind.HEALTH:
			if collector.has_method("heal"):
				collector.heal(definition.amount)
				applied = true
		PickupDefinition.Kind.ARMOR:
			if collector.has_method("add_armor"):
				collector.add_armor(definition.amount)
				applied = true
		PickupDefinition.Kind.AMMO:
			if collector.has_method("add_ammo"):
				collector.add_ammo(definition.ammo_type, int(definition.amount))
				applied = true
		PickupDefinition.Kind.WEAPON:
			if collector.has_method("unlock_weapon"):
				collector.unlock_weapon(definition.ammo_type)
				applied = true
		PickupDefinition.Kind.FULL_RESTORE:
			if collector.has_method("restore_full"):
				collector.restore_full()
				applied = true
		_:
			if collector.has_method("receive_pickup_effect"):
				applied = collector.receive_pickup_effect(definition.kind, definition.amount)
	if not applied:
		return false
	collected.emit(self, collector, definition.message)
	_consume()
	return true

func _on_body_entered(body: Node) -> void:
	try_collect(body)

func _consume() -> void:
	_available = false
	visible = false
	monitoring = false
	if definition.respawns:
		await get_tree().create_timer(definition.respawn_seconds).timeout
		_available = true
		visible = true
		monitoring = true
	else:
		queue_free()
