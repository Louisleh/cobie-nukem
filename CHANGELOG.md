# Changelog

All notable changes are recorded here. This project follows a lightweight form of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); release versions are assigned by the owner.

## Unreleased

### Added

- Repository-committed Spark orchestration with six explicitly pinned worker roles, isolated-writer contracts, validation, evidence, and independent review procedures.
- Sixteen data-authored Salmon Creek breakable, explosive, hazard, loot, and secret interactions with unique IDs, grounded placement, bounded effects, and checkpoint-safe lifecycle behavior.
- Typed Walker combat phases, phase damage floors, weak-point windows, summon limits, recovery drops, and Golden Ball-only defeat completion.
- Priority-aware, bounded captions for narrative, objectives, enemy warnings, boss phases, checkpoints, and PA cues.
- Locked Vancouver production foundation with five typed route zones, spawn volumes, patrol paths, surfaces, checkpoints, secrets, schema-v2 encounters, and a three-wave citation convoy contract.
- Honest Web download and title-menu preload states; the continue prompt is readiness-gated and failed preloads can be retried.
- Precision, Balanced, and Fast right-stick aim profiles with response curves, smoothing, delayed turn boost, and configurable target friction.
- Original illustrated future-mission cards for Vancouver Waterfront, Mount Hood, the Moon, and Ventura Pier, plus a fifth locked Ventura mission.
- Fixed twin-stick iPad controls: left movement, right rate-based aiming, simultaneous fire/actions, independent aim speeds, inversion, stick size/position presets, left-handed mirroring, and touch onboarding.
- Deterministic touch-aim and three-finger ownership coverage, with the soak gate expanded to 100 cancellation cycles, 100 checkpoint cycles, and 500 weapon transitions.
- Touch-first iPad/Web controls with independent movement and look fingers, on-screen fire/use/jump/reload/weapon/pause buttons, touch sensitivity, landscape scaling, and pointer-lock-free aiming.
- Behavioral checkpoint-respawn, mobile multi-touch, encounter failure, objective idempotence, JSON snapshot, validator-negative, and content-contract tests.
- Phase 1–2 production foundation: typed objective chains, data-driven encounter runner, three multidimensional difficulty profiles, enemy tactical archetypes, versioned level content manifests, and a headless content validator.
- Detailed multi-phase production PRD with Vancouver Waterfront, Mount Hood, and Moon mission briefs, relevant props/posters/Easter eggs, legal guardrails, and phase exit criteria.
- Mission content-authoring guide, template manifest, critical-path checklist, and regression tests for prerequisite, encounter, difficulty, and manifest contracts.
- Magazine and reserve-ammunition combat with manual/automatic reloads, per-weapon capacities, reload animation, and loaded/reserve HUD state.
- Original lower-pitched layered weapon synthesis, dry-fire/reload cues, grounded walking/running footsteps, and polyphonic effect playback.
- Reusable mission selector with one playable Salmon Creek course and three safely locked future-course cards.
- Responsive aspect-preserving title composition and in-game copyable playtest feedback reports.
- Release packaging tool that produces a root-entry itch.io ZIP, an unsigned versioned macOS ZIP, a staged GitHub Pages site, build metadata, and SHA-256 sums.
- Responsive, keyboard-accessible static landing page with a direct browser-play route and visible build identity.
- Release audit, playtest, deployment, known-issue, and test-evidence documentation.

### Changed

- Hot aim/player registry consumers now use stable read-only views instead of allocating arrays during physics ticks.
- Salmon Creek interaction construction, stable identity, callbacks, restore, and reset now live in a reusable `MissionInteractionRuntime` instead of the mission controller.
- Mission selection now uses illustrated, horizontally scrollable cards with explicit ACTIVE and COMING SOON states.
- Touch dead-zone shaping is profile-driven and aim response state is isolated from the player controller.
- Fable Phase 1–2 audit findings are triaged in the phase PRD; active encounters now reset at checkpoint retry with short spawn protection, authored enemy totals remain stable, and invalid encounters fail loudly.
- Content validation now rejects duplicate difficulties, non-finite positions, and spawn scenes without the enemy contract; difficulty profiles are cached and objective activation signals emit once.
- GitHub Actions now runs the complete repository validator, both exports, package verification, evidence upload, and immutable Pages-artifact deployment.

### Fixed

- Boss encounters now require and consume an explicit completion target; retry clears stale gameplay audio, timers, actors, summons, and phase rewards.
- Continue restores sanitized checkpoint identity immediately, and catalog loot/secrets remain deterministic across checkpoint retry.
- Authored interaction props no longer sink into floors or obstruct the Walker's central pressure lane.

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
