# Enemy presentation atlases

These atlases are project-original derivative assets generated for Cobie Nukem on 2026-07-13 with OpenAI image generation. Each canonical project-original character cutout was supplied as the sole identity reference. No third-party game art, characters, brands, or protected franchise material was used.

| Production asset | Canonical reference | Layout | SHA-256 |
| --- | --- | --- | --- |
| `leash_enforcement_drone_atlas.png` | `../leash_enforcement_drone.png` | 4 directional locomotion views + alert, attack, hurt, death | `9ac5924f9bb3af4e11abf1e5375d61e108ed1dd64c0332bb1384650af61cb8bb` |
| `mutant_groundskeeper_atlas.png` | `../mutant_groundskeeper.png` | 4 directional locomotion views + alert, attack, hurt, death | `f38c11d90dc2c11629d99026f5122298b729948227a6762c4769366fc36e5d19` |
| `squirrel_trooper_atlas.png` | `../squirrel_trooper.png` | 4 directional locomotion views + alert, attack, hurt, death | `76d434e45c856c21251f5103f7c0215a785a048b828acb00eef1235bc84039f4` |
| `compliance_hound_atlas.png` | `../compliance_hound.png` | 8×4 directional idle/locomotion and explicit reaction vocabulary | `2790a72cf0fd62a45bd6eacdfad6de5fd11c92226351962d1341b7892a171bc1` |
| `animal_control_walker_atlas.png` | `../animal_control_walker.png` | 8×4 directional idle/locomotion and boss reaction vocabulary | `db1c93fcfd0f94846c46aa4c11a8d628b4c7b01fa95f50e70b4a4eae08c35963` |

Generation contract: one exact 4-by-2 grid, stable identity/costume/scale, upper-left lighting, flat magenta chroma background, no text, logos, scenery, gore, watermark, or extra anatomy. The second row explicitly requested alert, attack, hurt/stagger, and defeated poses. The built-in image-generation workflow produced the RGB masters; the installed imagegen chroma helper removed the flat background with soft matte, despill, and one-pixel edge contraction. RGB chroma intermediates remain in the protected Codex generation cache and are intentionally excluded from the game package.

Runtime/import contract: one shared texture per enemy instance, `Sprite3D.hframes = 4`, `vframes = 2`, Compatibility renderer, lossless source import, no runtime image mutation, and no per-frame texture allocation.

Alpha.8 elite/boss contract: the Hound and Walker were generated from their project-original canonical cutouts as exact directional/reaction sheets on a flat magenta key, processed with the installed imagegen soft-matte/despill helper, normalized to a 1536×1024 8×4 grid, and bound through typed `EnemyPresentationProfile` Resources. The Walker generator returned three authored rows; its locomotion row is deliberately duplicated into the alternate-gait slot rather than inventing or mislabelling a missing view. Runtime still alternates the two slots deterministically and can accept a distinct authored gait in a later asset-only revision.
