class_name BuildInfo
extends RefCounted

const VERSION := "0.11.0-alpha.1-rc3"
const REVISION := "cb52fce42ada"
const BUILD_ID := "2026-10-03-feedback-rc3"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
