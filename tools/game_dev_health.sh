#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
BLENDER_BIN="${BLENDER_BIN:-/Applications/Blender.app/Contents/MacOS/Blender}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
GODOT_MCP_ENTRY="${GODOT_MCP_ENTRY:-$HOME/.codex/game-dev-tools/candidates/alexmeckes--godot-mcp/dist/index.js}"
BLENDER_MCP_BIN="${BLENDER_MCP_BIN:-$HOME/.local/bin/blender-mcp}"

failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }
info() { printf 'INFO  %s\n' "$1"; }

if [[ -x "$GODOT_BIN" ]] && [[ "$($GODOT_BIN --version)" == 4.7.* ]]; then
  pass "Godot $($GODOT_BIN --version)"
else
  fail "Godot 4.7 is not available at $GODOT_BIN"
fi

if [[ -x "$BLENDER_BIN" ]]; then
  blender_version="$($BLENDER_BIN --version 2>/dev/null | head -1)"
  pass "$blender_version"
else
  fail "Blender is not available at $BLENDER_BIN"
fi

if [[ -s "$GODOT_MCP_ENTRY" ]]; then
  pass "pinned Godot MCP entry exists"
else
  fail "Godot MCP entry missing: $GODOT_MCP_ENTRY"
fi

if [[ -x "$BLENDER_MCP_BIN" ]]; then
  pass "Blender MCP executable exists"
else
  fail "Blender MCP executable missing: $BLENDER_MCP_BIN"
fi

if [[ -s "$CODEX_CONFIG" ]] \
  && grep -q '^\[mcp_servers\.godot-cobie\]' "$CODEX_CONFIG" \
  && grep -q '^\[mcp_servers\.blender\]' "$CODEX_CONFIG" \
  && grep -q '^DISABLE_TELEMETRY = "true"' "$CODEX_CONFIG" \
  && grep -q '^BLENDER_HOST = "localhost"' "$CODEX_CONFIG"; then
  pass "Codex MCP configuration is discoverable and Blender telemetry is disabled"
else
  fail "Codex MCP configuration is missing or not privacy-hardened"
fi

if [[ ! -e addons/godot_ai_bridge ]] \
  && ! grep -q 'GodotAIBridgeRuntime\|godot_ai_bridge' project.godot; then
  pass "no live Godot bridge is enabled in the source project"
else
  fail "a live Godot bridge is present; disable it before validation or export"
fi

if command -v lsof >/dev/null 2>&1; then
  if lsof -nP -iTCP:6550 -sTCP:LISTEN >/dev/null 2>&1; then
    info "Godot MCP port 6550 is currently listening"
  else
    info "Godot MCP port 6550 is idle (normal outside an active editor session)"
  fi
  if lsof -nP -iTCP:9876 -sTCP:LISTEN >/dev/null 2>&1; then
    info "Blender MCP port 9876 is currently listening"
  else
    info "Blender MCP port 9876 is idle (start Blender GUI and enable the local addon when needed)"
  fi
fi

branch="$(git branch --show-current)"
revision="$(git rev-parse --short HEAD)"
if [[ -n "$(git status --porcelain)" ]]; then
  info "repository is dirty on $branch at $revision"
else
  pass "repository is clean on $branch at $revision"
fi

if (( failures > 0 )); then
  printf 'GAME DEV HEALTH: FAIL (%d issue(s))\n' "$failures"
  exit 1
fi
printf 'GAME DEV HEALTH: PASS\n'
