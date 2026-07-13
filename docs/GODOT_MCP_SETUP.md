# Godot MCP operating guide

The selected local bridge is the audited project fork at <https://github.com/Louisleh/godot-mcp>, branch `codex/cobie-hardened-e71540f`, pinned to `87ece143e3fedb494dd13494c35f120d6fb0a8d7` from upstream base `e71540f8985e123a0fe6f977dc531aa10ea5bb3a`. It won the three-candidate bakeoff and was then hardened to cover Godot 4.7 run/stop, bounded live node/property inspection, InputMap press/hold/release, raw keyboard input, pointer input, screenshots, pause state, output, and engine errors. The fork passes 148 tests, TypeScript build, and `npm audit --omit=dev` with zero known vulnerabilities.

## Health and startup

```bash
cd "/Users/louislehmann/Documents/Louis Lehmann Homepage/cobie-nukem"
bash tools/game_dev_health.sh
/opt/homebrew/bin/godot --editor --path .
```

Codex discovers the MCP as `godot-cobie` in `~/.codex/config.toml`, using localhost port `6550`. The editor addon is privileged and is copied/enabled only for an active live-inspection session. Inspect editor stdout alongside MCP error results; a bridge-reported empty error list never overrules an `ERROR:` line from Godot.

The reproducible Cobie bake-off is stored in the tool fork as `scripts/cobie-live-bakeoff.mjs`. It proves the complete title → menu → level-select → Salmon Creek route, live player/enemy/pickup state, movement, weapon input, pause/resume, screenshots, and a zero-error result. Raw title/menu activation uses `godot_runtime_tap_key`; `godot_runtime_tap_action` is reserved for InputMap-driven gameplay because a synthetic action is intentionally not equivalent to a raw physical UI event.

## Shutdown and removal

1. Stop the running scene through the bridge.
2. Disable the temporary editor addon.
3. Remove `addons/godot_ai_bridge` and any bridge autoload/plugin entry.
4. Quit the editor and confirm `git status` contains no editor normalization.
5. Run `bash tools/game_dev_health.sh`, then the focused tests.

`tools/release_validate.sh` refuses to parse or export while the bridge exists. It also scans produced PCKs for bridge, debug-gallery, evidence, pilot-source, and local-path markers.

## Troubleshooting

- Port idle: start the Godot editor and explicitly enable the audited addon for the session.
- Deferred-message/progress-dialog errors: use the hardened local fork and keep editor stdout visible.
- Repository changed after inspection: review every editor-written scene/project diff; never accept bulk normalization blindly.
- Bridge health uncertain: remove it and continue through the native CLI loop. MCP convenience is never a release dependency.
