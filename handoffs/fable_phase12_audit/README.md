# Fable Phase 1–2 Audit Handoff

## Preferred audit target

Point the auditing agent at the live repository:

`/Users/louislehmann/Documents/Louis Lehmann Homepage/cobie-nukem`

This is preferable to the archive because it includes the current Git history and already-generated local Web/macOS artifacts. The repository should be audited read-only; place findings under `handoffs/fable_phase12_audit/outputs/`.

## Start here

1. `AGENTS.md`
2. `handoffs/fable_phase12_audit/FABLE_AUDIT_PROMPT.md`
3. `docs/PHASE_ROADMAP_PRD.md`
4. `docs/PHASE_1_2_EVIDENCE.md`
5. `docs/ARCHITECTURE.md`
6. `docs/CONTENT_AUTHORING.md`
7. `docs/PRD.md`

## Important implementation areas

- `scripts/gameplay/` — new Phase 1 reusable contracts.
- `resources/content/`, `resources/objectives/`, `resources/encounters/`, `resources/difficulty/` — production data.
- `scripts/level/episode_1_level_1.gd` — Salmon Creek integration and remaining mission-specific logic.
- `scripts/ai/` and `resources/enemies/` — difficulty and tactical-role consumption.
- `tests/unit/gameplay_foundation_test.gd` and `tests/integration/test_episode_1_level.gd` — focused and route coverage.
- `tools/validate_content.gd` and `tools/release_validate.sh` — content/CI gates.

## Commands

```bash
cd "/Users/louislehmann/Documents/Louis Lehmann Homepage/cobie-nukem"
QA_EXPORTS=0 bash tools/release_validate.sh
QA_EXPORTS=1 bash tools/release_validate.sh
SKIP_VALIDATION=1 VERSION=0.3.0-dev bash tools/package_release.sh
```

Packaged Web build, when the existing local server is running:

`http://127.0.0.1:8060/`

## Expected outputs

- `handoffs/fable_phase12_audit/outputs/fable_phase12_audit.md`
- `handoffs/fable_phase12_audit/outputs/issue_inventory.csv`
- `handoffs/fable_phase12_audit/outputs/screenshots/` for visual evidence

Do not edit production code during this audit. A later Codex run will triage and implement verified fixes.
