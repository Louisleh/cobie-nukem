# Cobie Nukem: Retro Mayhem 3D

An original, macOS-first retro FPS vertical slice starring Cobie, an aviator-wearing labradoodle action hero. The canonical experience targets native macOS and an inexpensive flight stick; a keyboard/mouse-first Web build is secondary.

> Status: playable vertical-slice release candidate. The complete title-to-victory loop, input setup, accessibility UI, automated test suite, and macOS/Web export presets are implemented.

## Requirements

- Godot **4.7 stable**, standard build (not .NET)
- macOS or Linux for local development; macOS is the primary runtime target
- Python 3 for serving a local Web export
- Godot 4.7 export templates for export commands

The project deliberately uses GDScript and the Compatibility renderer so it can export to the Web. Internal rendering defaults to 320×180 and scales to the display with nearest-neighbor filtering.

## Quick start

```bash
godot --editor --path .
godot --path .
```

If the executable is named `godot4` on your machine, substitute that name in every command.

Run the headless project and contract tests:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
bash tools/release_validate.sh
```

Launch input diagnostics:

```bash
godot --path . -- --input-diagnostics
```

## Exports

Install matching Godot 4.7 export templates, then run:

```bash
mkdir -p builds/macos builds/web
godot --headless --path . --export-release macOS builds/macos/CobieNukem.zip
godot --headless --path . --export-release Web builds/web/index.html
python3 -m http.server 8060 --directory builds/web
```

Open `http://localhost:8060`. Browser joystick support is experimental; keyboard/mouse must always remain available. Full details are in [docs/BUILD_AND_RELEASE.md](docs/BUILD_AND_RELEASE.md).

## Default controls

Keyboard/mouse defaults use WASD, mouse look, left/right mouse fire, E interact, Space jump, Shift run, mouse wheel weapon cycle, and Escape pause. Flight-stick Classic 1996, Hybrid, remapping, and calibration are implemented through the input subsystem and remain subject to physical hardware verification.

The target Thrustmaster USB Joystick model 2960623 is **not verified on macOS** until it passes the physical checklist in the PRD. An M4 Mac mini requires a USB-A-to-USB-C adapter or hub.

## Vertical slice

Episode 1, Level 1 runs from the forbidden Salmon Creek sports field through the equipment shed, maintenance tunnels, Animal Compliance Lab, optional secret dog park, and Animal Control Walker arena. It includes three weapons, three regular enemies, the Compliance Hound elite, a four-phase boss, three secrets, a checkpoint, environmental jokes, the Golden Tennis Ball finale, and end-of-level rank statistics. Runtime-generated music and effects use original synthesis with no bundled third-party samples.

## Project map

- `docs/PRD.md` — product and acceptance source of truth
- `docs/ARCHITECTURE.md` — service boundaries, contracts, and runtime flow
- `docs/IMPLEMENTATION_PLAN.md` — milestones, ownership, and integration gates
- `docs/BUILD_AND_RELEASE.md` — local/CI build and release procedure
- `project.godot` — shared engine, autoload, action, and render configuration
- `scripts/core` — intentionally small global services and shared contracts
- `tests` — dependency-free headless contract tests plus feature tests
- `builds/macos/CobieNukem.zip` — unsigned Universal macOS artifact after export
- `builds/web/index.html` — single-thread browser build after export

## IP and assets

Do not add Duke Nukem code, maps, sprites, textures, audio, dialogue, logos, or extracted game files. Every asset must be original, user-provided, CC0, or permissively licensed and recorded in `docs/ASSET_MANIFEST.md`. The working title requires an IP/name review before public commercial release.

## Contributing

Read `AGENTS.md` before editing shared files. Keep the project importable, prefer data-driven resources, use named input actions rather than raw controls, and document any material PRD deviation in `docs/DECISIONS.md`.
