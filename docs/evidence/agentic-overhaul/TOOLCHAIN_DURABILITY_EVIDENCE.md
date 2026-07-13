# Toolchain durability evidence — 2026-07-13

## Audited Godot MCP fork

- Repository: <https://github.com/Louisleh/godot-mcp>
- Branch: `codex/cobie-hardened-e71540f`
- Revision: `87ece143e3fedb494dd13494c35f120d6fb0a8d7`
- Upstream base: `e71540f8985e123a0fe6f977dc531aa10ea5bb3a`
- Verification: 148/148 Vitest cases, TypeScript build, zero `npm audit --omit=dev` vulnerabilities.
- Shutdown verification: no attributable ObjectDB/resource leak after synchronous bridge teardown.

The checked-in tool-fork script `scripts/cobie-live-bakeoff.mjs` was run against Cobie source `749aa42171f9f2e92f9456ac707bc36893430bb9` with Godot `4.7.stable.official.5b4e0cb0f`. It completed 44 MCP operations and verified:

- title readiness and raw-key dismissal;
- main-menu and level-select navigation;
- Salmon Creek launch;
- one grounded player and a position change from Z `10.0` to `6.3472` after 30 movement frames;
- three opening enemies with live health/state/definition data;
- ten live, monitoring pickups with runtime position and availability data;
- weapon-next, fire, and reload actions;
- pause `false → true → false`;
- zero Godot errors from runtime, script, and log sources.

Six screenshots were captured outside the source repository. Their SHA-256 values are:

| Capture | SHA-256 |
| --- | --- |
| title ready | `e98a704f9ea723090f41aee56e1204f3f2fb56f3ced585b0c1c27d8e8516ad0a` |
| main menu | `b1a3403c148dafa552887c822da3eb533db33be888055ec93119e98f89385cbf` |
| level select | `5b7f4d5ae85a9e8a7b42e07b89b40d622f0974b8aef4d6c96d42df4da3cb5955` |
| Salmon Creek | `156dab0a0d2858e49487aa187b4896e6edf9ba8e048e43decd6724d20a0cf2b9` |
| weapon fired | `93e7335d7009a34fba2542aa9994950a5e29c4a8fff9dde4eed6f178eb22917e` |
| paused | `2727abdae4544995600a8360fe2f333c1664da90033353676b0112ef248ba50b` |

The temporary addon/autoload/plugin entries were removed after the run, editor-written project normalization was reversed, and the source repository returned to a clean state before this evidence branch was created.

## Clean-task skill discovery

A no-hardlink clean clone at source revision `749aa42171f9f2e92f9456ac707bc36893430bb9` was opened by an ephemeral Codex task in read-only mode with no conversation history. The prompt explicitly required `cobie-godot-production`, prohibited edits/installs/GUI startup, and requested repository orientation plus the health check.

The task independently:

- loaded the full skill and `references/production-loop.md`;
- identified Godot 4.7 stable and the Compatibility renderer;
- located the canonical import, test, release, and export commands;
- ran only `bash tools/game_dev_health.sh`;
- preserved a clean clone and correctly reported the remaining human-only gates.

This proves the project workflow is discoverable by a fresh task rather than depending on the original implementation conversation. The run also surfaced an unrelated connector reauthorization warning; it did not affect local skill discovery or repository checks.

A second ephemeral clean-clone task at source `497bfcf140f2fc1f6871741f39fa09d79b9dc783` used workspace-write only so Godot could create ignored import state. It independently read the skill, its full production-loop reference, `AGENTS.md`, PRD, architecture/toolchain, build, and MCP-removal contracts; verified the bridge guard before launching Godot; found the exact 4.7 stable executable; ran health/import validation; and executed the repository-documented bounded native launch. The Codex task exited successfully, left the Git worktree clean, installed nothing, and made no source edits. This closes the clean-task launch requirement that the earlier read-only orientation test intentionally did not exercise.
