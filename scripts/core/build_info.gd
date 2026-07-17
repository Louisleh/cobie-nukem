class_name BuildInfo
extends RefCounted

const VERSION := "0.7.0-alpha.1-rc2"
const REVISION := "0d80348"
const BUILD_ID := "2026-07-16-rain-city-rc2"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
