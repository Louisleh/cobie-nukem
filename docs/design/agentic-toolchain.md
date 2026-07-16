# Agentic game-development toolchain

## Boundary

The Godot project and its typed Resources remain the source of truth. MCP servers, editor plugins, Blender working files, generated screenshots, TrenchBroom maps, and optional test frameworks are development inputs. They do not become runtime or release dependencies implicitly.

## Installed local stack

- Godot `4.7.stable.official.5b4e0cb0f` at `/opt/homebrew/bin/godot`.
- `godot-cobie`: local audited Godot MCP, pinned from upstream commit `e71540f8985e123a0fe6f977dc531aa10ea5bb3a`, with dependency and lifecycle hardening applied locally.
- `blender`: Blender MCP pinned from upstream commit `6e99eb5a442b83766a5796975ec7bb5bfc791341`, connected to Blender 5.1.2 on localhost with telemetry and external services disabled.
- Material Maker 1.7 installed locally for editable procedural material graphs and Web-safe PBR exports; it is an authoring tool, not a project dependency.
- Chrome DevTools MCP configured globally with an isolated headless profile, usage statistics disabled, and CrUX disabled. It owns packaged-Web performance traces, heap/network/console inspection, and tablet emulation after a Codex restart.
- Context7 MCP configured globally as documentation-only support. It does not make architecture, art, or asset decisions.
- TrenchBroom 2026.1: available for the isolated FuncGodot pilot only.
- Cobie production and Visual Foundry skills plus focused Godot skills for 3D, navigation, animation, assets, audio, advanced GDScript, review, debugging, optimization, testing, input, mobile, VFX, physics, and responsive UI.

Exact local paths and installation state are machine-local. The repository records decisions and validation evidence, not third-party executable payloads.

## Main loop

1. Establish a clean branch and capture baseline behavior, logs, and metrics.
2. Use repository tests and static inspection before live tooling.
3. Enable the Godot bridge only for an active editor session. Connect, inspect the live tree, run the scene, drive named InputMap actions, capture screenshots, and inspect both runtime and editor process output.
4. Disable and remove the bridge before any headless gate. Confirm `project.godot` and editor-saved scenes did not acquire unrelated normalization changes.
5. Use Blender MCP only for original production assets with an explicit target, polygon/material/LOD/collision budget, deterministic export path, and manifest entry.
6. Run focused tests, then `QA_EXPORTS=1 bash tools/release_validate.sh`.
7. Record evidence and remaining human-only gates in the PRD, known issues, and manual checklist.

For visual production, use `docs/ART_BIBLE.md` and `.agents/skills/cobie-visual-foundry`. Capture the same named view before and after, preserve collision/navigation, store editable sources and provenance, compare at all supported aspect families, and trace the freshly packaged Web build. Automated image metrics catch malformed or surprising output; GPT-5.6 and humans retain visual judgment.

## Required Godot MCP capability gate

The selected bridge must provide:

- Godot 4.7 editor connection and project identity;
- live scene-tree and runtime-state inspection;
- run/stop control;
- press, hold, release, and tap for named InputMap actions;
- pointer/text operations for menu testing;
- viewport screenshots;
- output and error inspection;
- localhost binding;
- no bridge/autoload in exported artifacts.

Capability success is not enough. The editor process output is authoritative: an MCP-reported zero-error count does not overrule an `ERROR:` line printed by Godot.

## Blender security and provenance

- `DISABLE_TELEMETRY=true` is mandatory.
- Poly Haven, Sketchfab, Hyper3D, and Hunyuan integrations remain off unless the owner authorizes a specific source and license.
- Arbitrary Blender Python execution is treated like shell execution.
- Source `.blend` files and exported assets must be named, reviewed, and manifested; temporary validation objects are deleted.

## Export safety

`tools/release_validate.sh` rejects `addons/godot_ai_bridge`, `GodotAIBridgeRuntime`, or a `godot_ai_bridge` editor setting. Generated exports remain ignored. Any future development addon must add an equivalent mechanical exclusion and artifact inspection gate before adoption.
