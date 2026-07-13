# Enemy presentation atlases

These atlases are project-original derivative assets generated for Cobie Nukem on 2026-07-13 with OpenAI image generation. Each canonical project-original character cutout was supplied as the sole identity reference. No third-party game art, characters, brands, or protected franchise material was used.

| Production asset | Canonical reference | Layout | SHA-256 |
| --- | --- | --- | --- |
| `leash_enforcement_drone_atlas.png` | `../leash_enforcement_drone.png` | 4 directional locomotion views + alert, attack, hurt, death | `9ac5924f9bb3af4e11abf1e5375d61e108ed1dd64c0332bb1384650af61cb8bb` |
| `mutant_groundskeeper_atlas.png` | `../mutant_groundskeeper.png` | 4 directional locomotion views + alert, attack, hurt, death | `f38c11d90dc2c11629d99026f5122298b729948227a6762c4769366fc36e5d19` |
| `squirrel_trooper_atlas.png` | `../squirrel_trooper.png` | 4 directional locomotion views + alert, attack, hurt, death | `76d434e45c856c21251f5103f7c0215a785a048b828acb00eef1235bc84039f4` |

Generation contract: one exact 4-by-2 grid, stable identity/costume/scale, upper-left lighting, flat magenta chroma background, no text, logos, scenery, gore, watermark, or extra anatomy. The second row explicitly requested alert, attack, hurt/stagger, and defeated poses. The built-in image-generation workflow produced the RGB masters; the installed imagegen chroma helper removed the flat background with soft matte, despill, and one-pixel edge contraction. RGB chroma intermediates remain in the protected Codex generation cache and are intentionally excluded from the game package.

Runtime/import contract: one shared texture per enemy instance, `Sprite3D.hframes = 4`, `vframes = 2`, Compatibility renderer, lossless source import, no runtime image mutation, and no per-frame texture allocation.
