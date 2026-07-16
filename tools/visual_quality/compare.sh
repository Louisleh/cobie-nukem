#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_MANIFEST_PATH="${SCRIPT_DIR}/capture_manifest.json"

usage() {
	cat <<'USAGE'
Usage: compare.sh [options]

Compare canonical baselines to candidate captures using tools/visual_quality/capture_manifest.json.

Options:
  --manifest PATH    Path to capture manifest JSON (default: tools/visual_quality/capture_manifest.json)
  --baseline PATH    Baseline capture directory (default: capture_policy.default_baseline_root from manifest)
  --candidate PATH   Candidate capture directory (default: capture_policy.default_candidate_root from manifest)
  --out PATH         Output directory for comparison JSON + Markdown (default: builds/visual-quality/compare/<timestamp>)
  --help             Show this help and exit.
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

MANIFEST_PATH="$DEFAULT_MANIFEST_PATH"
BASELINE_OVERRIDE=""
CANDIDATE_OVERRIDE=""
OUTPUT_OVERRIDE=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help)
			usage
			exit 0
			;;
		--manifest)
			if [[ $# -lt 2 ]]; then
				echo "ERROR: missing value for $1" >&2
				exit 1
			fi
			MANIFEST_PATH="$2"
			shift 2
			;;
		--baseline)
			if [[ $# -lt 2 ]]; then
				echo "ERROR: missing value for $1" >&2
				exit 1
			fi
			BASELINE_OVERRIDE="$2"
			shift 2
			;;
		--candidate)
			if [[ $# -lt 2 ]]; then
				echo "ERROR: missing value for $1" >&2
				exit 1
			fi
			CANDIDATE_OVERRIDE="$2"
			shift 2
			;;
		--out)
			if [[ $# -lt 2 ]]; then
				echo "ERROR: missing value for $1" >&2
				exit 1
			fi
			OUTPUT_OVERRIDE="$2"
			shift 2
			;;
		*)
			echo "ERROR: unknown argument $1" >&2
			usage
			exit 1
			;;
	esac
done

if [[ ! -f "$MANIFEST_PATH" ]]; then
	echo "ERROR: missing manifest $MANIFEST_PATH" >&2
	exit 1
fi

manifest_json="$(cat "$MANIFEST_PATH")"
default_baseline="$(python3 - "$manifest_json" <<'PY'
import json
import sys

manifest = json.loads(sys.argv[1])
print(manifest.get("capture_policy", {}).get("default_baseline_root", "builds/visual-quality/baselines"))
PY
)"
default_candidate="$(python3 - "$manifest_json" <<'PY'
import json
import sys

manifest = json.loads(sys.argv[1])
print(manifest.get("capture_policy", {}).get("default_candidate_root", "builds/visual-quality/candidates"))
PY
)"

if [[ -z "$default_baseline" || -z "$default_candidate" ]]; then
	echo "ERROR: invalid capture policy in manifest" >&2
	exit 1
fi

BASELINE_PATH="${BASELINE_OVERRIDE:-$default_baseline}"
CANDIDATE_PATH="${CANDIDATE_OVERRIDE:-$default_candidate}"
OUTPUT_PATH="${OUTPUT_OVERRIDE:-builds/visual-quality/comparisons/$(date -u +%Y%m%dT%H%M%SZ)}"

/opt/homebrew/bin/uv run --project "$SCRIPT_DIR" python "$SCRIPT_DIR/compare_captures.py" \
	--manifest "$MANIFEST_PATH" \
	--baseline "$BASELINE_PATH" \
	--candidate "$CANDIDATE_PATH" \
	--out "$OUTPUT_PATH"
exit $?
