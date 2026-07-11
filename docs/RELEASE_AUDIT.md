# Release Audit

Use this as the release-candidate signoff record. A checked automated item must link to a CI run or `docs/TEST_EVIDENCE.md` entry. A checked manual item must name the tester, date, platform, and build revision. “Not available” is not a pass.

## Identity and reproducibility

- [ ] Release version and full git revision are visible in the build or copied playtest report.
- [ ] Working tree is clean, or every intentional generated artifact is listed.
- [ ] Godot version begins with `4.7.stable` and matching export templates are installed.
- [ ] `CHANGELOG.md` and `docs/RELEASE_NOTES.md` describe the candidate.
- [ ] Every non-code asset is covered by `docs/ASSET_MANIFEST.md`.
- [ ] Working title has owner/legal disposition before public commercial distribution.

## Automated gates

- [ ] `QA_EXPORTS=1 bash tools/release_validate.sh` exits 0.
- [ ] Parser/import gate exits 0 without new errors.
- [ ] All unit, integration, route, scene/resource smoke, and performance-stall tests pass.
- [ ] Asset/IP heuristic passes with `rg` available.
- [ ] Asset/IP heuristic passes with `rg` unavailable.
- [ ] Web and unsigned Universal macOS exports succeed.
- [ ] `SKIP_VALIDATION=1 bash tools/package_release.sh` verifies the itch archive layout.
- [ ] SHA-256 sums and exact artifact sizes are recorded.

## Manual product gates

- [ ] Clean New Game routes through level selection into the one unlocked level.
- [ ] Every locked level card is clearly locked and cannot enter a missing scene.
- [ ] Continue restores the expected checkpoint without changing New Game semantics.
- [ ] A clean, non-debug title-to-victory playthrough completes in 12–20 minutes.
- [ ] All required items, Fetch Collar, gates, secret wall, encounters, boss phases, and finale work.
- [ ] Pawstol, Barkshot, and Fetch Launcher magazines, reserve ammo, reloads, HUD values, sound, impact, and switching feel correct.
- [ ] Footsteps match grounded walk/run motion and stop while idle, airborne, paused, or dead.
- [ ] Pause, Options, death, focus loss, and pointer-lock recovery cannot trap the player.
- [ ] Playtest report copies useful non-sensitive session details and questions.

## Visual/browser matrix

- [ ] Title and Cobie artwork inspected at 1280×720.
- [ ] Title and Cobie artwork inspected at a 16:10 Mac-style viewport.
- [ ] Main menu, level selector, locked card, gameplay, pause/options, death, and victory screenshots inspected.
- [ ] Current Chrome full playthrough over HTTP(S).
- [ ] Current Safari full playthrough over HTTP(S).
- [ ] Browser console has no uncaught game, asset, audio, or navigation errors.
- [ ] First-click audio/pointer-lock copy is accurate.

## Native and hardware matrix

- [ ] Unsigned macOS artifact launches through the documented Gatekeeper workflow on the target Mac.
- [ ] Native keyboard/mouse full playthrough is complete.
- [ ] Generic controller tested and identified by exact model.
- [ ] Flight stick tested for 20 minutes, reconnect, saved bindings, diagnostics, and full-level completion; exact model and adapter recorded.
- [ ] Native performance and memory measured with the method in `docs/QA_PLAN.md`.

## Distribution

- [ ] itch.io ZIP has `index.html`, `.js`, `.pck`, and `.wasm` at archive root.
- [ ] Pages artifact opens the landing page and `/play/` game route.
- [ ] Production host serves HTTPS and correct WebAssembly MIME types.
- [ ] No signing, deployment, DNS, or store credential is committed.
- [ ] `docs/KNOWN_ISSUES.md` contains every remaining Major issue and explicit owner disposition.
- [ ] No Blocker or Critical issue remains open.
