extends SceneTree

var failures: Array[String] = []
var test_root := "user://mission_pack_loader_test"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_root()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	_test_definition_validation()
	await _test_native_bundled_ready()
	await _test_chunked_cached_verification()
	await _test_staged_atomic_promotion()
	await _test_invalid_cache_never_mounts_or_networks()
	_cleanup_root()
	if failures.is_empty():
		print("MISSION PACK LOADER TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_definition_validation() -> void:
	var invalid := MissionPackDefinition.new()
	invalid.pack_id = &""
	invalid.cache_file = "../escape.pck"
	invalid.expected_bytes = 12
	invalid.expected_sha256 = "bad"
	_expect(invalid.validate().size() >= 3, "definition rejects empty id, traversal, and malformed digest")
	var valid := _definition_for(PackedByteArray([1, 2, 3]), "valid-definition.pck")
	_expect(valid.validate().is_empty(), "complete HTTPS pack definition validates")


func _test_native_bundled_ready() -> void:
	var loader := MissionPackLoader.new()
	root.add_child(loader)
	var pack := MissionPackDefinition.new()
	pack.pack_id = &"native_core"
	pack.bundled_on_native = true
	pack.cache_file = "native-core.pck"
	var ready_count := [0]
	loader.pack_ready.connect(func(_id: StringName, path: String) -> void:
		ready_count[0] += 1
		_expect(path.is_empty(), "native bundled content needs no runtime mount")
	)
	_expect(loader.prepare(pack, 0), "native bundled prepare is accepted")
	_expect(loader.state == MissionPackLoader.State.READY and ready_count[0] == 1, "native bundled path becomes ready synchronously")
	loader.free()


func _test_chunked_cached_verification() -> void:
	var bytes := PackedByteArray()
	bytes.resize(MissionPackLoader.VERIFY_CHUNK_BYTES * 2 + 37)
	for index in bytes.size():
		bytes[index] = index % 251
	var pack := _definition_for(bytes, "chunked-cache.pck")
	var path := "%s/%s" % [test_root, pack.cache_file]
	_write(path, bytes)
	var loader := _loader_with_mount_stub()
	var progress_events := [0]
	loader.progress_changed.connect(func(_completed: int, _total: int) -> void: progress_events[0] += 1)
	_expect(loader.prepare(pack, 1), "valid cached Web pack starts verification")
	await _wait_terminal(loader)
	_expect(loader.state == MissionPackLoader.State.READY, "valid cached Web pack verifies and mounts")
	_expect(progress_events[0] >= 4, "verification yields across multiple fixed-size chunks")
	loader.free()


func _test_staged_atomic_promotion() -> void:
	var bytes := "atomic mission pack".to_utf8_buffer()
	var pack := _definition_for(bytes, "promoted-cache.pck")
	var staged := "%s/staged.download" % test_root
	_write(staged, bytes)
	var loader := _loader_with_mount_stub()
	_expect(loader.prepare_staged_candidate(pack, staged), "staged candidate enters shared verification path")
	await _wait_terminal(loader)
	var final_path := "%s/%s" % [test_root, pack.cache_file]
	_expect(loader.state == MissionPackLoader.State.READY, "verified staged candidate reaches ready")
	_expect(FileAccess.file_exists(final_path) and not FileAccess.file_exists(staged), "verified staged candidate is atomically promoted")
	loader.free()


func _test_invalid_cache_never_mounts_or_networks() -> void:
	var expected := "expected bytes".to_utf8_buffer()
	var pack := _definition_for(expected, "invalid-cache.pck")
	var path := "%s/%s" % [test_root, pack.cache_file]
	var corrupted := expected.duplicate()
	corrupted[0] = corrupted[0] ^ 0xff
	_write(path, corrupted)
	var loader := _loader_with_mount_stub()
	loader.allow_network = false
	var mounts := [0]
	loader.pack_mount_callable = func(_path: String, _replace: bool) -> bool:
		mounts[0] += 1
		return true
	_expect(loader.prepare(pack, 1), "invalid cache begins local check")
	await _wait_terminal(loader)
	_expect(loader.state == MissionPackLoader.State.FAILED, "invalid cache fails when network is disabled")
	_expect(mounts[0] == 0, "invalid bytes are never mounted")
	_expect(not FileAccess.file_exists(path), "invalid cache is removed before retry")
	loader.free()


func _loader_with_mount_stub() -> MissionPackLoader:
	var loader := MissionPackLoader.new()
	loader.cache_root = test_root
	loader.allow_network = false
	loader.pack_mount_callable = func(_path: String, replace_files: bool) -> bool:
		_expect(not replace_files, "mission packs never replace existing files")
		return true
	root.add_child(loader)
	return loader


func _definition_for(bytes: PackedByteArray, file_name: String) -> MissionPackDefinition:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	var pack := MissionPackDefinition.new()
	pack.pack_id = StringName(file_name.get_basename().replace("-", "_"))
	pack.content_version = 1
	pack.remote_url = "https://example.invalid/%s" % file_name
	pack.expected_bytes = bytes.size()
	pack.expected_sha256 = context.finish().hex_encode()
	pack.cache_file = file_name
	pack.bundled_on_native = false
	return pack


func _write(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not create test file %s" % path)
		return
	file.store_buffer(bytes)
	file = null


func _wait_terminal(loader: MissionPackLoader) -> void:
	for _frame in 60:
		if loader.state in [MissionPackLoader.State.READY, MissionPackLoader.State.FAILED, MissionPackLoader.State.CANCELLED]:
			return
		await process_frame
	failures.append("mission pack loader did not settle within 60 frames")


func _cleanup_root() -> void:
	var absolute := ProjectSettings.globalize_path(test_root)
	if DirAccess.dir_exists_absolute(absolute):
		_remove_recursive(absolute)


func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_remove_recursive(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
