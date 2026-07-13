# Autonomous Stabilization Goal — `0.6.0-alpha.2`

## Objective

Ship a publicly playable Cobie Nukem `0.6.0-alpha.2` stabilization release that makes startup state explicit, improves iPad right-stick aiming without reintroducing swipe-look, and turns the mission selector into an illustrated roadmap for Vancouver Waterfront, Mount Hood, the Moon, and Ventura Pier.

## Autonomous execution contract

1. Start from latest green `main`; remove only audited accidental duplicates and preserve owner work.
2. Capture the native/Web baseline before changing behavior.
3. Replace the ambiguous startup prompt with two honest states: Web download/engine boot, then in-game menu preload. Input remains disabled until the title is ready.
4. Keep the left movement stick and right aim stick. Add profile-driven dead zone, response curve, frame-rate-stable smoothing, delayed outer-ring turn boost, target friction, independent axis sensitivity, inversion, and settings presets. Never restore swipe aiming.
5. Create original, text-free 16:9 teaser art for Vancouver Waterfront, Mount Hood, the Moon, and Ventura Pier; record provenance and optimize for Web.
6. Add a fifth locked Ventura mission card. Every current/future mission card has preview art, narrow-screen horizontal reachability, and an honest active/coming-soon state.
7. Add regression coverage for readiness gating, five-card content, art presence, touch response, release cancellation, and supported viewports.
8. Run parser, unit, integration, route, soak, smoke, content, architecture, IP/provenance, native export, Web export, and package checks. Fix defects rather than weakening gates.
9. Update the single phase PRD, decisions, known issues, changelog, evidence, release notes, and build identity.
10. Merge source through a green PR, deploy the exact Web artifact through the website repository, and verify the public revision. Keep physical-iPad comfort, thermal behavior, and family feel as honest human gates.

## Acceptance gates

- No press/tap-to-continue prompt appears while loading is still in progress.
- A failed preload offers retry and never routes to a partially loaded menu.
- Touch aim release produces no drift or latched input.
- Precision/Balanced/Fast profiles and friction/turn-boost settings persist.
- All five mission cards fit through horizontal scrolling; exactly Salmon Creek is playable.
- Four new poster assets are original, manifested, and visible on their cards.
- `QA_EXPORTS=1 bash tools/release_validate.sh` and packaging pass.
- Public files, source revision, visible build label, and checksums agree.

## Human-only release follow-up

- Physical iPad Safari: stick reach, thumb fatigue, sensitivity, focus loss, audio unlock, heat, and sustained frame pacing.
- Family playtest: aim confidence, accidental firing, readability, difficulty, humor, and future-mission appeal.
