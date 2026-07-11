# Changelog

All notable changes are recorded here. This project follows a lightweight form of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); release versions are assigned by the owner.

## Unreleased

### Added

- Magazine and reserve-ammunition combat with manual/automatic reloads, per-weapon capacities, reload animation, and loaded/reserve HUD state.
- Original lower-pitched layered weapon synthesis, dry-fire/reload cues, grounded walking/running footsteps, and polyphonic effect playback.
- Reusable mission selector with one playable Salmon Creek course and three safely locked future-course cards.
- Responsive aspect-preserving title composition and in-game copyable playtest feedback reports.
- Release packaging tool that produces a root-entry itch.io ZIP, an unsigned versioned macOS ZIP, a staged GitHub Pages site, build metadata, and SHA-256 sums.
- Responsive, keyboard-accessible static landing page with a direct browser-play route and visible build identity.
- Release audit, playtest, deployment, known-issue, and test-evidence documentation.

### Changed

- GitHub Actions now runs the complete repository validator, both exports, package verification, evidence upload, and immutable Pages-artifact deployment.

## 0.1.0-rc — 2026-07-11

### Added

- Complete Episode 1 vertical slice from title through the Animal Control Walker finale.
- Keyboard/mouse, generic controller, hybrid, and experimental flight-stick profiles.
- Three weapons, progression pickups, three secrets, checkpoint recovery, accessibility options, and playthrough statistics.
- Original procedural audio and original/manifested visual assets.
- Headless unit, integration, route, smoke, performance-stall, and asset/IP heuristic checks.

### Fixed

- Pickup collection, out-of-bounds death, enemy grounding/deaths, projectile impacts, weapon switching, pointer capture, pause/options recovery, first-frame sizing, route continuity, and late-zone enemy activation.

See [release notes](docs/RELEASE_NOTES.md) for the evidence attached to the most recent built artifact.
