#!/usr/bin/env bash
set -u

# Serialize Godot access to this project and make every invocation bounded.
# Godot's editor/import state is not safe to mutate from multiple local
# processes, and abandoned headless tests otherwise survive a cancelled agent
# turn with their output pipes blocked.

usage() {
  echo "Usage: $0 [--timeout SECONDS] [--lock-wait SECONDS] -- GODOT_ARGS..."
}

timeout_seconds="${GODOT_RUN_TIMEOUT_SECONDS:-300}"
lock_wait_seconds="${GODOT_LOCK_WAIT_SECONDS:-120}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      timeout_seconds="$2"
      shift 2
      ;;
    --lock-wait)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      lock_wait_seconds="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

case "$timeout_seconds" in
  ''|*[!0-9]*) echo "ERROR: --timeout must be a positive integer"; exit 2 ;;
esac
case "$lock_wait_seconds" in
  ''|*[!0-9]*) echo "ERROR: --lock-wait must be a non-negative integer"; exit 2 ;;
esac
[[ "$timeout_seconds" -gt 0 ]] || { echo "ERROR: --timeout must be greater than zero"; exit 2; }

project_root="$(cd "$(dirname "$0")/.." && pwd -P)"
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot executable not found. Set GODOT_BIN."
  exit 1
fi

project_key="$(printf '%s' "$project_root" | cksum | awk '{print $1}')"
lock_dir="${TMPDIR:-/tmp}/cobie-godot-${UID:-$(id -u)}-${project_key}.lock"
lock_started="$(date +%s)"
lock_acquired=0
child_pid=""
watchdog_pid=""
timed_out_file="${TMPDIR:-/tmp}/cobie-godot-timeout-$$"
run_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/cobie-godot-run.XXXXXX")"
is_test_run=0
has_log_file=0
is_godot_bin=0
case "$(basename "$GODOT_BIN")" in
  *[Gg]odot*) is_godot_bin=1 ;;
esac
for argument in "$@"; do
  case "$argument" in
    res://tests/*) is_test_run=1 ;;
    --log-file) has_log_file=1 ;;
  esac
done
if [[ "$is_test_run" -eq 1 ]]; then
  # Automated runs must never read or overwrite a player's real Continue slot.
  if [[ "${GODOT_TEST_USE_REAL_HOME:-0}" == "1" ]]; then
    # Rendered macOS runs need the real Metal/OpenGL shader-cache location, but
    # SaveManager still receives an isolated slot root.
    export COBIE_TEST_SAVE_ROOT="$run_temp_dir/saves"
  else
    mkdir -p "$run_temp_dir/home"
    export HOME="$run_temp_dir/home"
    export XDG_DATA_HOME="$run_temp_dir/home/.local/share"
    mkdir -p \
      "$XDG_DATA_HOME/godot/app_userdata/Cobie Nukem- Retro Mayhem 3D" \
      "$HOME/Library/Application Support/Godot/app_userdata/Cobie Nukem- Retro Mayhem 3D"
  fi
fi

kill_descendants() {
  local parent="$1"
  local child
  for child in $(pgrep -P "$parent" 2>/dev/null || true); do
    kill_descendants "$child"
  done
  kill -TERM "$parent" 2>/dev/null || true
}

cleanup() {
  local exit_status=$?
  trap - EXIT INT TERM HUP
  if [[ -n "$watchdog_pid" ]]; then
    kill_descendants "$watchdog_pid"
    wait "$watchdog_pid" 2>/dev/null || true
  fi
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill_descendants "$child_pid"
    sleep 1
    kill -KILL "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  rm -f "$timed_out_file"
  rm -rf "$run_temp_dir"
  if [[ "$lock_acquired" -eq 1 ]]; then
    rm -rf "$lock_dir"
  fi
  exit "$exit_status"
}
trap cleanup EXIT INT TERM HUP

while ! mkdir "$lock_dir" 2>/dev/null; do
  owner_pid="$(sed -n '1p' "$lock_dir/pid" 2>/dev/null || true)"
  if [[ -z "$owner_pid" ]] || ! kill -0 "$owner_pid" 2>/dev/null; then
    echo "WARN: removing stale Godot project lock (owner ${owner_pid:-unknown})"
    rm -rf "$lock_dir"
    continue
  fi
  now="$(date +%s)"
  if [[ $((now - lock_started)) -ge "$lock_wait_seconds" ]]; then
    echo "ERROR: timed out waiting ${lock_wait_seconds}s for Godot project lock"
    echo "Lock owner PID: $owner_pid"
    sed -n '1,3p' "$lock_dir/command" 2>/dev/null || true
    exit 75
  fi
  sleep 1
done
lock_acquired=1
printf '%s\n' "$$" > "$lock_dir/pid"
printf '%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$lock_dir/started_at"
{
  printf 'cwd=%s\n' "$project_root"
  printf 'godot=%s\n' "$GODOT_BIN"
  printf 'args='
  printf '%q ' "$@"
  printf '\n'
} > "$lock_dir/command"

cd "$project_root"
if [[ "$has_log_file" -eq 1 || "$is_godot_bin" -eq 0 ]]; then
  "$GODOT_BIN" "$@" &
else
  "$GODOT_BIN" --log-file "$run_temp_dir/godot.log" "$@" &
fi
child_pid=$!

(
  sleep "$timeout_seconds"
  if kill -0 "$child_pid" 2>/dev/null; then
    : > "$timed_out_file"
    echo "ERROR: Godot exceeded ${timeout_seconds}s; terminating PID $child_pid" >&2
    kill_descendants "$child_pid"
    sleep 2
    kill -KILL "$child_pid" 2>/dev/null || true
  fi
) &
watchdog_pid=$!

set +e
wait "$child_pid"
status=$?
set -e
child_pid=""
kill_descendants "$watchdog_pid"
wait "$watchdog_pid" 2>/dev/null || true
watchdog_pid=""

if [[ -e "$timed_out_file" ]]; then
  rm -f "$timed_out_file"
  exit 124
fi
exit "$status"
