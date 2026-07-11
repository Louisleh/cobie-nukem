class_name HealthArmor
extends Node

signal health_changed(current: float, maximum: float)
signal armor_changed(current: float, maximum: float)
signal damaged(amount: float, health_damage: float, armor_damage: float, source: Node)
signal died(source: Node)

@export var max_health := 100.0
@export var max_armor := 100.0
@export_range(0.0, 1.0, 0.05) var armor_absorption := 0.65
@export var health := 100.0
@export var armor := 0.0

var is_dead := false

func _ready() -> void:
	health = clampf(health, 0.0, max_health)
	armor = clampf(armor, 0.0, max_armor)

func apply_damage(amount: float, source: Node = null) -> float:
	if amount <= 0.0 or is_dead:
		return 0.0
	var armor_damage := minf(armor, amount * armor_absorption)
	var health_damage := minf(health, amount - armor_damage)
	armor -= armor_damage
	health -= health_damage
	armor_changed.emit(armor, max_armor)
	health_changed.emit(health, max_health)
	damaged.emit(amount, health_damage, armor_damage, source)
	if health <= 0.0:
		is_dead = true
		died.emit(source)
	return health_damage

func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead:
		return 0.0
	var previous := health
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)
	return health - previous

func add_armor(amount: float) -> float:
	if amount <= 0.0 or is_dead:
		return 0.0
	var previous := armor
	armor = minf(max_armor, armor + amount)
	armor_changed.emit(armor, max_armor)
	return armor - previous

func restore_full() -> void:
	is_dead = false
	health = max_health
	armor = max_armor
	health_changed.emit(health, max_health)
	armor_changed.emit(armor, max_armor)

