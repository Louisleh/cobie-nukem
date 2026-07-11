# Phase 1–2 Implementation Evidence

Date: 2026-07-11  
Scope: gameplay systems foundation and content-production pipeline  
Godot: `4.7.stable.official.5b4e0cb0f`
Feature revision: `f7631fb`

## Implemented contracts

- Typed difficulty, objective, encounter, and content-manifest Resources.
- Reusable objective and encounter runtime nodes without a new autoload.
- Salmon Creek migration to five manifest encounters and four critical objectives.
- Tactical enemy archetype metadata and ranged/skirmisher spacing behavior.
- Headless content validation and mission-authoring documentation/template.

## Automated evidence

| Gate | Result |
| --- | --- |
| Parser/import | Pass |
| Core/input/combat/enemy/UI suites | Pass |
| Gameplay foundation suite | Pass |
| Integrated combat/persistence/input suite | Pass |
| Complete Salmon Creek route/gates/secrets/finale | Pass |
| Scene/resource smoke | Pass — 53 scenes and 45 Resources |
| Performance stall smoke | Pass — 6.828 ms average, 11.006 ms maximum over 180 headless frames |
| Asset/IP heuristic | Pass |
| Content manifests | Pass — one production manifest |
| Web + Universal macOS exports | Pass |
| Packaged Web acceptance | Pass — stamped `0.3.0-dev` title and live Salmon Creek opening/encounter HUD inspected at 1280×720 |

Command:

```bash
QA_EXPORTS=0 bash tools/release_validate.sh
```

## Development artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.3.0-dev-itch.zip` | 17,639,398 | `0776466a2714d9ae4ac4bce64252213eb80a226cda93ce49b4f4a9840b6d81ac` |
| `cobie-nukem-0.3.0-dev-macos-unsigned.zip` | 67,003,318 | `8d46055af2b7a141bd8a0a77dad0788cf83d3a5e22af149da15fb4d1a200aea6` |

The route test is debug-assisted automation, not a human playthrough. Subjective balance, the full difficulty-selection flow, physical controllers, and a clean human playthrough remain explicit follow-up gates.
