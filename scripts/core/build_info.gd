class_name BuildInfo
extends RefCounted

const VERSION := "0.9.0-alpha.1-rc1"
const REVISION := "df84813"
const BUILD_ID := "2026-07-18-five-mission-public-beta-rc1"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
