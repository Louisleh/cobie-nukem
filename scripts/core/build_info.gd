class_name BuildInfo
extends RefCounted

const VERSION := "0.3.0-dev"
const REVISION := "98b4824"
const BUILD_ID := "2026-07-11-production-foundation"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
