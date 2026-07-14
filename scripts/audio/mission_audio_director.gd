class_name MissionAudioDirector
extends Node

signal state_changed(state: StringName, cue_id: StringName)
signal zone_ambience_changed(cue_id: StringName)

const STATES := [&"exploration", &"tension", &"combat", &"boss", &"victory"]
const SILENCE_DB := -60.0

var _profile: MissionAudioProfile
var _library: AudioCueLibrary
var _cues: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _ambience_player: AudioStreamPlayer
var _active_music_index := 0
var _state: StringName = &""
var _music_cue_id: StringName = &""
var _ambience_cue_id: StringName = &""
var _crossfade: Tween
var playback_enabled := true


func configure(profile: MissionAudioProfile, library: AudioCueLibrary) -> bool:
	reset()
	_profile = profile
	_library = library
	if _profile == null or _library == null:
		return false
	if not _profile.validate().is_empty() or not _library.validation_errors().is_empty():
		return false
	_cues.clear()
	for cue in _library.cues:
		if cue != null:
			_cues[cue.id] = cue
	for required_id in _required_cue_ids():
		var cue := _cues.get(required_id) as AudioCueSet
		if cue == null or cue.spatial:
			_cues.clear()
			return false
	_ensure_players()
	return true


func request_state(state: StringName) -> bool:
	if state not in STATES or _profile == null:
		return false
	var cue_id := _cue_for_state(state)
	if cue_id == &"" or not _play_music_cue(cue_id):
		return false
	_state = state
	state_changed.emit(state, cue_id)
	return true


func set_zone_ambience(cue_id: StringName) -> bool:
	if cue_id == _ambience_cue_id:
		return true
	var cue := _cues.get(cue_id) as AudioCueSet
	if cue == null or cue.spatial:
		return false
	_ensure_players()
	if not playback_enabled:
		_ambience_cue_id = cue_id
		zone_ambience_changed.emit(cue_id)
		return true
	_ambience_player.stream = cue.choose_stream()
	if _ambience_player.stream == null:
		return false
	_ambience_player.bus = cue.bus
	_ambience_player.volume_db = cue.volume_db
	_ambience_player.pitch_scale = 1.0
	_ambience_player.play()
	_ambience_cue_id = cue_id
	zone_ambience_changed.emit(cue_id)
	return true


func reset() -> void:
	if _crossfade != null and _crossfade.is_valid():
		_crossfade.kill()
	_crossfade = null
	for player in _music_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	if is_instance_valid(_ambience_player):
		_ambience_player.stop()
		_ambience_player.stream = null
	_state = &""
	_music_cue_id = &""
	_ambience_cue_id = &""


func _exit_tree() -> void:
	# AudioServer can retain a playback object for a frame after an owning scene is
	# removed. Release voices synchronously so rapid restart/quit and headless soak
	# runs do not leave WAV playback resources behind.
	reset()
	# Do not free child players from their parent's exit callback. Godot tears down
	# children immediately after this callback; manually freeing them here can race
	# the audio mixer's playback release and intermittently retain a WAV resource.
	_music_players.clear()
	_ambience_player = null
	_cues.clear()
	_profile = null
	_library = null


func current_state() -> StringName: return _state
func current_music_cue() -> StringName: return _music_cue_id
func current_ambience_cue() -> StringName: return _ambience_cue_id


func owned_voice_count() -> int:
	return _music_players.size() + (1 if is_instance_valid(_ambience_player) else 0)


func active_voice_count() -> int:
	var count := 0
	for player in _music_players:
		if is_instance_valid(player) and player.playing:
			count += 1
	if is_instance_valid(_ambience_player) and _ambience_player.playing:
		count += 1
	return count


func _ensure_players() -> void:
	while _music_players.size() < 2:
		var player := AudioStreamPlayer.new()
		player.name = "MissionMusic%d" % _music_players.size()
		player.bus = &"Music"
		add_child(player)
		_music_players.append(player)
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.name = "MissionAmbience"
		_ambience_player.bus = &"Ambience"
		add_child(_ambience_player)


func _play_music_cue(cue_id: StringName) -> bool:
	if cue_id == _music_cue_id:
		return true
	var cue := _cues.get(cue_id) as AudioCueSet
	if cue == null or cue.spatial:
		return false
	if not playback_enabled:
		_music_cue_id = cue_id
		return true
	var stream := cue.choose_stream()
	if stream == null:
		return false
	_ensure_players()
	var next_index := 1 - _active_music_index
	var incoming := _music_players[next_index]
	var outgoing := _music_players[_active_music_index]
	incoming.stream = stream
	incoming.bus = cue.bus
	incoming.volume_db = SILENCE_DB if outgoing.playing else cue.volume_db
	incoming.pitch_scale = 1.0
	incoming.play()
	if _crossfade != null and _crossfade.is_valid():
		_crossfade.kill()
	if outgoing.playing and _profile.crossfade_seconds > 0.0:
		_crossfade = create_tween().set_parallel(true)
		_crossfade.tween_property(outgoing, "volume_db", SILENCE_DB, _profile.crossfade_seconds)
		_crossfade.tween_property(incoming, "volume_db", cue.volume_db, _profile.crossfade_seconds)
		_crossfade.chain().tween_callback(func() -> void:
			outgoing.stop()
			outgoing.stream = null
		)
	else:
		outgoing.stop()
		outgoing.stream = null
		incoming.volume_db = cue.volume_db
	_active_music_index = next_index
	_music_cue_id = cue_id
	return true


func _cue_for_state(state: StringName) -> StringName:
	match state:
		&"exploration": return _profile.exploration_ambience_cue_id
		&"tension": return _profile.tension_ambience_cue_id
		&"combat": return _profile.combat_ambience_cue_id
		&"boss": return _profile.boss_ambience_cue_id
		&"victory": return _profile.victory_ambience_cue_id
	return &""


func _required_cue_ids() -> Array[StringName]:
	return [_profile.exploration_ambience_cue_id, _profile.tension_ambience_cue_id, _profile.combat_ambience_cue_id, _profile.boss_ambience_cue_id, _profile.victory_ambience_cue_id]
