extends SceneTree

const HUD := preload("res://scenes/ui/hud.tscn")
var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _run() -> void:
	var hud := HUD.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame
	var presentation := MissionPresentation.new()
	root.add_child(presentation)
	presentation.set("_hud", hud)
	var sounds := hud.sounds
	sounds.stop_all()
	presentation.on_objective_changed("REACH THE LAB")
	_check(hud.notification_label.text == "OBJECTIVE: REACH THE LAB", "objective remains legible")
	_check(hud.get_caption_text().contains("REACH THE LAB"), "objective accessibility caption remains")
	_check(_silent(sounds), "objective does not falsely play pickup cue")
	hud.clear_captions()
	presentation.on_narrative_message("NO ANIMALS ON SPORTS FIELD", 2.5)
	_check(hud.notification_label.text == "NO ANIMALS ON SPORTS FIELD", "sign story remains legible")
	_check(hud.get_caption_text().contains("NO ANIMALS ON SPORTS FIELD"), "sign accessibility caption remains")
	_check(_silent(sounds), "sign story does not falsely play pickup cue")
	hud.show_notification("REAL PICKUP")
	_check(not _silent(sounds), "real pickup retains its distinct audio cue")
	sounds.stop_all()
	hud.show_secret("REAL SECRET")
	_check(not _silent(sounds), "secret retains its distinct audio cue")
	sounds.stop_all()
	presentation.queue_free()
	hud.queue_free()
	for index in 12: await process_frame
	if failures.is_empty():
		print("SALMON OPENING NOTIFICATION: PASS")
		quit(0)
	else:
		for failure in failures: push_error("OPENING NOTIFICATION: " + failure)
		quit(1)

func _silent(sounds: ProceduralAudio) -> bool:
	return sounds._voices.all(func(voice: AudioStreamPlayer) -> bool: return voice.stream == null)
