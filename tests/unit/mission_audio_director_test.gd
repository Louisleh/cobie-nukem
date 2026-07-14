extends SceneTree

const PROFILE := preload("res://resources/audio/salmon_mission_audio.tres")
const LIBRARY := preload("res://resources/audio/mission_audio_library.tres")

var failures: Array[String] = []


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	var director := MissionAudioDirector.new()
	director.playback_enabled = false
	root.add_child(director)
	_expect(director.configure(PROFILE, LIBRARY), "valid Salmon audio contract configures")
	_expect(director.owned_voice_count() == 3, "director owns exactly two music voices and one ambience voice")
	var states: Array[StringName] = [&"exploration", &"tension", &"combat", &"boss", &"victory"]
	for transition in 100:
		var state := states[transition % states.size()]
		_expect(director.request_state(state), "transition %d accepts %s" % [transition, state])
		_expect(director.current_state() == state, "transition %d records requested state" % transition)
		_expect(director.owned_voice_count() == 3, "transition %d does not allocate voices" % transition)
	_expect(director.set_zone_ambience(&"salmon_ambience_exterior"), "exterior ambience resolves")
	_expect(director.set_zone_ambience(&"salmon_ambience_tunnel"), "tunnel ambience resolves")
	_expect(not director.set_zone_ambience(&"missing_ambience"), "missing ambience fails closed")
	_expect(director.active_voice_count() <= 3, "active mission voices remain bounded")
	director.reset()
	_expect(director.active_voice_count() == 0, "reset stops every owned voice")
	_expect(director.owned_voice_count() == 3, "reset preserves the bounded pool")
	director.queue_free()
	await process_frame
	if failures.is_empty():
		print("MISSION AUDIO DIRECTOR TESTS: PASS")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
