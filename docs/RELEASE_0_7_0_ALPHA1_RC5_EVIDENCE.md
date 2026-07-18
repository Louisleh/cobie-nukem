# Rain City Run `0.7.0-alpha.1-rc5` release evidence

## Release identity

- Version: `0.7.0-alpha.1-rc5`
- Gameplay/runtime feature revision: `38f8164`
- Build ID: `2026-07-17-rain-city-foundry-rc5`
- Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`
- Public status: Rain City remains visibly labelled `BETA`; Mount Hood remains locked.

## Included production work

- Ten manifested Rain City runtime material families with albedo, normal, and packed ORM sources; lightweight albedo-only route floors retain Web/tablet performance.
- Five explicit Rain City environment identities with texture, material, surface, dominant-landmark, and background-landmark contracts.
- Zone presentation now applies environment/weather profiles and tears weather down deterministically on mission exit.
- A source-controlled Mount Hood foundry foundation: ten material families; original mountain, lodge, snowbank, fir, snowman, sign, and chairlift geometry; four-aspect pilot captures; no public scene, collision, navigation, or unlock change.
- PRD, manual checklist, known issues, asset/provenance manifest, architecture validation, and GitHub issue scope reconciled.

## Automated evidence

- Fresh `QA_EXPORTS=0` release validation passes parser/import, unit/integration/content/architecture/asset-IP, both mission routes, 100-route/checkpoint/touch/effect soaks, 500 weapon transitions, 100 Towmaster cycles, 66 scenes, and 95 resources.
- Foreground native Compatibility profile at 1280×720 samples 300 frames per zone. Rain City p95/p99: alley 17.447/23.337 ms; Slice 20.978/21.625; seawall 17.532/21.546; terminal 17.368/17.689; pier 17.485/20.358. Draw calls range from 200 to 403 and static memory remains near 83.6 MB.
- Zero recurring >100 ms stalls were observed. One isolated 1,054.530 ms macOS scheduling pause occurred in the pier sample and is retained honestly in the evidence.
- Mount Hood visual evidence exists at 16:9, 16:10, 4:3, and ultrawide. This proves the asset-foundation identity, not final art or gameplay.
- Full `QA_EXPORTS=1` validation passes on the stamped candidate, including Web and unsigned Universal macOS exports.
- Packaged browser checks pass at 1280×720 and simulated 1024×768 touch. Mission hover remains non-committing, Rain City is selectable as `BETA`, Mount Hood stays locked, and the touch HUD/portrait remain within the viewport.
- Chrome DevTools on the packaged build at 1024×768 touch, Fast 4G, and 2× CPU reports LCP 1.104 s, CLS 0.00, six successful cache-keyed requests, and no console warning/error. Physical-iPad conclusions remain open.

## Packaging and publication

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc5-itch.zip` | 45,804,160 | `10f51be8bd878cb519a41a3bce02f64f97fbc8b3eabceaf58369bb8c38ba2db0` |
| `cobie-nukem-0.7.0-alpha.1-rc5-macos-unsigned.zip` | 90,950,568 | `5006c14750c12209f8088db9e6718f7081650f5cbe755cdc5f594f701f13bc95` |
| `index-0.7.0-alpha.1-rc5.pck` | 38,229,008 | `a53c5ccc3b11222d55000d36dc547c508ca6a0683f13184ce3e5634b668b1bfa` |

The packaged Web directory is 74 MB, below the 90 MB target and 100 MB hard ceiling.

Publication completed through source PR [#55](https://github.com/Louisleh/cobie-nukem/pull/55) at integration commit `23511c191fb3eb08344993bd73114ae6a7fbb1af`. The exact packages are attached to the GitHub prerelease [`v0.7.0-alpha.1-rc5`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc5).

Website PR [#126](https://github.com/Louisleh/louislehmann-site/pull/126) deployed the cache-keyed Web artifact at commit `d51a92639d962fe79a35dcb9b5aeb654298a51af`. Vercel production deployment passed, and both the ordinary and uncached public URLs report version `0.7.0-alpha.1-rc5` with gameplay revision `38f8164`. The downloaded 38,229,008-byte public PCK is byte-identical to the local packaged artifact at SHA-256 `a53c5ccc3b11222d55000d36dc547c508ca6a0683f13184ce3e5634b668b1bfa`. The rollback release remains [`v0.7.0-alpha.1-rc4`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc4).

## Human-only gates still open

- Physical iPad Safari full routes, simultaneous twin-stick comfort, audio, thermals, focus/app switching, and portrait/enemy scale.
- Target-Mac and desktop Safari full playthroughs, Story/Mayhem spot checks, route duration, encounter/Towmaster fairness, contact motion, and navigation feel.
- Art cohesion, material readability, audio mix, humor, reduced-motion/flash comfort, and photosensitivity review.

These gates prevent removal of Rain City's `BETA` badge and prevent calling `0.7.0-alpha.1` final. They do not block an honestly labelled public RC.
