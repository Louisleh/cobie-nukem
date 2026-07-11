class_name CombatAudioBridge
extends Node

@onready var sounds: ProceduralAudio = $ProceduralAudio

func bind_player(player: Node) -> void:
	var mount := player.get_node_or_null("Head/Camera/WeaponMount")
	if mount != null:
		for weapon in mount.get_children():
			if weapon.has_signal("fired"):
				weapon.fired.connect(_on_weapon_fired)
			if weapon.has_signal("hit_confirmed"):
				weapon.hit_confirmed.connect(func(_target: Node, _damage: float) -> void: sounds.play(ProceduralAudio.Cue.HIT, -4.0))
	var health := player.get_node_or_null("HealthArmor")
	if health != null and health.has_signal("damaged"):
		health.damaged.connect(func(_a: float, _h: float, _r: float, _s: Node) -> void: sounds.play(ProceduralAudio.Cue.HURT))

func _on_weapon_fired(weapon: Node, _secondary: bool) -> void:
	var weapon_name := String(weapon.definition.display_name).to_lower() if weapon.get("definition") != null else ""
	if "barkshot" in weapon_name:
		sounds.play(ProceduralAudio.Cue.BARKSHOT)
	elif "fetch" in weapon_name:
		sounds.play(ProceduralAudio.Cue.FETCH)
	else:
		sounds.play(ProceduralAudio.Cue.PAWSTOL)

