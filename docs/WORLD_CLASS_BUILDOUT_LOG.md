# World-Class Buildout Log

This is the durable continuation ledger for the Cobie Nukem 3/6/9 quality program. New Hermes, Codex, or human sessions read this file after `AGENTS.md`, `docs/PRD.md` §1.5, and `docs/IMPLEMENTATION_PLAN.md`. Chat history is not a source of truth.

## Current state

- **Program branch:** `hermes/world-class-369-buildout`
- **Baseline source:** `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- **Public baseline declared by roadmap:** `0.11.0-alpha.1-rc1`, gameplay/runtime `3c2de29`
- **Current packet:** WCB-000 — PRD, governance, and continuity (ready to integrate)
- **Last verified packet:** WCB-000 documentation checks passed; integration commit pending
- **Next dependency-safe packet:** WCB-001 — record and close the reproduced Godot 4.7 baseline
- **Toolchain state:** Godot 4.7.1 and matching export templates are installed; automated import, tests, and export validation pass. Optional Blender/MCP production-art tooling remains unavailable and is recorded below.
- **Human-only gates:** target-Mac feel/playthrough, physical iPad, flight stick, art taste, pacing, mix, fairness, humor, motion comfort, photosensitivity

## Milestone dashboard

| Packet | State | Owner | Integrated commit | Verification | Honest boundary |
| --- | --- | --- | --- | --- | --- |
| WCB-000 Governance | READY TO INTEGRATE | Integration/docs | — | Diff/link/syntax checks pass | No gameplay claim |
| WCB-001 Toolchain baseline | NOT STARTED — PRECOMPUTED EVIDENCE ONLY | Architecture | — | Godot 4.7.1 import/tests/exports precomputed after intake | Cannot advance until WCB-000 integrates; optional art MCP tooling is not ready |
| WCB-002 Input ownership | BLOCKED by WCB-001 | Input/player seam | — | — | Remapping not proven at player level |
| WCB-003 Checkpoint invariants | BLOCKED by WCB-001 | Save/mission runtime | — | — | Later-mission restore risk remains |
| WCB-004 Settings/allocation | BLOCKED by WCB-001 | UI + combat | — | — | Runtime defaults/allocation budget unproven |
| WCB-005 Rain City spatial slice | BLOCKED by WCB-002–004 | Level | — | — | Current route remains public BETA |
| WCB-006 Encounters | BLOCKED by WCB-005 | Enemy/encounter | — | — | Human pacing/fairness open |
| WCB-007 Towmaster | BLOCKED by WCB-005 | Boss/presentation | — | — | Human spectacle/fairness open |
| WCB-008 Art/audio identity | BLOCKED by WCB-005 | Visual Foundry/audio | — | — | Human art/mix/humor open |
| WCB-009 RC evidence/selection | BLOCKED by WCB-005–008 | Integration/release | — | — | Human/device gates required |
| WCB-010 Second-mission replication | BLOCKED by WCB-009 | Assigned after selection | — | — | Mission-specific human gates required |
| WCB-011 Release identity/roadmap | BLOCKED by WCB-010 | Integration/release | — | — | Publish only an honest candidate |

## Intake evidence — 2026-07-21

### Repository and deployment

- Canonical source is `Louisleh/cobie-nukem`; website repository contains exported Web artifacts rather than reviewable Godot source.
- Audited source commit was clean at `4dbbe2e8571efec290ed863415a78f09bc970ca9`.
- The public build and audited source identify different gameplay revisions. This is not automatically a defect, but every future RC must make the relationship explicit and byte-verifiable.

### Automated evidence available at intake

- Safe-runner shell suite: PASS.
- Python visual-quality suite: 10/10 PASS in 6.96 seconds under the Hermes Python 3.11 environment.
- Repository CI installs Godot 4.7 and runs release validation.
- Fresh local Godot import/gameplay/release validation: BLOCKED because Godot was not installed.

### Precomputed WCB-001 workstation evidence — 2026-07-21

This evidence was collected while WCB-000 remained the active packet to avoid idle installation time. It does not advance WCB-001 or unblock dependent packets before the WCB-000 integration commit.

- Godot `4.7.1.stable.official.a13da4feb` installed at `/opt/homebrew/bin/godot`.
- Matching 4.7.1 export templates installed under `~/Library/Application Support/Godot/export_templates/4.7.1.stable`.
- `bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit`: PASS, clean asset import/editor exit.
- `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd`: PASS, `PASS: core contract checks`.
- `QA_EXPORTS=1 bash tools/release_validate.sh`: PASS, including packaged export validation; manual UX checklist remains required before release.
- Material Maker 1.7 is installed at `/Applications/Material Maker.app`.
- `bash tools/game_dev_health.sh`: FAIL with four optional production-tool findings: Blender absent, Godot MCP checkout not at the required clean revision, Blender MCP executable absent, and Codex MCP privacy-hardening check incomplete. The same command passed Godot 4.7.1 detection and confirmed no live Godot bridge in the source project. These findings block privileged visual-production tooling claims, not the clean headless Godot import/test/export baseline.
- Homebrew's Blender 5.2.0 cask failed because the official download URL returned HTTP 403. A read-only probe found an official-version mirror, but Blender was not installed from an unverified substitute during this packet.
- Sanitized GPT usage snapshot at 2026-07-21 15:10 PDT: main GPT/Codex 11% used / 89% remaining; GPT-5.3-Codex-Spark 0% used / 100% remaining. The next quota check is due after milestone 2 or before the first large Spark batch.

### Product evidence

- Five campaign missions are publicly selectable; Levels 2–5 retain honest `BETA` gates.
- Deterministic repository inventory at the baseline contains 247 GDScript files, 77 scenes, 228 Resources, six weapon Resource files, four weapon scenes, 24 enemy Resource files, 18 enemy scenes, four mission-preview PNGs, eight Vancouver-named WAV files, and ten Rain City Material Maker source graphs.
- `docs/TEST_EVIDENCE.md`, `docs/RELEASE_0_11_0_ALPHA1_RC1_EVIDENCE.md`, and `docs/evidence/rain_city_stabilization_2026-07-16.md` prove substantial automated/runtime production work while explicitly leaving art cohesion, route clarity, encounter/boss feel, mix, and physical-device approval open. The PRD's qualitative gap statements therefore remain review hypotheses, not machine-certified defects.
- Later mission content inherits several earlier enemy/boss scenes and audio cues. Reuse remains acceptable only when intentional and subordinate to a distinct mission identity.

### Correctness/performance risks entering WCB-001

1. Prove that activated custom input profiles drive the real player, not only diagnostics/storage.
2. Prove checkpoint restore order preserves later-mission progression state.
3. Make options reset reapply runtime quality immediately.
4. Measure and bound per-hit effect allocation/object churn.

## Decisions

### D-WCB-001 — Quality before breadth

Freeze new mission, weapon, enemy-variant, economy, and meta-progression breadth until one mission passes the Rain City vertical-slice gates. Existing public betas remain available and honest.

### D-WCB-002 — Rain City is the default definitive slice

Rain City has the strongest existing secondary-lane and urban-interactivity foundation. It is the default target unless WCB-001–004 evidence shows a lower-risk mission would produce a better 15–22 minute slice. Changing this decision requires a recorded comparison, not conversational preference.

### D-WCB-003 — Evidence classes do not collapse

Automated functional, native rendered, packaged Web, simulated tablet, and human-only evidence remain separate. One class cannot silently satisfy another.

### D-WCB-004 — One writer per owned path

Parallel writers use isolated checkouts and non-overlapping ownership. Integration reviews commit objects and reruns tests. Agents do not merge, stamp, deploy, or claim human evidence.

## Packet entry template

Copy this section for every packet before marking it complete.

```md
## YYYY-MM-DD — WCB-### <title>

- Source commit:
- Owner / writer:
- Acceptance condition:
- Files changed:
- Commands and exact results:
- Evidence and class:
- Review findings:
- Human-only/open claims:
- Integrated commit:
- Next dependency-safe packet:
```

## 2026-07-21 — WCB-000 PRD, governance, and continuity

- Source commit: `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- Owner / writer: GPT-5.6 integration/documentation
- Acceptance condition: the active PRD, dependency order, packet ledger, evidence classes, ownership boundaries, and resume protocol form one non-contradictory source-of-truth stack that survives chat/session compaction.
- Files changed: `AGENTS.md`, `docs/PRD.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/WORLD_CLASS_BUILDOUT_LOG.md`, `docs/PHASE_ROADMAP_PRD.md`, `docs/DECISIONS.md`, `docs/design/README.md`, `.agents/skills/cobie-godot-production/SKILL.md`, `tools/validate_world_class_docs.py`.
- Commands and exact results: `git diff --check` → exit 0; `python3 tools/validate_world_class_docs.py` → `WORLD-CLASS DOCS: PASS`; `/Users/orion/.hermes/hermes-agent/venv/bin/python .agents/skills/cobie-spark-orchestration/scripts/verify_spark_setup.py` → exit 0 and `SPARK SETUP: PASS (6 profiles pinned to gpt-5.3-codex-spark)`; read-only `codex exec --model gpt-5.3-codex-spark -c 'model_reasoning_effort="high"' --sandbox read-only ...` review → PASS with no Blocker/Critical/Major issue; its one timeout-consistency Minor was resolved by rerunning the canonical 300-second command.
- Evidence and class: documentation/source review plus `docs/RELEASE_0_11_0_ALPHA1_RC1_EVIDENCE.md`, `docs/TEST_EVIDENCE.md`, `docs/evidence/rain_city_stabilization_2026-07-16.md`, and `docs/RAIN_CITY_LEVEL2_QA_REPORT.md`; no new gameplay, rendered, browser, device, or human approval claim.
- Review findings: the historical roadmap remains release provenance; §1.5 and this ledger now own current product requirements and execution state respectively.
- Human-only/open claims: all product feel, art taste, pacing, fairness, mix, humor, motion comfort, photosensitivity, and physical-device claims remain open.
- Integrated commit: pending.
- Next dependency-safe packet: WCB-001 baseline closure, followed by WCB-002–004.

## Resume protocol

1. Read `AGENTS.md`, `docs/PRD.md` §1.5, `docs/IMPLEMENTATION_PLAN.md`, and this current-state section.
2. Run `git status --short --branch`; do not overwrite uncommitted work.
3. Confirm the current packet and dependency state above.
4. Inspect its latest commit/diff and rerun the smallest applicable verification before continuing.
5. Update this log before each milestone commit.
6. If context becomes crowded, stop at a describable verified state and resume from this file—not from an inferred chat summary.
