class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.2"
const REVISION := "e6b4700"
const BUILD_ID := "2026-07-12-aim-roadmap-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
