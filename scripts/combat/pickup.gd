class_name CombatPickup
extends Area3D

signal collected(pickup: CombatPickup, collector: Node, message: String)

@export var definition: PickupDefinition
@export var spin_speed := 1.7
@export var bob_height := 0.12
@export var bob_speed := 2.4

var _origin_y := 0.0
var _time := 0.0
var _available := true

func _ready() -> void:
	_origin_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _origin_y + sin(_time * bob_speed) * bob_height

func try_collect(collector: Node) -> bool:
	if not _available or definition == null:
		return false
	var applied := false
	match definition.kind:
		PickupDefinition.Kind.HEALTH:
			applied = collector.has_method("heal") and collector.heal(definition.amount) > 0.0
		PickupDefinition.Kind.ARMOR:
			applied = collector.has_method("add_armor") and collector.add_armor(definition.amount) > 0.0
		PickupDefinition.Kind.AMMO:
			applied = collector.has_method("add_ammo") and collector.add_ammo(definition.ammo_type, int(definition.amount)) > 0
		PickupDefinition.Kind.WEAPON:
			applied = collector.has_method("unlock_weapon") and collector.unlock_weapon(definition.ammo_type)
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
