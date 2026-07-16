#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_PATH="${SCRIPT_DIR}/capture_manifest.json"

usage() {
	cat <<'USAGE'
Usage: capture.sh [options]

Capture visual references declared in tools/visual_quality/capture_manifest.json.
This script only writes into candidate outputs unless --approve is supplied; policy requires --approve
to update baseline outputs.

Options:
  --manifest PATH       Path to capture manifest JSON (default: tools/visual_quality/capture_manifest.json)
  --baseline PATH       Baseline root path (default: manifest policy default_baseline_root)
  --candidate PATH      Candidate root path (default: manifest policy default_candidate_root)
  --view VIEW_ID        Capture only a specific canonical view ID. Repeat for multiple.
  --aspect WIDTHxHEIGHT Capture only a declared aspect. Repeat for multiple.
  --render-fps FPS      Deterministic render FPS: 30, 60, or 120.
  --physics-tps TPS     Physics ticks per second; use 10 for interpolation diagnostics.
  --approve             Copy captured files into baseline root (explicit overwrite allowed).
  --run-id TEXT         Custom candidate run folder name under candidate root.
  --help                Show this help and exit.
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

args=()
args+=(--manifest "$MANIFEST_PATH")
while [[ $# -gt 0 ]]; do
	case "$1" in
		--help)
			usage
			exit 0
			;;
		--manifest|--baseline|--candidate|--run-id|--view|--aspect|--render-fps|--physics-tps|--approve)
			args+=("$1")
			if [[ "$1" == "--approve" ]]; then
				shift
				continue
			fi
			if [[ $# -lt 2 ]]; then
				echo "ERROR: missing value for $1" >&2
				exit 1
			fi
			args+=("$2")
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

/opt/homebrew/bin/uv run --project "$SCRIPT_DIR" python "$SCRIPT_DIR/capture_tool.py" "${args[@]}"
exit $?
