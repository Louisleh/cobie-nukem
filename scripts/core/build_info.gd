class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.1"
const REVISION := "575d84e"
const BUILD_ID := "2026-07-12-twin-stick-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
