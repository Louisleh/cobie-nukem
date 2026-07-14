# Salmon Creek production surface kit

These four project-original surface textures were generated for Cobie Nukem with OpenAI image generation on 2026-07-13. The prompt requested an exact 2×2 atlas of rain-darkened sports turf, utility concrete, laboratory panels, and industrial arena plating with no text, logos, objects, characters, or protected-game references. The built-in result was split deterministically into equal quadrants and normalized to 512×512 RGB PNGs with the bundled Pillow runtime.

| Asset | SHA-256 |
| --- | --- |
| `wet_turf.png` | `94f0ade6935a523e5613e9ad16bdac840406947e35818e149ce147b656cb23e6` |
| `utility_concrete.png` | `cb5ebfeb6855cde82a30ba097eaec726f94a486542f242b652b6e05ffc23298b` |
| `lab_panels.png` | `a21d340e4831c70e6a93c51058fe26f9371c948d91a2cff803fab3eac186bb52` |
| `arena_plating.png` | `fb291e658a6bdbc6e8bf1ec7601118bfa7c6d4bd0da367dc216f96ab5a8b037f` |

Runtime contract: Compatibility renderer, triplanar world-space sampling, mipmapped 512×512 sources, shared cached `StandardMaterial3D` instances, no runtime image generation, and no third-party source material.
