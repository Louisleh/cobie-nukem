extends Node3D

var velocity := Vector3.ZERO

func _physics_process(_delta: float) -> void:
	position += velocity * _delta
