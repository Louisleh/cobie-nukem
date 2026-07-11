class_name LevelCardData
extends Resource

@export var level_id: StringName
@export var title := "LOCKED COURSE"
@export var episode := "EPISODE ?"
@export_multiline var description := "Animal Control has classified this location."
@export_range(1, 5, 1) var difficulty := 1
@export var expected_minutes := "12–20 MIN"
@export var secrets := 0
@export var encounter := "UNKNOWN THREAT"
@export var unlocked := false
@export_file("*.tscn") var scene_path := ""
@export var preview: Texture2D
