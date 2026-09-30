class_name PhysicalInputState
extends RefCounted

# This owner caches keyboard/mouse events only. Engine actions, touch and
# joystick state remain with their existing owners.
var _keys: Dictionary = {}
var _mouse_buttons: Dictionary = {}


func observe(event: InputEvent) -> void:
	if event is InputEventKey:
		_keys[event.physical_keycode] = event.pressed
		_keys[event.keycode] = event.pressed
	elif event is InputEventMouseButton:
		_mouse_buttons[event.button_index] = event.pressed


func strength(binding: Dictionary) -> float:
	var index := int(binding.get("index", 0))
	match str(binding.get("type", "")):
		"key":
			return 1.0 if bool(_keys.get(index, false)) else 0.0
		"mouse_button":
			return 1.0 if bool(_mouse_buttons.get(index, false)) else 0.0
	return 0.0


func release_on_focus(profile: InputProfile, discrete_latches: Dictionary, remaining_strength: Callable) -> void:
	var affected: Array[StringName] = []
	if profile != null:
		for action in profile.action_bindings:
			for binding in profile.bindings_for(StringName(action)):
				if strength(binding) > 0.0:
					affected.append(StringName(action))
					break
	_keys.clear()
	_mouse_buttons.clear()
	# Rearm only actions whose held physical source was removed and which no
	# other owner still holds. Preserve a mixed-source held action's edge latch.
	for action in affected:
		if float(remaining_strength.call(action)) < 0.5:
			discrete_latches.erase(action)
