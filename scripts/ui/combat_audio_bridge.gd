class_name CombatAudioBridge
extends Node

@onready var sounds: ProceduralAudio = $ProceduralAudio
@onready var samples: SampleAudioEmitter = get_node_or_null("SampleAudioEmitter") as SampleAudioEmitter
var _player: Node
var _last_weapon_index := -1


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_enemies")

func bind_player(player: Node) -> void:
	_player = player
	_last_weapon_index = int(player.get("current_weapon_index")) if player.get("current_weapon_index") != null else -1
	var mount := player.get_node_or_null("Head/Camera/WeaponMount")
	if mount != null:
		for weapon in mount.get_children():
			if weapon.has_signal("fired"):
				weapon.fired.connect(_on_weapon_fired)
			if weapon.has_signal("hit_confirmed"):
				weapon.hit_confirmed.connect(func(_target: Node, _damage: float) -> void: sounds.play(ProceduralAudio.Cue.HIT, -4.0))
			if weapon.has_signal("dry_fired"):
				weapon.dry_fired.connect(_on_weapon_dry_fired)
			if weapon.has_signal("reload_started"):
				weapon.reload_started.connect(_on_weapon_reload_started)
			if weapon.has_signal("reload_step"):
				weapon.reload_step.connect(_on_weapon_reload_step)
			if weapon.has_signal("reload_finished"):
				weapon.reload_finished.connect(_on_weapon_reload_finished)
	var health := player.get_node_or_null("HealthArmor")
	if health != null and health.has_signal("damaged"):
		health.damaged.connect(func(_a: float, _h: float, _r: float, _s: Node) -> void: sounds.play(ProceduralAudio.Cue.HURT))
	if player.has_signal("surface_footstep"):
		player.surface_footstep.connect(_on_surface_footstep)
	elif player.has_signal("footstep"):
		player.footstep.connect(func(running: bool) -> void: sounds.play(ProceduralAudio.Cue.FOOTSTEP_RUN if running else ProceduralAudio.Cue.FOOTSTEP_WALK, -5.0))
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_player_weapon_changed)

func _on_surface_footstep(surface: StringName, running: bool) -> void:
	if samples != null and samples.play(StringName("footstep_" + String(surface))): return
	sounds.play(ProceduralAudio.Cue.FOOTSTEP_RUN if running else ProceduralAudio.Cue.FOOTSTEP_WALK, -5.0)

func _on_weapon_fired(weapon: Node, _secondary: bool) -> void:
	var weapon_name := String(weapon.definition.display_name).to_lower() if weapon.get("definition") != null else ""
	var cue_id: StringName = weapon.definition.id if weapon.get("definition") != null else &""
	if samples != null and samples.play(StringName(String(cue_id) + "_shot")):
		samples.play(StringName(String(cue_id) + "_mechanical"))
		return
	if "barkshot" in weapon_name:
		sounds.play(ProceduralAudio.Cue.BARKSHOT)
	elif "fetch" in weapon_name:
		sounds.play(ProceduralAudio.Cue.FETCH)
	else:
		sounds.play(ProceduralAudio.Cue.PAWSTOL)


func _weapon_id(weapon: Node) -> StringName:
	return weapon.definition.id if weapon != null and weapon.get("definition") != null else &""


func _play_weapon_lifecycle(weapon: Node, suffix: String, fallback: ProceduralAudio.Cue, volume_db: float) -> void:
	var cue := StringName(String(_weapon_id(weapon)) + suffix)
	if samples != null and samples.play(cue): return
	sounds.play(fallback, volume_db)


func _on_weapon_dry_fired(weapon: Node) -> void:
	_play_weapon_lifecycle(weapon, "_empty", ProceduralAudio.Cue.DRY_FIRE, -2.0)


func _on_weapon_reload_started(weapon: Node, _duration: float) -> void:
	_play_weapon_lifecycle(weapon, "_reload_start", ProceduralAudio.Cue.RELOAD_START, -3.0)


func _on_weapon_reload_step(weapon: Node) -> void:
	_play_weapon_lifecycle(weapon, "_reload_step", ProceduralAudio.Cue.RELOAD_STEP, -2.0)


func _on_weapon_reload_finished(weapon: Node) -> void:
	_play_weapon_lifecycle(weapon, "_reload_complete", ProceduralAudio.Cue.RELOAD_COMPLETE, -2.0)


func _on_player_weapon_changed(_display_name: String, _ammo: int, _maximum_ammo: int) -> void:
	if _player == null or _player.get("current_weapon_index") == null: return
	var index := int(_player.get("current_weapon_index"))
	if index == _last_weapon_index: return
	_last_weapon_index = index
	var weapons: Array = _player.get("weapons")
	if index >= 0 and index < weapons.size():
		_play_weapon_lifecycle(weapons[index], "_switch", ProceduralAudio.Cue.RELOAD_START, -4.0)


func _bind_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		_bind_enemy(enemy)


func _on_node_added(node: Node) -> void:
	if node is EnemyAgent:
		_bind_enemy.call_deferred(node)


func _bind_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or enemy.has_meta(&"sample_audio_bound"): return
	enemy.set_meta(&"sample_audio_bound", true)
	if enemy.has_signal("state_changed"):
		enemy.state_changed.connect(_on_enemy_state_changed.bind(enemy))
	if enemy.has_signal("attack_fired"):
		enemy.attack_fired.connect(_on_enemy_attack_fired.bind(enemy))
	if enemy.has_signal("damaged"):
		enemy.damaged.connect(_on_enemy_damaged.bind(enemy))
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	# EncounterRunner may assign a target before node_added's deferred bind runs.
	# Replay the already-entered alert once so the authored first-contact cue is
	# not silently lost, while the binding metadata prevents duplicates.
	if enemy is EnemyAgent and enemy.state == EnemyAgent.State.ALERT:
		_on_enemy_state_changed(EnemyAgent.State.IDLE, EnemyAgent.State.ALERT, enemy)


func _on_enemy_state_changed(_previous: EnemyAgent.State, current: EnemyAgent.State, enemy: EnemyAgent) -> void:
	if current != EnemyAgent.State.ALERT or samples == null or enemy.definition == null: return
	samples.play_at(enemy.definition.alert_sound, enemy.global_position)


func _on_enemy_attack_fired(_kind: StringName, enemy: EnemyAgent) -> void:
	if samples == null or enemy.definition == null: return
	samples.play_at(enemy.definition.attack_sound_set, enemy.global_position)


func _on_enemy_damaged(_amount: float, _source: Node, hit_position: Vector3, enemy: EnemyAgent) -> void:
	# Lethal damage emits `damaged` immediately before `died`; reserve that beat
	# for the death family instead of stacking hurt and death transients.
	if samples == null or enemy.health <= 0.0: return
	var position := hit_position if hit_position != Vector3.ZERO else enemy.global_position
	samples.play_at(&"enemy_hurt", position)


func _on_enemy_died(enemy: EnemyAgent, _source: Node) -> void:
	if samples == null or enemy.definition == null: return
	samples.play_at(enemy.definition.death_sound_set, enemy.global_position)
