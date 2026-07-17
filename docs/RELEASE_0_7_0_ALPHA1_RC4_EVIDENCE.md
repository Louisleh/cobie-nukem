# Rain City Run `0.7.0-alpha.1-rc4` release evidence

**Built:** 2026-07-17  
**Godot:** `4.7.stable.official.5b4e0cb0f`  
**Runtime feature revision:** `e1afd5a`  
**Stamped candidate:** `e07c5cacf83bcd1df1cae061f6cc45b2c1d06694`  
**Build ID:** `2026-07-17-selector-public-beta-rc4`

## Scope

- Mission-card hover and focus no longer commit a different mission.
- Click, touch, Enter, or controller accept commits the selected card and its description/action.
- Locked future cards remain inspectable but expose a disabled `LOCKED` footer action.
- Rain City Run is restored as an always-available public `BETA` with `START BETA` and its work-in-progress warning.

## Automated and packaged-browser gates

- `QA_EXPORTS=1 GODOT_BIN=/opt/homebrew/bin/godot bash tools/release_validate.sh`: PASS.
- Parser/import, unit, integration, route, adversarial, content, smoke, performance, architecture, provenance/IP, Web, and Universal macOS export gates: PASS.
- Soak evidence: 100 routes, 100 checkpoint cycles, 100 twin-stick cancellation cycles, 500 weapon transitions, 100 effect cycles, and 100 convoy cycles: PASS.
- Focused selector contract: hover/focus preserves the committed mission; locked-card activation changes details and disables Start; Rain City is launchable with an empty campaign: PASS.
- Packaged Chrome: Salmon Creek stayed selected while keyboard focus moved to Rain City; Rain City stayed selected with `START BETA` while focus moved over Mount Hood; Enter deliberately committed Mount Hood and produced `LOCKED`: PASS.
- Packaged game-origin console warnings/errors: none.
- Simulated 1024×768 touch bootstrap and normalized title composition: PASS.
- Human physical-iPad, Safari, target-Mac full route, feel, pacing, art, mix, humor, and photosensitivity gates: OPEN.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc4-itch.zip` | 35,790,381 | `aa716223e009a600ee49535277968eb1d9c7734052b1d16570fc73befb8c6f7e` |
| `cobie-nukem-0.7.0-alpha.1-rc4-macos-unsigned.zip` | 85,155,270 | `f61d9a6b7c9d134caad70ba28852d02547edd4b1588cbfd613cbe6e02d55a6cf` |
| `index-0.7.0-alpha.1-rc4.pck` | 26,282,436 | `1260693005804915d30f6163036e4ab943063a0ccfbb75380aaee0729ed8bbe8` |

## Publication record

Source PR, GitHub prerelease, website deployment, and downloaded-public-artifact identity are recorded after their respective green publication gates complete.
