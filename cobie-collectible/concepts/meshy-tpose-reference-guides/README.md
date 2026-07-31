# Cobie T-pose reference guides

These five images were generated with OpenAI image generation on 2026-07-31
as vendor-facing, image-conditioned T-pose references for a possible hosted
image-to-3D experiment.

They are useful visual references, but they are **not** the canonical Phase 1
turnaround inputs and they do not clear a pipeline gate:

- the four cardinal images are not dimension-normalized;
- the set has no neutral three-quarter `hero` input;
- the pose is a full T-pose rather than the frozen neutral A-pose;
- the combined sheet contains only three views;
- no image-to-3D run, identity approval, mesh bakeoff, or physical validation
  has occurred.

Keep these files out of `concepts/turnaround/`. Before using them as generator
inputs, regenerate a complete five-view set through
`references/turnaround-prompts.md`, normalize dimensions and framing, run
`scripts/validate_turnaround.py`, and complete the human identity checklist.

## Files

| File | Dimensions | SHA-256 |
| --- | --- | --- |
| `cobie_tpose_front_v1.png` | 1023 x 1537 | `4f0c99fdf8f2f55dead41125f00535fdc8ff6924dec41d49c239a7c5f2164264` |
| `cobie_tpose_left_v1.png` | 1024 x 1536 | `040ed32ba8bbcefc809947b5e691bcf97245d47a88a3f91f34c0a7c68d0fb38f` |
| `cobie_tpose_rear_v1.png` | 1023 x 1537 | `c2c6852ab47321e35991afc4fa3aa6f4c87b84dabf3769df7af1f8b91ec38c37` |
| `cobie_tpose_right_v1.png` | 1023 x 1537 | `47dbdad3da68fa247923a9c44b8bb5908bce8eb5267eb67baa6269ff3a002a54` |
| `cobie_tpose_turnaround_sheet_v1.png` | 1774 x 887 | `c2ea955431bf8a5207b08e0497d8e46095d84be87996a68351e60f700d7ed8ce` |

The images are project-original generated concepts. They are not runtime game
assets, printable geometry, or evidence of a manufacturing-ready model.
