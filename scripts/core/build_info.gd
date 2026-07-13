class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.5"
const REVISION := "9143a31"
const BUILD_ID := "2026-07-13-production-navigation-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
