# Architecture

## Goals

The architecture supports one compact, complete FPS level while keeping input, gameplay, and presentation independently testable. It favors Godot-native scenes, Resources, signals, and small services over a framework or deep inheritance hierarchy.

## Runtime composition

`scenes/boot/boot.tscn` is the composition root and `scripts/core/boot.gd` is its intentionally minimal bootstrap. It records runtime information, establishes the boot phase, and honors `--input-diagnostics`. Menu and diagnostic owners subscribe to `GameState.diagnostics_requested` and route to their scene when those scenes are integrated.

The only global services are:

| Autoload | Responsibility | Must not own |
| --- | --- | --- |
| `DebugLog` | Structured runtime entries and text export | gameplay decisions |
| `SettingsManager` | Version-independent user preferences in `user://settings.cfg` | checkpoint/run progress |
| `SaveManager` | Versioned JSON slots under `user://saves` | live scene references |
| `InputManager` | Stable device/action boundary and control-method detection | movement or weapon behavior |
| `AudioManager` | Applying persisted levels to known audio buses | music encounter logic |
| `GameState` | Coarse phase and current-run summary | mutable entity state |
| `SceneRouter` | Validated scene replacement | level progression rules |

No feature should reach through an autoload to mutate another feature's nodes. Prefer a signal or an explicit method call at the owning component boundary.

## Shared contracts

- `DamagePacket` carries damage amount, origin, world hit data, and a stable damage type. Health components decide armor and health math.
- `Interactable` defines the common prompt, availability query, completion signal, and `interact(actor)` entry point. Feature-specific interactables override it while preserving the return contract.
- Stable IDs use `StringName`. Save files store IDs and primitive data, never Nodes or resource instance IDs.

Feature systems may introduce additional contracts in their owned directory. Promote one to `scripts/core/contracts` only when at least two independent domains consume it.

The reusable production gameplay layer lives in `scripts/gameplay`:

| Contract | Responsibility |
| --- | --- |
| `ObjectiveDefinition` / `ObjectiveTracker` | Data-driven required/optional goals, prerequisite chains, progress, and primitive snapshots |
| `EncounterDefinition` / `EncounterRunner` | One-shot zone encounters, spawn lifecycle, target assignment, and completion |
| `DifficultyProfile` | Independent enemy pressure, pickup, and aim-assist tuning dimensions |
| `ContentManifest` | Versioned machine-readable inventory for a production mission |

Mission controllers translate mission-specific events into these semantic contracts. They still own geometry, prose, set pieces, and fail-safe progression, but they do not own reusable encounter tables or objective state machines.

## Scene and resource boundaries

- A level scene composes player spawn, encounter instances, progression interactables, and level metadata.
- Player movement consumes normalized intent from the input layer. It does not inspect joystick device IDs.
- Weapons consume a data definition and emit damage/impact requests; they do not update HUD nodes directly.
- Enemies expose targetability and damage boundaries used by auto-aim/combat, with presentation under the enemy scene.
- UI observes signals/state and invokes public service/component methods. It does not become authoritative gameplay state.

Weapon, enemy, pickup, auto-aim, difficulty, input-profile, and level-metadata balance belongs in Resources. Scripts contain behavior and invariants, not per-instance balance tables.

## Input flow

```text
Godot device event
  -> InputManager / profile calibration
  -> named InputMap action or normalized intent
  -> player/menu consumer
  -> gameplay outcome signal
  -> HUD/audio/feedback observers
```

Raw axis and button numbers stop at the input subsystem. Keyboard/mouse is the recovery path for every screen. Browser device names and mappings are advisory, never sufficient to select a trusted hardware profile automatically.

## Rendering

The project viewport is 640×360 with `canvas_items` stretch. Compatibility (`gl_compatibility`) is configured for desktop and mobile rendering methods, and canvas textures default to linear filtering. This preserves a crisp high-resolution-retro presentation without the visibly pixelated 320×180 prototype baseline.

Low-poly 3D geometry, billboarded sprites, simple fog/unshaded materials, and limited dynamic lights are the performance baseline. Web export is single-threaded.

## Persistence

- Settings: Godot `ConfigFile`, defaults filled without overwriting user choices.
- Checkpoint/progress: versioned JSON envelope per save slot.
- Input profiles: owned by the input system, stored under `user://` through an explicit serializable representation.
- Compatibility policy: incompatible save envelopes are rejected safely; migrations must be explicit and tested.

Writes do not contain personal data. Corrupt or unavailable data falls back without trapping the player.

## Error handling and diagnostics

Recoverable external conditions (missing controller, failed profile load, unsupported Web mapping) use warnings and fallback behavior. Broken invariants (missing critical scene, invalid required resource) fail tests/CI. `DebugLog` can export newline-delimited JSON entries for hardware support without telemetry.

## Extension rules

Before adding a new global or abstraction, answer:

1. Does ownership already exist in a node/component or one of the seven autoloads?
2. Can a signal or Resource express the boundary?
3. Can it instantiate and test headlessly?
4. Does it remain valid in the single-threaded Web build?

Document material exceptions in `docs/DECISIONS.md`.
