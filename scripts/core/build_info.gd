class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.9"
const REVISION := "c00d54c"
const BUILD_ID := "2026-07-14-public-beta-focus"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
