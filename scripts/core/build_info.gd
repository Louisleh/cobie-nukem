class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.4"
const REVISION := "67a0ee4"
const BUILD_ID := "2026-07-13-agentic-overhaul-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
