#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "ERROR: $*"; exit 1; }

manifest_has() {
  if command -v rg >/dev/null 2>&1; then
    rg -Fq "\`$1\`" docs/ASSET_MANIFEST.md && return 0
  else
    grep -Fq "\`$1\`" docs/ASSET_MANIFEST.md && return 0
  fi
  while IFS= read -r pattern; do
    [[ "$1" == $pattern ]] && return 0
  done < <(grep -oE '`glob:[^`]+`' docs/ASSET_MANIFEST.md | sed 's/^`glob://; s/`$//')
  return 1
}

# Generated exports are deployment artifacts, never source-of-truth inputs.
if git ls-files builds | grep -Eq '\.(html|wasm|pck|zip|dmg)$'; then
  fail "generated build artifact is tracked under builds/"
fi

# New production scripts must stay reviewable. The legacy Salmon Creek
# orchestrator is temporarily exempt while issue #2 extracts its duties.
while IFS= read -r script; do
  [[ "$script" == "scripts/level/episode_1_level_1.gd" ]] && continue
  lines=$(wc -l < "$script" | tr -d ' ')
  [[ "$lines" -le 500 ]] || fail "$script has $lines lines (limit 500)"
done < <(find scripts -type f -name '*.gd' | sort)

# Every committed source asset needs a provenance row. Godot import metadata is
# derived and intentionally excluded.
while IFS= read -r asset; do
  [[ "$asset" == *.import ]] && continue
  manifest_has "$asset" || fail "unmanifested asset: $asset"
done < <(git ls-files 'assets/**')

# Gameplay callbacks must be owned by a node that disappears with the scene.
# SceneTreeTimer continuations can resume after their actor or captured locals
# are freed, producing teardown errors and state changes in the next scene.
if rg -n 'get_tree\(\)\.create_timer' scripts >/tmp/cobie-unowned-timers.txt; then
	cat /tmp/cobie-unowned-timers.txt
	rm -f /tmp/cobie-unowned-timers.txt
	fail "gameplay scripts contain unowned SceneTreeTimer callbacks"
fi
rm -f /tmp/cobie-unowned-timers.txt

# A release source tree may contain package instructions, but never a stale
# hard-coded public artifact outside the canonical BuildInfo file.
[[ -s scripts/core/build_info.gd ]] || fail "missing canonical build identity"
echo "ARCHITECTURE CHECK: PASS"
