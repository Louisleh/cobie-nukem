class_name CampaignBackupCodec
extends RefCounted

## Offline campaign backup codec.
##
## Format:
##   COBIE1.<base64url UTF-8 JSON>.<lowercase sha256 hex>
##
## Sanitization is enforced before encoding, so checkpoint/settings/PII
## can never be persisted in the campaign backup text.
const CampaignProgressPayload := preload("res://scripts/core/campaign_progress_payload.gd")

const PREFIX := "COBIE1"
const MAX_JSON_BYTES := 65536


static func encode(raw: Variant) -> String:
	var payload: Dictionary = CampaignProgressPayload.sanitize(raw)
	var canonical: Dictionary = _canonicalize_dictionary(payload)
	var payload_text := JSON.stringify(canonical)
	var payload_bytes := payload_text.to_utf8_buffer()
	var checksum := _sha256_hex(payload_bytes)
	var encoded_payload := _base64url_encode(payload_bytes)
	return "%s.%s.%s" % [PREFIX, encoded_payload, checksum]


static func decode(code: String) -> Dictionary:
	if code.is_empty():
		return {}

	var parts := code.split(".")
	if parts.size() != 3:
		return {}

	if parts[0] != PREFIX:
		return {}

	var encoded_payload: String = parts[1]
	if encoded_payload.is_empty() or not _is_base64url(encoded_payload):
		return {}

	var checksum: String = parts[2]
	if checksum.length() != 64:
		return {}
	if checksum != checksum.to_lower():
		return {}
	if not checksum.is_valid_hex_number(false):
		return {}

	var payload_bytes := _base64url_decode(encoded_payload)
	if payload_bytes.is_empty():
		return {}
	if payload_bytes.size() > MAX_JSON_BYTES:
		return {}

	if not _constant_time_equals(_sha256_hex(payload_bytes), checksum):
		return {}

	var payload_text := payload_bytes.get_string_from_utf8()
	if payload_bytes != payload_text.to_utf8_buffer():
		return {}

	var parser := JSON.new()
	if parser.parse(payload_text) != OK:
		return {}

	var parsed = parser.data
	if parsed is not Dictionary:
		return {}

	return CampaignProgressPayload.sanitize(parsed)


static func _canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		return _canonicalize_dictionary(value)
	if value is Array:
		return _canonicalize_array(value)
	return value


static func _canonicalize_dictionary(payload: Dictionary) -> Dictionary:
	var keys: PackedStringArray = payload.keys()
	keys.sort()
	var result := {}
	for key in keys:
		result[key] = _canonicalize(payload[key])
	return result


static func _canonicalize_array(values: Array) -> Array:
	var result := []
	for value in values:
		result.append(_canonicalize(value))
	return result


static func _base64url_encode(raw: PackedByteArray) -> String:
	if raw.is_empty():
		return ""
	var encoded := Marshalls.raw_to_base64(raw)
	return encoded.replace("+", "-").replace("/", "_")


static func _base64url_decode(value: String) -> PackedByteArray:
	if not _is_base64url(value):
		return PackedByteArray()

	var standard := value.replace("-", "+").replace("_", "/")
	var remainder := standard.length() % 4
	if remainder == 1:
		return PackedByteArray()
	if remainder != 0:
		standard += "=".repeat(4 - remainder)

	var decoded := Marshalls.base64_to_raw(standard)
	if decoded.is_empty():
		return PackedByteArray()
	return decoded


static func _is_base64url(value: String) -> bool:
	if value.is_empty():
		return false

	var bytes := value.to_ascii_buffer()
	var first_padding := -1
	for i in bytes.size():
		var ch := bytes[i]
		if ch == 61: # "="
			first_padding = i
			break
		if not _is_base64url_char(ch):
			return false

	if first_padding == -1:
		if bytes.size() % 4 == 1:
			return false
		return true

	for j in range(first_padding, bytes.size()):
		if bytes[j] != 61:
			return false

	var padding_count := bytes.size() - first_padding
	if padding_count > 2:
		return false
	if bytes.size() % 4 != 0:
		return false
	if padding_count == bytes.size():
		return false

	return true


static func _is_base64url_char(ch: int) -> bool:
	if ch >= 65 and ch <= 90:
		return true
	if ch >= 97 and ch <= 122:
		return true
	if ch >= 48 and ch <= 57:
		return true
	return ch == 45 or ch == 95


static func _sha256_hex(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode().to_lower()


static func _constant_time_equals(left: String, right: String) -> bool:
	var left_bytes := left.to_ascii_buffer()
	var right_bytes := right.to_ascii_buffer()
	var max_len := maxi(left_bytes.size(), right_bytes.size())
	var result := 0
	for i in max_len:
		var left_byte := left_bytes[i] if i < left_bytes.size() else 0
		var right_byte := right_bytes[i] if i < right_bytes.size() else 0
		result |= left_byte ^ right_byte
	return result == 0 and left_bytes.size() == right_bytes.size()


class CampaignBackupService:
	extends Node

	var save_manager: Node

	func encode(raw: Variant) -> String:
		return CampaignBackupCodec.encode(raw)

	func decode(code: String) -> Dictionary:
		return CampaignBackupCodec.decode(code)
