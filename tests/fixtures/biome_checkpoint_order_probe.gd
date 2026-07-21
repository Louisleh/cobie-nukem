extends BiomeMissionController

var call_order: Array[StringName] = []


func _init() -> void:
	metadata = preload("res://resources/level/ventura_pier_pressure.tres")
	content_manifest = preload("res://resources/content/ventura_manifest.tres")
	biome_profile = preload("res://resources/biomes/ventura_profile.tres")
	setup_presentation = false
	spawn_player = true


func run_order_probe() -> void:
	var game_state := Node.new()
	_initialize_runtime_and_player(game_state)
	game_state.free()


func _validate_configuration() -> bool:
	return true


func _apply_requested_checkpoint() -> void:
	call_order.append(&"consume")
	_restored_checkpoint = {"pending_compliance_tags": 1, "run_mode": "continued"}


func _start_or_restore_progression(_game_state: Node) -> void:
	call_order.append(&"progression")


func _setup_runtime() -> void:
	call_order.append(&"mission_runtime")
	_mission_runtime = MissionRuntime.new()
	add_child(_mission_runtime)


func _build_world() -> void:
	pass


func _restore_runtime_state() -> void:
	call_order.append(&"mission_restore")


func _spawn_player() -> void:
	call_order.append(&"player")
