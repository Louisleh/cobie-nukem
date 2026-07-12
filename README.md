# Cobie Nukem: Retro Mayhem 3D

An original, macOS-first retro FPS vertical slice starring Cobie, an aviator-wearing labradoodle action hero. The canonical experience targets native macOS and an inexpensive flight stick; a keyboard/mouse-first Web build is secondary.

> Status: ambitious family-playtest RC. The complete title-to-victory loop, magazine/reload combat, grounded footsteps, mission selector, playtest-report flow, accessibility UI, automated suite, and macOS/Web/itch packaging are implemented.

## Requirements

- Godot **4.7 stable**, standard build (not .NET)
- macOS or Linux for local development; macOS is the primary runtime target
- Python 3 for serving a local Web export
- Godot 4.7 export templates for export commands

The project deliberately uses GDScript and the Compatibility renderer so it can export to the Web. The retro UI is authored on a 320×180 canvas, while the 3D world renders at the output resolution for cleaner geometry and illustrated enemy sprites.

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

Require both release exports and create distribution packages:

```bash
QA_EXPORTS=1 bash tools/release_validate.sh
SKIP_VALIDATION=1 VERSION=0.6.0-alpha.1 bash tools/package_release.sh
python3 -m http.server 8060 --directory builds/pages
```

Open `http://127.0.0.1:8060/` for the landing page or `http://127.0.0.1:8060/play/` for the game. The packager also creates an itch.io-ready ZIP with `index.html` at archive root and a versioned unsigned macOS ZIP.

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

Open `http://localhost:8060`. Browser joystick support is experimental; keyboard/mouse must always remain available. Full local build details are in [Build and Release](docs/BUILD_AND_RELEASE.md); publishing steps are in [Deployment](docs/DEPLOYMENT.md).

## Default controls

Keyboard/mouse defaults use WASD, mouse look, left/right mouse fire, E interact, Space jump, Shift run, R reload, Up/Down or debounced-wheel weapon cycle (or 1/2/3 direct selection), and Escape pause. Flight-stick Classic 1996, Hybrid, remapping, and calibration are implemented through the input subsystem and remain subject to physical hardware verification.

The target Thrustmaster USB Joystick model 2960623 is **not verified on macOS** until it passes the physical checklist in the PRD. An M4 Mac mini requires a USB-A-to-USB-C adapter or hub.

## Vertical slice

Episode 1, Level 1 runs from the forbidden Salmon Creek sports field through the equipment shed, maintenance tunnels, Animal Compliance Lab, optional secret dog park, and Animal Control Walker arena. It includes three weapons, three regular enemies, the Compliance Hound elite, a four-phase boss, three secrets, a checkpoint, environmental jokes, the Golden Tennis Ball finale, and end-of-level rank statistics. Runtime-generated music and effects use original synthesis with no bundled third-party samples.

## Project map

- `docs/PRD.md` — product and acceptance source of truth
- `docs/ARCHITECTURE.md` — service boundaries, contracts, and runtime flow
- `docs/IMPLEMENTATION_PLAN.md` — milestones, ownership, and integration gates
- `docs/BUILD_AND_RELEASE.md` — local/CI build and release procedure
- `docs/DEPLOYMENT.md` — GitHub Pages, itch.io, and unsigned macOS delivery
- `docs/RELEASE_AUDIT.md` — automated, manual, browser, and hardware signoff gates
- `docs/PLAYTEST_GUIDE.md` — family-test instructions and evidence prompts
- `docs/TEST_EVIDENCE.md` — candidate-by-candidate evidence record
- `docs/KNOWN_ISSUES.md` — confirmed limitations and deliberately unperformed checks
- `CHANGELOG.md` — human-readable release history
- `project.godot` — shared engine, autoload, action, and render configuration
- `scripts/core` — intentionally small global services and shared contracts
- `tests` — dependency-free headless contract tests plus feature tests
- `builds/macos/CobieNukem.zip` — unsigned Universal macOS artifact after export
- `builds/web/index.html` — single-thread browser build after export
- `builds/pages/index.html` — packaged landing page; game is staged under `builds/pages/play/`
- `builds/packages/*-itch.zip` — browser upload with the game entry point at archive root

## IP and assets

Do not add Duke Nukem code, maps, sprites, textures, audio, dialogue, logos, or extracted game files. Every asset must be original, user-provided, CC0, or permissively licensed and recorded in `docs/ASSET_MANIFEST.md`. The working title requires an IP/name review before public commercial release.

## Contributing

Read `AGENTS.md` before editing shared files. Keep the project importable, prefer data-driven resources, use named input actions rather than raw controls, and document any material PRD deviation in `docs/DECISIONS.md`.

For a playtest candidate, use [the playtest guide](docs/PLAYTEST_GUIDE.md) and do not describe automated route checks as a human playthrough. Physical controller and flight-stick compatibility remains unverified until an exact-device test is recorded.
