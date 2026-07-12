class_name CombatAudioBridge
extends Node

@onready var sounds: ProceduralAudio = $ProceduralAudio
@onready var samples: SampleAudioEmitter = get_node_or_null("SampleAudioEmitter") as SampleAudioEmitter

func bind_player(player: Node) -> void:
	var mount := player.get_node_or_null("Head/Camera/WeaponMount")
	if mount != null:
		for weapon in mount.get_children():
			if weapon.has_signal("fired"):
				weapon.fired.connect(_on_weapon_fired)
			if weapon.has_signal("hit_confirmed"):
				weapon.hit_confirmed.connect(func(_target: Node, _damage: float) -> void: sounds.play(ProceduralAudio.Cue.HIT, -4.0))
			if weapon.has_signal("dry_fired"):
				weapon.dry_fired.connect(func(_weapon: Node) -> void: sounds.play(ProceduralAudio.Cue.DRY_FIRE, -2.0))
			if weapon.has_signal("reload_started"):
				weapon.reload_started.connect(func(_weapon: Node, _duration: float) -> void: sounds.play(ProceduralAudio.Cue.RELOAD_START, -3.0))
			if weapon.has_signal("reload_step"):
				weapon.reload_step.connect(func(_weapon: Node) -> void: sounds.play(ProceduralAudio.Cue.RELOAD_STEP, -2.0))
			if weapon.has_signal("reload_finished"):
				weapon.reload_finished.connect(func(_weapon: Node) -> void: sounds.play(ProceduralAudio.Cue.RELOAD_COMPLETE, -2.0))
	var health := player.get_node_or_null("HealthArmor")
	if health != null and health.has_signal("damaged"):
		health.damaged.connect(func(_a: float, _h: float, _r: float, _s: Node) -> void: sounds.play(ProceduralAudio.Cue.HURT))
	if player.has_signal("surface_footstep"):
		player.surface_footstep.connect(_on_surface_footstep)
	elif player.has_signal("footstep"):
		player.footstep.connect(func(running: bool) -> void: sounds.play(ProceduralAudio.Cue.FOOTSTEP_RUN if running else ProceduralAudio.Cue.FOOTSTEP_WALK, -5.0))

func _on_surface_footstep(surface: StringName, running: bool) -> void:
	if samples != null and samples.play(StringName("footstep_" + String(surface))): return
	sounds.play(ProceduralAudio.Cue.FOOTSTEP_RUN if running else ProceduralAudio.Cue.FOOTSTEP_WALK, -5.0)

func _on_weapon_fired(weapon: Node, _secondary: bool) -> void:
	var weapon_name := String(weapon.definition.display_name).to_lower() if weapon.get("definition") != null else ""
	var cue_id: StringName = weapon.definition.id if weapon.get("definition") != null else &""
	if samples != null and samples.play(cue_id): return
	if "barkshot" in weapon_name:
		sounds.play(ProceduralAudio.Cue.BARKSHOT)
	elif "fetch" in weapon_name:
		sounds.play(ProceduralAudio.Cue.FETCH)
	else:
		sounds.play(ProceduralAudio.Cue.PAWSTOL)
