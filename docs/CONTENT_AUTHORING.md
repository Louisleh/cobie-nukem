# Content Authoring Guide

This guide is the practical companion to `docs/PHASE_ROADMAP_PRD.md`. Shared gameplay behavior lives in `scripts/gameplay`; mission-specific geometry and narrative remain in `scripts/level` and `scenes/levels`.

## Mission skeleton workflow

1. Pick a stable level ID such as `episode_1_vancouver_waterfront`.
2. Create the level scene and a `LevelMetadata` Resource.
3. Create objective Resources under `resources/objectives`.
4. Create one encounter Resource per activation zone under `resources/encounters`.
5. Create a manifest under `resources/content` referencing the level, supported difficulties, objectives, and encounters.
6. Run `godot --headless --path . --script res://tools/validate_content.gd`.
7. Add a route integration test proving every required gate can be reached and completed in order.

## Encounter schema

Each spawn dictionary contains exactly:

```gdscript
{
    "scene": "res://scenes/enemies/example.tscn",
    "position": Vector3(0, 0, -10),
}
```

Use one stable encounter ID and one activation zone ID. Empty encounters and missing scene paths fail validation. `EncounterRunner` guarantees one-shot zone activation, assigns the player target through `set_target`, and emits lifecycle signals for UI, audio, metrics, and mission logic.

## Objective schema

An objective requires an ID, display title, kind, target ID, count, and optional prerequisite IDs. Record progress with the semantic event—not UI copy:

```gdscript
tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"waterfront_power")
```

The tracker ignores events whose prerequisites are incomplete, makes completion idempotent, and exposes a primitive-only snapshot. Do not use scene node names as progression IDs unless the name is deliberately stable.

## Difficulty

Enemy definitions contain base balance. `DifficultyProfile` applies independent health, damage, speed, aggression, pickup, and aim-assist multipliers. Never create separate enemy scenes solely for difficulty. If a mission needs a genuinely different enemy, create a distinct enemy definition and ID.

## Critical-path checklist

- The required key/item spawns before its gate.
- The item has a collision shape, stable floor position, and progression owner.
- A missed Area3D event has a spatial or explicit-interaction recovery path when appropriate.
- Required encounter completion cannot depend on an optional enemy.
- A boss failure cannot leave the finale permanently disabled.
- Checkpoint payloads contain stable IDs and primitives only.
- Every secret is optional and cannot consume a required item.
- New props and references are recorded in `docs/ASSET_MANIFEST.md`.

## Mission 2 production proof (authored, locked)

The Mission 2 skeleton now exists as real content and validates in CI without any change to shared gameplay code — the Phase 2 scaling proof:

- Manifest: `resources/content/vancouver_waterfront_manifest.tres` (`episode_1_vancouver_waterfront`)
- Level scene: `scenes/levels/vancouver_waterfront_graybox.tscn` — a non-public graybox of the five-zone route; it is not routed by any card and must stay that way until production
- Objectives: `resources/objectives/vancouver_*.tres` — `reach_waterfront` → `restore_terminal` → `stop_citation_convoy` → `complete_harbour_pier`
- Encounters: `resources/encounters/vancouver_*.tres` — one per zone (`downtown_alley`, `ruse_block`, `waterfront_seawall`, `terminal_service`, `harbour_pier`) with placeholder spawn groups drawn from existing enemy scenes
- Level card: `resources/level/rain_city_card.tres` stays locked with an empty `scene_path`; `ui_scene_test` enforces exactly one unlocked card and `gameplay_foundation_test` enforces the manifest/card contract

The harbour-pier encounter is a placeholder for the citation-convoy set piece; split it into explicit waves only after the runner gains multi-wave schema support.

### Mission 2 asset and landmark list (all original art; no copied logos, trade dress, or map geometry)

- Rain-soaked downtown service alley: dumpsters, fire escapes, puddle decals, steam vents, bike-lane markings
- Ruse block: an affectionate original **Ruse Pizza** storefront — pizza boxes, "RUSE SLICE / DOGS NEGOTIABLE" poster, delivery scooter, optional health-secret slice; confirm naming permission before public commercial distribution
- Waterfront seawall: railings, benches, gulls, umbrellas, stylized North Shore mountains and an original distant bridge silhouette skybox
- Terminal service corridors: cargo containers, harbor cranes, floatplane/ferry silhouettes, emergency leash-protocol signage
- Harbour pier finale: citation convoy vehicles, pier lighting, rain-slick neon reflections
- Posters: "RAIN DELAYED DUE TO RAIN", "SEAWALL SPEED LIMIT: ZOOMIES", "NO FETCHING FROM THE HARBOUR"
- New mechanic target: vertical combat across stairs/ramps/seawall levels; new enemy family target: umbrella shield unit or gull recon support

The detailed location, prop, poster, Easter-egg, and legal notes live in `docs/PHASE_ROADMAP_PRD.md` section 6.
