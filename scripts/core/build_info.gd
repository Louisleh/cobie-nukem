class_name BuildInfo
extends RefCounted

const VERSION := "0.11.0-alpha.1-rc1"
const REVISION := "3c2de29"
const BUILD_ID := "2026-07-18-doghouse-progression-rc1"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
