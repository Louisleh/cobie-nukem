class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.3"
const REVISION := "b8795dc"
const BUILD_ID := "2026-07-13-agentic-production-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
