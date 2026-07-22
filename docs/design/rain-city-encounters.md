# Rain City encounter choreography

## Contract

WCB-006 authors encounter intent without adding enemy families or changing shared AI. Rain City uses the existing 26-enemy budget and six existing roles:

| Role ID | Existing actor | Combat function |
| --- | --- | --- |
| `skirmisher` | Squirrel Trooper | Mobile ranged flank pressure |
| `aerial_harrier` | Leash Enforcement Drone | Elevated ranged pressure |
| `melee_pursuer` | Compliance Hound | Forces movement from cover |
| `shield_anchor` | Umbrella Shield Enforcer | Frontal space denial and flank demand |
| `dive_support` | Compliance Gull | Warning/searchlight and committed dive |
| `space_denial` | Mutant Groundskeeper | Slow close-range lane blocker |

Schema-v3 encounters attach a typed `EncounterChoreographyProfile`. Every spawn declares a role and approach. The runner derives current-wave choreography context and tags spawned actors; it does not fork AI logic or serialize redundant context. Existing schema-v2 missions remain compatible.

Automated checks prove declarations, runtime wave/context behavior, bounded resets, and authored geometry references. They do not prove that pacing, fairness, readability, or tactical meaningfulness feels good.

## Downtown Alley — crossing notice

- **Intent:** reveal pressure from both street edges while preserving the opening-center retreat.
- **Roles:** `skirmisher`, `melee_pursuer`, `aerial_harrier`.
- **Approaches:** `alley_left`, `alley_right`, `alley_overhead`.
- **Transition:** `crossing_reveal` on entry.
- **Recovery position:** center of the near alley, before the first encounter gate.
- **Environment choice:** hold the open center for visibility or rotate around the dumpster/crate edge to split pursuit from aerial fire.
- **Counters:** remove the drone sightline, kite the hound through center, then isolate the skirmisher.

## Rain City Slice — patio pinch

- **Intent:** establish storefront crossfire, then reveal a delayed patio reinforcement after the opening trio clears.
- **Roles:** `skirmisher`, `aerial_harrier`, `shield_anchor`.
- **Approaches:** `storefront_left`, `plaza_right`, `patio_rear`.
- **Transitions:** `storefront_watch_reveal`, then `patio_reinforcement`.
- **Recovery position:** open Slice plaza center.
- **Environment choice:** use plaza width to flank the shield or hold storefront cover and break the aerial angle first.
- **Counters:** rotate wide of the shield, prevent the drone from maintaining the upper angle, keep the delayed skirmisher out of the recovery lane.

## Waterfront Seawall — searchlight split

- **Intent:** warn with elevated Gull pressure, anchor the lower promenade, then reinforce from opposite seawall ends.
- **Roles:** `dive_support`, `shield_anchor`, `skirmisher`, `aerial_harrier`.
- **Approaches:** `harbour_side`, `city_side`, `overlook`.
- **Transitions:** `searchlight_warning`, then `overlook_reinforcement`.
- **Recovery position:** lower promenade center with access to both stair entries.
- **Environment choice:** stay low and use benches/crates for line breaks or take `seawall_overlook` to contest aerial support and gain a cross-area angle.
- **Counters:** break Gull telegraphs, flank the shield through a stair loop, and avoid being pinched by the delayed opposite-side wave.

## Terminal Service — control-room reversal

- **Intent:** lock the cargo floor with melee/shield/skirmisher pressure, then reposition aerial actors around the control loop.
- **Roles:** `melee_pursuer`, `shield_anchor`, `skirmisher`, `dive_support`, `aerial_harrier`.
- **Approaches:** `cargo_left`, `cargo_right`, `control_upper`.
- **Transitions:** `cargo_lockdown_ambush`, then `control_booth_reposition`.
- **Recovery position:** terminal north-side floor outside the cargo-machine pinch.
- **Environment choice:** use `terminal_control` for elevation and shield flanking or remain on the lower floor for a shorter route to the powered terminal interaction.
- **Counters:** separate the hound from the shield, use machinery to break Gull marks, then contest the upper aerial pair.

## Harbour Pier — convoy phase support

- **Intent:** provide bounded support pressure synchronized to four Towmaster stops without owning boss attacks or spectacle.
- **Roles:** `melee_pursuer`, `shield_anchor`, `dive_support`, `aerial_harrier`, `space_denial`.
- **Approaches:** `land_flank`, `water_flank`, `crane_upper`.
- **Transitions:** `convoy_intercept`, `waterfront_reinforcement`, `pier_space_denial`, `final_crossfire`.
- **Recovery position:** central pier lane between authored cover clusters.
- **Environment choice:** use `pier_crane_flank` for elevated crossfire or stay central for fastest convoy-module access.
- **Counters:** preserve a route to convoy modules, clear support before committing to exposed damage windows, and use the terminal secret to cancel only the explicitly tagged optional wave-one reinforcement.
- **Boundary:** wave order, four-wave external progression, phase mapping, and approved eight-enemy budget remain unchanged for WCB-007.

## Human review remains open

A human target-Mac playthrough must assess whether each recovery lane remains practically usable, roles are readable under final WCB-008 presentation, attack directions feel fair, reinforcements are paced rather than tedious, environment choices are meaningful, and the complete route remains within the 15–22 minute target.