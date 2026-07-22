# Municipal Towmaster production boss

```yaml
work_id: WCB-007
target: Municipal Towmaster combat, phase, arena-state, and defeat presentation
baseline_revision: cf8c5d5906d7431d0be674dae794122ea3c697de
canonical_views:
  - rain_city_towmaster at 1280x720
  - rain_city_towmaster at 1024x768
gameplay_readability: warm red/orange attack telegraphs, cyan active weak point, distinct lane/locked-zone/ring geometry, shape-plus-color state communication
silhouette_goal: preserve the project-original armoured tow vehicle, citation vault, tow fork, warning bar, and two escorts as a dominant harbour-pier threat
visual_story: an officious municipal towing convoy escalates from targeted paperwork bombardment to a tow-lane sweep and an impound pulse before collapsing into a ten-second ticket-and-sparks wreck payoff
palette: Rain City slate and harbour green environment; painted municipal orange; warm threat red; cyan weak points; cream ticket debris
value_hierarchy: active attack telegraph and weak point first, Towmaster silhouette second, recovery lane third, harbour landmark support last
materials: existing manifested Municipal Towmaster six-batch GLB; Godot-authored unshaded bounded VFX only
lighting_and_fog: phase warning lights escalate without adding shadows or flattening threat/background separation
animation_or_state_vocabulary: idle convoy, attack telegraph, attack resolve, four phase states, two arena states, module break, ordered ten-second defeat milestones, persistent wreck
platform_budgets: Compatibility renderer; no dynamic shadows; <= 6 actor-owned temporary hazard visuals; <= 48 combined ticket/spark particles; no unbounded timers/audio voices; Web-safe primitive VFX
source_and_license: existing project-original Blender source and GLB already manifested; WCB-007 adds no Blender-derived asset and makes no fresh Blender validation claim
owned_paths:
  - scenes/set_pieces/citation_convoy.tscn
  - scripts/level/citation_convoy_actor.gd
  - scripts/level/rain_city_convoy_presentation.gd
  - scripts/level/towmaster_*.gd
  - resources/set_pieces/vancouver_citation_convoy.tres
  - resources/set_pieces/vancouver_convoy_phases/
  - resources/set_pieces/towmaster_*
  - tests/integration/rain_city_convoy_boss_test.gd
  - tools/visual_quality/capture_manifest.json
  - scripts/debug/visual_direct_capture.gd
  - tests/unit/visual_capture_manifest_test.gd
  - docs/design/rain-city-towmaster.md
preserved_gameplay_contracts: four 250-HP modules in canonical order; four external harbour waves; exact 1000-HP budget; one completion callback; pre-boss checkpoint restart; completed wreck restore; route collision/navigation ownership; secret-reduced reinforcement
acceptance_evidence: typed profile validation; actor attack/arena/defeat contract; 100-cycle soak; route/mission/checkpoint/core tests; native 16:9 and 4:3 captures; packaged Web/macOS validation
human_review_questions: silhouette dominance, telegraph fairness, phase readability, recovery-lane usability, defeat spectacle, humor, motion comfort, photosensitivity, mix
out_of_scope: new Blender authoring/export, new audio assets or final mix, route geometry/navigation, new summons/enemy families, reward/economy breadth, release badge changes
```

## Combat contract

The Towmaster owns three attack families with different defensive answers:

1. **Citation barrage** locks a target position; leave the marked zone before resolve.
2. **Tow sweep** locks a directional lane; sidestep outside its width.
3. **Impound pulse** expands around the convoy; create distance beyond its radius.

Phase zero uses the barrage. Phase one adds the tow sweep and activates citation-lane arena state. Phase two adds the impound pulse and activates the impound-field arena state. Phase three uses all three with shorter cooldowns and stronger light/VFX escalation. Existing external enemy waves remain separate bounded pressure, not a fourth Towmaster attack.

Arena-state presentation may add persistent telegraph geometry and bounded periodic warning pulses, but it does not create collision, block route lanes, move cover, or own navigation. Active attacks apply damage only after their authored telegraph completes.

## Reset and defeat

Reset destroys the actor and therefore cancels all attack state, temporary visuals, defeat progression, and target references. A fresh actor starts phase zero with no inherited timers or arena state. Completed checkpoint restore spawns one terminal wreck and never re-emits objective completion.

The defeat sequence is a deterministic 10–11 second actor-owned timeline with ordered shutdown, ticket burst, tow-arm collapse, core discharge, and final-settle milestones. Reduced flashes suppress the bright discharge; reduced motion suppresses tilt/collapse transforms while preserving captions, state, and completion timing.

## Evidence boundary

Automated tests can prove phase/attack/arena contracts, damage geometry, bounds, reset cleanup, milestone order, packaged imports, and capture validity. They cannot approve fairness, drama, humor, perceived weight, audio mix, motion comfort, photosensitivity, or whether the silhouette is clearly better at ordinary play distance.
