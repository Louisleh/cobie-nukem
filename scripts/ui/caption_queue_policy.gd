class_name CaptionQueuePolicy
extends RefCounted

# Warning validity is the attack telegraph lifetime, not its readable hold time.
static func expired(payload: Dictionary) -> bool:
	return payload.has("expires_at_ms") and Time.get_ticks_msec() >= int(payload["expires_at_ms"])

static func matches(payload: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	return target["key"] == payload["key"] or target["message"] == payload["message"]

static func drop_expired_warnings(queue: Array[Dictionary]) -> void:
	for index in range(queue.size() - 1, -1, -1):
		if expired(queue[index]):
			queue.remove_at(index)

static func enqueue(queue: Array[Dictionary], payload: Dictionary, limit: int) -> void:
	if expired(payload):
		return
	var insertion_index := queue.size()
	for index in range(queue.size()):
		if queue[index]["priority"] < payload["priority"]:
			insertion_index = index
			break
	queue.insert(insertion_index, payload)
	if queue.size() > limit:
		queue.resize(limit)
