class_name BuildInfo
extends RefCounted

const VERSION := "0.7.0-alpha.1-rc3"
const REVISION := "ba7c449"
const BUILD_ID := "2026-07-17-startup-stability-rc3"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
