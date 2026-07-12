class_name BuildInfo
extends RefCounted

const VERSION := "0.5.0-rc1"
const REVISION := "2daf1a4"
const BUILD_ID := "2026-07-12-phase12-public-rc"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
