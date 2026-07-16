# Visual review packet

Every candidate packet records:

- work ID, source revision, runtime revision, Godot version, platform, quality profile, viewport, render FPS, physics TPS, and capture manifest version;
- before/candidate images with identical staging plus a generated difference image;
- dimensions, alpha/blank coverage, luminance distribution, contrast, perceptual-difference metrics, and safe-area result;
- a short deterministic motion sequence for animated work;
- native frame-time/draw-call/object/memory evidence and packaged-Web trace evidence when the change affects public rendering;
- source paths, runtime paths, hashes, tool versions, authoring method, and license/provenance;
- functional tests and cleanup/leak results;
- known compromises by Web/native quality tier;
- explicit human questions: hierarchy, readability, cohesion, motion comfort, humor, touch comfort, and photosensitivity.

Automated image difference is never an artistic pass/fail verdict. Hard failure is limited to missing capture, wrong dimensions, invalid/blank/transparent output, safe-area contract violations, import/runtime errors, or measurable budget violations.
