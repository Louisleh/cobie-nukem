extends SceneTree

const LIBRARY_PATH := "res://resources/audio/production_audio_library.tres"
const MISSION_LIBRARY_PATH := "res://resources/audio/mission_audio_library.tres"
const BRIDGE_SCENE := preload("res://scenes/ui/combat_audio_bridge.tscn")
const WEAPON_SCENES := [
	"res://scenes/weapons/pawstol.tscn",
	"res://scenes/weapons/barkshot.tscn",
	"res://scenes/weapons/fetch_launcher.tscn",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var library := load(LIBRARY_PATH) as AudioCueLibrary
	_expect(library != null, "production audio library loads")
	if library == null:
		_finish()
		return
	_expect(library.validation_errors().is_empty(), "cue contracts are valid: %s" % [library.validation_errors()])
	var required: Array[StringName] = []
	for weapon in [&"pawstol", &"barkshot", &"fetch_launcher"]:
		for suffix in [&"shot", &"mechanical", &"reload_start", &"reload_step", &"reload_complete", &"empty", &"switch"]:
			required.append(StringName("%s_%s" % [weapon, suffix]))
	required.append_array([&"enemy_alert", &"enemy_attack", &"enemy_hurt", &"enemy_death"])
	required.append_array([&"footstep_soil", &"footstep_concrete", &"footstep_wood", &"footstep_metal"])
	var ids := library.cue_ids()
	for cue_id in required:
		_expect(cue_id in ids, "required cue is authored: %s" % cue_id)
	_expect(ids.size() == required.size(), "library contains the intended 29 bounded cue families")

	var hashes: Dictionary = {}
	var stream_count := 0
	for cue in library.cues:
		_expect(cue.maximum_polyphony <= 6, "%s has bounded polyphony" % cue.id)
		for stream in cue.streams:
			stream_count += 1
			_expect(stream is AudioStreamWAV, "%s uses a low-latency WAV" % cue.id)
			if stream is AudioStreamWAV:
				var wav := stream as AudioStreamWAV
				_expect(not wav.stereo, "%s is mono for consistent first-person/spatial playback" % stream.resource_path)
				_expect(wav.mix_rate == 44100, "%s uses the authored 44.1 kHz rate" % stream.resource_path)
				_expect(wav.get_length() <= 1.0, "%s remains a short Web-safe SFX" % stream.resource_path)
			var digest := FileAccess.get_sha256(stream.resource_path)
			_expect(not hashes.has(digest), "variation is byte-distinct: %s" % stream.resource_path)
			hashes[digest] = stream.resource_path
	_expect(stream_count == 60, "all 60 authored variations are imported")
	var mission_library := load(MISSION_LIBRARY_PATH) as AudioCueLibrary
	_expect(mission_library != null, "mission audio library loads")
	if mission_library != null:
		_expect(mission_library.validation_errors().is_empty(), "mission cue contracts are valid: %s" % [mission_library.validation_errors()])
		var mission_ids := mission_library.cue_ids()
		for cue_id in [&"salmon_music_exploration", &"salmon_music_tension", &"salmon_music_combat", &"salmon_music_boss", &"salmon_music_victory", &"vancouver_music_exploration", &"vancouver_music_tension", &"vancouver_music_combat", &"vancouver_music_boss", &"vancouver_music_victory", &"salmon_ambience_exterior", &"salmon_ambience_tunnel", &"salmon_ambience_lab", &"salmon_ambience_arena", &"vancouver_ambience_dock", &"vancouver_ambience_terminal", &"vancouver_ambience_harbour", &"cobie_bark", &"hound_vocal", &"walker_vocal"]:
			_expect(cue_id in mission_ids, "mission cue is authored: %s" % cue_id)
		for cue in mission_library.cues:
			_expect(cue.maximum_polyphony <= 2, "%s has a strict mission voice bound" % cue.id)
			for stream in cue.streams:
				_expect(stream is AudioStreamWAV, "%s uses imported WAV playback" % cue.id)
				if stream is AudioStreamWAV:
					var mission_wav := stream as AudioStreamWAV
					_expect(not mission_wav.stereo, "%s remains mono" % stream.resource_path)
					_expect(mission_wav.mix_rate == 44100, "%s uses 44.1 kHz" % stream.resource_path)
					_expect(mission_wav.get_length() <= 10.0, "%s stays within the Web mission-bed budget" % stream.resource_path)

	# Exercise the real bridge callbacks rather than only proving files exist.
	var bridge := BRIDGE_SCENE.instantiate() as CombatAudioBridge
	root.add_child(bridge)
	await process_frame
	var weapon_nodes: Array[WeaponBase] = []
	for scene_path in WEAPON_SCENES:
		var weapon := (load(scene_path) as PackedScene).instantiate() as WeaponBase
		root.add_child(weapon)
		weapon_nodes.append(weapon)
		await process_frame
		bridge._on_weapon_fired(weapon, false)
		bridge._on_weapon_dry_fired(weapon)
		bridge._on_weapon_reload_started(weapon, 0.9)
		bridge._on_weapon_reload_step(weapon)
		bridge._on_weapon_reload_finished(weapon)
		bridge._play_weapon_lifecycle(weapon, "_switch", ProceduralAudio.Cue.RELOAD_START, -4.0)
		for suffix in [&"shot", &"mechanical", &"empty", &"reload_start", &"reload_step", &"reload_complete", &"switch"]:
			var cue_id := StringName("%s_%s" % [weapon.definition.id, suffix])
			_expect(bridge.samples.voice_count(cue_id) == 1, "bridge routes %s to imported playback" % cue_id)
	for surface in [&"soil", &"concrete", &"wood", &"metal"]:
		bridge._on_surface_footstep(surface, false)
		_expect(bridge.samples.voice_count(StringName("footstep_%s" % surface)) == 1, "surface footstep routes to %s samples" % surface)
	_expect(bridge.samples.play_at(&"enemy_alert", Vector3(2.0, 1.0, -3.0)), "enemy cue accepts positional playback")
	_expect(bridge.samples.voice_count(&"enemy_alert", true) == 1, "enemy playback uses a bounded 3D voice")
	_expect(bridge.samples.play_at(&"enemy_attack", Vector3(2.0, 1.0, -3.0)), "enemy attacks use authored positional playback")
	_expect(bridge.samples.voice_count(&"enemy_attack", true) == 1, "enemy attack playback uses a bounded 3D voice")
	_expect(bridge.samples.registered_cue_count() == required.size() + 20, "scene installs production and mission cue libraries")
	_expect(bridge.play_cobie_bark(), "bridge routes original nonverbal Cobie barks")
	_expect(bridge.samples.play_at(&"hound_vocal", Vector3.ZERO), "Hound family uses bounded positional playback")
	_expect(bridge.samples.play_at(&"walker_vocal", Vector3.ZERO), "Walker family uses bounded positional playback")
	for weapon in weapon_nodes:
		weapon.queue_free()
	bridge.queue_free()
	for frame in 12:
		await process_frame
	var quality := root.get_node_or_null("QualityManager")
	if quality != null:
		quality.apply_profile(quality.WEB)
		var capped_bridge := BRIDGE_SCENE.instantiate() as CombatAudioBridge
		root.add_child(capped_bridge)
		await process_frame
		for cue in library.cues:
			if cue.spatial:
				capped_bridge.samples.play_at(cue.id, Vector3.ZERO)
			else:
				capped_bridge.samples.play(cue.id)
		_expect(capped_bridge.samples.total_voice_count() <= quality.WEB.audio_voice_budget, "Web profile bounds concurrent imported-audio voices")
		capped_bridge.queue_free()
		quality.apply_profile(quality.NATIVE)
		for frame in 12:
			await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: imported audio contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
