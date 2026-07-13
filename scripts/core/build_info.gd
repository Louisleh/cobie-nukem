class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.6"
const REVISION := "52e8240"
const BUILD_ID := "2026-07-13-presentation-pacing-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
