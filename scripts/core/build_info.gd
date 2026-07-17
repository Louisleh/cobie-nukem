class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.10"
const REVISION := "20649be"
const BUILD_ID := "2026-07-16-production-foundry"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
