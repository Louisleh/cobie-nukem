class_name Interactable
extends Node3D

signal interaction_completed(actor: Node)

@export var prompt := "INTERACT"
@export var enabled := true

func can_interact(_actor: Node) -> bool:
	return enabled

func interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false
	interaction_completed.emit(actor)
	return true

