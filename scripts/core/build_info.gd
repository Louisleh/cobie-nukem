class_name BuildInfo
extends RefCounted

const VERSION := "0.11.0-alpha.1-rc2"
const REVISION := "a8e1a321c97c"
const BUILD_ID := "2026-10-02-feedback-rc2"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
