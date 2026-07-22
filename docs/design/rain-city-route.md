# Rain City spatial route contract

## Scope

WCB-005 owns Rain City Run's traversable geometry, route graph, collision/navigation sources, stateful route gate, canonical sightline probes, secret placement rationale, and landmark anchors. It does not approve visual taste, encounter choreography, boss design, or final art/audio identity.

Gameplay collision and navigation remain owned by `VancouverWaterfrontWorldBuilder` and `RainCitySpatialRouteBuilder`. `RainCityMaterialApplier` and `ZonePresentationProfile` may replace presentation without moving or owning those nodes.

## Frozen mechanical topology

The required lower accessibility route remains continuous from the opening checkpoint to harbour departure. Optional spatial features are:

| Feature | Kind | Mechanical contract |
|---|---|---|
| `seawall_overlook` | vertical loop | North stair, elevated concrete lane, and south stair reconnect to the lower seawall. |
| `terminal_control` | vertical loop | North stair, elevated control lane, and south stair reconnect to the lower terminal. |
| `pier_crane_flank` | vertical loop | North stair, elevated steel flank, and south stair reconnect to the lower pier. |
| `rainline_return` | powered shortcut/revisit | Terminal control lane connects back to the seawall upper lane; `terminal_power` opens its collision gate. |

`resources/routes/vancouver_route_definition.tres` declares the optional `terminal_service → waterfront_seawall` revisit edge. `MissionRouteRuntime` still advances objectives/checkpoints only to the next ordered zone; walking the optional edge must not regress progression.

## Route-state and checkpoint invariant

The Rain Line return gate starts collision-closed. Completing `restore_terminal` opens it. New runs and reset state close it. Checkpoint restoration reopens it exactly when the restored objective snapshot contains `restore_terminal`.

The waterfront secret is an interaction-backed Rain Line ball-return cache on the elevated seawall side of the powered return. Its stable secret and persistence IDs do not change.

## Sightline and landmark evidence

Mechanical sightline probes:

- `slice_to_seawall`: Rain City Slice into the seawall, targeting `vancouver_waterfront_pier`.
- `terminal_to_harbour`: terminal service into harbour, targeting `vancouver_harbour_mast`.

Automated tests raycast those probes against gameplay collision. Canonical landmark anchors bind:

- opening → `vancouver_downtown_waypoint`;
- mid-route → `vancouver_waterfront_pier`;
- finale → `vancouver_harbour_mast`.

These IDs must exist in their `ZonePresentationProfile` contracts. Automation proves declaration, collision clearance, and aspect-family capture assembly; it does not prove that a landmark is recognizable within ten seconds.

## Verification split

Mechanical acceptance requires:

- exactly three route loops, each with distinct entry/path/exit geometry;
- at least two elevated paths present in the baked navigation map;
- two unobstructed cross-zone collision raycasts;
- one collision-backed state gate bound to `terminal_power`;
- the optional revisit graph edge and checkpoint-safe gate restoration;
- exactly four stable interaction-backed secrets, including the gated return cache;
- opening/mid/finale anchors bound to manifested landmark IDs;
- opening-to-departure lower-route navigation remains connected.

Human review remains open for:

- 15–22 minute first-playthrough pacing;
- whether each loop/shortcut is meaningful in combat rather than merely traversable;
- landmark recognition within ten seconds at 16:9 and 4:3;
- readability, composition, comfort, and environmental identity.

The canonical automated review prompt is `vancouver_waterfront` at `1280x720` and `1024x768`. Differences are review prompts, not taste decisions. No new art asset or provenance entry is introduced by WCB-005 route geometry.
