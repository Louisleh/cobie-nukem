class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.8"
const REVISION := "f1f1e53"
const BUILD_ID := "2026-07-13-rain-city-forge"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
