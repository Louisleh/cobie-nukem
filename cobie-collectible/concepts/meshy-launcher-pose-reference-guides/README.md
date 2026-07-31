# Cobie launcher-pose reference guides

These three images were generated with OpenAI image generation on 2026-07-31
as vendor-facing visual references for a possible single-launcher collectible.
They are project-original concept images, not third-party source art.

They preserve useful identity, jacket, stance, grip, and Fetch Launcher cues,
but they are **not** a canonical turnaround or production gate:

- the views were generated independently rather than rendered from one model;
- only front, side, and rear views exist;
- the weapon position and occluded anatomy are not geometry-consistent;
- the backgrounds are opaque and dimensions are not normalized to the frozen
  five-view input contract;
- no image-to-3D run, mesh approval, print bakeoff, or physical validation has
  occurred.

Keep these files out of `concepts/turnaround/`. Use them only as secondary
look-development references. Any production generator input must be rebuilt as
a dimension-matched five-view set and pass `scripts/validate_turnaround.py`.

## Files

| File | Dimensions | SHA-256 |
| --- | --- | --- |
| `cobie_launcher_pose_front_v1.png` | 1023 x 1537 | `85e9b4347d93db084ef19115ed790ad333d217e0af4ef3e69b6e000b645ae393` |
| `cobie_launcher_pose_side_v1.png` | 1023 x 1537 | `69ac98b55d59277e2376f8c4700a2dabfdb5709717f2b8c6ed6ae407079ed191` |
| `cobie_launcher_pose_rear_v1.png` | 1023 x 1537 | `b0598f9f6a84ae6f3b09db4679e5cf8969f76467d7bae297a150033cec3812ed` |

These files are not runtime game assets, printable geometry, or evidence of a
manufacturing-ready model.
