class_name BuildInfo
extends RefCounted

const VERSION := "0.6.0-alpha.7"
const REVISION := "eb66cf8"
const BUILD_ID := "2026-07-13-spark-interaction-alpha"

static func label() -> String:
	return "v%s • %s • %s" % [VERSION, REVISION, BUILD_ID]
