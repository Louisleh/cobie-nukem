class_name NarrativeSign
extends StaticBody3D

signal read(sign_id: StringName, text: String, actor: Node, times_read: int)
signal secret_requested(secret_id: StringName, title: String)

@export var sign_id: StringName = &"sign"
@export_multiline var sign_text := "AUTHORIZED DOGS ONLY"
@export var secret_after_reads := 0
@export var secret_id: StringName = &""
@export var secret_title := "SIGN SEEMS OPTIONAL"
@export var size := Vector2(4.0, 1.8)
var times_read := 0


func _ready() -> void:
	if get_child_count() == 0: _build_visual()


func get_interaction_label() -> String:
	return "READ SIGN"


func interact(actor: Node) -> void:
	times_read += 1
	read.emit(sign_id, sign_text, actor, times_read)
	if secret_after_reads > 0 and times_read == secret_after_reads:
		secret_requested.emit(secret_id, secret_title)


func _build_visual() -> void:
	var board := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = Vector3(size.x, size.y, 0.15); board.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = Color("e9d8a6"); board.material_override = material; add_child(board)
	var label := Label3D.new(); label.text = sign_text; label.font_size = 48; label.modulate = Color("151515"); label.outline_size = 6; label.position.z = 0.09; label.pixel_size = 0.006; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.width = int(size.x / label.pixel_size * 0.8); add_child(label)
	var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = box.size; shape.shape = box_shape; add_child(shape)
