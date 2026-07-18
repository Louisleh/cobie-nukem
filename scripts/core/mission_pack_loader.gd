class_name MissionPackLoader
extends Node

signal state_changed(previous: State, current: State)
signal progress_changed(completed_bytes: int, total_bytes: int)
signal pack_ready(pack_id: StringName, mounted_path: String)
signal pack_failed(pack_id: StringName, reason: StringName)
signal pack_cancelled(pack_id: StringName)

enum State {
	IDLE,
	CHECKING_CACHE,
	DOWNLOADING,
	VERIFYING,
	PROMOTING,
	LOADING,
	READY,
	FAILED,
	CANCELLED,
}

const VERIFY_CHUNK_BYTES := 256 * 1024
const DEFAULT_CACHE_ROOT := "user://mission_packs"

var state := State.IDLE
var definition: MissionPackDefinition
var allow_network := true
var cache_root := DEFAULT_CACHE_ROOT
## Test seam and future platform adapter. Empty means the production
## ProjectSettings.load_resource_pack(path, false) implementation is used.
var pack_mount_callable: Callable

var _request: HTTPRequest
var _generation := 0
var _cache_path := ""
var _temporary_path := ""
var _verify_path := ""
var _verify_promote := false
var _verify_file: FileAccess
var _hash_context: HashingContext
var _verified_bytes := 0


func prepare(pack: MissionPackDefinition, web_override := -1) -> bool:
	cancel(false)
	_generation += 1
	definition = pack
	if definition == null:
		_fail(&"missing_definition")
		return false
	if not definition.validate().is_empty():
		_fail(&"invalid_definition")
		return false
	_cache_path = definition.cache_path(cache_root)
	_temporary_path = _cache_path + ".download"
	var web_build := OS.has_feature("web") if web_override < 0 else web_override != 0
	if not web_build and definition.bundled_on_native:
		return _prepare_native_bundle()
	_set_state(State.CHECKING_CACHE)
	if FileAccess.file_exists(_cache_path):
		_begin_verification(_cache_path, false)
		return true
	return _begin_download()


## Deterministic installer/test entry point. The staged file is verified using
## the same chunked path as a completed HTTP request, then atomically promoted.
func prepare_staged_candidate(pack: MissionPackDefinition, staged_path: String) -> bool:
	cancel(false)
	_generation += 1
	definition = pack
	if definition == null or not definition.validate().is_empty():
		_fail(&"invalid_definition")
		return false
	if not FileAccess.file_exists(staged_path):
		_fail(&"staged_file_missing")
		return false
	_cache_path = definition.cache_path(cache_root)
	_temporary_path = staged_path
	_begin_verification(staged_path, true)
	return true


func cancel(emit_signal := true) -> void:
	var was_active := state not in [State.IDLE, State.READY, State.FAILED, State.CANCELLED]
	_generation += 1
	_cleanup_request()
	_cleanup_verification()
	if was_active:
		_delete_file(_temporary_path)
	if was_active and emit_signal:
		_set_state(State.CANCELLED)
		pack_cancelled.emit(definition.pack_id if definition != null else &"")
	elif not emit_signal:
		state = State.IDLE
	set_process(false)


func reset() -> void:
	cancel(false)
	definition = null
	_cache_path = ""
	_temporary_path = ""
	_set_state(State.IDLE)


func _ready() -> void:
	set_process(false)


func _exit_tree() -> void:
	cancel(false)


func _process(_delta: float) -> void:
	if state != State.VERIFYING or _verify_file == null or _hash_context == null:
		return
	var remaining := definition.expected_bytes - _verified_bytes
	if remaining > 0:
		var chunk := _verify_file.get_buffer(mini(VERIFY_CHUNK_BYTES, remaining))
		if chunk.is_empty():
			_finish_verification(false, &"unexpected_end_of_file")
			return
		_hash_context.update(chunk)
		_verified_bytes += chunk.size()
		progress_changed.emit(_verified_bytes, definition.expected_bytes)
		return
	_finish_verification(true)


func _prepare_native_bundle() -> bool:
	if definition.bundled_pack_path.is_empty():
		_ready_pack("")
		return true
	_set_state(State.LOADING)
	if not _mount_pack(definition.bundled_pack_path):
		_fail(&"bundled_mount_failed")
		return false
	if not _required_resources_ready():
		_fail(&"required_resource_missing")
		return false
	_ready_pack(definition.bundled_pack_path)
	return true


func _begin_download() -> bool:
	if not definition.is_download_configured():
		_fail(&"download_not_configured")
		return false
	if not allow_network:
		_fail(&"network_disabled")
		return false
	if not _ensure_cache_directory():
		_fail(&"cache_directory_failed")
		return false
	_delete_file(_temporary_path)
	_request = HTTPRequest.new()
	_request.name = "MissionPackRequest"
	_request.download_file = _temporary_path
	_request.request_completed.connect(_on_request_completed.bind(_generation))
	add_child(_request)
	_set_state(State.DOWNLOADING)
	set_process(true)
	var error := _request.request(definition.remote_url)
	if error != OK:
		_fail(&"request_start_failed")
		return false
	return true


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, generation: int) -> void:
	if generation != _generation or state != State.DOWNLOADING:
		return
	_cleanup_request()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_delete_file(_temporary_path)
		_fail(&"download_failed")
		return
	_begin_verification(_temporary_path, true)


func _begin_verification(path: String, promote: bool) -> void:
	_cleanup_verification()
	if definition.expected_bytes <= 0 or definition.normalized_sha256().length() != 64:
		_fail(&"verification_not_configured")
		return
	_verify_file = FileAccess.open(path, FileAccess.READ)
	if _verify_file == null:
		_fail(&"verification_open_failed")
		return
	if _verify_file.get_length() != definition.expected_bytes:
		_cleanup_verification()
		if promote:
			_delete_file(path)
			_fail(&"size_mismatch")
		else:
			_delete_file(_cache_path)
			_begin_download()
		return
	_hash_context = HashingContext.new()
	if _hash_context.start(HashingContext.HASH_SHA256) != OK:
		_cleanup_verification()
		_fail(&"hash_start_failed")
		return
	_verify_path = path
	_verify_promote = promote
	_verified_bytes = 0
	_set_state(State.VERIFYING)
	progress_changed.emit(0, definition.expected_bytes)
	set_process(true)


func _finish_verification(read_complete: bool, failure_reason: StringName = &"hash_mismatch") -> void:
	if not read_complete or _verified_bytes != definition.expected_bytes:
		var failed_path := _verify_path
		var was_promote := _verify_promote
		_cleanup_verification()
		if was_promote:
			_delete_file(failed_path)
			_fail(failure_reason)
		else:
			_delete_file(_cache_path)
			_begin_download()
		return
	var digest := _hash_context.finish().hex_encode().to_lower()
	var verified_path := _verify_path
	var should_promote := _verify_promote
	_cleanup_verification()
	if digest != definition.normalized_sha256():
		if should_promote:
			_delete_file(verified_path)
			_fail(&"hash_mismatch")
		else:
			_delete_file(_cache_path)
			_begin_download()
		return
	if should_promote:
		_promote_verified_file(verified_path)
	else:
		_load_verified_pack(_cache_path)


func _promote_verified_file(path: String) -> void:
	_set_state(State.PROMOTING)
	if not _ensure_cache_directory():
		_delete_file(path)
		_fail(&"cache_directory_failed")
		return
	if path != _cache_path:
		_delete_file(_cache_path)
		var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(_cache_path))
		if error != OK:
			_delete_file(path)
			_fail(&"atomic_promote_failed")
			return
	_load_verified_pack(_cache_path)


func _load_verified_pack(path: String) -> void:
	_set_state(State.LOADING)
	if not _mount_pack(path):
		_delete_file(path)
		_fail(&"mount_failed")
		return
	if not _required_resources_ready():
		_delete_file(path)
		_fail(&"required_resource_missing")
		return
	_ready_pack(path)


func _mount_pack(path: String) -> bool:
	if pack_mount_callable.is_valid():
		return bool(pack_mount_callable.call(path, false))
	return ProjectSettings.load_resource_pack(path, false)


func _required_resources_ready() -> bool:
	for path in definition.required_resource_paths:
		if not ResourceLoader.exists(path):
			return false
	return true


func _ready_pack(path: String) -> void:
	set_process(false)
	_set_state(State.READY)
	pack_ready.emit(definition.pack_id, path)


func _fail(reason: StringName) -> void:
	_cleanup_request()
	_cleanup_verification()
	set_process(false)
	_set_state(State.FAILED)
	pack_failed.emit(definition.pack_id if definition != null else &"", reason)


func _set_state(next: State) -> void:
	if state == next:
		return
	var previous := state
	state = next
	state_changed.emit(previous, state)


func _cleanup_request() -> void:
	if _request == null or not is_instance_valid(_request):
		_request = null
		return
	_request.cancel_request()
	_request.queue_free()
	_request = null


func _cleanup_verification() -> void:
	_verify_file = null
	_hash_context = null
	_verify_path = ""
	_verify_promote = false
	_verified_bytes = 0


func _ensure_cache_directory() -> bool:
	var absolute := ProjectSettings.globalize_path(cache_root)
	return DirAccess.make_dir_recursive_absolute(absolute) in [OK, ERR_ALREADY_EXISTS]


func _delete_file(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
