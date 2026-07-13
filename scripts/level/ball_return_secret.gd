class_name BallReturnSecret
extends Area3D

signal secret_requested(secret_id: StringName, title: String)

@export var secret_id: StringName = &"ball_return"
@export var secret_title := "AUTHORIZED FETCHING"
var activated := false


func _ready() -> void:
	# The use key cannot solve this puzzle, but group membership surfaces the
	# explanatory prompt through the proximity-interaction fallback.
	add_to_group(&"interactables")
	body_entered.connect(_on_body_entered)


func get_interaction_label() -> String:
	return "BALL RETURN — PROJECTILES ONLY"


func interact(_actor: Node) -> void:
	# Explains the puzzle without allowing the use key to bypass it.
	pass


func _on_body_entered(body: Node) -> void:
	if activated: return
	if body is FetchProjectile or body.is_in_group(&"fetch_projectiles"):
		activated = true
		secret_requested.emit(secret_id, secret_title)
