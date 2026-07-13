# Build and Release

## Toolchain pin

Use the standard Godot **4.7 stable** executable and matching export templates. Do not use a .NET editor/build. `project.godot` declares the `4.7` and `GL Compatibility` features; CI requests 4.7.0 explicitly.

Verify locally:

```bash
godot --version
godot --headless --path . --editor --quit
```

The version output must begin with `4.7`. A newer patch in the 4.7 stable line is acceptable after recording the exact version in release evidence. An RC/dev build is not a release toolchain.

## Local validation

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --path . --quit-after 5
```

The editor import catches resource/import/parser failures. The test runner checks contracts and feature suites. The bounded runtime launch catches bootstrap/autoload failures.

Interactive commands:

```bash
godot --editor --path .
godot --path .
godot --path . -- --input-diagnostics
```

Arguments after `--` are passed to the game and are read through `OS.get_cmdline_user_args()`.

## Export templates

In Godot, install the templates matching the exact editor version via **Editor → Manage Export Templates**. CI installs them through the setup action.

### macOS

```bash
mkdir -p builds/macos
godot --headless --path . --export-release macOS builds/macos/CobieNukem.zip
```

The preset targets a Universal binary and intentionally performs no code signing or notarization. Those steps require owner-controlled Apple credentials and an explicit release process. Unsigned local artifacts may trigger Gatekeeper warnings.

### Web

```bash
mkdir -p builds/web
godot --headless --path . --export-release Web builds/web/index.html
python3 -m http.server 8060 --directory builds/web
```

Open `http://localhost:8060`. The preset is single-threaded and does not require cross-origin isolation headers. Production hosting must use HTTPS. Browser input activation begins after user interaction and keyboard/mouse remains the supported baseline.

### Distribution packages

After both exports pass, stage the landing page and create verified distribution archives:

```bash
SKIP_VALIDATION=1 VERSION=0.6.0-alpha.4 bash tools/package_release.sh
python3 -m http.server 8060 --directory builds/pages
```

Omit `SKIP_VALIDATION=1` to have the packager rerun the full validator and both exports itself. The itch.io ZIP is verified to contain `index.html`, `index.js`, `index.pck`, and `index.wasm` at archive root. `builds/packages/SHA256SUMS.txt` records both distribution archives. See [DEPLOYMENT.md](DEPLOYMENT.md) for host-specific instructions.

## CI behavior

`.github/workflows/ci.yml` runs the full release validator, macOS/Web exports, package verification, and evidence upload on pull requests and `main`. A `main` build publishes the tested Pages artifact: a static landing page at `/` and the Godot build under `/play/`, when Pages is enabled for GitHub Actions in repository settings.

CI does not notarize, claim physical hardware testing, perform a gameplay feel assessment, or establish asset licensing. Those remain explicit release checks.

## Release evidence

For a release candidate, record in release notes:

- commit and game version;
- exact Godot/editor and export-template version;
- commands and exit codes;
- artifact names, sizes, and SHA-256 hashes;
- native macOS model/OS/manual playthrough result;
- Chrome and Safari Web playthrough result;
- controller models physically tested, adapter/hub, and diagnostics report;
- remaining known issues and any unverified Definition of Done item.

Signing and notarization are a later credentialed operation. Never place certificates, profiles, API keys, or `export_credentials.cfg` in the repository.
