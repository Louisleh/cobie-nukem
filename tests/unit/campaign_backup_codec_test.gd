extends SceneTree

const Codec := preload("res://scripts/core/campaign_backup_codec.gd")
const CampaignProgressPayload := preload("res://scripts/core/campaign_progress_payload.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_test_encode_decode_cycles()
	_test_canonical_order_stability()
	_test_tamper_and_checksum_rejection()
	_test_malformed_prefix_and_size_rejection()
	_test_unknown_keys_are_removed()
	_test_no_save_slot_writes()
	if failures.is_empty():
		print("PASS: campaign backup codec")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_encode_decode_cycles() -> void:
	for cycle in range(100):
		var raw := _payload_for_cycle(cycle)
		var code := Codec.encode(raw)
		var decoded := Codec.decode(code)
		var expected := CampaignProgressPayload.sanitize(raw)
		_expect(decoded == expected, "encode/decode cycle %d is deterministic and sanitizer-safe" % cycle)


func _test_canonical_order_stability() -> void:
	var canonical_a := {
		"selected_cosmetics": {"slot_one": "skin_fallback", "slot_two": "skin_core"},
		"wallet": {"compliance_tags": 4},
		"mission_records": {
			"mission_beta": {"rank": "A", "difficulty": "story", "best_time_msec": 450, "best_secrets": 3, "total_secrets": 4},
			"mission_alpha": {"difficulty": "mayhem", "rank": "S", "best_time_msec": 300},
		},
		"completed_missions": ["mission_alpha", "mission_beta", "mission_alpha"],
	}
	var canonical_b := {
		"mission_records": {
			"mission_alpha": {"best_time_msec": 300, "rank": "S", "difficulty": "mayhem"},
			"mission_beta": {"total_secrets": 4, "best_time_msec": 450, "best_secrets": 3, "difficulty": "story", "rank": "A"},
		},
		"selected_cosmetics": {"slot_two": "skin_core", "slot_one": "skin_fallback"},
		"completed_missions": ["mission_beta", "mission_alpha"],
		"wallet": {"compliance_tags": 4},
	}

	var code_a := Codec.encode(canonical_a)
	var code_b := Codec.encode(canonical_b)
	_expect(code_a == code_b, "dictionary key order does not change backup output")
	_expect(Codec.decode(code_a) == Codec.decode(code_b), "canonicalized payload decodes identically across key orders")


func _test_tamper_and_checksum_rejection() -> void:
	var raw := _payload_for_cycle(12)
	var code := Codec.encode(raw)
	var parts := code.split(".")
	_expect(parts.size() == 3, "generated code has the expected component count")
	if parts.size() != 3:
		return

	var tampered_payload := parts[1]
	var first_char := tampered_payload[0]
	tampered_payload = tampered_payload.substr(0, 0) + ("A" if first_char != "A" else "B") + tampered_payload.substr(1)
	var tampered_payload_code := "%s.%s.%s" % [parts[0], tampered_payload, parts[2]]
	_expect(Codec.decode(tampered_payload_code).is_empty(), "tampered payload without checksum recompute is rejected")

	var bad_checksum := "0" + parts[2].substr(1)
	if bad_checksum == parts[2]:
		bad_checksum = "1" + parts[2].substr(1)
	var tampered_checksum_code := "%s.%s.%s" % [parts[0], parts[1], bad_checksum]
	_expect(Codec.decode(tampered_checksum_code).is_empty(), "checksum mismatch is rejected")


func _test_malformed_prefix_and_size_rejection() -> void:
	var good := _payload_for_cycle(4)
	var good_code := Codec.encode(good)
	var good_parts := good_code.split(".")
	_expect(good_parts.size() == 3, "generated good code has three parts")

	_expect(Codec.decode("WRONG.%s.%s" % [good_parts[1], good_parts[2]]).is_empty(), "wrong prefix is rejected")
	_expect(Codec.decode("COBIE1.%s" % good_parts[1]).is_empty(), "wrong component count is rejected")
	var bad_b64 := "COBIE1.x$%s.%s" % [good_parts[1], good_parts[2]]
	_expect(Codec.decode(bad_b64).is_empty(), "non-base64url symbols are rejected")

	var oversized_payload := "%s%s%s" % ["{\"oversized\":\"", "x".repeat(70000), "\""]
	var oversized_code := _offline_code(oversized_payload + "}")
	_expect(_oversize_is_large(oversized_payload + "}"), "oversized fixture remains above byte budget")
	_expect(Codec.decode(oversized_code).is_empty(), "oversized decoded JSON is rejected")

	var non_dict_code := _offline_code("[\"campaign\", \"backup\"]")
	_expect(Codec.decode(non_dict_code).is_empty(), "non-dictionary JSON is rejected")


func _test_unknown_keys_are_removed() -> void:
	var noisy := {
		"_noise_root": "disallowed",
		"completed_missions": ["mission_alpha", "mission_alpha", "  "],
		"unlocked_missions": ["mission_gamma"],
		"mission_records": {
			"mission_alpha": {"best_time_msec": 900, "bogus_field": "x", "difficulty": "story", "rank": "B", "best_secrets": 2, "total_secrets": 3},
			"mission bad": {"best_time_msec": 1200},
		},
		"campaign_upgrades": {
			"mission_alpha": ["upgrade_two", "upgrade_two", ""],
			"mission bad": ["upgrade_one"],
		},
		"wallet": {"compliance_tags": 12, "_noisy": true},
		"equipped_weapon_mods": {"weapon_alpha": "mod_one", "bad weapon": "mod"},
		"selected_cosmetics": {"head_slot": "cosmetic_alpha", "bad slot": "bad"},
		"unknown_nested": {"a": 1},
	}
	var code := Codec.encode(noisy)
	var decoded := Codec.decode(code)
	var expected := CampaignProgressPayload.sanitize(noisy)
	_expect(decoded == expected, "sanitize contract runs during decode")
	_expect(not decoded.has("_noise_root") and not decoded.has("unknown_nested"), "top-level unknown keys are removed")
	_expect(not decoded.get("mission_records", {}).get("mission_alpha", {}).has("bogus_field"), "unknown mission_record keys are removed")
	_expect(not decoded.has("mission_records") or not decoded.mission_records.has("mission bad"), "unstable mission ids are removed")


func _test_no_save_slot_writes() -> void:
	var tracker := FakeSaveManager.new()
	var service := Codec.CampaignBackupService.new()
	service.save_manager = tracker
	var payload := _payload_for_cycle(77)
	var code := service.encode(payload)
	var decoded := service.decode(code)
	_expect(decoded == CampaignProgressPayload.sanitize(payload), "service delegates to codec")
	_expect(tracker.save_slot_calls == 0, "encode does not write slots")
	_expect(tracker.load_slot_calls == 0, "decode does not read slots")
	_expect(tracker.delete_slot_calls == 0, "service codec path does not delete slots")
	tracker.queue_free()
	service.queue_free()


func _payload_for_cycle(cycle: int) -> Dictionary:
	var mission_a_time := 400 + cycle
	var mission_b_time := 500 + (cycle % 31)
	return {
		"unlocked_missions": ["mission_beta", "mission_alpha", "mission_alpha", 12, ""],
		"completed_missions": ["mission_alpha", "mission_alpha", "mission_gamma", "  "],
		"mission_records": {
			"mission_alpha": {"best_time_msec": mission_a_time, "best_secrets": 1, "total_secrets": 3, "difficulty": "story", "rank": "S"},
			"mission_beta": {"best_time_msec": mission_b_time, "difficulty": "classic", "rank": "A", "off_leash": 9},
		},
		"campaign_upgrades": {"mission_alpha": ["upgrade_beta", "upgrade_alpha", ""], "mission_beta": ["upgrade_gamma"]},
		"wallet": {"compliance_tags": cycle},
		"mission_collectibles": {"mission_alpha": ["collect_a", "collect_a", "collect_c"], "bad mission": ["collect_b"]},
		"purchased_rewards": ["reward_alpha", "reward_alpha"],
		"equipped_weapon_mods": {"weapon_alpha": "mod_alpha", "weapon_beta": "mod_beta", "": "bad"},
		"completed_challenges": ["challenge_alpha", "challenge_beta", "challenge_alpha"],
		"selected_cosmetics": {"head_slot": "skin_alpha"},
	}


func _offline_code(json_text: String) -> String:
	var bytes := json_text.to_utf8_buffer()
	var checksum := _sha256_hex(bytes)
	var payload := _base64url_encode(bytes)
	return "COBIE1.%s.%s" % [payload, checksum]


func _oversize_is_large(json_text: String) -> bool:
	var bytes := json_text.to_utf8_buffer()
	return bytes.size() > Codec.MAX_JSON_BYTES


func _sha256_hex(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode().to_lower()


func _base64url_encode(raw: PackedByteArray) -> String:
	if raw.is_empty():
		return ""
	return Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_")


class FakeSaveManager extends Node:
	var save_slot_calls := 0
	var load_slot_calls := 0
	var delete_slot_calls := 0

	func save_slot(_slot: StringName, _payload: Variant) -> int:
		save_slot_calls += 1
		return OK

	func load_slot(_slot: StringName) -> Dictionary:
		load_slot_calls += 1
		return {}

	func delete_slot(_slot: StringName) -> int:
		delete_slot_calls += 1
		return OK


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
