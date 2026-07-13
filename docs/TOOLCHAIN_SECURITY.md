# Agentic toolchain security

## Trust boundary

- Godot and Blender MCPs are privileged local developer tools capable of file writes and code execution.
- Both bind to localhost; Blender telemetry is disabled.
- No credentials, remote asset keys, external generators, or download services are enabled.
- Third-party revisions and decisions are recorded in `docs/design/agentic-toolchain.md` and `docs/AGENTIC_GAMEDEV_BASELINE.md`.
- The Godot project and typed Resources remain authoritative; editor bridges and generated exports do not.

## Release controls

- The live Godot addon/autoload mechanically blocks validation.
- Source-only Blender files sit below a `.gdignore` boundary.
- Debug galleries, capture runners, pilot runtime exports, and evidence are excluded from both presets.
- PCK inspection rejects known bridge/debug/source/local-path markers.
- Asset provenance and IP filename/source heuristics run in every release matrix.
- `builds/` is ignored and may never become the gameplay source of truth.

## Update policy

Re-audit license, revision diff, dependencies, ports, telemetry, editor/runtime files, arbitrary execution, export behavior, and removal before changing either pinned MCP. Bake off a replacement on a disposable branch; retain exactly one permanent Godot MCP.
