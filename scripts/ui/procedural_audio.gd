class_name ProceduralAudio
extends Node

enum Cue { MOVE, ACCEPT, BACK, ERROR, PICKUP, SECRET, PAWSTOL, BARKSHOT, FETCH, HIT, HURT, VICTORY }

@export var bus := &"SFX"
var _player: AudioStreamPlayer
var _cache: Dictionary = {}

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus
	add_child(_player)

func play(cue: Cue, volume_db := 0.0) -> void:
	if _player == null:
		return
	if not _cache.has(cue):
		_cache[cue] = _build_cue(cue)
	_player.stream = _cache[cue]
	_player.volume_db = volume_db
	_player.play()

func create_menu_music() -> AudioStreamWAV:
	var notes := [110.0, 110.0, 146.83, 164.81, 110.0, 196.0, 174.61, 146.83]
	var duration := 8.0
	return _synthesize(duration, func(time: float) -> float:
		var step := mini(int(time / 0.25), notes.size() * 4 - 1)
		var frequency: float = notes[step % notes.size()] * (2.0 if step % 8 == 7 else 1.0)
		var pulse := 0.16 if fmod(time * frequency, 1.0) < 0.5 else -0.16
		var bass_frequency: float = notes[(step / 4) as int % notes.size()] * 0.5
		var bass := sin(TAU * bass_frequency * time) * 0.09
		var beat := exp(-fmod(time, 0.5) * 18.0) * sin(TAU * 54.0 * time) * 0.16
		return pulse + bass + beat
	, true)

func _build_cue(cue: Cue) -> AudioStreamWAV:
	match cue:
		Cue.MOVE:
			return _tone(0.045, 660.0, 880.0, 0.16, "square")
		Cue.ACCEPT:
			return _tone(0.11, 440.0, 920.0, 0.24, "square")
		Cue.BACK:
			return _tone(0.09, 520.0, 220.0, 0.2, "triangle")
		Cue.ERROR:
			return _tone(0.14, 130.0, 85.0, 0.28, "square")
		Cue.PICKUP:
			return _tone(0.18, 520.0, 1300.0, 0.3, "triangle")
		Cue.SECRET:
			return _arpeggio([392.0, 523.25, 659.25, 783.99], 0.1, 0.27)
		Cue.PAWSTOL:
			return _noise_burst(0.09, 0.48, 170.0)
		Cue.BARKSHOT:
			return _noise_burst(0.25, 0.68, 72.0)
		Cue.FETCH:
			return _tone(0.19, 150.0, 610.0, 0.38, "saw")
		Cue.HIT:
			return _tone(0.055, 1200.0, 440.0, 0.25, "square")
		Cue.HURT:
			return _noise_burst(0.16, 0.42, 95.0)
		Cue.VICTORY:
			return _arpeggio([261.63, 329.63, 392.0, 523.25, 659.25], 0.16, 0.34)
	return _tone(0.05, 440.0, 440.0, 0.1, "square")

func _tone(duration: float, start_hz: float, end_hz: float, amplitude: float, shape: String) -> AudioStreamWAV:
	return _synthesize(duration, func(time: float) -> float:
		var progress := time / duration
		var frequency := lerpf(start_hz, end_hz, progress)
		var phase := fmod(time * frequency, 1.0)
		var sample := sin(TAU * phase)
		if shape == "square":
			sample = 1.0 if phase < 0.5 else -1.0
		elif shape == "triangle":
			sample = 1.0 - 4.0 * absf(phase - 0.5)
		elif shape == "saw":
			sample = phase * 2.0 - 1.0
		return sample * amplitude * (1.0 - progress)
	)

func _noise_burst(duration: float, amplitude: float, body_hz: float) -> AudioStreamWAV:
	var seed := 0xC0B1E
	return _synthesize(duration, func(time: float) -> float:
		seed = (seed * 1103515245 + 12345) & 0x7fffffff
		var noise := (float(seed % 2000) / 1000.0) - 1.0
		var envelope := pow(1.0 - time / duration, 2.2)
		return (noise * 0.75 + sin(TAU * body_hz * time) * 0.25) * amplitude * envelope
	)

func _arpeggio(notes: Array, step_duration: float, amplitude: float) -> AudioStreamWAV:
	var duration := notes.size() * step_duration
	return _synthesize(duration, func(time: float) -> float:
		var note_index := mini(int(time / step_duration), notes.size() - 1)
		var local_time := fmod(time, step_duration)
		return sin(TAU * float(notes[note_index]) * time) * amplitude * (1.0 - local_time / step_duration)
	)

func _synthesize(duration: float, sample_function: Callable, loop := false) -> AudioStreamWAV:
	const MIX_RATE := 22050
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(int(duration * MIX_RATE) * 2)
	for index in int(duration * MIX_RATE):
		var sample := clampf(float(sample_function.call(float(index) / MIX_RATE)), -1.0, 1.0)
		var value := int(sample * 32767.0)
		if value < 0:
			value += 65536
		bytes[index * 2] = value & 0xff
		bytes[index * 2 + 1] = (value >> 8) & 0xff
	stream.data = bytes
	return stream

