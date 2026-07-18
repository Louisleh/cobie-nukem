extends SceneTree

const GALLERY := preload("res://scenes/debug/mount_hood_foundry_gallery.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene := GALLERY.instantiate()
	root.add_child(scene)
	for _frame in range(8):
		await process_frame
	var output := "res://artifacts/visual-foundry/mount_hood/pilot_16x9.png"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	var absolute := ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := root.get_texture().get_image().save_png(absolute)
	if error != OK:
		push_error("Could not save Mount Hood capture: %s" % error)
	else:
		print("Captured Mount Hood gallery: %s" % absolute)
	quit(error)
