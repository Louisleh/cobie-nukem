class_name SampleAudioEmitter
extends Node

@export var cues: Array[AudioCueSet] = []
var _by_id: Dictionary = {}
var _voices: Dictionary = {}


func _ready() -> void:
	for cue in cues:
		if cue != null and cue.id != &"": _by_id[cue.id] = cue


func play(cue_id: StringName) -> bool:
	var cue: AudioCueSet = _by_id.get(cue_id)
	if cue == null: return false
	var stream := cue.choose_stream()
	if stream == null: return false
	var pool: Array = _voices.get(cue_id, [])
	var voice: AudioStreamPlayer
	for candidate: Variant in pool:
		if is_instance_valid(candidate) and not candidate.playing:
			voice = candidate
			break
	if voice == null:
		if pool.size() >= cue.maximum_polyphony: return false
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
