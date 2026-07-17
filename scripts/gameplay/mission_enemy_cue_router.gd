class_name MissionEnemyCueRouter
extends Node

var _hud: GameHUD
var _samples: SampleAudioEmitter
var _bound: Dictionary = {}


func configure(hud: GameHUD, library: AudioCueLibrary) -> void:
	_hud = hud
	if _samples == null:
		_samples = SampleAudioEmitter.new()
		_samples.name = "MissionEnemySamples"
		_samples.library = library
		add_child(_samples)


func bind_enemy(enemy: Node) -> void:
	if enemy == null or not enemy.has_signal("telegraph_started"):
		return
	if enemy.has_meta(&"mission_presentation_warning_bound"):
		return
	enemy.set_meta(&"mission_presentation_warning_bound", true)
	var enemy_ref: WeakRef = weakref(enemy)
	_bound[enemy.get_instance_id()] = enemy_ref
	enemy.telegraph_started.connect(_on_enemy_telegraph.bind(enemy_ref))
	if enemy is ComplianceGull:
		var gull := enemy as ComplianceGull
		gull.target_marked.connect(_on_gull_target_marked.bind(enemy_ref))
		gull.attack_fired.connect(_on_gull_attack_fired.bind(enemy_ref))
		gull.dive_interrupted.connect(_on_gull_dive_interrupted.bind(enemy_ref))
		gull.died.connect(_on_gull_died.bind(enemy_ref))
	elif enemy is UmbrellaShieldEnforcer:
		var enforcer := enemy as UmbrellaShieldEnforcer
		enforcer.guard_state_changed.connect(_on_umbrella_guard_state_changed.bind(enemy_ref))


func play_at(cue_id: StringName, world_position: Vector3) -> bool:
	return _samples != null and _samples.play_at(cue_id, world_position)


func stop_all() -> void:
	if _samples != null:
		_samples.stop_all()


func bound_enemy_count() -> int:
	_prune()
	return _bound.size()


func is_enemy_bound(enemy: Node) -> bool:
	return enemy != null and enemy.has_meta(&"mission_presentation_warning_bound")


func _on_enemy_telegraph(kind: StringName, _duration: float, _enemy_ref: WeakRef) -> void:
	if _hud != null:
		_hud.show_caption("%s WARNING" % String(kind).replace("_", " "), GameHUD.CaptionCategory.ENEMY_WARNING, 1.2)


func _on_gull_target_marked(_target: Node3D, _duration: float, enemy_ref: WeakRef) -> void:
	_play_enemy_cue(&"rain_city_gull_mark", enemy_ref)


func _on_gull_attack_fired(kind: StringName, enemy_ref: WeakRef) -> void:
	if kind == &"gull_mark_dive":
		_play_enemy_cue(&"rain_city_gull_dive", enemy_ref)


func _on_gull_dive_interrupted(enemy_ref: WeakRef) -> void:
	_play_enemy_cue(&"rain_city_gull_dive", enemy_ref)


func _on_gull_died(_enemy: EnemyAgent, _source: Node, enemy_ref: WeakRef) -> void:
	_play_enemy_cue(&"rain_city_gull_death", enemy_ref)


func _on_umbrella_guard_state_changed(_previous: UmbrellaShieldEnforcer.GuardState, current: UmbrellaShieldEnforcer.GuardState, enemy_ref: WeakRef) -> void:
	match current:
		UmbrellaShieldEnforcer.GuardState.GUARDING:
			_play_enemy_cue(&"rain_city_shield_brace", enemy_ref)
		UmbrellaShieldEnforcer.GuardState.OPENING:
			_play_enemy_cue(&"rain_city_shield_open", enemy_ref)
		UmbrellaShieldEnforcer.GuardState.BROKEN:
			_play_enemy_cue(&"rain_city_shield_break", enemy_ref)


func _play_enemy_cue(cue_id: StringName, enemy_ref: WeakRef) -> bool:
	if enemy_ref == null:
		return false
	var enemy := enemy_ref.get_ref() as Node3D
	return enemy != null and is_instance_valid(enemy) and play_at(cue_id, enemy.global_position)


func _prune() -> void:
	for instance_id: Variant in _bound.keys():
		var reference := _bound[instance_id] as WeakRef
		if reference == null or reference.get_ref() == null:
			_bound.erase(instance_id)


func _exit_tree() -> void:
	stop_all()
	_bound.clear()
