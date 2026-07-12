class_name GameHUD
extends CanvasLayer

@onready var health_label: Label = %HealthLabel
@onready var armor_label: Label = %ArmorLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var notification_label: Label = %NotificationLabel
@onready var portrait: CobiePortrait = %CobiePortrait
@onready var crosshair: RetroCrosshair = %Crosshair
@onready var sounds: ProceduralAudio = %ProceduralAudio

var _notification_tween: Tween

func bind_player(player: Node) -> void:
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon_changed)
	if player.has_signal("weapon_ammo_state_changed"):
		player.weapon_ammo_state_changed.connect(_on_weapon_ammo_state_changed)
	if player is CobiePlayer and not player.weapons.is_empty():
		var current: WeaponBase = player.weapons[player.current_weapon_index]
		_on_weapon_ammo_state_changed(current.definition.display_name, current.ammo, current.definition.magazine_size, current.reserve_ammo, current.definition.infinite_reserve)
	if player.has_signal("interaction_available"):
		player.interaction_available.connect(_on_interaction_available)
	if player.has_signal("pickup_message"):
		player.pickup_message.connect(show_notification)
	if player.has_signal("shot_resolved"):
		player.shot_resolved.connect(func(kind: StringName, _position: Vector3) -> void: crosshair.show_shot_result(kind))
	if player.has_signal("access_item_changed"):
		player.access_item_changed.connect(set_access_item)
	set_access_item("ACCESS COLLAR" if player.is_in_group(&"has_access_collar") else "NO ACCESS COLLAR")
	var health_component := player.get_node_or_null("HealthArmor")
	if health_component != null:
		health_component.health_changed.connect(_on_health_changed)
		health_component.armor_changed.connect(_on_armor_changed)
		health_component.damaged.connect(func(_a: float, _h: float, _r: float, _s: Node) -> void: sounds.play(ProceduralAudio.Cue.HURT))
		_on_health_changed(health_component.health, health_component.max_health)
		_on_armor_changed(health_component.armor, health_component.max_armor)
	var aim := player.get_node_or_null("AutoAim")
	if aim != null and aim.has_signal("target_changed"):
		aim.target_changed.connect(func(target: Node3D) -> void: crosshair.target_locked = target != null)

func show_notification(message: String, cue := ProceduralAudio.Cue.PICKUP) -> void:
	notification_label.text = message
	notification_label.modulate.a = 1.0
	sounds.play(cue)
	if _notification_tween != null:
		_notification_tween.kill()
	_notification_tween = create_tween()
	_notification_tween.tween_interval(1.5)
	_notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.45)

func show_secret(message := "SECRET FOUND. GOOD SNIFFING.") -> void:
	show_notification(message, ProceduralAudio.Cue.SECRET)

func show_objective(message: String) -> void:
	%ObjectiveLabel.text = "OBJECTIVE // " + message.to_upper()
	%ObjectiveLabel.visible = not message.is_empty()

func set_access_item(label: String) -> void:
	%AccessLabel.text = label

func _on_health_changed(current: float, maximum: float) -> void:
	health_label.text = "%03d" % int(ceil(current))
	portrait.health_ratio = current / maxf(maximum, 1.0)

func _on_armor_changed(current: float, _maximum: float) -> void:
	armor_label.text = "%03d" % int(ceil(current))

func _on_weapon_changed(display_name: String, ammo: int, maximum_ammo: int) -> void:
	weapon_label.text = display_name.to_upper()
	ammo_label.text = "∞" if maximum_ammo <= 0 else "%02d" % ammo

func _on_weapon_ammo_state_changed(display_name: String, loaded: int, _capacity: int, reserve: int, infinite_reserve: bool) -> void:
	weapon_label.text = display_name.to_upper()
	ammo_label.text = "%02d / %s" % [loaded, "∞" if infinite_reserve else "%02d" % reserve]

func _on_interaction_available(label: String) -> void:
	interaction_label.visible = not label.is_empty()
	interaction_label.text = "[E] %s" % label.to_upper()
