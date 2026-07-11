class_name BuildInfo
extends RefCounted

const VERSION := "0.3.0-dev"
const REVISION := "phase12+"
const BUILD_ID := "2026-07-11-production-foundation"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
