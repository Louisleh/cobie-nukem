#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
runner="tools/run_godot_safe.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

GODOT_BIN=/bin/sh bash "$runner" --timeout 10 --lock-wait 5 -- -c 'sleep 2' \
  >"$tmp_dir/first.log" 2>&1 &
first_pid=$!
sleep 0.2

set +e
GODOT_BIN=/bin/sh bash "$runner" --timeout 10 --lock-wait 1 -- -c 'exit 0' \
  >"$tmp_dir/blocked.log" 2>&1
blocked_status=$?
set -e
[[ "$blocked_status" -eq 75 ]] || {
  echo "FAIL: concurrent invocation returned $blocked_status, expected 75"
  cat "$tmp_dir/blocked.log"
  exit 1
}
wait "$first_pid"

set +e
GODOT_BIN=/bin/sh bash "$runner" --timeout 1 --lock-wait 2 -- -c 'sleep 5' \
  >"$tmp_dir/timeout.log" 2>&1
timeout_status=$?
set -e
[[ "$timeout_status" -eq 124 ]] || {
  echo "FAIL: timed invocation returned $timeout_status, expected 124"
  cat "$tmp_dir/timeout.log"
  exit 1
}

GODOT_BIN=/bin/sh bash "$runner" --timeout 5 --lock-wait 2 -- -c 'exit 0'

save_root_probe="$tmp_dir/save-root.txt"
GODOT_BIN=/bin/sh bash "$runner" --timeout 5 --lock-wait 2 -- \
  -c 'printf "%s" "$HOME" > "$2"' probe res://tests/probe.gd "$save_root_probe"
[[ -s "$save_root_probe" ]] || {
  echo "FAIL: test invocation did not receive an isolated HOME"
  exit 1
}
[[ "$(cat "$save_root_probe")" != "$HOME" ]] || {
  echo "FAIL: test invocation inherited the player's HOME"
  exit 1
}
echo "SAFE GODOT RUNNER TESTS: PASS"
