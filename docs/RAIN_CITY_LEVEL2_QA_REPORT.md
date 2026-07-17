# Rain City Run (Mission 2 / Vancouver Waterfront) — QA & Design Report for Codex

**Author:** Fable (Claude) implementation/QA pass
**Date:** 2026-07-16
**Branch prepared from:** `main` @ `a62b27e` (Rain City RC2)
**Level under test:** `episode_1_vancouver_waterfront` — `scenes/levels/episode_1_vancouver_waterfront.tscn`

This report is a continuation point for Codex. It records what was tested, what is confirmed broken or low‑value, and a concrete design menu for replacing the "hot air duct" hazard squares with more interesting objects and challenges. It is **not** a claim of a human playthrough — all findings below are from automated headless tests, code/resource inspection, and headless sprite/geometry diagnostics.

---

## 1. How it was tested

All on Godot 4.7.stable (Linux headless), from repo root:

| Suite | Result |
| --- | --- |
| `tests/integration/vancouver_content_contract_test.gd` | **PASS** |
| `tests/integration/vancouver_interaction_catalog_test.gd` | **PASS** |
| `tests/integration/vancouver_route_foundation_test.gd` | **PASS** |
| `tests/integration/vancouver_mission_host_test.gd` | **PASS** |
| `QA_EXPORTS=0 bash tools/release_validate.sh` (full non‑export gate) | **PASS** |
| Headless sprite/geometry diagnostic on Vancouver enemies + convoy boss | see §4 |

**Interpretation:** the level is *contract‑valid* — routes, gates, checkpoints, encounters, the interaction catalog, save/continue rehydration, and the convoy set piece all pass their deterministic tests. Every issue below is therefore about **readability, feel, and value**, not a broken system. These are exactly the things the automated gate cannot see and that a human (or this kind of design review) has to catch.

**Route/structure as built** (from `vancouver_waterfront_world_builder.gd`, world runs from roughly `z ≈ +10` to `z ≈ -175`):

1. `downtown_alley` — rainy service alley, fire escapes, dumpster, steam vent (start).
2. `ruse_block` — Rain City Slice pizza frontage (warm interior beat).
3. `waterfront_seawall` — lower promenade + **upper glass‑canopy lane** reached by a ramp (the one real vertical‑combat beat).
4. `terminal_service` — enclosed terminal with an elevated control booth / control loop.
5. `harbour_pier` — broad boss arena; the **Citation Convoy / Municipal Towmaster** 4‑phase moving set piece finale (`stop_markers = [0.22, 0.51, 0.75, 0.94]`, phases: appeal_filed → appeal_denied → final_notice → case_closed).

**Enemy budget (26 total):** downtown 3, ruse 4, seawall 6, terminal 5, harbour 8 — a clean escalation. Archetypes: Squirrel Trooper, Leash Enforcement Drone, Umbrella Shield Enforcer, Compliance Gull (mesh‑based, searchlight), Compliance Hound, Mutant Groundskeeper.

---

## 2. PRIORITY FIX — Remove the "hot air duct" hazard squares

There are **three** `HAZARD_ZONE` (kind `2`) interactions in Rain City. Each is auto‑visualized by `WorldInteraction._ensure_visual_if_empty()` as a **flat matte `BoxMesh`** (height ≈ 0.2 m) in a dull beige/grey — i.e. the same "random slab on the floor" that was already removed from Salmon Creek after the last iPad playtest. They deal silent tick damage with no telegraph, particles, or warning colour. This is the "hot air duct square" the owner flagged.

| Definition id | Placement id | Zone | World position | Slab size | Colour | Damage | Dead "prompt" |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `downtown_hazard_fogline_01` | `placement_downtown_hazard_fogline_01` | downtown_alley | `(5.4, 0.45, -15.4)` | `3.4 × 0.2 × 2.2` | beige `#E8C396` | 6.5 / 0.7s, r2.2 | "VENT THE FISHGAS" |
| `waterfront_hazard_marine_pipe_01` | `placement_waterfront_hazard_marine_pipe_01` | waterfront_seawall | `(10.4, 0.45, -79.1)` | `4.1 × 0.22 × 2.6` | pale blue‑grey `#B5CBD1` | 5.5 / 0.65s, r2.4 | "AIM FOR THE WIND" |
| `harbour_hazard_gasline_01` | `placement_harbour_hazard_gasline_01` | harbour_pier | `(13.3, 0.45, -141.7)` | `3.8 × 0.2 × 2.8` | beige `#F2C79F` | 5.0 / 0.8s, r2.4 | "FLUSH THE DUCT" |

**Why they're low‑value / bad, specifically:**

1. **They read as scenery, not danger.** A flat 0.2 m beige box on the floor looks like a loading dock plate or a patch of pavement — nothing signals "stand here and you lose health." All damage feedback is off‑screen (the HUD number ticking down), so it feels like random/unfair chip damage.
2. **Their authored prompts are dead data.** `WorldInteraction.get_interaction_label()` returns `""` for `HAZARD_ZONE` and `interact()` returns `false`. So "VENT THE FISHGAS", "AIM FOR THE WIND", and "FLUSH THE DUCT" **never appear and can never be triggered** — the names imply an interaction that does not exist. Misleading for both players and future authors.
3. **They're off the critical path** (`x = 5.4 / 10.4 / 13.3`, all to one side of ≥20 m‑wide floors). So most of the time they do nothing, and when a player wanders into one it's a confusing "why am I taking damage" moment. Low value either way.
4. **No telegraph or rhythm.** Constant aura damage with no on/off cycle is the least interesting hazard shape possible — you can't outplay it, only avoid a zone you can't see.

**Removal is clean.** Each affected zone currently holds **4** interactions and the density contract (`required_zone_minimums`, enforced by `interaction_catalog_test`) requires **≥3 per zone**. Removing the three hazard placements leaves downtown/seawall/harbour at exactly 3, so **no replacement is strictly required to stay green**. (This is different from Salmon Creek, where hazards had to be *converted* to keep density.)

**Recommended action for Codex (pick one):**

- **Option A — delete outright.** Remove the three `Placement*Hazard*` entries and the three `*HazardA` sub‑resources from `resources/interactions/vancouver_waterfront_interactions.tres`; fix `load_steps` and the `placements` array. Zones stay at 3. Simplest; fully honours "remove that."
- **Option B — replace with something interesting** (preferred — see §3). Convert each hazard placement to a better object so the zones stay rich, using the design menu below. Keep the ≥3 density and add real value.

Either way: also **do NOT leave the dead prompt strings** on any hazard that survives elsewhere, and consider fixing the shared root cause in §5.

> Note: `terminal_secret_hazard_gate_01` has "hazard" in its name but is a **SECRET_TRIGGER** (kind `4`), not a damage zone — it's a normal breakable secret and should be left alone. Only the three `kind = 2` entries above are the slabs.

---

## 3. Design menu — more interesting objects & challenges for Rain City

The level already builds a lot of unused affordances (an upper seawall lane + ramp, a terminal control loop + booth steps, a pier crane flank + crane masts/arms, a harbour water plane, a delivery scooter, a pizza oven, gull searchlights, chain‑reaction explosives). The best replacements *use geometry that already exists* and lean into the "petty municipal bureaucracy vs. one good dog" comedy. Ordered rough‑cheapest first.

**Cheap, high‑value (reuse existing systems):**

1. **Telegraphed steam/flare hazard (fixes the hazard, keeps the beat).** Keep a `HAZARD_ZONE` but give it a *real* look and rhythm: an emissive vertical steam/electric column + a pulsing floor ring, and an **on/off duty cycle** (e.g. 1.2 s safe → 0.8 s venting) so it becomes a timing challenge you dodge through, not invisible aura chip. Put it in a chokepoint you *want* to cross (e.g. the Rain City Slice delivery window) so it matters. Requires: a `HAZARD_ZONE` visual upgrade (see §5) + an optional `hazard_active_cycle` field on `WorldInteractionDefinition`.
2. **Explosive chain domino.** The explosive prop + `chain_reaction_radius`/`chain_reaction_limit` already exist. Cluster 2–3 "fizzle boxes"/"rebar tangles" next to an enemy cover cluster so one well‑placed Fetch shot chains and clears a pocket. Pure content authoring, no code. Great "aha" moment near the terminal cargo machines.
3. **Awning / sign drop (environmental kill).** Reuse a breakable prop as a *support*: shoot it and drop the Rain City Slice awning (already a prop at `(-5.2, 2.5, -37)`) onto whatever's under it. Author as a breakable whose "break" spawns a one‑shot falling slab + AoE. Thematic and readable.
4. **Searchlight aggro zones (soft hazard).** The Compliance Gull already carries a searchlight cone. Instead of flat damage, make standing in a gull's light *raise combat pressure / call a reinforcement* — a stealth‑ish "stay out of the light" beat that's about positioning, not chip damage. Uses `CombatPressure`, which the level already talks to.

**Medium (small new component, big payoff):**

5. **Swinging/dropping crane load.** The harbour crane masts + arms are already modelled at `(±12/13, ~5–9, -167)`. Add a container that swings along the arm or periodically drops on a telegraph — a moving hazard *and* moving cover on the boss pier. This is the single most "level‑2‑signature" idea and pairs naturally with the convoy finale. Could reuse the `MovingSetPiece` runtime.
6. **Runaway delivery scooter / tow‑cart.** There's a `DeliveryScooter` prop and the whole mission is about a citation *convoy*. A scooter or wheel‑clamp cart that rolls down the seawall ramp toward the player (dodge or shoot to stop) is on‑theme and uses the existing ramp geometry. Reuse `MovingSetPiece` on a short spline.
7. **Wheel‑clamp / tow‑clamp snap trap.** "Parking joy is a towable offence" is literally on a sign. A clamp on the ground that telegraphs then snaps (roots the player briefly / small damage) is funnier and more readable than a beige slab, and reinforces the story.
8. **Rising‑tide timing gate.** The terminal already has a "flood gate" secret and an elevated control loop + booth steps. Turn one stretch into a short "get to high ground before the water rises" beat — the water plane exists as a prop; a timed vertical climb using the already‑built steps would give the seawall/terminal a real traversal identity (the PRD's stated Mission‑2 "vertical combat" pillar).

**Stretch (identity beats):**

9. **Pizza‑oven flare puzzle** at Rain City Slice: the oven vents a readable flame on a beat; time your run past it to grab a health/loot reward behind it. Turns the warm interior into a mini‑challenge.
10. **Optional rooftop secret** via the fire‑escape landings (already modelled at `(-7.1, 2–5.6, -7)`) — a small platforming detour to a 5th secret / upgrade, giving the vertical geometry a reward.

**Guidance for whoever authors these:** keep tuning in the typed `WorldInteractionDefinition` / `MovingSetPieceDefinition` resources (not hard‑coded in the level script), keep each new hazard **telegraphed and readable** (emissive + a clear "shape" that isn't a floor slab), and keep the ≥3‑interactions‑per‑zone density. Prefer 1–2 *memorable* set‑piece objects per zone over many flat props.

---

## 4. Other findings (verified) & things a human still must check

**Verified via headless diagnostic (sprite world sizes, after the merged hound/walker fix in PR #36):**

- **Compliance Hound** (appears in terminal + harbour) was rendering tiny; **already fixed** on `main` (pixel_size corrected, now ~1.4 m). No action.
- **Umbrella Shield Enforcer** sprite ≈ `2.10 × 2.10` m — good.
- **Compliance Gull** is mesh‑based (sphere body + prism wings + searchlight), not a billboard — renders fine, no sizing risk.
- **Citation Convoy / Towmaster** is a vehicle mesh set piece, not a sprite — fine.
- Recommend adding the Gull + Umbrella Enforcer to `enemy_contract_tests.gd` so the new "sprite is not a tiny speck / oversized sheet" guard covers *all* Mission‑2 enemies, not just the original five.

**Flaky CI / test hygiene (found while running this pass):**

- `tests/unit/mission_presentation_test.gd` intermittently leaks at process exit — `2 ObjectDB instances were leaked` + `1 resources still in use at exit`. It passed the full local gate and **5/5** isolated local re-runs cleanly, but failed once in CI. Because `tools/release_validate.sh` was hardened to fail on any `^ERROR:` line, this non-deterministic leak turns into a hard CI failure that can block *any* PR (including docs-only ones) at random. `MissionPresentation` is shared by both missions, so this is worth a real fix: audit `mission_presentation_test.gd` teardown (and `MissionPresentation`'s owned tweens/timers/audio streams) to free everything before `quit()`, mirroring the audio-stop pattern the smoke runner already uses. Not caused by any Rain City content; flagged here because it surfaced during Mission‑2 validation.

**Worth a human eye (cannot be settled headlessly):**

- **Hazard fall risk:** the seawall hazard `(10.4, -79.1)` sits between the promenade and the harbour side; confirm that dodging it doesn't nudge a player toward a rail gap / kill plane. (Geometry check says it's inside the floor, but feel matters.)
- **15–22 min pacing, boss telegraph fairness, convoy "feel", touch comfort, art cohesion, audio mix** — all remain the human/device gates already listed in `docs/KNOWN_ISSUES.md`; nothing here changes that.
- **Signage density:** the comedic signs are great but dense in spots (e.g. three around the pier); a human should confirm they don't crowd the boss read.

---

## 5. Root‑cause cleanup (optional but recommended)

The reason hazards look like "random slabs" in *both* missions is that `scripts/level/world_interaction.gd::_ensure_visual_if_empty()` builds one generic matte `BoxMesh` for every kind. A small, high‑leverage fix: give `HAZARD_ZONE` a distinct generated visual (emissive/translucent warning colour, a low warning ring or a vent column, and optional rising particles) so *any* authored hazard is unmistakable without per‑placement art. If §3 option 1 (duty‑cycled hazards) is pursued, do this at the same time. This also future‑proofs Mount Hood / Moon hazards.

---

## 6. Suggested commit grouping for Codex

- `content: remove Rain City hot-air-duct hazard slabs` (or `...replace with <chosen object>`), updating `vancouver_waterfront_interactions.tres` (+ `load_steps`, placements array, zone density) and `vancouver_interaction_catalog_test.gd` expectations if counts change.
- `feat: readable telegraphed HAZARD_ZONE visual` (if §5 pursued) in `world_interaction.gd` + `world_interaction_test.gd`.
- `feat: <chosen set-piece object>` for the replacement challenge, as a typed resource + reuse of `MovingSetPiece`/`CombatPressure`.
- `test: cover Gull + Umbrella Enforcer sprite sizing` in `enemy_contract_tests.gd`.
- `docs: record Rain City level-2 QA pass` (update `KNOWN_ISSUES.md` interaction counts if they change).

## 7. Definition of done for the follow‑up

- The three `kind = 2` hazard slabs are gone from Rain City (removed or replaced).
- Any surviving hazard anywhere has a readable, telegraphed visual and no dead prompt string.
- Zone density stays ≥3 and all `vancouver_*` suites + `interaction_catalog`/`world_interaction` tests stay green.
- At least one *interesting* physical object or challenge (§3) is added so Mission 2 gains value, not just loses a slab.
- `QA_EXPORTS=0 bash tools/release_validate.sh` passes; the live website is untouched until an owner‑approved release.
