extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")
const EPISODE: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	var pawstol := player.weapons[0]
	var fetch := player.weapons[2] as FetchLauncher
	var original_pawstol := pawstol.definition
	var original_reload := original_pawstol.reload_seconds
	var original_raise := original_pawstol.feel.raise_seconds
	var applied := WeaponModApplicator.apply(player, {
		"pawstol": "pawstol_quick_draw",
		"fetch_launcher": "fetch_extra_bounce",
	}, EPISODE.progression_catalog)
	_expect(applied.size() == 2, "two valid mods apply")
	_expect(pawstol.definition != original_pawstol, "weapon definition is duplicated before mutation")
	_expect(is_equal_approx(original_pawstol.reload_seconds, original_reload), "shared Pawstol resource remains unchanged")
	_expect(is_equal_approx(original_pawstol.feel.raise_seconds, original_raise), "shared feel resource remains unchanged")
	_expect(pawstol.definition.reload_seconds < original_reload, "Quick Draw improves reload")
	_expect(pawstol.definition.feel.raise_seconds < original_raise, "Quick Draw improves raise time")
	_expect(fetch.mod_bounce_bonus == 2, "Extra Bounce adds two ricochets")

	var second_player := PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(second_player)
	await process_frame
	var second_fetch := second_player.weapons[2] as FetchLauncher
	WeaponModApplicator.apply(second_player, {"fetch_launcher": "fetch_rapid_return"}, EPISODE.progression_catalog)
	second_fetch.apply_municipal_recall_override()
	_expect(is_equal_approx(second_fetch.recall_speed_multiplier, 1.6875), "Rapid Return composes with Municipal Recall")
	_expect(second_fetch.recall_speed_multiplier <= 1.75, "recall composition remains bounded")

	CosmeticApplicator.apply_weapon_cosmetics(second_player, {"fetch_trail": "fetch_golden_trail"})
	_expect(second_fetch.golden_trail_enabled, "Golden Fetch Trail selection reaches the launcher")
	var projectile := preload("res://scenes/weapons/fetch_projectile.tscn").instantiate() as FetchProjectile
	root.add_child(projectile)
	projectile.set_golden_trail(second_fetch.golden_trail_enabled)
	_expect((projectile.get_node("GoldenTrail") as GPUParticles3D).emitting, "Golden Fetch Trail emits bounded projectile particles")
	projectile.queue_free()
	player.queue_free(); second_player.queue_free()
	await process_frame
	if failures.is_empty():
		print("WEAPON MOD APPLICATOR TEST: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
