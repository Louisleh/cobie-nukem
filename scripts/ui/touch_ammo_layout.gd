class_name TouchAmmoLayout
extends Node

var _hud: Node
var _controls: MobileControls
var _shutting_down := false


static func bind_to_hud(hud: Node, existing_layout: Node, controls: MobileControls) -> Node:
	var layout := existing_layout
	if not is_instance_valid(layout):
		layout = TouchAmmoLayout.new()
		hud.add_child(layout)
	layout.call(&"bind_controls", hud, controls)
	return layout


func bind_controls(hud: Node, controls: MobileControls) -> void:
	_disconnect_controls()
	_hud = hud
	_controls = controls
	_shutting_down = false
	if is_instance_valid(_controls):
		_controls.visibility_changed.connect(_on_layout_changed)
		_controls.resized.connect(_on_layout_changed)
		_controls.layout_settings_changed.connect(_on_layout_changed)
		_controls.tree_exiting.connect(_on_controls_tree_exiting)
	_on_layout_changed()


func has_bound_controls() -> bool:
	return is_instance_valid(_controls)


func _disconnect_controls() -> void:
	if not is_instance_valid(_controls):
		_controls = null
		return
	for binding in [
		[_controls.visibility_changed, _on_layout_changed],
		[_controls.resized, _on_layout_changed],
		[_controls.layout_settings_changed, _on_layout_changed],
		[_controls.tree_exiting, _on_controls_tree_exiting],
	]:
		var source: Signal = binding[0]
		var callback: Callable = binding[1]
		if source.is_connected(callback):
			source.disconnect(callback)
	_controls = null


func _on_controls_tree_exiting() -> void:
	_disconnect_controls()
	_on_layout_changed()


func _can_update_hud() -> bool:
	return not _shutting_down and is_inside_tree() and is_node_ready() and is_instance_valid(_hud) and _hud.is_inside_tree() and _hud.is_node_ready()


func _on_layout_changed() -> void:
	if not _can_update_hud(): return
	# The ordinary layout restores desktop placement first. GameHUD then calls
	# apply() to reserve the touch lane only while the bound controls are drawn.
	var viewport_size := _hud.get_viewport().get_visible_rect().size
	_hud.call(&"_apply_bottom_bar_layout", viewport_size)
	# The first bind runs before the factory returns the helper to GameHUD.
	apply(viewport_size)


func apply(viewport_size: Vector2) -> void:
	if not _can_update_hud() or not is_instance_valid(_controls) or not _controls.is_visible_in_tree(): return
	# Keep every touch target in place. The lower middle lane between the
	# sticks stays clear even for the largest fully deflected stick knobs.
	var left := viewport_size.x * 0.25
	if _controls.left_handed:
		left = viewport_size.x - left - 148.0
	var viewport_rect := Rect2(left, viewport_size.y * (5.0 / 9.0), 148.0, 40.0)
	var ammo_label := _hud.get_node("Root/BottomBar/AmmoLabel") as Label
	var bottom_bar := ammo_label.get_parent() as Control
	ammo_label.position = viewport_rect.position - bottom_bar.position
	ammo_label.size = viewport_rect.size


func shutdown() -> void:
	_shutting_down = true
	_disconnect_controls()
	_hud = null


func _exit_tree() -> void:
	shutdown()
