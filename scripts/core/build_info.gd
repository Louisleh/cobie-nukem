class_name BuildInfo
extends RefCounted

const VERSION := "0.7.0-alpha.1-rc4"
const REVISION := "e1afd5a"
const BUILD_ID := "2026-07-17-selector-public-beta-rc4"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
