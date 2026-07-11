extends SceneTree

const CONTENT_DIRECTORY := "res://resources/content"


func _initialize() -> void:
	var failures := PackedStringArray()
	var files := DirAccess.get_files_at(CONTENT_DIRECTORY)
	var manifests := 0
	for filename in files:
		if not filename.ends_with(".tres"): continue
		var path := CONTENT_DIRECTORY.path_join(filename)
		var manifest := load(path) as ContentManifest
		if manifest == null:
			failures.append("%s: not a ContentManifest" % path)
			continue
		manifests += 1
		for error in manifest.validate(): failures.append("%s: %s" % [path, error])
	if manifests == 0: failures.append("no content manifests found in %s" % CONTENT_DIRECTORY)
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		print("CONTENT VALIDATION: FAIL (%d issue(s))" % failures.size())
		quit(1)
		return
	print("CONTENT VALIDATION: PASS (%d manifest(s))" % manifests)
	quit(0)
