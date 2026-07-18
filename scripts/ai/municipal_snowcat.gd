class_name MunicipalSnowcat
extends AnimalControlWalker

signal weather_core_exposed


func _ready() -> void:
	super._ready()
	boss_phase_changed.connect(_on_snowcat_phase_changed)


func _on_snowcat_phase_changed(_previous: BossPhase, current: BossPhase) -> void:
	if current == BossPhase.FINAL_VULNERABILITY:
		weather_core_exposed.emit()
