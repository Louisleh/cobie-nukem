# Cobie Nukem — per-mission art briefs

One brief per mission's bounded visual-production target. A brief is the **front of the
art pipeline**: it locks silhouette, palette, readability, materials, enemy roster, sprite
scale, IP, and platform budget *before* any Blender / Material Maker / capture work begins.

**Read these first:** `EPISODE_VISUAL_ORCHESTRATION.md` (the L1→L5 cohesion contract,
persistent-kit lock, per-level asset checklist/to-do list, and the ImageGen prompt kit),
`docs/ART_BIBLE.md` (global direction, mission identity rows, the
`Sprite3D.pixel_size = intended_world_height / opaque_frame_height` contract, prohibited
placeholder treatments), and the `cobie-visual-foundry` skill
(`.agents/skills/cobie-visual-foundry/SKILL.md` + `references/art-brief-contract.md`).

`EPISODE_VISUAL_ORCHESTRATION.md` is the orchestrator/checklist that ties the per-mission
briefs below into one cohesive visual direction and hands ChatGPT/ImageGen + Blender + Codex
a concrete, ordered to-do list.

| Brief | Mission | Status |
| --- | --- | --- |
| `rain_city_run.yaml` | 2 — Rain City Run | In production (public BETA) |
| `mount_hood_summit.yaml` | 3 — Off-Leash Summit | **Ready — active buildout**; grounded in the PRD Mission 3 brief |
| `moon_fetch.yaml` | 4 — One Giant Fetch | Ready; grounded in the PRD Mission 4 brief |
| `ventura_pier.yaml` | 5 — Ventura Pier | **Design-gated** — ART_BIBLE identity is locked, but route/mechanic/enemy/boss are proposals needing owner ratification (see the SPEC GAP block in the file) |

## How these were authored (2026-07-17, Fable pass)

Design/direction artifacts only — no binary assets were generated. This environment has no
Blender, Material Maker, or diffusion model, so per the visual-foundry skill the correct
deliverable is the briefs themselves; Blender owns final directional renders and Material
Maker owns surfaces downstream. Each brief conforms to `art-brief-contract.md`, names its
`docs/ART_BIBLE.md` identity row, and adds the enemy-roster / prop / ground-surface detail
needed to start production.

## Cross-cutting rules every brief inherits

- **Sprite scale is gameplay data.** One fixed 8×4 atlas grid, one feet baseline, and
  `pixel_size = intended_world_height / opaque_frame_height` — never re-tuned per device.
  (This is exactly the contract whose absence produced the tiny-robot-dog and tiny-boss
  bugs; the briefs state each enemy's intended world height so it can't recur.)
- **No flat slabs with invisible damage.** The art bible explicitly prohibits them; the
  Salmon Creek and Rain City hazard clean-ups came from that anti-pattern. New hazards must
  be telegraphed and readable.
- **Identity over recolor.** Each mission must be recognizable from an unlabelled
  screenshot; a later level may not read as a recolored Salmon Creek.
- **Reuse, don't fork.** New bosses/set pieces reuse the MovingSetPiece + multi-phase boss
  vocabulary; new support enemies can be mesh-primary like the Compliance Gull.
- **IP-original, provenance-complete.** Real places are evoked through original silhouettes
  and fictionalized signage; every committed asset gets an ASSET_MANIFEST entry + hash and
  must pass `tools/asset_ip_scan.sh`.
