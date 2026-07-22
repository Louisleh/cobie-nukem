#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
SAFE_GODOT_RUNNER="${SAFE_GODOT_RUNNER:-tools/run_godot_safe.sh}"
if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot 4.7 executable not found. Set GODOT_BIN."
  exit 1
fi
if [[ "$($GODOT_BIN --version)" != 4.7.* ]]; then
  echo "ERROR: release validation requires Godot 4.7 stable."
  "$GODOT_BIN" --version
  exit 1
fi

# Live-editor automation is privileged development tooling. It is installed only
# for an active local session and must never enter a source or release artifact.
if [[ -e addons/godot_ai_bridge ]] \
  || grep -q 'GodotAIBridgeRuntime\|godot_ai_bridge' project.godot; then
  echo "ERROR: Godot AI bridge is enabled or present. Remove it before validation/export."
  exit 1
fi
if find tmp -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.tres' \) -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR: development Resources under tmp/ would be discovered by Godot and packed. Remove them before validation/export."
  find tmp -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.tres' \) -print
  exit 1
fi

run_godot_test() {
  local script="$1"
  local log_file
  local status
  log_file="$(mktemp)"
  echo "==> $script"
  set +e
  GODOT_BIN="$GODOT_BIN" bash "$SAFE_GODOT_RUNNER" --timeout "${GODOT_TEST_TIMEOUT_SECONDS:-300}" -- \
    --headless --path . --script "$script" 2>&1 | tee "$log_file"
  status=${PIPESTATUS[0]}
  set -e
  if [[ $status -ne 0 ]]; then
    rm -f "$log_file"
    return "$status"
  fi
  if grep -q '^ERROR:' "$log_file"; then
    echo "ERROR: engine errors were emitted by $script"
    rm -f "$log_file"
    return 1
  fi
  if grep -Eq '^SCRIPT ERROR:|ObjectDB instances? (was|were) leaked at exit|resources? still in use at exit|orphan nodes?' "$log_file"; then
    echo "ERROR: script errors, leaks, or orphan nodes were emitted by $script"
    rm -f "$log_file"
    return 1
  fi
  rm -f "$log_file"
}

echo "==> import/parser validation"
GODOT_BIN="$GODOT_BIN" bash "$SAFE_GODOT_RUNNER" --timeout "${GODOT_IMPORT_TIMEOUT_SECONDS:-600}" -- \
  --headless --path . --editor --quit
bash tools/tests/run_godot_safe_test.sh
run_godot_test res://tests/run_tests.gd
run_godot_test res://tests/unit/input_system_test.gd
run_godot_test res://tests/unit/combat_test_runner.gd
run_godot_test res://tests/unit/enemy_contract_tests.gd
run_godot_test res://tests/unit/enemy_sprite_presentation_test.gd
run_godot_test res://tests/unit/enemy_presentation_profile_test.gd
run_godot_test res://tests/unit/navigation_contract_test.gd
run_godot_test res://tests/unit/ui_scene_test.gd
run_godot_test res://tests/unit/asset_contract_test.gd
run_godot_test res://tests/unit/gameplay_foundation_test.gd
run_godot_test res://tests/unit/world_interaction_test.gd
run_godot_test res://tests/unit/interaction_catalog_test.gd
run_godot_test res://tests/unit/save_schema_test.gd
run_godot_test res://tests/unit/run_result_calculator_test.gd
run_godot_test res://tests/unit/campaign_backup_codec_test.gd
run_godot_test res://tests/unit/progression_content_test.gd
run_godot_test res://tests/unit/weapon_mod_applicator_test.gd
run_godot_test res://tests/unit/mobile_controls_test.gd
run_godot_test res://tests/unit/secondary_fire_touch_hud_test.gd
run_godot_test res://tests/unit/imported_audio_contract_test.gd
run_godot_test res://tests/unit/mission_audio_director_test.gd
run_godot_test res://tests/unit/mission_presentation_test.gd
run_godot_test res://tests/unit/rain_city_audio_event_contract_test.gd
run_godot_test res://tests/unit/mission_route_runtime_test.gd
run_godot_test res://tests/unit/mission_spawn_registry_test.gd
run_godot_test res://tests/unit/moving_set_piece_runtime_test.gd
run_godot_test res://tests/unit/moving_set_piece_encounter_coordinator_test.gd
run_godot_test res://tests/unit/external_wave_encounter_test.gd
run_godot_test res://tests/unit/directional_shield_component_test.gd
run_godot_test res://tests/unit/umbrella_shield_enforcer_test.gd
run_godot_test res://tests/unit/compliance_gull_test.gd
run_godot_test res://tests/unit/campaign_progress_runtime_test.gd
run_godot_test res://tests/unit/rain_city_campaign_test.gd
run_godot_test res://tests/unit/rain_city_checkpoint_state_test.gd
run_godot_test res://tests/unit/mission_loadout_profile_test.gd
run_godot_test res://tests/unit/alpha8_resource_contract_test.gd
run_godot_test res://tests/integration/integration_test_runner.gd
run_godot_test res://tests/integration/mission_runtime_contract_test.gd
run_godot_test res://tests/integration/off_leash_mode_test.gd
run_godot_test res://tests/integration/test_episode_1_level.gd
run_godot_test res://tests/integration/salmon_creek_encounter_pacing_test.gd
run_godot_test res://tests/integration/vancouver_content_contract_test.gd
run_godot_test res://tests/integration/vancouver_route_foundation_test.gd
run_godot_test res://tests/integration/vancouver_interaction_catalog_test.gd
run_godot_test res://tests/integration/umbrella_shield_content_test.gd
run_godot_test res://tests/integration/vancouver_mission_host_test.gd
run_godot_test res://tests/integration/rain_city_route_production_test.gd
run_godot_test res://tests/integration/rain_city_convoy_boss_test.gd
run_godot_test res://tests/integration/rain_city_towmaster_combat_test.gd
run_godot_test res://tests/integration/mount_hood_beta_test.gd
run_godot_test res://tests/integration/moon_mission_contract_test.gd
run_godot_test res://tests/integration/ventura_mission_contract_test.gd
run_godot_test res://tests/integration/five_mission_gauntlet_test.gd
run_godot_test res://tests/integration/adversarial_state_test.gd
run_godot_test res://tests/integration/vertical_slice_soak_test.gd
run_godot_test res://tests/smoke/smoke_test_runner.gd
run_godot_test res://tests/smoke/performance_smoke.gd
# The zone profiler is a rendered/native evidence command and is intentionally
# not run headlessly here. See docs/AGENTIC_GAMEDEV_WORKFLOW.md.
bash tools/asset_ip_scan.sh
bash tools/architecture_check.sh
run_godot_test res://tools/validate_content.gd

required_release_paths=(
  docs/PRD.md
  docs/QA_PLAN.md
  docs/ASSET_MANIFEST.md
  docs/KNOWN_ISSUES.md
  export_presets.cfg
  assets/brand/cobie_nukem_cover.png
)
for path in "${required_release_paths[@]}"; do
  [[ -s "$path" ]] || { echo "ERROR required release path missing/empty: $path"; exit 1; }
done

if ! find scenes/menus -type f -name '*.tscn' -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR release requires at least one menu scene."
  exit 1
fi
if ! find scenes/levels -type f -name '*.tscn' -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR release requires at least one playable level scene."
  exit 1
fi

if [[ "${QA_EXPORTS:-0}" == "1" ]]; then
  echo "==> release exports"
  rm -rf builds/web builds/macos
  mkdir -p builds/web builds/macos
  GODOT_BIN="$GODOT_BIN" bash "$SAFE_GODOT_RUNNER" --timeout "${GODOT_EXPORT_TIMEOUT_SECONDS:-900}" -- \
    --headless --path . --export-release Web builds/web/index.html
  GODOT_BIN="$GODOT_BIN" bash "$SAFE_GODOT_RUNNER" --timeout "${GODOT_EXPORT_TIMEOUT_SECONDS:-900}" -- \
    --headless --path . --export-release macOS builds/macos/CobieNukem.zip
  test -s builds/web/index.html
  test -s builds/macos/CobieNukem.zip

  inspect_release_pack() {
    local pack_path="$1"
    local marker
    local forbidden_markers=(
      "godot_ai_bridge"
      "GodotAIBridgeRuntime"
      "production_asset_gallery"
      "vertical_slice_capture"
      "assets/models/pilot"
      "assets/sprites/experiments"
      "docs/evidence"
      "cobie_production_pilot.blend"
      "/Users/louislehmann"
    )
    for marker in "${forbidden_markers[@]}"; do
      if strings "$pack_path" | grep -Fq "$marker"; then
        echo "ERROR forbidden development marker entered release pack $pack_path: $marker"
        return 1
      fi
    done
  }

  inspect_release_pack builds/web/index.pck
  mac_pack_entry="$(unzip -Z1 builds/macos/CobieNukem.zip | grep -E '\.pck$' | head -1)"
  if [[ -z "$mac_pack_entry" ]]; then
    echo "ERROR macOS archive does not contain a PCK"
    exit 1
  fi
  mac_pack_tmp="$(mktemp)"
  unzip -p builds/macos/CobieNukem.zip "$mac_pack_entry" > "$mac_pack_tmp"
  inspect_release_pack "$mac_pack_tmp"
  rm -f "$mac_pack_tmp"
else
  echo "SKIP exports (set QA_EXPORTS=1 for release artifacts)"
fi

echo "Automated release validation passed. Complete docs/MANUAL_UX_CHECKLIST.md before release."
