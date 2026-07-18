class_name CitationConvoyActor
extends PhasedModuleActor

var _defeat_started := false


func play_defeat_sequence() -> bool:
	if _defeat_started:
		return false
	_defeat_started = true
	set_active_phase(phase_module_count())
	var tickets := get_node_or_null("TicketDebris") as CPUParticles3D
	if tickets != null:
		tickets.amount = maxi(8, roundi(28.0 * _particle_density()))
		tickets.restart()
		tickets.emitting = true
	var sparks := get_node_or_null("DefeatSparks") as CPUParticles3D
	if sparks != null and not _reduced_flashes():
		sparks.amount = maxi(6, roundi(18.0 * _particle_density()))
		sparks.restart()
		sparks.emitting = true
	if not _reduced_motion():
		var lead := get_node_or_null("LeadVehicle") as Node3D
		var left := get_node_or_null("EscortLeft") as Node3D
		var right := get_node_or_null("EscortRight") as Node3D
		var tween := create_tween().set_parallel(true)
		if lead != null:
			tween.tween_property(lead, "rotation:z", deg_to_rad(7.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(lead, "position:y", -0.16, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if left != null:
			tween.tween_property(left, "rotation:y", deg_to_rad(-11.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if right != null:
			tween.tween_property(right, "rotation:y", deg_to_rad(12.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return true


func defeat_started() -> bool:
	return _defeat_started


func _particle_density() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return 1.0
	return clampf(float(settings.get_value(&"video", &"particle_density", 1.0)), 0.25, 1.0)


func _reduced_flashes() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"video", &"reduced_flashes", false))


func _reduced_motion() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"accessibility", &"reduced_motion", false))
