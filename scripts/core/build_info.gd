class_name BuildInfo
extends RefCounted

const VERSION := "0.4.0-mobile-rc1"
const REVISION := "eb562e0"
const BUILD_ID := "2026-07-11-public-ipad-rc"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
