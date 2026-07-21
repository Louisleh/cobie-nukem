class_name PlayerImpactEffects
extends Node

var pool := ImpactEffectPool.new()


func _ready() -> void:
	pool.prewarm()


func _process(delta: float) -> void:
	pool.update(delta)


func _exit_tree() -> void:
	pool.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		pool.clear()
