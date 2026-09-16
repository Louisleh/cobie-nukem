# ENV-2A — pinned Godot bridge and bounded live probe

Date: 2026-09-15 PT. Owner: Astra/Hermes.
Status: **Godot restoration and Hermes registration verified; ENV-2 remains open.**
Game source at start: `74e80ae414227045fb9093bffed8dde1a53ff764`.

## Acceptance and ownership

Restore the previously selected bridge rather than introduce another engine/tool stack. Prove its dependency audit, build/tests, live editor identity/tree, run/stop, named input, runtime inspection and screenshot capture in a disposable project. Keep the canonical game's source, saves and exported runtime free of the bridge.

Owned: `tools/godot_mcp.py`, `tools/godot_mcp_probe.mjs`, `tools/tests/test_godot_mcp.py`, health pin, CI unit step, toolchain docs and this receipt. Machine-local configuration changes touch only the default Hermes `godot_cobie` MCP entry and this project's ignored `.codex/config.toml`; no model or other profile was changed.

## Installed and exercised

- Fork: <https://github.com/Louisleh/godot-mcp/commit/0854fee0974b615297cae52da8beb91d8a37e415>, branch `cobie/env2-dependency-refresh`. Push verified by remote ref readback.
- Checkout: `~/.codex/game-dev-tools/candidates/alexmeckes--godot-mcp`.
- The old July lock had ten advisories including five production advisories. Refresh pins Vitest/coverage to 4.1.11 and refreshes the transitive lock. `npm audit` now reports zero known advisories; this is a dated audit, not a guarantee of security.
- npm 10.9.8's resolver crashed with `edgesOut`. A one-off npm 12.0.2 regenerated the lock without lifecycle scripts; the machine's default npm was not upgraded. `npm ci --ignore-scripts`, `npm test` (148 tests), `npm run build`, and `npm audit` passed.
- Launcher refuses a dirty or wrong-revision checkout and missing build/dependencies. The serve environment excludes inherited credentials/PYTHONPATH. This is not an OS filesystem sandbox.
- Probe creates a fresh synthetic project and isolated HOME/CFFIXED_USER_HOME/XDG state, uses only localhost, checks startup readiness, applies timeouts, tears down owned process groups and removes the scratch project. It writes only a small synthetic screenshot/log receipt, not a gameplay recording.
- Live Godot 4.7.1/Apple M4 Compatibility renderer: editor identity/tree, run, one `ui_accept` input, runtime `taps == 1`, screenshot, zero reported errors, stop/disconnect passed. Entire editor/import logs were checked for errors/leaks as well.
- PNG is exactly 640×360 and was visually inspected: teal fixture with legible “COBIE / TOOLCHAIN PROBE” and “Synthetic fixture - not gameplay”.

The probe waits for `Automation harness ready`, not merely `running:true`; early runtime requests can be lost. Exact viewport dimensions require explicit viewport content scaling; the embedded macOS window otherwise produced 638×359 despite nominal 640×360 settings. Earlier failed probes are not acceptance evidence.

## Agent access

Hermes: `hermes mcp test godot_cobie` connects and discovers the server's 101 native tools. A separate fresh-process call to `discover_mcp_tools(['godot_cobie'])` verified **exactly 12 registered inspection/connection tools**, matching the allowlist. Generated resource/prompt utilities and sampling are explicitly disabled. Arbitrary script execution, mutations and runtime method invocation are not exposed through this default entry. This verifies a fresh process, not a hot reload of the already-running chat/gateway.

Codex: a machine-local, project-scoped `.codex/config.toml` with the same allowlist exists and parses, but `codex mcp get godot-cobie --json` reports no such server, including with an explicit project-trust CLI override. **Do not claim Codex/ChatGPT Desktop integration is live yet.** Resolve the client configuration/discovery behavior in ENV-2B; do not silently broaden global trust or expose all tools as a workaround.

Native editor actions remain on-demand and owner-controlled. The default source tree contains no addon/autoload. This phase does not add a permanently listening editor service.

## Repeatable commands

From the Cobie repo:

```bash
python3 -m unittest discover -s tools/tests -p test_godot_mcp.py -v
python3 tools/godot_mcp.py probe --output /tmp/cobie-godot-probe-NEW
# MCP transport command for clients; speaks stdio, not an interactive CLI:
python3 tools/godot_mcp.py serve
```

Fresh results:
- Godot launcher tests: 8 passed; existing workstation tests: 9 passed.
- `node --check tools/godot_mcp_probe.mjs`: passed.
- Final probe: `/tmp/cobie-env2-godot-final` passed after the final process-ownership refactor.
- `bash tools/architecture_check.sh`: passed.
- Safe-runner headless editor import: passed.
- Safe-runner `res://tests/run_tests.gd`: `PASS: core contract checks`.
- Raw probe logs, MCP result, PNG and source/evidence hashes: [`godot-mcp/`](godot-mcp/).

## Remaining gates / next packet

ENV-2B: finish Codex/ChatGPT host discovery, verify the existing Blender Python asset workflow and decide whether a pinned, telemetry-off local Blender bridge adds value; browser/Material Maker access stays separately evidenced. No successful delegated Blender audit is accepted into this receipt.

ENV-1 heavy-workload reserve remains open: latest free disk is about 14 GiB, below the 20 GiB target. Bounded synthetic probes are not permission for heavy parallel renders/captures. ENV-3 moving gameplay evidence, ENV-4 Rain City art pilot and ENV-5 physical iPhone/iPad acceptance remain open. No fresh full release matrix, public deployment, game visual-quality approval or device acceptance is claimed here.
