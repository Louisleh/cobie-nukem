class_name BuildInfo
extends RefCounted

const VERSION := "0.7.0-alpha.1-rc5"
const REVISION := "38f8164"
const BUILD_ID := "2026-07-17-rain-city-foundry-rc5"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
