class_name SampleAudioEmitter
extends Node

@export var cues: Array[AudioCueSet] = []
@export var library: AudioCueLibrary
var _by_id: Dictionary = {}
var _voices: Dictionary = {}
var _spatial_voices: Dictionary = {}


func _ready() -> void:
	var registered: Array[AudioCueSet] = []
	registered.append_array(cues)
	if library != null:
		registered.append_array(library.cues)
	for cue in registered:
		if cue != null and cue.id != &"": _by_id[cue.id] = cue


func play(cue_id: StringName) -> bool:
	var cue: AudioCueSet = _by_id.get(cue_id)
	if cue == null or cue.spatial: return false
	var stream := cue.choose_stream()
	if stream == null: return false
	var pool: Array = _voices.get(cue_id, [])
	var voice: AudioStreamPlayer
	for candidate: Variant in pool:
		if is_instance_valid(candidate) and not candidate.playing:
			voice = candidate
			break
	if voice == null:
		if pool.size() >= cue.maximum_polyphony or _active_voice_count() >= _voice_budget(): return false
		voice = AudioStreamPlayer.new()
		voice.bus = cue.bus
		add_child(voice)
		pool.append(voice)
		_voices[cue_id] = pool
	voice.stream = stream
	voice.volume_db = cue.volume_db
	voice.pitch_scale = randf_range(cue.pitch_min, cue.pitch_max)
	voice.play()
	return true


func play_at(cue_id: StringName, world_position: Vector3) -> bool:
	var cue: AudioCueSet = _by_id.get(cue_id)
	if cue == null or not cue.spatial: return false
	var stream := cue.choose_stream()
	if stream == null: return false
	var pool: Array = _spatial_voices.get(cue_id, [])
	var voice: AudioStreamPlayer3D
	for candidate: Variant in pool:
		if is_instance_valid(candidate) and not candidate.playing:
			voice = candidate
			break
	if voice == null:
		if pool.size() >= cue.maximum_polyphony or _active_voice_count() >= _voice_budget(): return false
		voice = AudioStreamPlayer3D.new()
		voice.bus = cue.bus
		voice.max_distance = cue.max_distance
		voice.unit_size = cue.unit_size
		voice.max_polyphony = 1
		add_child(voice)
		pool.append(voice)
		_spatial_voices[cue_id] = pool
	voice.stream = stream
	voice.volume_db = cue.volume_db
	voice.pitch_scale = randf_range(cue.pitch_min, cue.pitch_max)
	voice.global_position = world_position
	voice.play()
	return true


func registered_cue_count() -> int:
	return _by_id.size()


func voice_count(cue_id: StringName, spatial := false) -> int:
	return (_spatial_voices if spatial else _voices).get(cue_id, []).size()


func total_voice_count() -> int:
	var total := 0
	for pools in [_voices, _spatial_voices]:
		for pool: Array in pools.values():
			total += pool.size()
	return total


func _active_voice_count() -> int:
	var total := 0
	for pools in [_voices, _spatial_voices]:
		for pool: Array in pools.values():
			for voice: Variant in pool:
				if is_instance_valid(voice) and voice.playing:
					total += 1
	return total


func _voice_budget() -> int:
	var quality := get_node_or_null("/root/QualityManager")
	if quality != null and quality.current != null:
		return maxi(1, quality.current.audio_voice_budget)
	return 32


func _exit_tree() -> void:
	for pools in [_voices, _spatial_voices]:
		for pool: Array in pools.values():
			for voice: Variant in pool:
				if is_instance_valid(voice):
					voice.stop()
					voice.stream = null
	_voices.clear()
	_spatial_voices.clear()
