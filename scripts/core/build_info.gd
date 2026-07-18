class_name BuildInfo
extends RefCounted

const VERSION := "0.8.0-alpha.1-rc1"
const REVISION := "7e6684e"
const BUILD_ID := "2026-07-18-whiteout-public-beta-rc1"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
