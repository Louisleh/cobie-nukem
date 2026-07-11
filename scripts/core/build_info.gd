class_name BuildInfo
extends RefCounted

const VERSION := "0.2.0-rc1"
const REVISION := "67d6a33"
const BUILD_ID := "2026-07-11-ambitious-rc"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
