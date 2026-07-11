extends Node

## Minimal composition root. Feature owners attach the initial menu/game route here.

func _ready() -> void:
	DebugLog.info("Boot complete", {
		"godot": Engine.get_version_info().get("string", "unknown"),
		"renderer": RenderingServer.get_current_rendering_method(),
	})
	GameState.begin_boot()
	if "--input-diagnostics" in OS.get_cmdline_user_args():
		GameState.request_diagnostics()
		SceneRouter.go_to.call_deferred("res://scenes/debug/input_diagnostics.tscn")
	else:
		SceneRouter.go_to.call_deferred("res://scenes/menus/title_screen.tscn")
