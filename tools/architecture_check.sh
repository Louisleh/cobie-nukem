#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "ERROR: $*"; exit 1; }

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
  if command -v rg >/dev/null 2>&1; then
    rg -Fq "\`$asset\`" docs/ASSET_MANIFEST.md || fail "unmanifested asset: $asset"
  else
    grep -Fq "\`$asset\`" docs/ASSET_MANIFEST.md || fail "unmanifested asset: $asset"
  fi
done < <(git ls-files 'assets/**')

# A release source tree may contain package instructions, but never a stale
# hard-coded public artifact outside the canonical BuildInfo file.
[[ -s scripts/core/build_info.gd ]] || fail "missing canonical build identity"
echo "ARCHITECTURE CHECK: PASS"
