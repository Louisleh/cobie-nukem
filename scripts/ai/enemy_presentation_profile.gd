class_name EnemyPresentationProfile
extends Resource

## Data contract for profile-backed enemy atlases.
##
## Atlas contract:
## - 8 columns (directional octants) x 4 rows
## - row 0: idle / non-locomotion directional frames
## - row 1: locomotion-A (alternate movement frame)
## - row 2: locomotion-B (alternate movement frame)
## - row 3: reaction frames for alert/telegraph/attack/hurt/stagger/milestone/death

const HORIZONTAL_FRAMES := 8
const VERTICAL_FRAMES := 4
const DIRECTION_COUNT := HORIZONTAL_FRAMES

const ROW_IDLE := 0
const ROW_LOCOMOTION_A := 1
const ROW_LOCOMOTION_B := 2
const ROW_REACTIONS := 3

@export var id: StringName = &"enemy_presentation_profile"
@export var atlas_texture: Texture2D
@export_range(1.0, 40.0, 0.25) var animation_fps := 8.0
@export_range(1.0, 24.0, 0.25) var far_animation_fps := 4.0
@export_range(4.0, 128.0, 0.5) var far_distance := 28.0
@export_range(0.01, 3.0, 0.01) var telegraph_hold_seconds := 0.24
@export_range(0.01, 3.0, 0.01) var attack_hold_seconds := 0.16
@export_range(0.01, 3.0, 0.01) var milestone_hold_seconds := 0.22
@export_range(0.01, 1.0, 0.01) var alert_hold_seconds := 0.12
@export_range(0, 7, 1) var alert_frame_column := 0
@export_range(0, 7, 1) var telegraph_frame_column := 1
@export_range(0, 7, 1) var attack_frame_column := 2
@export_range(0, 7, 1) var hurt_frame_column := 3
@export_range(0, 7, 1) var stagger_frame_column := 4
@export_range(0, 7, 1) var milestone_frame_column := 5
@export_range(0, 7, 1) var death_frame_column := 6
@export var idle_direction_frames: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
@export var locomotion_a_frames: Array[int] = [8, 9, 10, 11, 12, 13, 14, 15]
@export var locomotion_b_frames: Array[int] = [16, 17, 18, 19, 20, 21, 22, 23]
@export var death_style: StringName = &"grounded_collapse"
@export var phase_accent_colors: Array[Color] = []
@export_range(0, 32, 1) var fragment_count_web := 12
@export_range(0, 48, 1) var fragment_count_native := 20


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("enemy_presentation_profile has empty id")

	if atlas_texture == null:
		errors.append("enemy_presentation_profile %s missing atlas_texture" % id)
		return errors

	var width := atlas_texture.get_width()
	var height := atlas_texture.get_height()
	if width <= 0 or height <= 0:
		errors.append("enemy_presentation_profile %s has invalid atlas_texture dimensions" % id)
	else:
		if width % HORIZONTAL_FRAMES != 0:
			errors.append("enemy_presentation_profile %s atlas_texture width must be divisible by %d" % [id, HORIZONTAL_FRAMES])
		if height % VERTICAL_FRAMES != 0:
			errors.append("enemy_presentation_profile %s atlas_texture height must be divisible by %d" % [id, VERTICAL_FRAMES])

	var frame_width := width / HORIZONTAL_FRAMES
	var frame_height := height / VERTICAL_FRAMES
	if frame_width < 1 or frame_height < 1:
		errors.append("enemy_presentation_profile %s has invalid atlas fragment budget" % id)
	if frame_width * HORIZONTAL_FRAMES != width or frame_height * VERTICAL_FRAMES != height:
		errors.append("enemy_presentation_profile %s atlas texture does not map evenly into 8x4 fragments" % id)
	if not is_finite(animation_fps) or animation_fps <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid animation_fps" % id)
	if not is_finite(far_animation_fps) or far_animation_fps <= 0.0 or far_animation_fps > animation_fps:
		errors.append("enemy_presentation_profile %s has invalid far_animation_fps" % id)
	if not is_finite(far_distance) or far_distance <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid far_distance" % id)
	if not is_finite(telegraph_hold_seconds) or telegraph_hold_seconds <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid telegraph_hold_seconds" % id)
	if not is_finite(attack_hold_seconds) or attack_hold_seconds <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid attack_hold_seconds" % id)
	if not is_finite(milestone_hold_seconds) or milestone_hold_seconds <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid milestone_hold_seconds" % id)
	if not is_finite(alert_hold_seconds) or alert_hold_seconds <= 0.0:
		errors.append("enemy_presentation_profile %s has invalid alert_hold_seconds" % id)

	var reaction_columns := [alert_frame_column, telegraph_frame_column, attack_frame_column, hurt_frame_column, stagger_frame_column, milestone_frame_column, death_frame_column]
	var seen: Dictionary = {}
	for column in reaction_columns:
		if column < 0 or column >= HORIZONTAL_FRAMES:
			errors.append("enemy_presentation_profile %s reaction column %d out of bounds [0, %d]" % [id, column, HORIZONTAL_FRAMES - 1])
			continue
		var key := str(column)
		if seen.has(key):
			errors.append("enemy_presentation_profile %s has duplicate reaction columns at %d" % [id, column])
		else:
			seen[key] = true

	if reaction_columns.size() != 7:
		errors.append("enemy_presentation_profile %s must define seven reaction frames" % id)
	_validate_direction_frames(idle_direction_frames, "idle_direction_frames", errors)
	_validate_direction_frames(locomotion_a_frames, "locomotion_a_frames", errors)
	_validate_direction_frames(locomotion_b_frames, "locomotion_b_frames", errors)
	if death_style == &"":
		errors.append("enemy_presentation_profile %s has empty death_style" % id)
	if fragment_count_web < 0 or fragment_count_web > 32 or fragment_count_native < 0 or fragment_count_native > 48:
		errors.append("enemy_presentation_profile %s has invalid fragment budget" % id)
	elif fragment_count_native < fragment_count_web:
		errors.append("enemy_presentation_profile %s native fragment budget is below Web budget" % id)
	return errors


func _validate_direction_frames(frames: Array[int], label: String, errors: PackedStringArray) -> void:
	if frames.size() != DIRECTION_COUNT:
		errors.append("enemy_presentation_profile %s %s must contain eight frames" % [id, label])
		return
	var seen: Dictionary = {}
	for frame in frames:
		if frame < 0 or frame >= frame_budget():
			errors.append("enemy_presentation_profile %s %s frame %d is out of bounds" % [id, label, frame])
		elif seen.has(frame):
			errors.append("enemy_presentation_profile %s %s repeats frame %d" % [id, label, frame])
		seen[frame] = true


func frame_for_row_and_column(row: int, direction: int) -> int:
	if row < 0 or row >= VERTICAL_FRAMES:
		return -1
	if direction < 0 or direction >= HORIZONTAL_FRAMES:
		return -1
	return (row * HORIZONTAL_FRAMES) + direction


func direction_row_idle() -> int:
	return ROW_IDLE


func direction_row_a() -> int:
	return ROW_LOCOMOTION_A


func direction_row_b() -> int:
	return ROW_LOCOMOTION_B


func direction_frame(direction: int, chase_row := ROW_LOCOMOTION_A) -> int:
	if direction < 0 or direction >= DIRECTION_COUNT:
		return -1
	match chase_row:
		ROW_IDLE: return idle_direction_frames[direction]
		ROW_LOCOMOTION_A: return locomotion_a_frames[direction]
		ROW_LOCOMOTION_B: return locomotion_b_frames[direction]
	return -1


func reaction_alert_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, alert_frame_column)


func reaction_telegraph_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, telegraph_frame_column)


func reaction_attack_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, attack_frame_column)


func reaction_hurt_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, hurt_frame_column)


func reaction_stagger_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, stagger_frame_column)


func reaction_milestone_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, milestone_frame_column)


func reaction_death_frame() -> int:
	return frame_for_row_and_column(ROW_REACTIONS, death_frame_column)


func frame_budget() -> int:
	return HORIZONTAL_FRAMES * VERTICAL_FRAMES


func direction_count() -> int:
	return DIRECTION_COUNT
