class_name BuildInfo
extends RefCounted

const VERSION := "0.10.0-alpha.1-rc1"
const REVISION := "7cb7ac6"
const BUILD_ID := "2026-07-18-definitive-convergence-rc1"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
