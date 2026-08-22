# OX-WCB-008L-M1B — Additive capture host and focused Godot contract

**Role:** bounded Ox Alpha writer, serialized milestone 2 of one logical lane
**Start gate:** root must independently accept and integrate M1A first. Do not start from an unverified or unintegrated M1A candidate.

## Exact owned paths

- `scenes/debug/wcb008l_frame_sequence_capture_host.tscn`
- `scripts/debug/wcb008l_frame_sequence_capture_host.gd`
- `scripts/debug/wcb008l_frame_sequence_capture_host.gd.uid`
- `tests/integration/rain_city_frame_sequence_capture_host_test.gd`
- `tests/integration/rain_city_frame_sequence_capture_host_test.gd.uid`

No other path may change.

## Purpose

Implement only the additive in-engine host and focused integration contract from `wcb008l_m1s_frame_sequence_spike.md`. The host instantiates the untouched canonical WCB-008L harness, connects before `add_child`, runs without Movie Maker, counts actual `RenderingServer.frame_post_draw` callbacks, writes exactly 60 frames to a required absolute output directory, emits one truthful non-evidence JSON receipt, and quits deferred after a post-draw flush.

Do not edit the canonical harness, production content, project settings, wrappers, verifiers, manifests, or existing tests. Do not launch the real 60-frame probe in this milestone. Make one cohesive local commit only after the focused Godot test, editor import, `git diff --check`, and exact ownership checks pass.
