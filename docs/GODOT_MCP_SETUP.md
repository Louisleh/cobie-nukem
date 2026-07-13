# Godot MCP operating guide

The selected local bridge is the audited `alexmeckes/godot-mcp` fork pinned from upstream `e71540f8985e123a0fe6f977dc531aa10ea5bb3a`. It won the three-candidate bakeoff because it alone covered Godot 4.7 run/stop, live tree/state inspection, InputMap press/hold/release, screenshots, and output queries. The local dependency/lifecycle hardening passes 144 tests with zero known npm vulnerabilities.

## Health and startup

```bash
cd "/Users/louislehmann/Documents/Louis Lehmann Homepage/cobie-nukem"
bash tools/game_dev_health.sh
/opt/homebrew/bin/godot --editor --path .
```

Codex discovers the MCP as `godot-cobie` in `~/.codex/config.toml`, using localhost port `6550`. The editor addon is privileged and is copied/enabled only for an active live-inspection session. Inspect editor stdout alongside MCP error results; a bridge-reported empty error list never overrules an `ERROR:` line from Godot.

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
